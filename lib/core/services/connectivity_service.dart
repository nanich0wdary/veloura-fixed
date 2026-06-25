// lib/core/services/connectivity_service.dart
// Veloura — Real-time connectivity monitoring
// Watches network state and triggers sync on reconnect.

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  ConnectivityService._();
  static final ConnectivityService instance = ConnectivityService._();

  StreamSubscription<List<ConnectivityResult>>? _sub;
  bool _isOnline = false;
  bool get isOnline => _isOnline;

  // Callback fired whenever network state changes
  Function(bool isOnline)? onConnectivityChanged;

  Future<void> init() async {
    try {
      // Check initial state
      final results = await Connectivity().checkConnectivity();
      _isOnline = _hasConnection(results);

      // Listen for changes
      _sub = Connectivity().onConnectivityChanged.listen((results) {
        final wasOnline = _isOnline;
        _isOnline = _hasConnection(results);
        if (_isOnline != wasOnline) {
          if (kDebugMode) debugPrint('Network: ${_isOnline ? "online" : "offline"}');
          onConnectivityChanged?.call(_isOnline);
        }
      });

      if (kDebugMode) debugPrint('ConnectivityService initialized — '
          '${_isOnline ? "online" : "offline"}');
    } catch (e) {
      if (kDebugMode) debugPrint('ConnectivityService init error: $e');
      _isOnline = true; // Assume online if can't check
    }
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  void dispose() {
    _sub?.cancel();
  }
}
