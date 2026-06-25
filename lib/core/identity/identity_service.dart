// lib/core/identity/identity_service.dart
// Veloura — Local Cryptographic Identity (simplified, no ASN1 parsing)
// Uses UUID device ID + secure storage for identity persistence

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:crypto/crypto.dart';
import 'local_user.dart';

const _kDeviceId    = 'identity_device_id';
const _kDisplayName = 'identity_display_name';
const _kSetupDone   = 'identity_setup_done';
const _kAvatarEmoji = 'identity_avatar_emoji';
const _kSecretSeed  = 'identity_secret_seed';

class IdentityService {
  IdentityService._();
  static final IdentityService instance = IdentityService._();

  static const _storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true));
  static const _uuid = Uuid();

  LocalUser? _currentUser;
  LocalUser? get currentUser => _currentUser;
  bool get isSetup => _currentUser != null;

  /// Init — load existing identity from storage
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDone = prefs.getBool(_kSetupDone) ?? false;
      if (!isDone) return;

      final deviceId    = prefs.getString(_kDeviceId) ?? '';
      final displayName = prefs.getString(_kDisplayName) ?? '';
      final avatarEmoji = prefs.getString(_kAvatarEmoji) ?? '💜';
      final seed        = await _storage.read(key: _kSecretSeed) ?? '';

      if (deviceId.isEmpty) return;

      _currentUser = LocalUser(
        deviceId:     deviceId,
        displayName:  displayName,
        publicKeyPem: _derivePublicKey(deviceId, seed),
        avatarEmoji:  avatarEmoji,
        createdAt:    DateTime.now(),
      );
      if (kDebugMode) debugPrint('Identity loaded: ${_currentUser!.fingerprint}');
    } catch (e) {
      if (kDebugMode) debugPrint('IdentityService init error: $e');
    }
  }

  /// Create a new identity (first launch)
  Future<LocalUser> createIdentity(String displayName,
      {String avatarEmoji = '💜'}) async {
    final deviceId = _uuid.v4();
    // Generate a secure random seed (256 bits)
    final random   = Random.secure();
    final seedBytes = Uint8List.fromList(
        List.generate(32, (_) => random.nextInt(256)));
    final seed = base64Encode(seedBytes);

    // Derive a "public key" fingerprint from deviceId + seed
    final publicKey = _derivePublicKey(deviceId, seed);

    // Store seed securely (device only)
    await _storage.write(key: _kSecretSeed, value: seed);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDeviceId,    deviceId);
    await prefs.setString(_kDisplayName, displayName.trim());
    await prefs.setString(_kAvatarEmoji, avatarEmoji);
    await prefs.setBool(_kSetupDone,     true);

    _currentUser = LocalUser(
      deviceId:     deviceId,
      displayName:  displayName.trim(),
      publicKeyPem: publicKey,
      avatarEmoji:  avatarEmoji,
      createdAt:    DateTime.now(),
    );

    if (kDebugMode) debugPrint('Identity created: ${_currentUser!.fingerprint}');
    return _currentUser!;
  }

  /// Update display name
  Future<void> updateDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDisplayName, name.trim());
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(displayName: name.trim());
    }
  }

  /// Derive a stable "public key" from deviceId + seed
  String _derivePublicKey(String deviceId, String seed) {
    final data  = utf8.encode('$deviceId:$seed:veloura-v3');
    final hash  = sha256.convert(data);
    return 'VLR-${base64Encode(hash.bytes).replaceAll('=', '')}';
  }

  /// Derive shared AES key from both device IDs + pair code
  String deriveSharedKey(String myDeviceId, String partnerDeviceId,
      String pairCode) {
    final ids  = [myDeviceId, partnerDeviceId]..sort();
    final seed = '${ids[0]}:${ids[1]}:$pairCode:veloura-v3';
    final hash = sha256.convert(utf8.encode(seed));
    return hash.toString();
  }
}
