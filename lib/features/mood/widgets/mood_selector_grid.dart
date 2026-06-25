// lib/features/mood/widgets/mood_selector_grid.dart
// Veloura — Mood Selection Grid

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/mood.dart';

class MoodSelectorGrid extends StatelessWidget {
  const MoodSelectorGrid({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final MoodType selected;
  final ValueChanged<MoodType> onSelect;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      children: Mood.all.asMap().entries.map((e) {
        final i = e.key;
        final mood = e.value;
        final isSelected = mood.type == selected;
        return _MoodTile(
          mood: mood,
          isSelected: isSelected,
          onTap: () => onSelect(mood.type),
        )
            .animate(delay: (i * 60).ms)
            .fadeIn(duration: 300.ms)
            .scale(
              begin: const Offset(0.8, 0.8),
              duration: 300.ms,
              curve: Curves.easeOut,
            );
      }).toList(),
    );
  }
}

class _MoodTile extends StatefulWidget {
  const _MoodTile({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  final Mood mood;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_MoodTile> createState() => _MoodTileState();
}

class _MoodTileState extends State<_MoodTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1, end: 0.9)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _c.forward(),
      onTapUp: (_) {
        _c.reverse();
        widget.onTap();
      },
      onTapCancel: () => _c.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: widget.isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.mood.colors,
                  )
                : null,
            color: widget.isSelected
                ? null
                : Colors.white.withValues(alpha: 0.06),
            border: Border.all(
              color: widget.isSelected
                  ? widget.mood.colors.first.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.1),
              width: widget.isSelected ? 1 : 0.5,
            ),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: widget.mood.colors.first.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.mood.emoji,
                style: TextStyle(
                  fontSize: widget.isSelected ? 24 : 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.mood.label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Cinzel',
                  fontSize: 8,
                  color: widget.isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.45),
                  letterSpacing: 0.5,
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
