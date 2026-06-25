// lib/features/pairing/widgets/connected_card.dart
// Veloura — Connected State Card

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pair_data.dart';

class ConnectedCard extends StatefulWidget {
  const ConnectedCard({
    super.key,
    required this.pairData,
    required this.onUnpair,
  });

  final PairData pairData;
  final VoidCallback onUnpair;

  @override
  State<ConnectedCard> createState() => _ConnectedCardState();
}

class _ConnectedCardState extends State<ConnectedCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
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
        final pulse = _c.value;
        return Column(
          children: [
            // ── Dual orbit animation ──
            SizedBox(
              width: 200,
              height: 200,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFC084FC)
                              .withValues(alpha: 0.1 + pulse * 0.1),
                          blurRadius: 50 + pulse * 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),

                  // My orb
                  Positioned(
                    left: 20 - pulse * 5,
                    child: _Orb(
                      label: widget.pairData.displayName,
                      colors: const [Color(0xFFC084FC), Color(0xFFF472B6)],
                      pulse: pulse,
                    ),
                  ),

                  // Partner orb
                  Positioned(
                    right: 20 - pulse * 5,
                    child: _Orb(
                      label: widget.pairData.partnerName ?? 'Partner',
                      colors: const [Color(0xFF60A5FA), Color(0xFFC084FC)],
                      pulse: pulse,
                    ),
                  ),

                  // Center heart
                  Icon(
                    Icons.favorite_rounded,
                    size: 28 + pulse * 6,
                    color: Colors.white.withValues(alpha: 0.5 + pulse * 0.3),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(
                    begin: const Offset(0.7, 0.7),
                    duration: 1000.ms,
                    curve: Curves.elasticOut),

            const SizedBox(height: 24),

            // ── Status text ──
            Text(
              'CONNECTED',
              style: GoogleFonts.cinzel(
                fontSize: 11,
                color: const Color(0xFF34D399),
                letterSpacing: 4,
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 600.ms),

            const SizedBox(height: 6),

            Text(
              '${widget.pairData.displayName}  ♡  ${widget.pairData.partnerName}',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 600.ms),

            const SizedBox(height: 20),

            // ── Info card ──
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399).withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFF34D399).withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(
                        icon: Icons.people_outline_rounded,
                        label: 'Partner',
                        value: widget.pairData.partnerName ?? '—',
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.lock_outline_rounded,
                        label: 'Pair Code',
                        value: widget.pairData.pairCode,
                      ),
                      if (widget.pairData.pairedAt != null) ...[
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Connected since',
                          value: _formatDate(widget.pairData.pairedAt!),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 600.ms, duration: 600.ms)
                .slideY(begin: 0.1, end: 0, delay: 600.ms),

            const SizedBox(height: 20),

            // ── Unpair button ──
            GestureDetector(
              onTap: () => _confirmUnpair(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.red.withValues(alpha: 0.2),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.link_off_rounded,
                        color: Colors.red.withValues(alpha: 0.7), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Unpair',
                      style: GoogleFonts.cinzel(
                        fontSize: 11,
                        color: Colors.red.withValues(alpha: 0.7),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 600.ms),
          ],
        );
      },
    );
  }

  void _confirmUnpair(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1035),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Unpair?',
            style: GoogleFonts.cinzel(color: Colors.white, fontSize: 16)),
        content: Text(
          'This will disconnect you from ${widget.pairData.partnerName}. Your messages and memories will be kept.',
          style: GoogleFonts.cormorantGaramond(
              color: Colors.white60, fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.cinzel(
                    color: Colors.white38, fontSize: 12)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onUnpair();
            },
            child: Text('Unpair',
                style: GoogleFonts.cinzel(
                    color: Colors.red.withValues(alpha: 0.8), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _Orb extends StatelessWidget {
  const _Orb({
    required this.label,
    required this.colors,
    required this.pulse,
  });
  final String label;
  final List<Color> colors;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80, height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            colors.first.withValues(alpha: 0.4 + pulse * 0.2),
            colors.last.withValues(alpha: 0.15),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colors.first.withValues(alpha: 0.25 + pulse * 0.2),
            blurRadius: 20 + pulse * 10,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label.isNotEmpty ? label[0].toUpperCase() : '?',
          style: const TextStyle(
            fontFamily: 'Cinzel',
            fontSize: 26,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white30),
        const SizedBox(width: 8),
        Text('$label  ',
            style: const TextStyle(
                fontSize: 12, color: Colors.white30,
                fontFamily: 'Cinzel', letterSpacing: 0.5)),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13, color: Colors.white70,
                  fontFamily: 'Cinzel', letterSpacing: 1)),
        ),
      ],
    );
  }
}
