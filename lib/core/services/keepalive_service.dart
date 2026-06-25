// lib/core/services/keepalive_service.dart
// Veloura — Smart sync trigger (lifecycle + connectivity, not polling timer)

import 'package:flutter/foundation.dart';

class KeepaliveService {
  KeepaliveService._();
  static final KeepaliveService instance = KeepaliveService._();

  VoidCallback? _onSync;

  // Called by HomeScreen on app resume / connectivity change
  void configure({required VoidCallback onSync}) {
    _onSync = onSync;
  }

  void triggerSync() {
    try {
      _onSync?.call();
    } catch (e) {
      if (kDebugMode) debugPrint('KeepaliveService triggerSync error: $e');
    }
  }

  // No timer — sync triggered by lifecycle events instead
  void start() { if (kDebugMode) debugPrint('KeepaliveService: lifecycle-based sync active'); }
  void stop()  {}
}
