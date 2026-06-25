// lib/features/memories/widgets/memory_card.dart
// Veloura — Memory Card Widget

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/memory.dart';

// Gradient palette for memory cards
const _gradients = [
  [Color(0xFFC084FC), Color(0xFFF472B6)],
  [Color(0xFF60A5FA), Color(0xFFC084FC)],
  [Color(0xFFF472B6), Color(0xFFFBBF24)],
  [Color(0xFF34D399), Color(0xFF60A5FA)],
  [Color(0xFF8B5CF6), Color(0xFFEC4899)],
  [Color(0xFF06B6D4), Color(0xFF3B82F6)],
];

List<Color> gradientFor(int index) =>
    _gradients[index % _gradients.length];

class MemoryCard extends StatelessWidget {
  const MemoryCard({
    super.key,
    required this.memory,
    required this.index,
    required this.onFavorite,
    required this.onDelete,
    required this.onTap,
  });

  final Memory memory;
  final int index;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = gradientFor(memory.gradientIndex);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: colors.first.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.first.withValues(alpha: 0.12),
                    colors.last.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: colors.first.withValues(alpha: 0.22),
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Top gradient bar ──
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(22)),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header row ──
                        Row(
                          children: [
                            // Emoji badge
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    colors.first.withValues(alpha: 0.2),
                                    colors.last.withValues(alpha: 0.1),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: colors.first.withValues(alpha: 0.3),
                                  width: 0.5,
                                ),
                              ),
                              child: Center(
                                child: Text(memory.emoji,
                                    style: const TextStyle(fontSize: 18)),
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    memory.title,
                                    style: GoogleFonts.cormorantGaramond(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(memory.createdAt),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white30,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Type badge
                            _TypeBadge(type: memory.type, color: colors.first),

                            const SizedBox(width: 8),

                            // Favorite
                            GestureDetector(
                              onTap: onFavorite,
                              child: Icon(
                                memory.isFavorite
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_outline_rounded,
                                color: memory.isFavorite
                                    ? colors.first
                                    : Colors.white24,
                                size: 18,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // ── Content preview ──
                        Text(
                          memory.content,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 15,
                            color: Colors.white.withValues(alpha: 0.65),
                            height: 1.6,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: (index * 80).ms)
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut);
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

// ── Type Badge ───────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, required this.color});
  final MemoryType type;
  final Color color;

  String get _label {
    switch (type) {
      case MemoryType.note: return 'NOTE';
      case MemoryType.photo: return 'PHOTO';
      case MemoryType.moment: return 'MOMENT';
      case MemoryType.milestone: return 'MILESTONE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: 7,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
