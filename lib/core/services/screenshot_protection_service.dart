// lib/core/services/screenshot_protection_service.dart
// Veloura Phase 5 — Screenshot protection via native channel

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenshotProtectionService {
  ScreenshotProtectionService._();
  static final instance = ScreenshotProtectionService._();

  static const _channel = MethodChannel('com.veloura.app/screenshot');

  Future<void> enable() async {
    try {
      await _channel.invokeMethod('enable');
    } catch (e) {
      if (kDebugMode) debugPrint('Screenshot protection enable error: $e');
    }
  }

  Future<void> disable() async {
    try {
      await _channel.invokeMethod('disable');
    } catch (e) {
      if (kDebugMode) debugPrint('Screenshot protection disable error: $e');
    }
  }
}
