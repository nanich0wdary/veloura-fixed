// lib/features/pairing/widgets/qr_display.dart
// Veloura — Animated QR Code Display

import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QrDisplay extends StatefulWidget {
  const QrDisplay({super.key, required this.data, required this.pairCode});
  final String data;
  final String pairCode;

  @override
  State<QrDisplay> createState() => _QrDisplayState();
}

class _QrDisplayState extends State<QrDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final glow = _pulse.value;
        return Column(
          children: [
            // QR Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC084FC)
                        .withValues(alpha: 0.1 + glow * 0.2),
                    blurRadius: 40 + glow * 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFC084FC)
                            .withValues(alpha: 0.2 + glow * 0.15),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        QrImageView(
                          data: widget.data,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.transparent,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Colors.white,
                          ),
                          dataModuleStyle: QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFC084FC), Color(0xFFF472B6)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFC084FC).withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.favorite_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.85, 0.85), duration: 600.ms),

            const SizedBox(height: 20),

            // Pair code
            Text('YOUR PAIR CODE',
                style: TextStyle(
                  fontFamily: 'Cinzel', fontSize: 9,
                  color: Colors.white.withValues(alpha: 0.35), letterSpacing: 2.5,
                )),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: widget.pairCode.split('-').asMap().entries.map((e) {
                return Row(children: [
                  if (e.key > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('—',
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white.withValues(alpha: 0.25))),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC084FC)
                          .withValues(alpha: 0.08 + glow * 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFC084FC)
                            .withValues(alpha: 0.25 + glow * 0.15),
                        width: 0.5,
                      ),
                    ),
                    child: Text(e.value,
                        style: const TextStyle(
                          fontFamily: 'Cinzel', fontSize: 22,
                          color: Colors.white, letterSpacing: 5,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                ]);
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text('Share this code or QR with your partner',
                style: TextStyle(
                  fontFamily: 'Cormorant Garamond', fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.3), letterSpacing: 0.5,
                )),
          ],
        );
      },
    );
  }
}
