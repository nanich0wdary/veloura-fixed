import '../../../core/identity/identity_service.dart';
// lib/features/mood/screens/mood_screen.dart
// Veloura — Mood Sync Screen

import 'dart:ui';
import '../../pairing/providers/pairing_provider.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/mood.dart';
import '../providers/mood_provider.dart';
import '../widgets/aura_orb.dart';
import '../widgets/mood_selector_grid.dart';

class MoodScreen extends ConsumerStatefulWidget {
  const MoodScreen({super.key});

  @override
  ConsumerState<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends ConsumerState<MoodScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bgController;
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bgController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(moodProvider);
    final myMood = state.myMoodData;
    final partnerMood = state.partnerMoodData;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      body: Stack(
        children: [
          // ── Animated gradient background ──
          _AnimatedBg(
            controller: _bgController,
            colors: [...myMood.colors, ...partnerMood.colors],
          ),

          // ── Particle overlay ──
          _ParticleOverlay(
            controller: _bgController,
            colors: myMood.colors,
          ),

          // ── Content ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                children: [
                  // ── Dual aura orb ──
                  DualAuraOrb(
                    myMood: myMood,
                    partnerMood: partnerMood,
                    partnerName: ref.watch(pairingProvider)
                        .pairData?.partnerName ?? 'Partner',
                    myName: IdentityService.instance.currentUser
                        ?.displayName ?? 'You',
                  )
                      .animate()
                      .fadeIn(duration: 800.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        duration: 1000.ms,
                        curve: Curves.elasticOut,
                      ),

                  const SizedBox(height: 4),

                  // ── Sync status ──
                  _SyncStatus(state: state)
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 600.ms),

                  const SizedBox(height: 24),

                  // ── Partner mood card ──
                  _PartnerMoodCard(mood: partnerMood)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .slideY(begin: 0.1, end: 0, delay: 200.ms),

                  const SizedBox(height: 20),

                  // ── Section label ──
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'HOW ARE YOU FEELING?',
                      style: GoogleFonts.cinzel(
                        fontSize: 10,
                        color: myMood.colors.first,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Mood selector grid ──
                  MoodSelectorGrid(
                    selected: state.myMood,
                    onSelect: (mood) =>
                        ref.read(moodProvider.notifier).setMyMood(mood),
                  )
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 600.ms),

                  const SizedBox(height: 20),

                  // ── Note to partner ──
                  _NoteField(
                    controller: _noteController,
                    initialValue: state.note,
                    accentColor: myMood.colors.first,
                    onChanged: (v) =>
                        ref.read(moodProvider.notifier).setNote(v),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 600.ms),

                  const SizedBox(height: 20),

                  // ── Sync button ──
                  _SyncButton(
                    isSyncing: state.isSyncing,
                    colors: myMood.colors,
                    onTap: () => ref
                        .read(moodProvider.notifier)
                        .setMyMood(state.myMood),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.5),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.07),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 18, color: Colors.white70),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        'MOOD SYNC',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cinzel(
                          fontSize: 13,
                          color: Colors.white,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sync Status ──────────────────────────────────────────────

class _SyncStatus extends StatelessWidget {
  const _SyncStatus({required this.state});
  final MoodState state;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (state.isSyncing) ...[
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: state.myMoodData.colors.first,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'syncing mood...',
            style: TextStyle(
              fontFamily: 'Cormorant Garamond',
              fontSize: 13,
              color: state.myMoodData.colors.first,
              letterSpacing: 1,
            ),
          ),
        ] else ...[
          Icon(
            Icons.sync_rounded,
            size: 12,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 6),
          Text(
            'synced just now',
            style: TextStyle(
              fontFamily: 'Cormorant Garamond',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.3),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ],
    );
  }
}

// ── Partner Mood Card ────────────────────────────────────────

