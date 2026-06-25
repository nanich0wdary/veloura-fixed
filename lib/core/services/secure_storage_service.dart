// lib/core/services/secure_storage_service.dart
// Sensitive values — pair code, device ID — stored in encrypted storage

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  static const _storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true));

  static const _kPairCode  = 'sec_pair_code';
  static const _kDeviceId  = 'sec_device_id';
  static const _kPairToken = 'sec_pair_token';

  Future<void>    savePairCode(String code) =>
      _storage.write(key: _kPairCode, value: code);
  Future<String?> readPairCode() =>
      _storage.read(key: _kPairCode);

  Future<void>    saveDeviceId(String id) =>
      _storage.write(key: _kDeviceId, value: id);
  Future<String?> readDeviceId() =>
      _storage.read(key: _kDeviceId);

  Future<void>    savePairToken(String token) =>
      _storage.write(key: _kPairToken, value: token);
  Future<String?> readPairToken() =>
      _storage.read(key: _kPairToken);

  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      if (kDebugMode) debugPrint('SecureStorage clearAll error: $e');
    }
  }
}
