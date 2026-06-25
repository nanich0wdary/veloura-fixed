// lib/features/pairing/providers/pairing_provider.dart
// Veloura Phase 3 — Real cryptographic pairing provider

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/pair_data.dart';
import '../../../core/identity/identity_service.dart';
import '../../../core/services/secure_storage_service.dart';

const _kBox      = 'veloura_pairing';
const _kPairData = 'pair_data';

// ── Pairing steps (for UI progress) ──────────────────────────
enum PairingStep {
  idle,           // not started
  showMyQr,       // showing my QR for partner to scan
  scanPartnerQr,  // scanning partner's QR
  verifyKeys,     // cross-verifying fingerprints
  confirmed,      // both confirmed — deriving shared key
  paired,         // fully paired and ready
}

class PairingState {
  const PairingState({
    this.pairData,
    this.step       = PairingStep.idle,
    this.isLoading  = false,
    this.statusMessage = '',
    this.error,
    this.scannedPartner,
  });

  final PairData?  pairData;
  final PairingStep step;
  final bool       isLoading;
  final String     statusMessage;
  final String?    error;
  final PairData?  scannedPartner; // partner data from their QR scan

  bool get isPaired   => pairData?.isPaired ?? false;
  bool get hasPartner => pairData?.hasPartner ?? false;

  PairingState copyWith({
    PairData?     pairData,
    PairingStep?  step,
    bool?         isLoading,
    String?       statusMessage,
    String?       error,
    PairData?     scannedPartner,
  }) => PairingState(
    pairData:        pairData        ?? this.pairData,
    step:            step            ?? this.step,
    isLoading:       isLoading       ?? this.isLoading,
    statusMessage:   statusMessage   ?? this.statusMessage,
    error:           error,
    scannedPartner:  scannedPartner  ?? this.scannedPartner,
  );
}

class PairingNotifier extends StateNotifier<PairingState> {
  PairingNotifier() : super(const PairingState()) { _init(); }

  Box? _box;

