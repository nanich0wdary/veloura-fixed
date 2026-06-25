// lib/core/services/biometric_service.dart
// Veloura — Biometric / PIN lock service

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kBiometricEnabled = 'biometric_enabled';

class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final _auth = LocalAuthentication();

  /// Check if device supports biometrics
  Future<bool> isAvailable() async {
    try {
      return await _auth.canCheckBiometrics ||
             await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> availableTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Authenticate with biometrics
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Veloura to access your private space',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow PIN fallback
        ),
      );
    } on PlatformException catch (e) {
      if (kDebugMode) debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  /// Check if biometric lock is enabled in settings
  Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabled) ?? false;
  }

  /// Enable / disable biometric lock
  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, enabled);
  }

  /// Authenticate if biometric lock is enabled
  /// Returns true if auth passed OR if biometric is disabled
  Future<bool> authenticateIfEnabled() async {
    if (!await isEnabled()) return true;
    if (!await isAvailable()) return true;
    return authenticate();
  }
}
