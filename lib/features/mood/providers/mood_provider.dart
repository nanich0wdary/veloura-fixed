// lib/features/mood/providers/mood_provider.dart
// Veloura — Mood sync via Google Drive

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mood.dart';
import '../../../core/services/drive_sync_service.dart';
import '../../../core/services/notification_service.dart';

const _kBox         = 'veloura_mood';
const _kMyMood      = 'my_mood';
const _kPartnerMood = 'partner_mood';
const _kNote        = 'mood_note';

class MoodState {
  const MoodState({
    this.myMood      = MoodType.romantic,
    this.partnerMood = MoodType.calm,
    this.note        = '',
    this.partnerNote = '',
    this.isSyncing   = false,
    this.lastSynced,
  });
  final MoodType  myMood;
  final MoodType  partnerMood;
  final String    note;
  final String    partnerNote;
  final bool      isSyncing;
  final DateTime? lastSynced;

  MoodState copyWith({
    MoodType?  myMood,
    MoodType?  partnerMood,
    String?    note,
    String?    partnerNote,
    bool?      isSyncing,
    DateTime?  lastSynced,
  }) => MoodState(
    myMood:      myMood      ?? this.myMood,
    partnerMood: partnerMood ?? this.partnerMood,
    note:        note        ?? this.note,
    partnerNote: partnerNote ?? this.partnerNote,
    isSyncing:   isSyncing   ?? this.isSyncing,
    lastSynced:  lastSynced  ?? this.lastSynced,
  );

  Mood get myMoodData      => Mood.byType(myMood);
  Mood get partnerMoodData => Mood.byType(partnerMood);
  List<Color> get auraColors =>
      [...myMoodData.colors, ...partnerMoodData.colors];
}

class MoodNotifier extends StateNotifier<MoodState> {
  MoodNotifier() : super(const MoodState()) { _init(); }

  Box? _box;

  Future<void> _init() async {
    try {
      _box = Hive.isBoxOpen(_kBox)
          ? Hive.box(_kBox)
          : await Hive.openBox(_kBox);
      final box        = _box!;
      final myIdx      = (box.get(_kMyMood,      defaultValue: 0) as int)
          .clamp(0, MoodType.values.length - 1);
      final partnerIdx = (box.get(_kPartnerMood, defaultValue: 1) as int)
          .clamp(0, MoodType.values.length - 1);
      final note       = box.get(_kNote, defaultValue: '') as String;
      if (mounted) {
        state = state.copyWith(
          myMood:     MoodType.values[myIdx],
          partnerMood: MoodType.values[partnerIdx],
          note:       note,
          lastSynced: DateTime.now(),
        );
      }
    } catch (e) {
      if (kDebugMode) debugPrint('MoodNotifier init error: $e');
    }
  }

  Future<void> setMyMood(MoodType mood) async {
    if (!mounted) return;
    state = state.copyWith(myMood: mood, isSyncing: true);
    try { await _box?.put(_kMyMood, mood.index); } catch (_) {}

    // Upload mood to Drive
    try {
      await DriveSyncService.instance.uploadMood({
        'myMood':    mood.index,
        'note':      state.note,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) debugPrint('Mood upload error: $e');
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      state = state.copyWith(isSyncing: false, lastSynced: DateTime.now());
    }

    // Simulate partner response in offline/demo mode
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) _simulatePartnerResponse(mood);
  }

  Future<void> setNote(String note) async {
    if (!mounted) return;
    state = state.copyWith(note: note);
    try { await _box?.put(_kNote, note); } catch (_) {}
  }

  Future<void> syncPartnerMood() async {
    try {
      final remote = await DriveSyncService.instance.downloadMood();
      if (remote == null || !mounted) return;
      final idx = (remote['partnerMood'] as int? ?? 1)
          .clamp(0, MoodType.values.length - 1);
      final note = remote['note'] as String? ?? '';
      final mood = MoodType.values[idx];
      state = state.copyWith(partnerMood: mood, partnerNote: note);
      try { _box?.put(_kPartnerMood, idx); } catch (_) {}
      await NotificationService.instance.showMoodUpdate(
        partnerName: 'Partner',
        moodLabel:   mood.name,
        moodEmoji:   Mood.byType(mood).emoji,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Sync partner mood error: $e');
    }
  }

  void _simulatePartnerResponse(MoodType myMood) {
    if (!mounted) return;
    const responses = {
      MoodType.romantic:    MoodType.romantic,
      MoodType.calm:        MoodType.peaceful,
      MoodType.missing:     MoodType.melancholic,
      MoodType.joyful:      MoodType.joyful,
      MoodType.peaceful:    MoodType.calm,
      MoodType.melancholic: MoodType.missing,
      MoodType.energetic:   MoodType.joyful,
    };
    final pm = responses[myMood] ?? MoodType.calm;
    state = state.copyWith(partnerMood: pm);
    try { _box?.put(_kPartnerMood, pm.index); } catch (_) {}
  }
}

final moodProvider = StateNotifierProvider<MoodNotifier, MoodState>(
    (ref) => MoodNotifier());
