// lib/features/memories/models/memory.dart
// Veloura — Memory Model

import 'dart:convert';

enum MemoryType { note, photo, moment, milestone }

class Memory {
  Memory({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.gradientIndex,
    this.emoji = '💜',
    this.isFavorite = false,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String content;
  final MemoryType type;
  final DateTime createdAt;
  final int gradientIndex;
  final String emoji;
  final bool isFavorite;
  final List<String> tags;

  Memory copyWith({bool? isFavorite}) => Memory(
        id: id,
        title: title,
        content: content,
        type: type,
        createdAt: createdAt,
        gradientIndex: gradientIndex,
        emoji: emoji,
        isFavorite: isFavorite ?? this.isFavorite,
        tags: tags,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'type': type.index,
        'createdAt': createdAt.toIso8601String(),
        'gradientIndex': gradientIndex,
        'emoji': emoji,
        'isFavorite': isFavorite,
        'tags': tags,
      };

  factory Memory.fromMap(Map<String, dynamic> m) => Memory(
        id: m['id'] as String,
        title: m['title'] as String,
        content: m['content'] as String,
        type: MemoryType.values[m['type'] as int],
        createdAt: DateTime.parse(m['createdAt'] as String),
        gradientIndex: m['gradientIndex'] as int,
        emoji: m['emoji'] as String? ?? '💜',
        isFavorite: m['isFavorite'] as bool? ?? false,
        tags: List<String>.from(m['tags'] as List? ?? []),
      );

  String toJson() => jsonEncode(toMap());
  factory Memory.fromJson(String s) =>
      Memory.fromMap(jsonDecode(s) as Map<String, dynamic>);
}
