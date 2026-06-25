// lib/features/memories/screens/memories_screen.dart
// Veloura — Memories / Timeline Screen

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/memory.dart';
import '../providers/memories_provider.dart';
import '../widgets/memory_card.dart';
import '../widgets/add_memory_sheet.dart';
import 'memory_detail_screen.dart';

class MemoriesScreen extends ConsumerWidget {
  const MemoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(memoriesProvider);
    final notifier = ref.read(memoriesProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context),
      floatingActionButton: _AddButton(
        onTap: () => _showAddSheet(context, notifier),
      ),
      body: Stack(
        children: [
          // Ambient background
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.3, -0.8),
                radius: 1.3,
                colors: [Color(0xFF1E1035), Color(0xFF0F172A)],
              ),
            ),
          ),

          Column(
            children: [
              // ── Stats banner ──
              SizedBox(height: MediaQuery.of(context).padding.top + 70),
              _StatsBanner(memories: state.memories)
                  .animate()
                  .fadeIn(duration: 600.ms),

              const SizedBox(height: 12),

              // ── Filter tabs ──
              _FilterTabs(
                selected: state.filter,
                onSelect: notifier.setFilter,
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 600.ms),

              const SizedBox(height: 12),

              // ── Memory list ──
              Expanded(
                child: state.filtered.isEmpty
                    ? _EmptyState()
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                        itemCount: state.filtered.length,
                        itemBuilder: (_, i) {
                          final memory = state.filtered[i];
                          return MemoryCard(
                            memory: memory,
                            index: i,
                            onFavorite: () =>
                                notifier.toggleFavorite(memory.id),
                            onDelete: () =>
                                notifier.deleteMemory(memory.id),
                            onTap: () => Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, a1, a2) =>
                                    MemoryDetailScreen(
                                  memory: memory,
                                  onFavorite: () =>
                                      notifier.toggleFavorite(memory.id),
                                  onDelete: () =>
                                      notifier.deleteMemory(memory.id),
                                ),
                                transitionsBuilder:
                                    (_, anim, __, child) =>
                                        FadeTransition(
                                            opacity: anim, child: child),
                                transitionDuration:
                                    const Duration(milliseconds: 350),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
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
              color: const Color(0xFF0F172A).withValues(alpha: 0.6),
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
                        'OUR MEMORIES',
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

  void _showAddSheet(BuildContext context, MemoriesNotifier notifier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMemorySheet(
        onAdd: ({
          required String title,
          required String content,
          required MemoryType type,
          required String emoji,
          required int gradientIndex,
        }) {
          notifier.addMemory(
            title: title,
            content: content,
            type: type,
            emoji: emoji,
            gradientIndex: gradientIndex,
          );
        },
      ),
    );
  }
}

// ── Stats Banner ─────────────────────────────────────────────

class _StatsBanner extends StatelessWidget {
  const _StatsBanner({required this.memories});
  final List<Memory> memories;

  @override
  Widget build(BuildContext context) {
    final total = memories.length;
    final favs = memories.where((m) => m.isFavorite).length;
    final milestones = memories
        .where((m) => m.type == MemoryType.milestone)
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _StatTile(value: '$total', label: 'MEMORIES',
              color: const Color(0xFFC084FC)),
          const SizedBox(width: 10),
          _StatTile(value: '$favs', label: 'FAVOURITES',
              color: const Color(0xFFF472B6)),
          const SizedBox(width: 10),
          _StatTile(value: '$milestones', label: 'MILESTONES',
              color: const Color(0xFFFBBF24)),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.cinzel(
                fontSize: 22,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.cinzel(
                fontSize: 7,
                color: color.withValues(alpha: 0.6),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Filter Tabs ──────────────────────────────────────────────

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onSelect});
  final MemoryFilter selected;
  final ValueChanged<MemoryFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    const filters = [
      (MemoryFilter.all, 'All'),
      (MemoryFilter.favorites, '♡ Faves'),
      (MemoryFilter.notes, 'Notes'),
      (MemoryFilter.moments, 'Moments'),
    ];
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        children: filters.map((f) {
          final active = selected == f.$1;
          return GestureDetector(
            onTap: () => onSelect(f.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: active
                    ? const LinearGradient(
                        colors: [Color(0xFFC084FC), Color(0xFFF472B6)],
                      )
                    : null,
                color: active ? null : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active
                      ? Colors.transparent
                      : Colors.white.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
              child: Text(
                f.$2,
                style: GoogleFonts.cinzel(
                  fontSize: 10,
                  color: active ? Colors.white : Colors.white38,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💌', style: TextStyle(fontSize: 48))
              .animate()
              .fadeIn(duration: 600.ms)
              .scale(begin: const Offset(0.5, 0.5)),
          const SizedBox(height: 16),
          Text(
            'No memories yet',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              color: Colors.white38,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap + to add your first memory',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 14,
              color: Colors.white24,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ── FAB Add Button ───────────────────────────────────────────

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFC084FC), Color(0xFFF472B6)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC084FC).withValues(alpha: 0.4),
              blurRadius: 18,
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}
