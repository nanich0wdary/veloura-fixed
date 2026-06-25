// lib/core/services/background_sync_service.dart
// Veloura — Background sync stub (workmanager removed, P2P handles real-time)

import 'package:flutter/foundation.dart';

// Top-level callback (kept for future workmanager integration)
void callbackDispatcher() {}

class BackgroundSyncService {
  BackgroundSyncService._();
  static final BackgroundSyncService instance = BackgroundSyncService._();

  Future<void> init()                  async {}
  Future<void> registerPeriodicSync()  async {}
  Future<void> cancelSync()            async {}
  Future<void> runOnceNow()            async {
    if (kDebugMode) debugPrint('Background sync: P2P handles real-time delivery');
  }
}
