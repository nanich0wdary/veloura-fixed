// lib/features/chat/models/message.dart
// Veloura — Message Model
// Stored as JSON in Hive — no code generation needed.

import 'dart:convert';

enum MessageType { text, emoji, voice, image }
enum MessageStatus { sending, sent, delivered, read }

class Message {
  Message({
    required this.id,
    required this.text,
    required this.isMine,
    required this.timestamp,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
    this.reaction,
  });

  final String id;
  final String text;
  final bool isMine;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;
  final String? reaction;

  // ── Serialization ──────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'isMine': isMine,
        'timestamp': timestamp.toIso8601String(),
        'type': type.index,
        'status': status.index,
        'reaction': reaction,
      };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: map['id'] as String,
        text: map['text'] as String,
        isMine: map['isMine'] as bool,
        timestamp: DateTime.parse(map['timestamp'] as String),
        type: MessageType.values[map['type'] as int],
        status: MessageStatus.values[map['status'] as int],
        reaction: map['reaction'] as String?,
      );

  String toJson() => jsonEncode(toMap());
  factory Message.fromJson(String source) =>
      Message.fromMap(jsonDecode(source) as Map<String, dynamic>);

  Message copyWith({
    String? text,
    MessageStatus? status,
    String? reaction,
  }) =>
      Message(
        id: id,
        text: text ?? this.text,
        isMine: isMine,
        timestamp: timestamp,
        type: type,
        status: status ?? this.status,
        reaction: reaction ?? this.reaction,
      );
}
