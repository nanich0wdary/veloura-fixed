import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/splash/screens/splash_screen.dart';
import 'features/chat/screens/chat_screen.dart';
import 'features/mood/screens/mood_screen.dart';
import 'features/memories/screens/memories_screen.dart';
import 'features/pairing/screens/pairing_screen.dart';
import 'features/pairing/providers/pairing_provider.dart';
import 'features/sync/screens/sync_screen.dart';
import 'features/onboarding/screens/setup_screen.dart';
import 'features/onboarding/screens/profile_screen.dart';
import 'features/lock/app_lock_screen.dart';
import 'core/services/sync_provider.dart';
import 'core/services/notification_service.dart';
import 'core/services/background_sync_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/hive_migration_service.dart';
import 'core/services/biometric_service.dart';
import 'core/services/screenshot_protection_service.dart';
import 'core/identity/identity_service.dart';
import 'core/p2p/p2p_provider.dart';
import 'features/settings/screens/settings_screen.dart';
import 'core/services/keepalive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) debugPrint('Uncaught error: $error\n$stack');
    return true;
  };

  // Disable Google Fonts runtime fetching — fonts served from package assets
  // This improves privacy (no Google CDN calls) and works offline
  GoogleFonts.config.allowRuntimeFetching = false;

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));

  try { await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); } catch (_) {}
  try { await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]); } catch (_) {}

  // Hive init — all boxes encrypted with device-specific AES key
  try {
    await Hive.initFlutter();
    // Secure key management — generate once, store in encrypted storage
    final sec = FlutterSecureStorage(   // final not const — not a compile-time constant
        aOptions: const AndroidOptions(encryptedSharedPreferences: true));
    String? hexKey = await sec.read(key: 'hive_encryption_key');
    if (hexKey == null) {
      final rng   = Random.secure();
      final bytes = Uint8List.fromList(
          List.generate(32, (_) => rng.nextInt(256)));
      hexKey = bytes.map((b) => b.toRadixString(16).padLeft(2,'0')).join();
      await sec.write(key: 'hive_encryption_key', value: hexKey);
    }
    final resolvedKey = hexKey; // promote to non-null for use in closure
    final keyBytes = Uint8List.fromList(
        List.generate(resolvedKey.length ~/ 2,
            (i) => int.parse(resolvedKey.substring(i*2, i*2+2), radix: 16)));
    final cipher = HiveAesCipher(keyBytes);

    await Future.wait([
      Hive.openBox('veloura_messages', encryptionCipher: cipher),
      Hive.openBox('veloura_memories', encryptionCipher: cipher),
      Hive.openBox('veloura_mood',     encryptionCipher: cipher),
      Hive.openBox('veloura_pairing',  encryptionCipher: cipher),
      Hive.openBox('veloura_partner',  encryptionCipher: cipher),
    ]);
    await HiveMigrationService.instance.runMigrations();
    if (kDebugMode) debugPrint('Hive: all boxes AES-encrypted ✅');
  } catch (e, st) {
    if (kDebugMode) debugPrint('Hive init failed: \$e\n\$st');
  }

  // Init all services
  await NotificationService.instance.init();
  await BackgroundSyncService.instance.init();
  await ConnectivityService.instance.init();
  await IdentityService.instance.init();

  // Enable screenshot protection (Android FLAG_SECURE)
  await ScreenshotProtectionService.instance.enable();
  // Init keepalive for WebRTC connection
  KeepaliveService.instance; // singleton ready

  runApp(const ProviderScope(child: VelouraApp()));
}

class VelouraApp extends ConsumerWidget {
  const VelouraApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Veloura',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC084FC),
          secondary: Color(0xFFF472B6),
        ),
      ),
      home: const SplashEntry(),
    );
  }
}

// ── Splash → Lock → Onboarding → Home ────────────────────────

class SplashEntry extends StatefulWidget {
  const SplashEntry({super.key});
  @override
  State<SplashEntry> createState() => _SplashEntryState();
}

class _SplashEntryState extends State<SplashEntry> {
  bool _splashDone  = false;
  bool _identitySet = false;
  bool _locked      = false;

  @override
  Widget build(BuildContext context) {
    // Biometric lock screen
    if (_splashDone && _identitySet && _locked) {
      return AppLockScreen(
        onUnlocked: () => setState(() => _locked = false),
      );
    }
    // Identity setup (first launch)
    if (_splashDone && !_identitySet) {
      return SetupScreen(
        onComplete: () => setState(() => _identitySet = true),
      );
    }
    // Home
    if (_splashDone && _identitySet) {
      return const HomeScreen();
    }
    // Splash
    return SplashScreen(
      onComplete: () async {
        final ready       = IdentityService.instance.isSetup;
        final shouldLock  = ready &&
            await BiometricService.instance.isEnabled();
        if (mounted) setState(() {
          _splashDone  = true;
          _identitySet = ready;
          _locked      = shouldLock;
        });
      },
    );
  }
}

