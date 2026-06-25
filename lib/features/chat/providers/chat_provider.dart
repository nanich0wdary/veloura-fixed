// lib/features/chat/providers/chat_provider.dart
// Veloura — Drive-sync chat provider (no WebRTC, messages sync via Google Drive)

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/message.dart';
import '../../../core/services/drive_sync_service.dart';
import '../../../core/services/notification_service.dart';

const _kBoxName = 'veloura_messages';

class ChatState {
  const ChatState({
    this.messages        = const [],
    this.isPartnerTyping = false,
    this.isSending       = false,
    this.isSyncing       = false,
  });
  final List<Message> messages;
  final bool isPartnerTyping;
  final bool isSending;
  final bool isSyncing;
  // Drive sync active = messages can be delivered
  bool get isP2PActive => !isSyncing;

  ChatState copyWith({
    List<Message>? messages, bool? isPartnerTyping,
    bool? isSending, bool? isSyncing,
  }) => ChatState(
    messages:        messages        ?? this.messages,
    isPartnerTyping: isPartnerTyping ?? this.isPartnerTyping,
    isSending:       isSending       ?? this.isSending,
    isSyncing:       isSyncing       ?? this.isSyncing,
  );
}

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier() : super(const ChatState()) { _init(); }

  final _uuid = const Uuid();
  Box? _box;
  Timer? _syncTimer;

  Future<void> _init() async {
    try {
      _box = Hive.isBoxOpen(_kBoxName)
          ? Hive.box(_kBoxName)
          : await Hive.openBox(_kBoxName);
      await _loadMessages();
    } catch (e) {
      if (kDebugMode) debugPrint('ChatNotifier init error: $e');
      if (mounted) state = state.copyWith(messages: _demoMessages());
    }
    // Pull from Drive every 30 seconds
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) => syncFromDrive());
  }

  Future<void> _loadMessages() async {
    final box = _box;
    if (box == null) return;
    final messages = <Message>[];
    for (final raw in box.values.cast<String>()) {
      try { messages.add(Message.fromJson(raw)); } catch (_) {}
    }
    messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    if (messages.isEmpty) {
      final demo = _demoMessages();
      for (final m in demo) { try { await box.put(m.id, m.toJson()); } catch (_) {} }
      if (mounted) state = state.copyWith(messages: demo);
    } else {
      if (mounted) state = state.copyWith(messages: messages);
    }
  }

  // ── Send message ─────────────────────────────────────────

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final msg = Message(
      id:        _uuid.v4(),
      text:      text.trim(),
      isMine:    true,
      timestamp: DateTime.now(),
      status:    MessageStatus.sending,
    );
    if (!mounted) return;
    state = state.copyWith(messages: [...state.messages, msg], isSending: true);
    try { await _box?.put(msg.id, msg.toJson()); } catch (_) {}

    // Upload to Drive
    final maps = state.messages.map((m) => m.toMap()).toList();
    final ok   = await DriveSyncService.instance.uploadMessages(maps);

    _updateStatus(msg.id, ok ? MessageStatus.delivered : MessageStatus.sent);
    if (mounted) state = state.copyWith(isSending: false);
  }

  // ── Pull from Drive (partner's messages) ─────────────────

  Future<void> syncFromDrive() async {
    if (!mounted) return;
    state = state.copyWith(isSyncing: true);
    try {
      final remote = await DriveSyncService.instance.downloadMessages();
      if (remote.isEmpty || !mounted) {
        if (mounted) state = state.copyWith(isSyncing: false);
        return;
      }
      final local  = state.messages.map((m) => m.toMap()).toList();
      final merged = DriveSyncService.instance.mergeMessages(local, remote);
      int  newCount = 0;

      final mergedMsgs = <Message>[];
      for (final map in merged) {
        try {
          final m = Message.fromMap(map);
          mergedMsgs.add(m);
          // Save new partner messages to local Hive
          if (!m.isMine && !state.messages.any((e) => e.id == m.id)) {
            try { await _box?.put(m.id, m.toJson()); } catch (_) {}
            newCount++;
          }
        } catch (_) {}
      }

      if (newCount > 0) {
        NotificationService.instance.showSyncComplete(newMessages: newCount);
      }

      if (mounted) state = state.copyWith(messages: mergedMsgs, isSyncing: false);
    } catch (e) {
      if (kDebugMode) debugPrint('syncFromDrive error: $e');
      if (mounted) state = state.copyWith(isSyncing: false);
    }
  }

  // ── Reactions ─────────────────────────────────────────────

  Future<void> addReaction(String messageId, String emoji) async {
    if (!mounted) return;
    final updated = state.messages.map((m) {
      if (m.id != messageId) return m;
      final r = m.copyWith(reaction: emoji);
      try { _box?.put(messageId, r.toJson()); } catch (_) {}
      return r;
    }).toList();
    state = state.copyWith(messages: updated);
  }

  // ── Typing indicator (local only) ─────────────────────────

  void sendTyping(bool isTyping) {}

  // ── Helpers ───────────────────────────────────────────────

  void _updateStatus(String id, MessageStatus s) {
    if (!mounted) return;
    final updated = state.messages.map((m) {
      if (m.id == id) return m.copyWith(status: s);
      return m;
    }).toList();
    state = state.copyWith(messages: updated);
  }

  List<Message> _demoMessages() {
    final now = DateTime.now();
    return [
      Message(id: _uuid.v4(), text: 'hey love 🌙', isMine: false,
          timestamp: now.subtract(const Duration(minutes: 42)),
          status: MessageStatus.read),
      Message(id: _uuid.v4(), text: 'just got home, thinking of you',
          isMine: false,
          timestamp: now.subtract(const Duration(minutes: 41)),
          status: MessageStatus.read),
      Message(id: _uuid.v4(), text: 'been thinking of you all day 💜',
          isMine: true,
          timestamp: now.subtract(const Duration(minutes: 40)),
          status: MessageStatus.read),
      Message(id: _uuid.v4(),
          text: 'the sky looked just like that photo we took ✨',
          isMine: false,
          timestamp: now.subtract(const Duration(minutes: 20)),
          status: MessageStatus.read, reaction: '💜'),
      Message(id: _uuid.v4(), text: "can't wait to see you again",
          isMine: true,
          timestamp: now.subtract(const Duration(minutes: 5)),
          status: MessageStatus.read),
    ];
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>(
    (ref) => ChatNotifier());
