// lib/core/services/encryption_service.dart
// AES-256-GCM + PBKDF2 (RANDOM salt per message) + HMAC

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:pointycastle/export.dart' as pc;
import 'package:flutter/foundation.dart';

class EncryptionService {
  EncryptionService._();
  static final EncryptionService instance = EncryptionService._();

  final _rng = Random.secure();

  Uint8List _deriveKey(String pairCode, Uint8List salt) {
    try {
      final pw     = Uint8List.fromList(utf8.encode(pairCode));
      final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64));
      pbkdf2.init(pc.Pbkdf2Parameters(salt, 100000, 32));
      return pbkdf2.process(pw);
    } catch (_) {
      final h = Hmac(sha256, salt);
      return Uint8List.fromList(h.convert(utf8.encode(pairCode)).bytes);
    }
  }

  String encrypt(String plaintext, String pairCode) {
    // Random 16-byte salt every time — never predictable
    final salt      = Uint8List.fromList(
        List.generate(16, (_) => _rng.nextInt(256)));
    final keyBytes  = _deriveKey(pairCode, salt);
    final key       = enc.Key(keyBytes);
    final iv        = enc.IV.fromSecureRandom(12);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encrypt(plaintext, iv: iv);

    final env = {
      'v': 3,
      's': base64Encode(salt),           // random salt — stored with message
      'n': base64Encode(iv.bytes),
      'c': base64Encode(encrypted.bytes),
      't': DateTime.now().millisecondsSinceEpoch,
      'h': _hmac(encrypted.bytes, keyBytes),
    };
    return base64Encode(utf8.encode(jsonEncode(env)));
  }

  String decrypt(String ciphertext, String pairCode) {
    final env        = jsonDecode(utf8.decode(base64Decode(ciphertext)))
        as Map<String, dynamic>;
    final salt       = base64Decode(env['s'] as String);
    final keyBytes   = _deriveKey(pairCode, Uint8List.fromList(salt));
    final cipherBytes = base64Decode(env['c'] as String);
    final storedHmac  = env['h'] as String?;

    if (storedHmac != null && storedHmac != _hmac(cipherBytes, keyBytes)) {
      throw Exception('HMAC mismatch');
    }

    final key       = enc.Key(keyBytes);
    final iv        = enc.IV(Uint8List.fromList(base64Decode(env['n'] as String)));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.gcm));
    return encrypter.decrypt(
        enc.Encrypted(Uint8List.fromList(cipherBytes)), iv: iv);
  }

  String _hmac(List<int> data, List<int> key) =>
      base64Encode(Hmac(sha256, key).convert(data).bytes);

  String encryptMap(Map<String, dynamic> data, String pairCode) =>
      encrypt(jsonEncode(data), pairCode);

  Map<String, dynamic> decryptToMap(String ct, String pairCode) {
    try { return jsonDecode(decrypt(ct, pairCode)) as Map<String, dynamic>; }
    catch (_) { return {}; }
  }
}