// ── Home Screen ───────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _aura;
  int  _navIndex = 0;
  bool _isPushing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _aura = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _aura.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycle) {
    if (lifecycle == AppLifecycleState.resumed) {
      // Trigger Drive sync when user returns to app
      BackgroundSyncService.instance.runOnceNow();
      KeepaliveService.instance.triggerSync();
    }
  }

  Future<void> _push(Widget screen) async {
    if (_isPushing) return;
    _isPushing = true;
    try {
      await Navigator.push<void>(
        context,
        PageRouteBuilder(
          pageBuilder: (_, a1, a2) => screen,
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } finally {
      if (mounted) _isPushing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [Color(0xFF1E1035), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(children: [
              const SizedBox(height: 20),
              _Header(),
              const SizedBox(height: 28),
              _AuraRing(controller: _aura)
                  .animate().fadeIn(duration: 800.ms)
                  .scale(begin: const Offset(0.7, 0.7),
                  duration: 1000.ms, curve: Curves.elasticOut),
              const SizedBox(height: 22),
              _PartnerCard()
                  .animate().fadeIn(delay: 200.ms, duration: 600.ms)
                  .slideY(begin: 0.08, end: 0, delay: 200.ms),
              const SizedBox(height: 16),
              _FeatureGrid(onNavigate: _push)
                  .animate().fadeIn(delay: 350.ms, duration: 600.ms)
                  .slideY(begin: 0.08, end: 0, delay: 350.ms),
              const SizedBox(height: 16),
              _EmotionRow()
                  .animate().fadeIn(delay: 500.ms, duration: 600.ms),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(
        index: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 1) _push(const ChatScreen())
              .then((_) { if (mounted) setState(() => _navIndex = 0); });
          else if (i == 2) _push(const MoodScreen())
              .then((_) { if (mounted) setState(() => _navIndex = 0); });
          else if (i == 3) _push(const MemoriesScreen())
              .then((_) { if (mounted) setState(() => _navIndex = 0); });
          else if (i == 4) _push(const SyncScreen())
              .then((_) { if (mounted) setState(() => _navIndex = 0); });
        },
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncProvider);
    final user = IdentityService.instance.currentUser;
    final syncColor = sync.syncEnabled && sync.isSignedIn
        ? const Color(0xFF34D399)
        : sync.isSignedIn ? const Color(0xFFC084FC) : Colors.white38;
    final syncLabel = sync.isSyncing ? 'syncing...'
        : sync.syncEnabled ? 'synced' : 'local only';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Row(children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFC084FC).withValues(alpha: 0.15),
                border: Border.all(
                    color: const Color(0xFFC084FC).withValues(alpha: 0.4), width: 1),
              ),
              child: Center(child: Text(
                user?.avatarEmoji ?? '💜',
                style: const TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 8),
            Text(user?.displayName ?? 'VELOURA',
                style: GoogleFonts.cinzel(
                    fontSize: 13, color: const Color(0xFFC084FC),
                    letterSpacing: 2)),
          ]),
        ),
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1), width: 0.5),
            ),
            child: Row(children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: syncColor)),
              const SizedBox(width: 5),
              Text(syncLabel, style: GoogleFonts.cinzel(
                  fontSize: 9, color: Colors.white38, letterSpacing: 1)),
            ]),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1), width: 0.5),
              ),
              child: const Icon(Icons.settings_outlined,
                  size: 16, color: Colors.white38),
            ),
          ),
        ]),
      ],
    );
  }
}

// ── Aura Ring ─────────────────────────────────────────────────

class _AuraRing extends StatelessWidget {
  const _AuraRing({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final glow = controller.value;
        return Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: const Color(0xFFC084FC).withValues(alpha: 0.2 + glow * 0.3),
              blurRadius: 30 + glow * 20, spreadRadius: 2 + glow * 4,
            )],
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [
                Color(0xFFC084FC), Color(0xFFF472B6),
                Color(0xFF60A5FA), Color(0xFFC084FC),
              ]),
            ),
            padding: const EdgeInsets.all(2.5),
            child: Container(
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF0F172A)),
              child: const Center(child: Icon(Icons.favorite_rounded,
                  color: Colors.white, size: 34)),
            ),
          ),
        );
      },
    );
  }
}

// ── Partner Card ──────────────────────────────────────────────

class _PartnerCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairing = ref.watch(pairingProvider);
    final p2p     = ref.watch(p2pProvider);
    final name    = pairing.pairData?.partnerName
        ?? p2p.partner?.displayName ?? 'Your person';
    final emoji   = pairing.pairData?.partnerEmoji
        ?? p2p.partner?.avatarEmoji ?? '💜';
    final isPaired   = pairing.isPaired;
    final isP2P      = p2p.isConnected;
    final statusText = isP2P ? 'P2P connected · encrypted'
        : isPaired ? 'paired · offline'
        : 'not paired yet';
    final statusColor = isP2P ? const Color(0xFF34D399)
        : isPaired ? Colors.white38 : Colors.white24;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.1), width: 0.5),
        boxShadow: [BoxShadow(
            color: const Color(0xFFC084FC).withValues(alpha: 0.07),
            blurRadius: 20)],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFC084FC).withValues(alpha: 0.12),
            border: Border.all(
                color: const Color(0xFFC084FC).withValues(alpha: 0.35), width: 1.5),
            boxShadow: [BoxShadow(
                color: const Color(0xFFC084FC).withValues(alpha: 0.25),
                blurRadius: 12)],
          ),
          child: Center(child: Text(emoji,
              style: const TextStyle(fontSize: 26))),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: GoogleFonts.cormorantGaramond(
                fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white)),
            const SizedBox(height: 3),
            Row(children: [
              Container(width: 6, height: 6,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: statusColor)),
              const SizedBox(width: 5),
              Text(statusText, style: GoogleFonts.cormorantGaramond(
                  fontSize: 12, color: statusColor.withValues(alpha: 0.8))),
            ]),
            const SizedBox(height: 5),
            Text(
              isPaired ? '"connected and always with you 💜"'
                  : '"go to Pairing to connect your devices"',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 13, color: Colors.white38,
                  fontStyle: FontStyle.italic),
            ),
          ],
        )),
      ]),
    );
  }
}

