// lib/core/p2p/p2p_provider.dart
// Veloura — P2P state provider (Drive-based, no WebRTC)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../identity/local_user.dart';
import 'webrtc_service.dart';

class P2PState {
  const P2PState({
    this.status  = P2PStatus.disconnected,
    this.partner,
    this.pendingOffer,
    this.pendingAnswer,
  });

  final P2PStatus  status;
  final LocalUser? partner;
  final String?    pendingOffer;
  final String?    pendingAnswer;

  bool get isConnected  => status == P2PStatus.connected;
  bool get isConnecting => status == P2PStatus.connecting;

  P2PState copyWith({
    P2PStatus? status, LocalUser? partner,
    String? pendingOffer, String? pendingAnswer,
  }) => P2PState(
    status:        status        ?? this.status,
    partner:       partner       ?? this.partner,
    pendingOffer:  pendingOffer  ?? this.pendingOffer,
    pendingAnswer: pendingAnswer ?? this.pendingAnswer,
  );
}

class P2PNotifier extends StateNotifier<P2PState> {
  P2PNotifier() : super(const P2PState());

  Future<void> createOffer()              async {}
  Future<void> createAnswer(String offer) async {}
  Future<void> receiveAnswer(String ans)  async {}

  void setPartner(LocalUser partner) {
    if (mounted) state = state.copyWith(
        status: P2PStatus.connected, partner: partner);
  }
}

final p2pProvider = StateNotifierProvider<P2PNotifier, P2PState>(
    (ref) => P2PNotifier());
