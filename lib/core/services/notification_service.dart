// lib/core/services/notification_service.dart
// Stub — flutter_local_notifications removed (caused desugar AAR conflict)
// Replace with a real implementation once AGP/desugar issue is resolved

import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  Future<void> init() async {
    if (kDebugMode) debugPrint('NotificationService: stub mode');
  }

  Future<void> showNewMessage({
    required String senderName,
    required String message,
  }) async {}

  Future<void> showMoodUpdate({
    required String partnerName,
    required String moodLabel,
    required String moodEmoji,
  }) async {}

  Future<void> showSyncComplete({int newMessages = 0}) async {}

  Future<void> showMemoryAdded({required String title}) async {}

  Future<void> cancelAll() async {}
}
