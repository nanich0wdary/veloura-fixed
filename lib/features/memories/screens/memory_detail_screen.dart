// lib/features/memories/screens/memory_detail_screen.dart
// Veloura — Memory Detail Screen

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/memory.dart';
import '../widgets/memory_card.dart';

class MemoryDetailScreen extends StatelessWidget {
  const MemoryDetailScreen({
    super.key,
    required this.memory,
    required this.onFavorite,
    required this.onDelete,
  });

  final Memory memory;
  final VoidCallback onFavorite;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = gradientFor(memory.gradientIndex);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              memory.isFavorite
                  ? Icons.favorite_rounded
                  : Icons.favorite_outline_rounded,
              color: memory.isFavorite ? colors.first : Colors.white38,
              size: 20,
            ),
            onPressed: () {
              onFavorite();
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 20, color: Colors.white38),
            onPressed: () {
              onDelete();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.4,
                colors: [
                  colors.first.withValues(alpha: 0.15),
                  const Color(0xFF0F172A),
                ],
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            colors.first.withValues(alpha: 0.2),
                            colors.last.withValues(alpha: 0.1),
                          ],
                        ),
                        border: Border.all(
                          color: colors.first.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colors.first.withValues(alpha: 0.2),
                            blurRadius: 24,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(memory.emoji,
                            style: const TextStyle(fontSize: 36)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Gradient line
                  Container(
                    height: 1.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          colors.first,
                          colors.last,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Date
                  Text(
                    _formatDate(memory.createdAt),
                    style: TextStyle(
                      fontFamily: 'Cinzel',
                      fontSize: 10,
                      color: colors.first.withValues(alpha: 0.7),
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Title
                  Text(
                    memory.title,
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Content
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          memory.content,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 18,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.8,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
