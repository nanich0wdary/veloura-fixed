// lib/features/memories/widgets/add_memory_sheet.dart
// Veloura — Add Memory Bottom Sheet

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/memory.dart';

class AddMemorySheet extends StatefulWidget {
  const AddMemorySheet({super.key, required this.onAdd});

  final Function({
    required String title,
    required String content,
    required MemoryType type,
    required String emoji,
    required int gradientIndex,
  }) onAdd;

  static Future<void> show(BuildContext context,
      {required Function onAdd}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMemorySheet(onAdd: onAdd as dynamic),
    );
  }

  @override
  State<AddMemorySheet> createState() => _AddMemorySheetState();
}

class _AddMemorySheetState extends State<AddMemorySheet> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  MemoryType _type = MemoryType.moment;
  String _emoji = '💜';
  int _gradientIndex = 0;

  static const _emojis = [
    '💜', '💌', '✨', '🌙', '🌧️', '🎵',
    '🌸', '💋', '🤗', '🌊', '⭐', '💯',
  ];

  static const _gradients = [
    [Color(0xFFC084FC), Color(0xFFF472B6)],
    [Color(0xFF60A5FA), Color(0xFFC084FC)],
    [Color(0xFFF472B6), Color(0xFFFBBF24)],
    [Color(0xFF34D399), Color(0xFF60A5FA)],
    [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    [Color(0xFF06B6D4), Color(0xFF3B82F6)],
  ];

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty ||
        _contentCtrl.text.trim().isEmpty) { return; }
    widget.onAdd(
      title: _titleCtrl.text.trim(),
      content: _contentCtrl.text.trim(),
      type: _type,
      emoji: _emoji,
      gradientIndex: _gradientIndex,
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    final colors = _gradients[_gradientIndex];

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(22, 14, 22, inset + 24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.9),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'ADD A MEMORY',
                  style: GoogleFonts.cinzel(
                    fontSize: 12,
                    color: colors.first,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 18),

                // ── Emoji picker ──
                Text('CHOOSE EMOJI',
                    style: GoogleFonts.cinzel(
                        fontSize: 9, color: Colors.white38, letterSpacing: 2)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _emojis.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final selected = _emojis[i] == _emoji;
                      return GestureDetector(
                        onTap: () => setState(() => _emoji = _emojis[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? colors.first.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                              color: selected
                                  ? colors.first.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                          child: Center(
                            child: Text(_emojis[i],
                                style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                // ── Gradient picker ──
                Text('CARD COLOR',
                    style: GoogleFonts.cinzel(
                        fontSize: 9, color: Colors.white38, letterSpacing: 2)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(_gradients.length, (i) {
                    final selected = i == _gradientIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _gradientIndex = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                              colors: _gradients[i]),
                          border: Border.all(
                            color: selected
                                ? Colors.white.withValues(alpha: 0.8)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                // ── Type selector ──
                Text('TYPE',
                    style: GoogleFonts.cinzel(
                        fontSize: 9, color: Colors.white38, letterSpacing: 2)),
                const SizedBox(height: 8),
                Row(
                  children: MemoryType.values.map((t) {
                    final labels = ['Note', 'Photo', 'Moment', 'Milestone'];
                    final selected = t == _type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = t),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: selected
                                ? colors.first.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                              color: selected
                                  ? colors.first.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.1),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            labels[t.index],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Cinzel',
                              fontSize: 8,
                              color: selected
                                  ? colors.first
                                  : Colors.white38,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // ── Title ──
                _Field(
                  controller: _titleCtrl,
                  hint: 'title...',
                  accentColor: colors.first,
                  maxLines: 1,
                ),

                const SizedBox(height: 10),

                // ── Content ──
                _Field(
                  controller: _contentCtrl,
                  hint: 'describe this memory...',
                  accentColor: colors.first,
                  maxLines: 4,
                ),

                const SizedBox(height: 20),

                // ── Save button ──
                GestureDetector(
                  onTap: _submit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: colors),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: colors.first.withValues(alpha: 0.3),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: Text(
                      'SAVE MEMORY',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(
                        fontSize: 12,
                        color: Colors.white,
                        letterSpacing: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.accentColor,
    required this.maxLines,
  });

  final TextEditingController controller;
  final String hint;
  final Color accentColor;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 0.5,
        ),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.cormorantGaramond(
          fontSize: 16,
          color: Colors.white,
          height: 1.5,
        ),
        decoration: InputDecoration(
          hintText: hint,
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
    );
  }
}
