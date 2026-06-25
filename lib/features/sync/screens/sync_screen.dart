// lib/features/sync/screens/sync_screen.dart
// Veloura — Google Drive Sync Settings Screen

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/sync_provider.dart';

class SyncScreen extends ConsumerStatefulWidget {
  const SyncScreen({super.key});
  @override
  ConsumerState<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends ConsumerState<SyncScreen> {
  final _codeCtrl = TextEditingController();
  bool _hydrated = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sync = ref.watch(syncProvider);
    final notifier = ref.read(syncProvider.notifier);

    if (!_hydrated && _codeCtrl.text.isEmpty && sync.pairCode.isNotEmpty) {
      _codeCtrl.text = sync.pairCode;
      _hydrated = true;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: _appBar(context),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.3, -0.8),
                radius: 1.3,
                colors: [Color(0xFF1E1035), Color(0xFF0F172A)],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
              child: Column(
                children: [
                  _SyncOrb(isOnline: sync.isSignedIn, isSyncing: sync.isSyncing)
                      .animate().fadeIn(duration: 600.ms)
                      .scale(begin: const Offset(0.7, 0.7),
                          duration: 800.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 20),

                  Text(
                    sync.isSignedIn
                        ? (sync.syncEnabled ? 'SYNC ACTIVE' : 'SIGNED IN')
                        : 'NOT CONNECTED',
                    style: GoogleFonts.cinzel(
                      fontSize: 11, letterSpacing: 4,
                      color: sync.isSignedIn
                          ? (sync.syncEnabled
                              ? const Color(0xFF34D399)
                              : const Color(0xFFC084FC))
                          : Colors.white38,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  if (sync.isSignedIn) ...[
                    const SizedBox(height: 6),
                    Text(sync.userEmail,
                        style: GoogleFonts.cormorantGaramond(
                            fontSize: 14, color: Colors.white54)),
                    const SizedBox(height: 4),
                    Text('Last sync: ${sync.lastSyncText}',
                        style: GoogleFonts.cormorantGaramond(
                            fontSize: 12, color: Colors.white30,
                            fontStyle: FontStyle.italic)),
                  ],

                  const SizedBox(height: 28),

                  _InfoCard().animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 20),

                  _PairCodeField(
                    controller: _codeCtrl,
                    onSave: (code) => notifier.setPairCode(code),
                  ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 16),

                  if (sync.error != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.red.withValues(alpha: 0.2),
                            width: 0.5),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline_rounded,
                            color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(sync.error!,
                            style: GoogleFonts.cormorantGaramond(
                                fontSize: 14, color: Colors.redAccent))),
                      ]),
                    ).animate().fadeIn().shakeX(),

                  const SizedBox(height: 16),

                  if (!sync.isSignedIn)
                    _ActionButton(
                      label: 'SIGN IN WITH GOOGLE',
                      icon: Icons.login_rounded,
                      colors: const [Color(0xFFC084FC), Color(0xFFF472B6)],
                      isLoading: sync.isSyncing,
                      onTap: () => notifier.signIn(),
                    ).animate().fadeIn(delay: 500.ms)
                  else if (!sync.syncEnabled)
                    _ActionButton(
                      label: 'ENABLE DRIVE SYNC',
                      icon: Icons.sync_rounded,
                      colors: const [Color(0xFF34D399), Color(0xFF3B82F6)],
                      isLoading: sync.isSyncing,
                      onTap: () => notifier.enableSync(),
                    ).animate().fadeIn(delay: 500.ms)
                  else
                    Column(children: [
                      _ActionButton(
                        label: 'SYNC NOW',
                        icon: Icons.refresh_rounded,
                        colors: const [Color(0xFF34D399), Color(0xFF60A5FA)],
                        isLoading: sync.isSyncing,
                        onTap: () => notifier.triggerSync(),
                      ),
                      const SizedBox(height: 12),
                      _ActionButton(
                        label: 'DISABLE SYNC',
                        icon: Icons.sync_disabled_rounded,
                        colors: [Colors.grey.shade700, Colors.blueGrey.shade700],
                        isLoading: false,
                        onTap: () => notifier.disableSync(),
                      ),
                    ]).animate().fadeIn(delay: 500.ms),

                  const SizedBox(height: 16),

