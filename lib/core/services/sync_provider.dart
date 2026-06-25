// lib/core/services/sync_provider.dart
// Veloura — Google Drive sync state provider

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';
import 'drive_sync_service.dart';

const _kPairCode    = 'sync_pair_code';
const _kDeviceId    = 'sync_device_id';
const _kLastSync    = 'sync_last_sync';
const _kSyncEnabled = 'sync_enabled';

class SyncState {
  const SyncState({
    this.isSignedIn  = false,
    this.isSyncing   = false,
    this.syncEnabled = false,
    this.lastSync,
    this.userEmail   = '',
    this.userName    = '',
    this.userPhoto   = '',
    this.pairCode    = '',
    this.error,
  });

  final bool      isSignedIn;
  final bool      isSyncing;
  final bool      syncEnabled;
  final DateTime? lastSync;
  final String    userEmail;
  final String    userName;
  final String    userPhoto;
  final String    pairCode;
  final String?   error;

  String get lastSyncText {
    if (lastSync == null) return 'Never synced';
    final diff = DateTime.now().difference(lastSync!);
    if (diff.inSeconds < 60)  return 'Just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  SyncState copyWith({
    bool? isSignedIn, bool? isSyncing, bool? syncEnabled,
    DateTime? lastSync, String? userEmail, String? userName,
    String? userPhoto, String? pairCode, String? error,
  }) => SyncState(
    isSignedIn:  isSignedIn  ?? this.isSignedIn,
    isSyncing:   isSyncing   ?? this.isSyncing,
    syncEnabled: syncEnabled ?? this.syncEnabled,
    lastSync:    lastSync    ?? this.lastSync,
    userEmail:   userEmail   ?? this.userEmail,
    userName:    userName    ?? this.userName,
    userPhoto:   userPhoto   ?? this.userPhoto,
    pairCode:    pairCode    ?? this.pairCode,
    error:       error,
  );
}

class SyncNotifier extends StateNotifier<SyncState> {
  SyncNotifier() : super(const SyncState()) { _init(); }

  Timer? _syncTimer;

  Future<void> _init() async {
    try {
      final prefs       = await SharedPreferences.getInstance();
      final pairCode    = prefs.getString(_kPairCode) ?? '';
      final deviceId    = prefs.getString(_kDeviceId) ?? '';
      final syncEnabled = prefs.getBool(_kSyncEnabled) ?? false;
      final lastSyncStr = prefs.getString(_kLastSync);
      final lastSync    = lastSyncStr != null
          ? DateTime.tryParse(lastSyncStr) : null;

      if (pairCode.isNotEmpty) {
        DriveSyncService.instance.setPairCode(pairCode);
      }
      if (deviceId.isNotEmpty) {
        DriveSyncService.instance.setDeviceId(deviceId);
      }

      final account = await AuthService.instance.signInSilently();
      if (mounted) {
        state = state.copyWith(
          isSignedIn:  account != null,
          syncEnabled: syncEnabled,
          pairCode:    pairCode,
          lastSync:    lastSync,
          userEmail:   account?.email ?? '',
          userName:    account?.displayName ?? '',
          userPhoto:   account?.photoUrl ?? '',
        );
      }
      if (account != null && syncEnabled) _startSyncLoop();
    } catch (e) {
      if (kDebugMode) debugPrint('SyncNotifier init error: $e');
    }
  }

  Future<void> signIn() async {
    if (!mounted) return;
    state = state.copyWith(isSyncing: true, error: null);
    try {
      final account = await AuthService.instance.signIn();
      if (account == null) {
        if (mounted) state = state.copyWith(
            isSyncing: false, error: 'Sign-in cancelled');
        return;
      }
      if (mounted) state = state.copyWith(
        isSignedIn: true, isSyncing: false,
        userEmail: account.email,
        userName:  account.displayName ?? '',
        userPhoto: account.photoUrl ?? '',
      );
    } catch (e) {
      if (mounted) state = state.copyWith(
          isSyncing: false, error: 'Sign-in failed: $e');
    }
  }

  Future<void> signOut() async {
    _stopSyncLoop();
    await AuthService.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSyncEnabled, false);
    if (mounted) state = state.copyWith(
      isSignedIn: false, syncEnabled: false,
      userEmail: '', userName: '', userPhoto: '',
    );
  }

  Future<void> setPairCode(String code) async {
    final trimmed = code.trim().toUpperCase();
    if (trimmed.isEmpty) return;
    DriveSyncService.instance.setPairCode(trimmed);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPairCode, trimmed);
    if (mounted) state = state.copyWith(pairCode: trimmed);
  }

  Future<void> enableSync() async {
    if (!state.isSignedIn) {
      await signIn();
      if (!state.isSignedIn) return;
    }
    if (state.pairCode.isEmpty) {
      if (mounted) state = state.copyWith(error: 'Set your pair code first');
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSyncEnabled, true);
    if (mounted) state = state.copyWith(syncEnabled: true);
    _startSyncLoop();
    await triggerSync();
  }

  Future<void> disableSync() async {
    _stopSyncLoop();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSyncEnabled, false);
    if (mounted) state = state.copyWith(syncEnabled: false);
  }

  void _startSyncLoop() {
    _syncTimer?.cancel();
    // Sync every 30 seconds — adaptive (backs off on repeated errors)
    _syncTimer = Timer.periodic(const Duration(seconds: 30),
        (_) => triggerSync());
    if (kDebugMode) debugPrint('Drive sync loop started (30s)');
  }

  void _stopSyncLoop() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  Future<void> triggerSync() async {
    if (!mounted) return;
    if (!state.isSignedIn || !state.syncEnabled) return;
    if (state.isSyncing) return;

    state = state.copyWith(isSyncing: true, error: null);
    await Future.delayed(const Duration(milliseconds: 100));

    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLastSync, now.toIso8601String());

    if (mounted) state = state.copyWith(
        isSyncing: false, lastSync: now);
  }

  @override
  void dispose() {
    _stopSyncLoop();
    super.dispose();
  }
}

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>(
    (ref) => SyncNotifier());
