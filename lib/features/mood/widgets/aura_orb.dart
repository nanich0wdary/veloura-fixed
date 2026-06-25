// lib/features/mood/widgets/aura_orb.dart
// Veloura — Dual Aura Orb (both partners' moods merging)

import 'dart:math' as math;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../models/mood.dart';

class DualAuraOrb extends StatefulWidget {
  const DualAuraOrb({
    super.key,
    required this.myMood,
    required this.partnerMood,
    this.partnerName = 'Partner',
    this.myName = 'You',
  });

  final Mood   myMood;
  final Mood   partnerMood;
  final String partnerName;
  final String myName;

  @override
  State<DualAuraOrb> createState() => _DualAuraOrbState();
}

class _DualAuraOrbState extends State<DualAuraOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        final pulse = math.sin(t * math.pi);

        return SizedBox(
          width: 260,
          height: 260,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer glow ring
              _GlowRing(
                size: 260,
                colors: [
                  ...widget.myMood.colors,
                  ...widget.partnerMood.colors,
                ],
                opacity: 0.06 + pulse * 0.06,
              ),
              _GlowRing(
                size: 220,
                colors: [
                  ...widget.myMood.colors,
                  ...widget.partnerMood.colors,
                ],
                opacity: 0.08 + pulse * 0.08,
              ),

              // My orb (left)
              Positioned(
                left: 20 - pulse * 8,
                child: _Orb(
                  size: 110,
                  colors: widget.myMood.colors,
                  label: widget.myName,
                  emoji: widget.myMood.emoji,
                  pulse: pulse,
                ),
              ),

              // Partner orb (right)
              Positioned(
                right: 20 - pulse * 8,
                child: _Orb(
                  size: 110,
                  colors: widget.partnerMood.colors,
                  label: widget.partnerName,
                  emoji: widget.partnerMood.emoji,
                  pulse: pulse,
                ),
              ),

              // Center merge glow
              Container(
                width: 60 + pulse * 20,
                height: 60 + pulse * 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: widget.myMood.colors.first
                          .withValues(alpha: 0.15 + pulse * 0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                    BoxShadow(
                      color: widget.partnerMood.colors.first
                          .withValues(alpha: 0.15 + pulse * 0.15),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
              ),

              // Center heart
              Icon(
                Icons.favorite_rounded,
                size: 22 + pulse * 4,
                color: Colors.white.withValues(alpha: 0.4 + pulse * 0.3),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.size,
    required this.colors,
    required this.label,
    required this.emoji,
    required this.pulse,
  });

  final double size;
  final List<Color> colors;
  final String label;
  final String emoji;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colors.first.withValues(alpha: 0.5),
                colors.last.withValues(alpha: 0.2),
                Colors.transparent,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.first.withValues(alpha: 0.25 + pulse * 0.2),
                blurRadius: 30 + pulse * 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: TextStyle(fontSize: 28 + pulse * 4)),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.6),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GlowRing extends StatelessWidget {
  const _GlowRing({
    required this.size,
    required this.colors,
    required this.opacity,
  });

  final double size;
  final List<Color> colors;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          for (final c in colors)
            BoxShadow(
              color: c.withValues(alpha: opacity),
              blurRadius: 40,
              spreadRadius: 2,
            ),
        ],
      ),
    );
  }
}