// ── Feature Grid ──────────────────────────────────────────────

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.onNavigate});
  final void Function(Widget) onNavigate;

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.chat_bubble_outline_rounded, 'CHAT',
          [const Color(0xFFC084FC), const Color(0xFFF472B6)], const ChatScreen()),
      (Icons.auto_awesome_rounded, 'MOOD',
          [const Color(0xFF3B82F6), const Color(0xFFC084FC)], const MoodScreen()),
      (Icons.photo_album_outlined, 'MEMORIES',
          [const Color(0xFFF472B6), const Color(0xFFFBBF24)], const MemoriesScreen()),
      (Icons.qr_code_rounded, 'PAIRING',
          [const Color(0xFF34D399), const Color(0xFF3B82F6)], const PairingScreen()),
      (Icons.cloud_sync_outlined, 'SYNC',
          [const Color(0xFF34D399), const Color(0xFF60A5FA)], const SyncScreen()),
    ];
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 2.2,
      children: features.map((f) => GestureDetector(
        onTap: () => onNavigate(f.$4),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              f.$3.first.withValues(alpha: 0.15),
              f.$3.last.withValues(alpha: 0.08),
            ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: f.$3.first.withValues(alpha: 0.25), width: 0.5),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(f.$1, color: f.$3.first, size: 20),
            const SizedBox(width: 8),
            Text(f.$2, style: GoogleFonts.cinzel(
                fontSize: 11, color: Colors.white70, letterSpacing: 1.5)),
          ]),
        ),
      )).toList(),
    );
  }
}

// ── Emotion Row ───────────────────────────────────────────────

class _EmotionRow extends StatefulWidget {
  @override
  State<_EmotionRow> createState() => _EmotionRowState();
}

class _EmotionRowState extends State<_EmotionRow> {
  final _sent = <String>{};
  void _tap(String key) {
    setState(() => _sent.add(key));
    Future.delayed(const Duration(seconds: 2),
        () { if (mounted) setState(() => _sent.remove(key)); });
  }
  @override
  Widget build(BuildContext context) {
    final btns = [
      ('🤗', 'Hug'), ('💋', 'Kiss'), ('🌙', 'Miss You'),
      ('🛡', 'Safe'), ('✨', 'Thinking'),
    ];
    return Wrap(
      spacing: 8, runSpacing: 8, alignment: WrapAlignment.center,
      children: btns.map((b) {
        final active = _sent.contains(b.$1);
        return GestureDetector(
          onTap: () => _tap(b.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: active
                  ? const Color(0xFFC084FC).withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: active
                    ? const Color(0xFFC084FC).withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Text(
              active ? '${b.$1} Sent!' : '${b.$1} ${b.$2}',
              style: TextStyle(fontSize: 13,
                  color: active ? const Color(0xFFC084FC) : Colors.white54),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Bottom Nav ────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.index, required this.onTap});
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_rounded,         Icons.home_outlined,               'Home'),
      (Icons.chat_bubble_rounded,  Icons.chat_bubble_outline_rounded, 'Chat'),
      (Icons.auto_awesome_rounded, Icons.auto_awesome_outlined,       'Mood'),
      (Icons.photo_album_rounded,  Icons.photo_album_outlined,        'Memories'),
      (Icons.cloud_sync_rounded,   Icons.cloud_sync_outlined,         'Sync'),
    ];
    return Container(
      margin: EdgeInsets.fromLTRB(
          16, 0, 16, MediaQuery.of(context).padding.bottom + 10),
      height: 62,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.12), width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final item   = items[i];
          final active = index == i;
          return GestureDetector(
            onTap: () => onTap(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: active
                    ? const Color(0xFFC084FC).withValues(alpha: 0.15)
                    : Colors.transparent,
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(active ? item.$1 : item.$2,
                    color: active ? const Color(0xFFC084FC) : Colors.white30,
                    size: 20),
                const SizedBox(height: 2),
                Text(item.$3, style: GoogleFonts.cinzel(
                    fontSize: 8, letterSpacing: 0.5,
                    color: active ? const Color(0xFFC084FC) : Colors.white30)),
              ]),
            ),
          );
        }),
      ),
    );
  }
}
