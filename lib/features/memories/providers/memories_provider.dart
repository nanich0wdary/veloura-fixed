// lib/features/memories/providers/memories_provider.dart
// Veloura — Memories with Drive backup

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/memory.dart';
import '../../../core/services/drive_sync_service.dart';

const _kBox = 'veloura_memories';

class MemoriesState {
  const MemoriesState({
    this.memories = const [],
    this.filter   = MemoryFilter.all,
    this.isAdding = false,
  });
  final List<Memory> memories;
  final MemoryFilter filter;
  final bool         isAdding;

  List<Memory> get filtered {
    switch (filter) {
      case MemoryFilter.all:
        return memories;
      case MemoryFilter.favorites:
        return memories.where((m) => m.isFavorite).toList();
      case MemoryFilter.notes:
        return memories.where((m) => m.type == MemoryType.note).toList();
      case MemoryFilter.moments:
        return memories.where((m) =>
            m.type == MemoryType.moment ||
            m.type == MemoryType.milestone).toList();
    }
  }

  MemoriesState copyWith({
    List<Memory>? memories,
    MemoryFilter? filter,
    bool?         isAdding,
  }) => MemoriesState(
    memories: memories ?? this.memories,
    filter:   filter   ?? this.filter,
    isAdding: isAdding ?? this.isAdding,
  );
}

enum MemoryFilter { all, favorites, notes, moments }

class MemoriesNotifier extends StateNotifier<MemoriesState> {
  MemoriesNotifier() : super(const MemoriesState()) { _init(); }

  final _uuid = const Uuid();
  Box? _box;

  Future<void> _init() async {
    try {
      _box = Hive.isBoxOpen(_kBox)
          ? Hive.box(_kBox)
          : await Hive.openBox(_kBox);
      await _load();
    } catch (e) {
      if (kDebugMode) debugPrint('MemoriesNotifier init error: $e');
      if (mounted) state = state.copyWith(memories: _demo());
    }
  }

  Future<void> _load() async {
    final box = _box;
    if (box == null) {
      if (mounted) state = state.copyWith(memories: _demo());
      return;
    }
    final memories = <Memory>[];
    for (final raw in box.values.cast<String>()) {
      try { memories.add(Memory.fromJson(raw)); } catch (_) {}
    }
    memories.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (memories.isEmpty) {
      final demo = _demo();
      for (final m in demo) {
        try { await box.put(m.id, m.toJson()); } catch (_) {}
      }
      if (mounted) state = state.copyWith(memories: demo);
    } else {
      if (mounted) state = state.copyWith(memories: memories);
    }
  }

  Future<void> addMemory({
    required String title,
    required String content,
    required MemoryType type,
    required String emoji,
    required int gradientIndex,
  }) async {
    if (!mounted) return;
    state = state.copyWith(isAdding: true);
    final mem = Memory(
      id:            _uuid.v4(),
      title:         title,
      content:       content,
      type:          type,
      createdAt:     DateTime.now(),
      gradientIndex: gradientIndex,
      emoji:         emoji,
    );
    try { await _box?.put(mem.id, mem.toJson()); } catch (_) {}
    if (mounted) {
      state = state.copyWith(
          memories: [mem, ...state.memories], isAdding: false);
    }
    // Backup to Drive
    try {
      final maps = state.memories.map((m) => m.toMap()).toList();
      await DriveSyncService.instance.uploadMemories(maps);
    } catch (e) {
      if (kDebugMode) debugPrint('Memories upload error: $e');
    }
  }

  Future<void> toggleFavorite(String id) async {
    if (!mounted) return;
    final updated = state.memories.map((m) {
      if (m.id != id) return m;
      final t = m.copyWith(isFavorite: !m.isFavorite);
      try { _box?.put(id, t.toJson()); } catch (_) {}
      return t;
    }).toList();
    if (mounted) state = state.copyWith(memories: updated);
  }

  Future<void> deleteMemory(String id) async {
    if (!mounted) return;
    try { await _box?.delete(id); } catch (_) {}
    if (mounted) {
      state = state.copyWith(
          memories: state.memories.where((m) => m.id != id).toList());
    }
  }

  void setFilter(MemoryFilter f) {
    if (mounted) state = state.copyWith(filter: f);
  }

  List<Memory> _demo() {
    final now = DateTime.now();
    return [
      Memory(
          id: _uuid.v4(), title: 'First video call',
          content: 'We talked for 4 hours. Your laugh is my favourite sound.',
          type: MemoryType.milestone,
          createdAt: now.subtract(const Duration(days: 180)),
          gradientIndex: 0, emoji: '✨', isFavorite: true),
      Memory(
          id: _uuid.v4(), title: 'The rainy evening',
          content: 'You sent a voice note of the rain. I played it on repeat.',
          type: MemoryType.moment,
          createdAt: now.subtract(const Duration(days: 90)),
          gradientIndex: 1, emoji: '🌧️', isFavorite: true),
      Memory(
          id: _uuid.v4(), title: 'Things I love about you',
          content: 'The way you say goodnight. Your voice when sleepy.',
          type: MemoryType.note,
          createdAt: now.subtract(const Duration(days: 60)),
          gradientIndex: 2, emoji: '💌'),
      Memory(
          id: _uuid.v4(), title: '100 days together',
          content: 'A hundred days of late night calls, falling deeper.',
          type: MemoryType.milestone,
          createdAt: now.subtract(const Duration(days: 45)),
          gradientIndex: 3, emoji: '💯', isFavorite: true),
      Memory(
          id: _uuid.v4(), title: 'Surprise message',
          content: 'Woke up to 12 messages describing your dream about us.',
          type: MemoryType.moment,
          createdAt: now.subtract(const Duration(days: 7)),
          gradientIndex: 0, emoji: '🌙', isFavorite: true),
    ];
  }
}

final memoriesProvider =
    StateNotifierProvider<MemoriesNotifier, MemoriesState>(
        (ref) => MemoriesNotifier());
