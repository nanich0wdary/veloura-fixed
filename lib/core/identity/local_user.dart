// lib/core/identity/local_user.dart
// Veloura — Local User Model (no cloud, cryptographic identity)

import 'dart:convert';

class LocalUser {
  const LocalUser({
    required this.deviceId,
    required this.displayName,
    required this.publicKeyPem,
    this.avatarEmoji = '💜',
    this.createdAt,
  });

  final String   deviceId;
  final String   displayName;
  final String   publicKeyPem;
  final String   avatarEmoji;
  final DateTime? createdAt;

  /// Short fingerprint for display (last 8 chars of deviceId)
  String get fingerprint => deviceId.length >= 8
      ? deviceId.substring(deviceId.length - 8).toUpperCase()
      : deviceId.toUpperCase();

  LocalUser copyWith({
    String? displayName,
    String? avatarEmoji,
  }) => LocalUser(
    deviceId:     deviceId,
    displayName:  displayName  ?? this.displayName,
    publicKeyPem: publicKeyPem,
    avatarEmoji:  avatarEmoji  ?? this.avatarEmoji,
    createdAt:    createdAt,
  );

  Map<String, dynamic> toMap() => {
    'deviceId':    deviceId,
    'displayName': displayName,
    'publicKeyPem': publicKeyPem,
    'avatarEmoji': avatarEmoji,
    'createdAt':   createdAt?.toIso8601String(),
  };

  factory LocalUser.fromMap(Map<String, dynamic> m) => LocalUser(
    deviceId:     m['deviceId']    as String,
    displayName:  m['displayName'] as String,
    publicKeyPem: m['publicKeyPem'] as String? ?? '',
    avatarEmoji:  m['avatarEmoji'] as String? ?? '💜',
    createdAt:    m['createdAt'] != null
        ? DateTime.tryParse(m['createdAt'] as String) : null,
  );

  String toJson() => jsonEncode(toMap());
  factory LocalUser.fromJson(String s) =>
      LocalUser.fromMap(jsonDecode(s) as Map<String, dynamic>);

  /// QR payload — scanned by partner during pairing
  String get qrPayload => jsonEncode({
    'app':     'veloura',
    'version': '3',
    'deviceId':    deviceId,
    'displayName': displayName,
    'publicKey':   publicKeyPem,
    'avatarEmoji': avatarEmoji,
  });

  static LocalUser? fromQrPayload(String raw) {
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      if (m['app'] != 'veloura') return null;
      return LocalUser(
        deviceId:     m['deviceId']    as String,
        displayName:  m['displayName'] as String,
        publicKeyPem: m['publicKey']   as String? ?? '',
        avatarEmoji:  m['avatarEmoji'] as String? ?? '💜',
      );
    } catch (_) {
      return null;
    }
  }
}
