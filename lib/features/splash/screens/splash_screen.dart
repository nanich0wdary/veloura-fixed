// lib/features/splash/screens/splash_screen.dart
// Veloura — Cinematic Splash Screen

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();
    Future.delayed(const Duration(milliseconds: 3200), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          _ParticleBg(controller: _controller),
          _RadialGlow(controller: _controller),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AuraRing(controller: _controller)
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      duration: 1200.ms,
                      curve: Curves.elasticOut,
                    ),
                const SizedBox(height: 36),
                Text('VELOURA',
                    style: GoogleFonts.cinzel(
                      fontSize: 36, fontWeight: FontWeight.w600,
                      color: Colors.white, letterSpacing: 8,
                    ))
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 800.ms)
                    .slideY(begin: 0.3, end: 0, delay: 500.ms,
                        duration: 800.ms, curve: Curves.easeOut),
                const SizedBox(height: 10),
                Text('your private universe, together',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 14, color: Colors.white38,
                      letterSpacing: 2, fontStyle: FontStyle.italic,
                    ))
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 800.ms),
                const SizedBox(height: 56),
                _LoadingBar()
                    .animate()
                    .fadeIn(delay: 1000.ms, duration: 600.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuraRing extends StatelessWidget {
  const _AuraRing({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final glow = (math.sin(controller.value * math.pi * 2) + 1) / 2;
        return SizedBox(
          width: 120, height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC084FC)
                          .withValues(alpha: 0.15 + glow * 0.25),
                      blurRadius: 40 + glow * 20, spreadRadius: 4,
                    ),
                    BoxShadow(
                      color: const Color(0xFFF472B6)
                          .withValues(alpha: 0.1 + glow * 0.15),
                      blurRadius: 60, spreadRadius: 8,
                    ),
                  ],
                ),
              ),
              Container(
                width: 100, height: 100,
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
                    shape: BoxShape.circle,
                    color: Color(0xFF0F172A),
                  ),
                  child: Center(
                    child: Icon(Icons.favorite_rounded,
                        color: Colors.white.withValues(alpha: 0.8 + glow * 0.2),
                        size: 36),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LoadingBar extends StatefulWidget {
  @override
  State<_LoadingBar> createState() => _LoadingBarState();
}

class _LoadingBarState extends State<_LoadingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _p;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..forward();
    _p = CurvedAnimation(parent: _c, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _p,
      builder: (_, __) => Column(
        children: [
          Container(
            width: 180, height: 1.5,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(1),
              color: Colors.white.withValues(alpha: 0.06),
            ),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: _p.value,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(1),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC084FC), Color(0xFFF472B6)]),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC084FC).withValues(alpha: 0.5),
                      blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            _p.value < 0.5
                ? 'preparing your space...'
                : _p.value < 0.9
                    ? 'almost there...'
                    : 'welcome back ♡',
            style: GoogleFonts.cinzel(
              fontSize: 9,
              color: Colors.white.withValues(alpha: 0.25),
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialGlow extends StatelessWidget {
  const _RadialGlow({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8 + controller.value * 0.4,
            colors: [
              const Color(0xFF1E1035).withValues(alpha: 0.8),
              const Color(0xFF0F172A),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticleBg extends StatelessWidget {
  const _ParticleBg({required this.controller});
  final AnimationController controller;

  static final _pts = List.generate(30, (i) => [
    (i * 0.137) % 1.0, (i * 0.241) % 1.0,
    (i * 0.073) % 1.0 * 2 + 0.5,
    (i * 0.179) % 1.0 * 0.3 + 0.05,
    (i % 3).toDouble(),
  ]);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => CustomPaint(
        painter: _PtPainter(t: controller.value, pts: _pts),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PtPainter extends CustomPainter {
  const _PtPainter({required this.t, required this.pts});
  final double t;
  final List<List<double>> pts;

  static const _colors = [
    Color(0xFFC084FC), Color(0xFFF472B6), Color(0xFF60A5FA),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pts) {
      final angle = t * math.pi * 2 + p[0] * 6;
      final x = ((p[0] + math.cos(angle) * 0.1) % 1) * size.width;
      final y = ((p[1] - t * 0.05) % 1) * size.height;
      final breathe = (math.sin(t * math.pi * 2 + p[1] * 4) + 1) / 2;
      canvas.drawCircle(
        Offset(x, y), p[2],
        Paint()
          ..color = _colors[p[4].toInt()].withValues(alpha: p[3] * (0.4 + breathe * 0.6))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_PtPainter o) => o.t != t;
}
