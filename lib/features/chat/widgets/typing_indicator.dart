// lib/features/chat/widgets/typing_indicator.dart
// Veloura Phase 4 — Typing indicator with partner name

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key, this.name = 'Partner'});
  final String name;
  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, bottom: 4),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1), width: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) =>
                      _Dot(controller: _c, delay: i * 0.2))),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${widget.name} is typing...',
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.3),
              fontFamily: 'Cormorant Garamond',
              letterSpacing: 0.5,
            )),
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.controller, required this.delay});
  final AnimationController controller;
  final double delay;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t      = (controller.value - delay).clamp(0.0, 1.0);
        final bounce = t < 0.5 ? t * 2 : (1 - t) * 2;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 6,
          height: 6 + bounce * 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end:   Alignment.bottomCenter,
              colors: [
                const Color(0xFFC084FC)
                    .withValues(alpha: 0.5 + bounce * 0.5),
                const Color(0xFFF472B6)
                    .withValues(alpha: 0.3 + bounce * 0.4),
              ],
            ),
          ),
        );
      },
    );
  }
}
