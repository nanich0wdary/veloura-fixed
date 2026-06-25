// lib/features/mood/models/mood.dart
// Veloura — Mood Model

import 'package:flutter/material.dart';

enum MoodType {
  romantic,
  calm,
  missing,
  joyful,
  peaceful,
  melancholic,
  energetic,
}

class Mood {
  const Mood({
    required this.type,
    required this.label,
    required this.emoji,
    required this.colors,
    required this.message,
  });

  final MoodType type;
  final String label;
  final String emoji;
  final List<Color> colors;
  final String message;

  static const all = [
    Mood(
      type: MoodType.romantic,
      label: 'Romantic',
      emoji: '💗',
      colors: [Color(0xFFEC4899), Color(0xFFA855F7)],
      message: 'feeling deeply in love right now',
    ),
    Mood(
      type: MoodType.calm,
      label: 'Calm',
      emoji: '🌊',
      colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
      message: 'at peace, thinking of you',
    ),
    Mood(
      type: MoodType.missing,
      label: 'Missing You',
      emoji: '🌙',
      colors: [Color(0xFF8B5CF6), Color(0xFFC084FC)],
      message: 'the distance feels so far tonight',
    ),
    Mood(
      type: MoodType.joyful,
      label: 'Joyful',
      emoji: '✨',
      colors: [Color(0xFFF472B6), Color(0xFFFBBF24)],
      message: 'smiling because of you',
    ),
    Mood(
      type: MoodType.peaceful,
      label: 'Peaceful',
      emoji: '🌿',
      colors: [Color(0xFF34D399), Color(0xFF3B82F6)],
      message: 'safe and at rest',
    ),
    Mood(
      type: MoodType.melancholic,
      label: 'Melancholic',
      emoji: '🌧️',
      colors: [Color(0xFF6366F1), Color(0xFF1E1B4B)],
      message: 'a little blue, need you close',
    ),
    Mood(
      type: MoodType.energetic,
      label: 'Energetic',
      emoji: '⚡',
      colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
      message: 'full of energy today!',
    ),
  ];

  static Mood byType(MoodType type) =>
      all.firstWhere((m) => m.type == type);
}