                  if (sync.isSignedIn)
                    GestureDetector(
                      onTap: () => notifier.signOut(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.2),
                              width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.logout_rounded,
                                color: Colors.red.withValues(alpha: 0.7),
                                size: 16),
                            const SizedBox(width: 8),
                            Text('Sign Out',
                                style: GoogleFonts.cinzel(
                                    fontSize: 11,
                                    color: Colors.red.withValues(alpha: 0.7),
                                    letterSpacing: 1.5)),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _appBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.6),
              border: Border(bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.07), width: 0.5)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(
                    child: Text('DRIVE SYNC',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cinzel(
                            fontSize: 13, color: Colors.white,
                            letterSpacing: 4)),
                  ),
                  const SizedBox(width: 48),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sync Orb ─────────────────────────────────────────────────

class _SyncOrb extends StatefulWidget {
  const _SyncOrb({required this.isOnline, required this.isSyncing});
  final bool isOnline;
  final bool isSyncing;
  @override
  State<_SyncOrb> createState() => _SyncOrbState();
}

class _SyncOrbState extends State<_SyncOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final glow = _c.value;
        final color = widget.isOnline
            ? (widget.isSyncing
                ? const Color(0xFF60A5FA)
                : const Color(0xFF34D399))
            : Colors.white24;
        return Container(
          width: 100, height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
              color: color.withValues(alpha: 0.2 + glow * 0.3),
              blurRadius: 30 + glow * 20, spreadRadius: 2,
            )],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: widget.isOnline
                    ? [const Color(0xFF34D399), const Color(0xFF3B82F6)]
                    : [Colors.white12, Colors.white.withValues(alpha: 0.05)]),
            ),
            padding: const EdgeInsets.all(2.5),
            child: Container(
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0xFF0F172A)),
              child: Center(child: Icon(
                widget.isSyncing ? Icons.sync_rounded
                    : (widget.isOnline
                        ? Icons.cloud_done_rounded
                        : Icons.cloud_off_rounded),
                color: widget.isOnline ? color : Colors.white30,
                size: 34,
              )),
            ),
          ),
        );
      },
    );
  }
}

// ── Info Card ─────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.lock_outline_rounded,    'AES-256 encrypted before upload'),
      (Icons.cloud_outlined,          'Stored in your Google Drive AppData'),
      (Icons.people_outline_rounded,  'Only you + partner can decrypt'),
      (Icons.sync_rounded,            'Auto-syncs every 5 seconds'),
      (Icons.wifi_off_rounded,        'Works offline — syncs when online'),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.08), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HOW SYNC WORKS',
                  style: GoogleFonts.cinzel(fontSize: 9,
                      color: const Color(0xFFC084FC), letterSpacing: 2)),
              const SizedBox(height: 14),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Icon(item.$1, size: 14,
                      color: const Color(0xFFC084FC).withValues(alpha: 0.7)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item.$2,
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 14, color: Colors.white60))),
                ]),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Pair Code Field ───────────────────────────────────────────

class _PairCodeField extends StatelessWidget {
  const _PairCodeField({required this.controller, required this.onSave});
  final TextEditingController controller;
  final ValueChanged<String> onSave;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text('SYNC PAIR CODE',
                  style: GoogleFonts.cinzel(fontSize: 8,
                      color: Colors.white38, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.vpn_key_outlined,
                    color: Colors.white38, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    style: GoogleFonts.cinzel(
                        fontSize: 18, color: Colors.white, letterSpacing: 4),
                    decoration: InputDecoration(
                      hintText: 'VELO-XXXX',
                      hintStyle: GoogleFonts.cinzel(
                          fontSize: 16, letterSpacing: 4,
                          color: Colors.white.withValues(alpha: 0.15)),
                      border: InputBorder.none, isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 12),
                    ),
                    inputFormatters: [LengthLimitingTextInputFormatter(9)],
                    onSubmitted: onSave,
                  ),
                ),
                GestureDetector(
                  onTap: () => onSave(controller.text),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC084FC).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('SAVE',
                        style: GoogleFonts.cinzel(fontSize: 9,
                            color: const Color(0xFFC084FC),
                            letterSpacing: 1)),
                  ),
                ),
              ]),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action Button ─────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label, required this.icon, required this.colors,
    required this.isLoading, required this.onTap,
  });
  final String label;
  final IconData icon;
  final List<Color> colors;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(
              color: colors.first.withValues(alpha: 0.35), blurRadius: 16)],
        ),
        child: Center(child: isLoading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(label, style: GoogleFonts.cinzel(
                    fontSize: 12, color: Colors.white, letterSpacing: 2)),
              ])),
      ),
    );
  }
}