class _PartnerMoodCard extends ConsumerWidget {
  const _PartnerMoodCard({super.key, required this.mood});
  final Mood mood;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                mood.colors.first.withValues(alpha: 0.12),
                mood.colors.last.withValues(alpha: 0.07),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: mood.colors.first.withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              Text(mood.emoji,
                  style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ref.read(pairingProvider).pairData?.partnerName ?? "Partner"} feels ${mood.label}',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '"${mood.message}"',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 13,
                        color: Colors.white54,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: mood.colors.first.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: mood.colors.first.withValues(alpha: 0.3),
                    width: 0.5,
                  ),
                ),
                child: Text(
                  'LIVE',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 9,
                    color: mood.colors.first,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Note Field ───────────────────────────────────────────────

class _NoteField extends StatefulWidget {
  const _NoteField({
    required this.controller,
    required this.initialValue,
    required this.accentColor,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String initialValue;
  final Color accentColor;
  final ValueChanged<String> onChanged;

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  bool _hydrated = false;

  @override
  Widget build(BuildContext context) {
    // FIX: Guard with a flag rather than setting inside build() unconditionally.
    // Setting controller.text inside build causes cursor-jump on every rebuild
    // and will unexpectedly refill the field if the user clears it while
    // state.note is still non-empty.
    // We only hydrate once — when the controller is still pristine.
    if (!_hydrated && widget.controller.text.isEmpty && widget.initialValue.isNotEmpty) {
      widget.controller.value = widget.controller.value.copyWith(text: widget.initialValue);
      _hydrated = true;
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A NOTE TO ARIANA',
                style: GoogleFonts.cinzel(
                  fontSize: 9,
                  color: widget.accentColor,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: widget.controller,
                onChanged: widget.onChanged,
                maxLines: 3,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'share how you\'re feeling...',
                  hintStyle: GoogleFonts.cormorantGaramond(
                    fontSize: 15,
                    color: Colors.white24,
                    fontStyle: FontStyle.italic,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sync Button ──────────────────────────────────────────────

class _SyncButton extends StatelessWidget {
  const _SyncButton({
    required this.isSyncing,
    required this.colors,
    required this.onTap,
  });

  final bool isSyncing;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSyncing ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(colors: colors),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.35),
              blurRadius: 16,
            ),
          ],
        ),
        child: Center(
          child: isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sync_rounded,
                        color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      'SYNC MY MOOD',
                      style: GoogleFonts.cinzel(
                        fontSize: 13,
                        color: Colors.white,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Animated Background ──────────────────────────────────────

class _AnimatedBg extends StatelessWidget {
  const _AnimatedBg({
    required this.controller,
    required this.colors,
  });

  final AnimationController controller;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(
                math.sin(t * math.pi) * 0.4,
                math.cos(t * math.pi) * 0.3 - 0.3,
              ),
              radius: 1.4,
              colors: [
                colors.isNotEmpty
                    ? colors.first.withValues(alpha: 0.15)
                    : const Color(0xFF1E1035),
                const Color(0xFF0F172A),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Particle Overlay ─────────────────────────────────────────

class _ParticleOverlay extends StatelessWidget {
  const _ParticleOverlay({
    required this.controller,
    required this.colors,
  });

  final AnimationController controller;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: _ParticlePainter(
          progress: controller.value,
          colors: colors,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter({required this.progress, required this.colors});
  final double progress;
  final List<Color> colors;

  static final _particles = List.generate(
    25,
    (i) => [
      (i * 0.137) % 1.0,
      (i * 0.237) % 1.0,
      (i * 0.073) % 1.0 * 2 + 0.5,
      (i * 0.179) % 1.0 * 0.3 + 0.03,
      // FIX: must be double — `i % 3` is int, and `p[4] as double` below
      // would throw a TypeError at runtime on every MoodScreen render.
      (i % 3).toDouble(),
    ],
  );

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particles) {
      final x  = p[0];
      final y  = p[1];
      final r  = p[2];
      final op = p[3];
      final ci = p[4].toInt();

      final angle = progress * math.pi * 2 + x * 6;
      final px = ((x + math.cos(angle) * 0.1) % 1) * size.width;
      final py = ((y - progress * 0.08) % 1) * size.height;
      final breathe = (math.sin(progress * math.pi * 2 + y * 4) + 1) / 2;

      final color = colors.isNotEmpty
          ? colors[ci % colors.length]
          : const Color(0xFFC084FC);

      canvas.drawCircle(
        Offset(px, py),
        r,
        Paint()
          ..color = color.withValues(alpha: op * (0.5 + breathe * 0.5))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter o) => o.progress != progress;
}