  Future<void> _init() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true);

    try {
      _box = Hive.isBoxOpen(_kBox)
          ? Hive.box(_kBox)
          : await Hive.openBox(_kBox);
      if (!mounted) return;

      final raw = _box?.get(_kPairData) as String?;
      if (raw != null) {
        try {
          final loaded = PairData.fromJson(raw);
          state = state.copyWith(pairData: loaded, isLoading: false);
          return;
        } catch (e) {
          if (kDebugMode) debugPrint('Corrupted pair data, resetting: $e');
        }
      }
      await _createFromIdentity();
    } catch (e) {
      if (kDebugMode) debugPrint('PairingNotifier init error: $e');
      await _createFromIdentity();
    }
  }

  // ── Create PairData from identity ────────────────────────

  Future<void> _createFromIdentity() async {
    final identity = IdentityService.instance.currentUser;
    final data = PairData(
      deviceId:    identity?.deviceId    ?? PairCodeGenerator.deviceId(),
      pairCode:    PairCodeGenerator.generate(),
      displayName: identity?.displayName ?? 'You',
    );
    try {
      await _box?.put(_kPairData, data.toJson());
      // Also persist sensitive values in secure storage
      await SecureStorageService.instance.savePairCode(data.pairCode);
      await SecureStorageService.instance.saveDeviceId(data.deviceId);
    } catch (_) {}
    if (mounted) state = state.copyWith(pairData: data, isLoading: false);
  }

  // ── Step 1: Show my QR ────────────────────────────────────

  void startShowingQr() {
    if (!mounted) return;
    state = state.copyWith(
      step: PairingStep.showMyQr,
      error: null,
      statusMessage: 'Show this QR to your partner',
    );
  }

  // ── Step 2: Scan partner QR ───────────────────────────────

  void startScanning() {
    if (!mounted) return;
    state = state.copyWith(
      step: PairingStep.scanPartnerQr,
      error: null,
      statusMessage: 'Scan your partner\'s QR code',
    );
  }

  // ── Step 3: Process scanned QR ────────────────────────────

  Future<void> processScannedQr(String qrData) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final scanned = PairData.fromQrPayload(qrData);
      if (scanned == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid QR code. Please scan a Veloura QR.',
        );
        return;
      }

      // Cannot pair with yourself
      if (scanned.deviceId == state.pairData?.deviceId) {
        state = state.copyWith(
          isLoading: false,
          error: 'You cannot pair with your own device.',
        );
        return;
      }

      // Move to verification step
      state = state.copyWith(
        isLoading:      false,
        scannedPartner: scanned,
        step:           PairingStep.verifyKeys,
        statusMessage:  'Verify this is your partner',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to read QR: $e',
      );
    }
  }

  // ── Step 4: Confirm pairing ───────────────────────────────

  Future<void> confirmPairing() async {
    if (!mounted) return;
    final scanned = state.scannedPartner;
    final myData  = state.pairData;
    if (scanned == null || myData == null) return;

    state = state.copyWith(
      step:          PairingStep.confirmed,
      isLoading:     true,
      statusMessage: 'Deriving shared secret...',
    );

    // Derive shared secret from both device IDs + pairCode
    // Both devices compute the SAME value independently
    final sharedSecret = PairData.deriveSharedSecret(
      myData.deviceId,
      scanned.deviceId,
      myData.pairCode,
    );

    // Save partner's public key in secure storage
    if (scanned.partnerPublicKey != null) {
      await SecureStorageService.instance
          .savePairToken('partner_pubkey:${scanned.partnerPublicKey}');
    }

    final updated = myData.copyWith(
      partnerId:        scanned.deviceId,
      partnerName:      scanned.displayName,
      partnerPublicKey: scanned.partnerPublicKey,
      partnerEmoji:     scanned.partnerEmoji,
      sharedSecret:     sharedSecret,
      status:           PairingStatus.connected,
      pairedAt:         DateTime.now(),
    );

    try { await _box?.put(_kPairData, updated.toJson()); } catch (_) {}

    if (mounted) {
      state = state.copyWith(
        pairData:      updated,
        step:          PairingStep.paired,
        isLoading:     false,
        scannedPartner: null,
        statusMessage: 'Paired with ${scanned.displayName}! 💜',
      );
    }
  }

  // ── Cancel / reject ───────────────────────────────────────

  void cancelPairing() {
    if (!mounted) return;
    state = state.copyWith(
      step:           PairingStep.idle,
      scannedPartner: null,
      error:          null,
      statusMessage:  '',
    );
  }

  // ── Unpair ────────────────────────────────────────────────

  Future<void> unpair() async {
    if (!mounted) return;
    final current = state.pairData;
    if (current == null) return;
    // Regenerate pair code on unpair
    final reset = PairData(
      deviceId:    current.deviceId,
      pairCode:    PairCodeGenerator.generate(),
      displayName: current.displayName,
    );
    try { await _box?.put(_kPairData, reset.toJson()); } catch (_) {}
    await SecureStorageService.instance.clearAll();
    if (mounted) state = state.copyWith(
      pairData:      reset,
      step:          PairingStep.idle,
      scannedPartner: null,
      statusMessage: '',
      error:         null,
    );
  }

  // ── Update display name ───────────────────────────────────

  Future<void> setDisplayName(String name) async {
    if (name.trim().isEmpty || !mounted) return;
    final current = state.pairData;
    if (current == null) return;
    final updated = PairData(
      deviceId:         current.deviceId,
      pairCode:         current.pairCode,
      displayName:      name.trim(),
      partnerId:        current.partnerId,
      partnerName:      current.partnerName,
      partnerPublicKey: current.partnerPublicKey,
      partnerEmoji:     current.partnerEmoji,
      sharedSecret:     current.sharedSecret,
      status:           current.status,
      pairedAt:         current.pairedAt,
    );
    try { await _box?.put(_kPairData, updated.toJson()); } catch (_) {}
    if (mounted) state = state.copyWith(pairData: updated);
  }

  void clearError() {
    if (mounted) state = state.copyWith(error: null);
  }
}

final pairingProvider =
    StateNotifierProvider<PairingNotifier, PairingState>(
        (ref) => PairingNotifier());
