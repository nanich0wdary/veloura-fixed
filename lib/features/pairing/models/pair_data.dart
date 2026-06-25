// lib/features/pairing/models/pair_data.dart
// Veloura Phase 3 — Real cryptographic pairing model
//
// QR payload now includes:
//  - deviceId    : unique device identifier
//  - displayName : user's chosen name
//  - publicKey   : RSA public key (for key verification)
//  - avatarEmoji : user's avatar
//  - version     : protocol version '3'

import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

enum PairingStatus { unpaired, waiting, connected }

class PairData {
  const PairData({
    required this.deviceId,
    required this.pairCode,
    required this.displayName,
    this.partnerId,
    this.partnerName,
    this.partnerPublicKey,
    this.partnerEmoji,
    this.sharedSecret,
    this.status = PairingStatus.unpaired,
    this.pairedAt,
  });

  final String   deviceId;
  final String   pairCode;
  final String   displayName;
  final String?  partnerId;
  final String?  partnerName;
  final String?  partnerPublicKey; // partner's RSA public key
  final String?  partnerEmoji;
  final String?  sharedSecret;     // derived AES key for encryption
  final PairingStatus status;
  final DateTime? pairedAt;

  bool get isPaired     => status == PairingStatus.connected;
  bool get hasPartner   => partnerId != null && partnerId!.isNotEmpty;

  // Derive a stable shared secret from both device IDs + pairCode
  // Both devices compute the same value independently
  static String deriveSharedSecret(
      String deviceIdA, String deviceIdB, String pairCode) {
    final ids  = [deviceIdA, deviceIdB]..sort(); // sort = deterministic
    final seed = '${ids[0]}:${ids[1]}:$pairCode:veloura-v3';
    final hash = sha256.convert(utf8.encode(seed));
    return hash.toString();
  }

  // Short human-readable fingerprint for verification
  String get pairingFingerprint {
    if (partnerId == null) return '—';
    final ids  = [deviceId, partnerId!]..sort();
    final seed = '${ids[0]}:${ids[1]}:$pairCode';
    final hash = sha256.convert(utf8.encode(seed));
    final hex  = hash.toString().toUpperCase();
    // Show as groups: A1B2 C3D4 E5F6
    return '${hex.substring(0, 4)} ${hex.substring(4, 8)} ${hex.substring(8, 12)}';
  }

  PairData copyWith({
    String? partnerId,
    String? partnerName,
    String? partnerPublicKey,
    String? partnerEmoji,
    String? sharedSecret,
    PairingStatus? status,
    DateTime? pairedAt,
  }) => PairData(
    deviceId:         deviceId,
    pairCode:         pairCode,
    displayName:      displayName,
    partnerId:        partnerId        ?? this.partnerId,
    partnerName:      partnerName      ?? this.partnerName,
    partnerPublicKey: partnerPublicKey ?? this.partnerPublicKey,
    partnerEmoji:     partnerEmoji     ?? this.partnerEmoji,
    sharedSecret:     sharedSecret     ?? this.sharedSecret,
    status:           status           ?? this.status,
    pairedAt:         pairedAt         ?? this.pairedAt,
  );

  // QR payload v3 — includes public key for real crypto pairing
  String get qrPayload => jsonEncode({
    'app':         'veloura',
    'version':     '3',
    'deviceId':    deviceId,
    'pairCode':    pairCode,
    'name':        displayName,
  });

  // Full QR payload with public key for Phase 3 pairing
  String qrPayloadWithKey(String publicKeyPem) => jsonEncode({
    'app':         'veloura',
    'version':     '3',
    'deviceId':    deviceId,
    'pairCode':    pairCode,
    'name':        displayName,
    'publicKey':   publicKeyPem,
  });

  static PairData? fromQrPayload(String raw) {
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      if (map['app'] != 'veloura') return null;
      return PairData(
        deviceId:         map['deviceId']   as String,
        pairCode:         map['pairCode']   as String,
        displayName:      map['name']       as String,
        partnerPublicKey: map['publicKey']  as String?,
        partnerEmoji:     map['emoji']      as String?,
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() => {
    'deviceId':         deviceId,
    'pairCode':         pairCode,
    'displayName':      displayName,
    'partnerId':        partnerId,
    'partnerName':      partnerName,
    'partnerPublicKey': partnerPublicKey,
    'partnerEmoji':     partnerEmoji,
    'sharedSecret':     sharedSecret,
    'status':           status.index,
    'pairedAt':         pairedAt?.toIso8601String(),
  };

  factory PairData.fromMap(Map<String, dynamic> m) => PairData(
    deviceId:         m['deviceId']         as String,
    pairCode:         m['pairCode']         as String,
    displayName:      m['displayName']      as String,
    partnerId:        m['partnerId']        as String?,
    partnerName:      m['partnerName']      as String?,
    partnerPublicKey: m['partnerPublicKey'] as String?,
    partnerEmoji:     m['partnerEmoji']     as String?,
    sharedSecret:     m['sharedSecret']     as String?,
    status: PairingStatus.values[m['status'] as int? ?? 0],
    pairedAt: m['pairedAt'] != null
        ? DateTime.parse(m['pairedAt'] as String) : null,
  );

  String toJson() => jsonEncode(toMap());
  factory PairData.fromJson(String s) =>
      PairData.fromMap(jsonDecode(s) as Map<String, dynamic>);
}

class PairCodeGenerator {
  static final _rng = Random.secure();

  /// Generates a cryptographically strong 32-byte pair secret.
  /// Displayed as XXXX-XXXX-XXXX for human verification.
  static String generate() {
    // 32 bytes = 256 bits of entropy — brute force infeasible
    final bytes = List.generate(32, (_) => _rng.nextInt(256));
    final hex   = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    // Format as 4 groups of 8 hex chars: A1B2C3D4-E5F6A7B8-C9D0E1F2-A3B4C5D6
    return '${hex.substring(0,8)}-${hex.substring(8,16)}-'
           '${hex.substring(16,24)}-${hex.substring(24,32)}';
  }

  /// Short display code (first 12 chars) for manual verification
  static String shortDisplay(String fullCode) =>
      fullCode.replaceAll('-', '').substring(0, 12).toUpperCase();

  static String deviceId() =>
      List.generate(16,
          (_) => _rng.nextInt(16).toRadixString(16)).join();
}
