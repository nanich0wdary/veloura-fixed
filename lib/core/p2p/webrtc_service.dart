// lib/core/p2p/webrtc_service.dart
// Veloura — P2P stub (WebRTC removed, Drive sync is primary communication)
// Kept as interface layer so providers compile without changes

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../identity/local_user.dart';

enum P2PStatus { disconnected, connecting, connected, failed }

class P2PMessage {
  const P2PMessage({
    required this.id,
    required this.text,
    required this.fromDeviceId,
    required this.timestamp,
    this.type = 'text',
  });
  final String   id;
  final String   text;
  final String   fromDeviceId;
  final DateTime timestamp;
  final String   type;

  Map<String, dynamic> toMap() => {
    'id':           id,
    'text':         text,
    'fromDeviceId': fromDeviceId,
    'timestamp':    timestamp.toIso8601String(),
    'type':         type,
  };

  factory P2PMessage.fromMap(Map<String, dynamic> m) => P2PMessage(
    id:           m['id']           as String,
    text:         m['text']         as String,
    fromDeviceId: m['fromDeviceId'] as String,
    timestamp:    DateTime.parse(m['timestamp'] as String),
    type:         m['type']         as String? ?? 'text',
  );
}

class WebRTCService {
  WebRTCService._();
  static final WebRTCService instance = WebRTCService._();

  P2PStatus _status = P2PStatus.disconnected;
  P2PStatus get status => _status;

  String     _sharedKey  = '';
  String     _myDeviceId = '';
  LocalUser? _partner;
  LocalUser? get partner => _partner;

  final _messageCtrl = StreamController<P2PMessage>.broadcast();
  final _statusCtrl  = StreamController<P2PStatus>.broadcast();
  final _iceCtrl     = StreamController<Map<String, dynamic>>.broadcast();

  Stream<P2PMessage>           get onMessage => _messageCtrl.stream;
  Stream<P2PStatus>            get onStatus  => _statusCtrl.stream;
  Stream<Map<String, dynamic>> get onIce     => _iceCtrl.stream;

  void configure({
    required String myDeviceId,
    required String sharedKey,
    LocalUser? partner,
  }) {
    _myDeviceId = myDeviceId;
    _sharedKey  = sharedKey;
    _partner    = partner;
    if (kDebugMode) debugPrint('WebRTCService configured — Drive sync is primary');
  }

  // All send methods are no-ops — Drive sync handles delivery
  Future<bool> sendMessage(String text)               async => false;
  Future<void> sendControl(Map<String, dynamic> p)    async {}
  Future<void> sendTyping(bool isTyping)              async {}
  Future<void> sendMood(String idx, String emoji)     async {}
  Future<void> sendReaction(String msgId, String emoji) async {}

  // Signaling stubs
  Future<String> createOffer()              async => '';
  Future<String> createAnswer(String offer) async => '';
  Future<void>   setAnswer(String answer)   async {}
  Future<void>   addIceCandidate(Map<String, dynamic> c) async {}

  Future<void> disconnect() async {
    _status = P2PStatus.disconnected;
    if (!_statusCtrl.isClosed) _statusCtrl.add(_status);
  }

  void dispose() {
    disconnect();
    _messageCtrl.close();
    _statusCtrl.close();
    _iceCtrl.close();
  }
}
