// lib/features/pairing/screens/pairing_screen.dart
// Veloura Phase 3 — Real QR Pairing Screen

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/pairing_provider.dart';
import '../models/pair_data.dart';
import '../../../core/identity/identity_service.dart';
import 'qr_scan_screen.dart';
import 'webrtc_signal_screen.dart';

class PairingScreen extends ConsumerStatefulWidget {
  const PairingScreen({super.key});
  @override
  ConsumerState<PairingScreen> createState() => _PairingScreenState();
}

class _PairingScreenState extends ConsumerState<PairingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bg;

  @override
  void initState() {
    super.initState();
    _bg = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat(reverse: true);
  }

  @override
  void dispose() { _bg.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state    = ref.watch(pairingProvider);
    final notifier = ref.read(pairingProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: _appBar(context),
      body: Stack(children: [
        AnimatedBuilder(
          animation: _bg,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.3 + _bg.value * 0.4, -0.6),
                radius: 1.4,
                colors: const [Color(0xFF1E1035), Color(0xFF0F172A)],
              ),
            ),
          ),
        ),
        SafeArea(
          child: state.isLoading
              ? _LoadingView(message: state.statusMessage)
              : _buildBody(state, notifier),
        ),
      ]),
    );
  }

  Widget _buildBody(PairingState state, PairingNotifier notifier) {
    // Already paired
    if (state.isPaired && state.pairData != null) {
      return _PairedView(state: state, notifier: notifier);
    }

    // Verification step
    if (state.step == PairingStep.verifyKeys &&
        state.scannedPartner != null) {
      return _VerifyView(state: state, notifier: notifier);
    }

    // Main unpaired view
    return _UnpairedView(state: state, notifier: notifier, bg: _bg);
  }

  PreferredSizeWidget _appBar(BuildContext context) => PreferredSize(
    preferredSize: const Size.fromHeight(60),
    child: ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.6),
            border: Border(bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.07), width: 0.5)),
          ),
          child: SafeArea(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(child: Text('PAIR DEVICES',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                      fontSize: 13, color: Colors.white, letterSpacing: 4))),
              const SizedBox(width: 48),
            ]),
          )),
        ),
      ),
    ),
  );
}

// ── Loading View ──────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const CircularProgressIndicator(
          color: Color(0xFFC084FC), strokeWidth: 2),
      const SizedBox(height: 20),
      Text(message, style: GoogleFonts.cormorantGaramond(
          fontSize: 16, color: Colors.white54, fontStyle: FontStyle.italic)),
    ]),
  );
}

// ── Unpaired View ─────────────────────────────────────────────

class _UnpairedView extends StatelessWidget {
  const _UnpairedView({
    required this.state, required this.notifier, required this.bg});
  final PairingState state;
  final PairingNotifier notifier;
  final AnimationController bg;

  @override
  Widget build(BuildContext context) {
    final identity = IdentityService.instance.currentUser;
    final pairData = state.pairData;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
      physics: const BouncingScrollPhysics(),
      child: Column(children: [
        const SizedBox(height: 8),

        // Title
        Text('Connect with your person',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 22, color: Colors.white70,
                fontStyle: FontStyle.italic),
            textAlign: TextAlign.center)
            .animate().fadeIn(duration: 600.ms),

        const SizedBox(height: 4),
        Text('Both devices must have Veloura installed',
            style: GoogleFonts.cinzel(
                fontSize: 9, color: Colors.white24, letterSpacing: 1.5))
            .animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 28),

        // How it works
        _HowItWorksCard()
            .animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 24),

        // My QR code
        if (pairData != null) ...[
          Text('MY QR CODE',
              style: GoogleFonts.cinzel(
                  fontSize: 9, color: Colors.white30, letterSpacing: 2)),
          const SizedBox(height: 12),
          _QrCard(
            qrData: identity != null && pairData.partnerPublicKey == null
                ? pairData.qrPayloadWithKey(identity.publicKeyPem)
                : pairData.qrPayload,
            pairCode: pairData.pairCode,
          ).animate().fadeIn(delay: 400.ms)
              .scale(begin: const Offset(0.9, 0.9), duration: 500.ms),

          const SizedBox(height: 28),
        ],

        // Error
        if (state.error != null)
          _ErrorBanner(error: state.error!)
              .animate().fadeIn().shakeX(),

        const SizedBox(height: 16),

        // Scan partner QR button
        _ActionButton(
          icon:   Icons.qr_code_scanner_rounded,
          label:  'SCAN PARTNER\'S QR',
          colors: const [Color(0xFFC084FC), Color(0xFFF472B6)],
          onTap:  () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const QrScanScreen())),
        ).animate().fadeIn(delay: 500.ms),

        const SizedBox(height: 12),

        // Pair code display
        if (pairData != null)
          _PairCodeDisplay(pairCode: pairData.pairCode)
              .animate().fadeIn(delay: 600.ms),

        const SizedBox(height: 20),

        // P2P Direct Connect section
        Text('DIRECT P2P CONNECTION',
            style: GoogleFonts.cinzel(
                fontSize: 9, color: Colors.white24, letterSpacing: 2))
            .animate().fadeIn(delay: 650.ms),
        const SizedBox(height: 12),

        Row(children: [
          Expanded(child: _P2PButton(
            icon:  Icons.wifi_tethering_rounded,
            label: 'INITIATOR',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) =>
                    const WebRTCSignalScreen(isInitiator: true))),
          ).animate().fadeIn(delay: 700.ms)),
          const SizedBox(width: 10),
          Expanded(child: _P2PButton(
            icon:  Icons.qr_code_scanner_rounded,
            label: 'RECEIVER',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) =>
                    const WebRTCSignalScreen(isInitiator: false))),
          ).animate().fadeIn(delay: 800.ms)),
        ]),
      ]),
    );
  }
}

// ── Verification View ─────────────────────────────────────────

class _VerifyView extends StatelessWidget {
  const _VerifyView({required this.state, required this.notifier});
  final PairingState state;
  final PairingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final partner  = state.scannedPartner!;
    final myData   = state.pairData!;
    final fingerprint = PairData.deriveSharedSecret(
        myData.deviceId, partner.deviceId, myData.pairCode);
    final shortFp = fingerprint.substring(0, 12).toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(children: [

        // Partner avatar
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFC084FC).withValues(alpha: 0.12),
            border: Border.all(
                color: const Color(0xFFC084FC).withValues(alpha: 0.4), width: 2),
          ),
          child: Center(child: Text(
            partner.partnerEmoji ?? '💜',
            style: const TextStyle(fontSize: 40))),
        ).animate().fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.7, 0.7), duration: 800.ms,
            curve: Curves.elasticOut),

        const SizedBox(height: 16),

        Text(partner.displayName,
            style: GoogleFonts.cormorantGaramond(
                fontSize: 26, color: Colors.white, fontWeight: FontWeight.w500))
            .animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 4),

        Text('wants to pair with you',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 15, color: Colors.white38,
                fontStyle: FontStyle.italic))
            .animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 32),

        // Fingerprint verification card
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFFFBBF24).withValues(alpha: 0.25),
                    width: 0.5),
              ),
              child: Column(children: [
                Row(children: [
                  const Icon(Icons.verified_user_outlined,
                      color: Color(0xFFFBBF24), size: 16),
                  const SizedBox(width: 8),
                  Text('VERIFY PAIRING',
                      style: GoogleFonts.cinzel(
                          fontSize: 10, color: const Color(0xFFFBBF24),
                          letterSpacing: 2)),
                ]),
                const SizedBox(height: 12),
                Text(
                  'Ask your partner to confirm this fingerprint matches on their device:',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 14, color: Colors.white54, height: 1.5),
                ),
                const SizedBox(height: 16),
                // Fingerprint display
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFFBBF24).withValues(alpha: 0.3),
                        width: 0.5),
                  ),
                  child: Text(
                    '${shortFp.substring(0,4)}  ${shortFp.substring(4,8)}  ${shortFp.substring(8,12)}',
                    style: GoogleFonts.cinzel(
                        fontSize: 22, color: const Color(0xFFFBBF24),
                        letterSpacing: 8, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'This code is the same on both devices if no one tampered with the QR.',
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 12, color: Colors.white30, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0, delay: 400.ms),

        const SizedBox(height: 24),

        // Partner info
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08), width: 0.5),
              ),
              child: Column(children: [
                _VerifyRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Name',
                    value: partner.displayName),
                const SizedBox(height: 8),
                _VerifyRow(
                    icon: Icons.devices_rounded,
                    label: 'Device',
                    value: partner.deviceId.substring(0, 12).toUpperCase()),
                if (partner.partnerPublicKey != null) ...[
                  const SizedBox(height: 8),
                  _VerifyRow(
                      icon: Icons.security_rounded,
                      label: 'Public Key',
                      value: '✓ Received'),
                ],
              ]),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms),

        const SizedBox(height: 28),

        // Confirm button
        _ActionButton(
          icon:   Icons.check_circle_outline_rounded,
          label:  'CONFIRM PAIRING',
          colors: const [Color(0xFF34D399), Color(0xFF3B82F6)],
          onTap:  notifier.confirmPairing,
        ).animate().fadeIn(delay: 600.ms),

        const SizedBox(height: 12),

        // Cancel button
        GestureDetector(
          onTap: notifier.cancelPairing,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1), width: 0.5),
            ),
            child: Center(child: Text('Cancel',
                style: GoogleFonts.cinzel(
                    fontSize: 12, color: Colors.white38, letterSpacing: 1.5))),
          ),
        ).animate().fadeIn(delay: 700.ms),
      ]),
    );
  }
}

class _VerifyRow extends StatelessWidget {
  const _VerifyRow({
    required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: Colors.white30),
    const SizedBox(width: 8),
    Text('$label  ', style: const TextStyle(
        fontSize: 11, color: Colors.white30,
        letterSpacing: 0.5)),
    Expanded(child: Text(value,
        textAlign: TextAlign.right,
        style: const TextStyle(
            fontSize: 13, color: Colors.white70, letterSpacing: 1))),
  ]);
}

// ── Paired View ───────────────────────────────────────────────

class _PairedView extends StatelessWidget {
  const _PairedView({required this.state, required this.notifier});
  final PairingState state;
  final PairingNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final pair = state.pairData!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(children: [

        // Connected orb
        _ConnectedOrb(partnerEmoji: pair.partnerEmoji ?? '💜',
            myEmoji: IdentityService.instance.currentUser?.avatarEmoji ?? '💜')
            .animate().fadeIn(duration: 800.ms)
            .scale(begin: const Offset(0.7, 0.7), duration: 1000.ms,
            curve: Curves.elasticOut),

        const SizedBox(height: 20),

        Text('PAIRED', style: GoogleFonts.cinzel(
            fontSize: 11, color: const Color(0xFF34D399), letterSpacing: 4))
            .animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 6),

        Text('${pair.displayName}  💜  ${pair.partnerName}',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 22, color: Colors.white, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center)
            .animate().fadeIn(delay: 400.ms),

        const SizedBox(height: 24),

        // Paired info card
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF34D399).withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF34D399).withValues(alpha: 0.2),
                    width: 0.5),
              ),
              child: Column(children: [
                _InfoRow(icon: Icons.people_outline_rounded,
                    label: 'Partner', value: pair.partnerName ?? '—'),
                const SizedBox(height: 10),
                _InfoRow(icon: Icons.security_rounded,
                    label: 'Encryption', value: 'AES-256-GCM active'),
                if (pair.pairedAt != null) ...[
                  const SizedBox(height: 10),
                  _InfoRow(icon: Icons.calendar_today_outlined,
                      label: 'Paired since',
                      value: _formatDate(pair.pairedAt!)),
                ],
                const SizedBox(height: 10),
                _InfoRow(icon: Icons.fingerprint_rounded,
                    label: 'Fingerprint',
                    value: pair.pairingFingerprint),
              ]),
            ),
          ),
        ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0, delay: 500.ms),

        const SizedBox(height: 24),

        // Unpair button
        GestureDetector(
          onTap: () => _confirmUnpair(context, notifier),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.red.withValues(alpha: 0.2), width: 0.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.link_off_rounded,
                  color: Colors.red.withValues(alpha: 0.7), size: 16),
              const SizedBox(width: 8),
              Text('Unpair',
                  style: GoogleFonts.cinzel(
                      fontSize: 11,
                      color: Colors.red.withValues(alpha: 0.7),
                      letterSpacing: 1.5)),
            ]),
          ),
        ).animate().fadeIn(delay: 600.ms),
      ]),
    );
  }

  void _confirmUnpair(BuildContext context, PairingNotifier notifier) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1035),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Unpair?',
            style: GoogleFonts.cinzel(color: Colors.white, fontSize: 16)),
        content: Text(
          'This will disconnect you from ${state.pairData?.partnerName}. '
          'Your messages and memories will be kept.',
          style: GoogleFonts.cormorantGaramond(
              color: Colors.white60, fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.cinzel(color: Colors.white38, fontSize: 12)),
          ),
          TextButton(
            onPressed: () { Navigator.pop(context); notifier.unpair(); },
            child: Text('Unpair',
                style: GoogleFonts.cinzel(
                    color: Colors.red.withValues(alpha: 0.8), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 14, color: Colors.white30),
    const SizedBox(width: 8),
    Text('$label  ', style: const TextStyle(
        fontSize: 12, color: Colors.white30, letterSpacing: 0.5)),
    Expanded(child: Text(value,
        textAlign: TextAlign.right,
        style: const TextStyle(
            fontSize: 13, color: Colors.white70, letterSpacing: 1))),
  ]);
}

class _ConnectedOrb extends StatefulWidget {
  const _ConnectedOrb({required this.myEmoji, required this.partnerEmoji});
  final String myEmoji, partnerEmoji;
  @override
  State<_ConnectedOrb> createState() => _ConnectedOrbState();
}

class _ConnectedOrbState extends State<_ConnectedOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final p = _c.value;
        return SizedBox(width: 200, height: 120, child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(left: 20 - p * 5, child: _OrbBall(
                emoji: widget.myEmoji,
                color: const Color(0xFFC084FC), pulse: p)),
            Icon(Icons.favorite_rounded,
                size: 22 + p * 5,
                color: Colors.white.withValues(alpha: 0.4 + p * 0.3)),
            Positioned(right: 20 - p * 5, child: _OrbBall(
                emoji: widget.partnerEmoji,
                color: const Color(0xFF60A5FA), pulse: p)),
          ],
        ));
      },
    );
  }
}

class _OrbBall extends StatelessWidget {
  const _OrbBall({required this.emoji, required this.color, required this.pulse});
  final String emoji;
  final Color color;
  final double pulse;
  @override
  Widget build(BuildContext context) => Container(
    width: 72, height: 72,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: 0.15 + pulse * 0.1),
      border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      boxShadow: [BoxShadow(
          color: color.withValues(alpha: 0.25 + pulse * 0.15),
          blurRadius: 20 + pulse * 10)],
    ),
    child: Center(child: Text(emoji,
        style: const TextStyle(fontSize: 28))),
  );
}

// ── QR Card ───────────────────────────────────────────────────

class _QrCard extends StatelessWidget {
  const _QrCard({required this.qrData, required this.pairCode});
  final String qrData, pairCode;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFFC084FC).withValues(alpha: 0.25), width: 0.5),
        boxShadow: [BoxShadow(
            color: const Color(0xFFC084FC).withValues(alpha: 0.1),
            blurRadius: 24)],
      ),
      child: Column(children: [
        // QR code
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 200,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A)),
            dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A)),
          ),
        ),
        const SizedBox(height: 16),
        Text('PAIR CODE',
            style: GoogleFonts.cinzel(
                fontSize: 9, color: Colors.white30, letterSpacing: 2)),
        const SizedBox(height: 6),
        Text(pairCode,
            style: GoogleFonts.cinzel(
                fontSize: 24, color: Colors.white,
                letterSpacing: 6, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Share this QR or code with your partner',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 12, color: Colors.white30,
                fontStyle: FontStyle.italic)),
      ]),
    );
  }
}

// ── Pair Code Display ─────────────────────────────────────────

class _PairCodeDisplay extends StatelessWidget {
  const _PairCodeDisplay({required this.pairCode});
  final String pairCode;
  @override
  Widget build(BuildContext context) {
    final parts = pairCode.split('-');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: parts.asMap().entries.map((e) => Row(children: [
        if (e.key > 0) Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text('—', style: TextStyle(
              fontSize: 18, color: Colors.white.withValues(alpha: 0.2))),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFC084FC).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: const Color(0xFFC084FC).withValues(alpha: 0.2), width: 0.5),
          ),
          child: Text(e.value,
              style: GoogleFonts.cinzel(
                  fontSize: 20, color: Colors.white,
                  letterSpacing: 4, fontWeight: FontWeight.w600)),
        ),
      ])).toList(),
    );
  }
}

// ── How It Works Card ─────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final steps = [
      ('1', Icons.qr_code_rounded,        'Show your QR to your partner'),
      ('2', Icons.qr_code_scanner_rounded, 'Scan your partner\'s QR'),
      ('3', Icons.verified_user_outlined,  'Verify the fingerprint'),
      ('4', Icons.lock_rounded,            'Secure channel established'),
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.08), width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('HOW PAIRING WORKS',
                  style: GoogleFonts.cinzel(
                      fontSize: 9, color: const Color(0xFFC084FC),
                      letterSpacing: 2)),
              const SizedBox(height: 14),
              ...steps.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Container(
                    width: 22, height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFC084FC).withValues(alpha: 0.15),
                    ),
                    child: Center(child: Text(s.$1,
                        style: GoogleFonts.cinzel(
                            fontSize: 10, color: const Color(0xFFC084FC)))),
                  ),
                  const SizedBox(width: 10),
                  Icon(s.$2, size: 14,
                      color: const Color(0xFFC084FC).withValues(alpha: 0.6)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(s.$3,
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 14, color: Colors.white60))),
                ]),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      color: Colors.red.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
          color: Colors.red.withValues(alpha: 0.2), width: 0.5),
    ),
    child: Row(children: [
      Icon(Icons.error_outline_rounded,
          color: Colors.red.withValues(alpha: 0.7), size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(error,
          style: GoogleFonts.cormorantGaramond(
              fontSize: 14, color: Colors.red.withValues(alpha: 0.8)))),
    ]),
  );
}

// ── Action Button ─────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon, required this.label,
    required this.colors, required this.onTap,
  });
  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(
            color: colors.first.withValues(alpha: 0.35), blurRadius: 16)],
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 10),
        Text(label, style: GoogleFonts.cinzel(
            fontSize: 12, color: Colors.white, letterSpacing: 2)),
      ]),
    ),
  );
}

// ── P2P Button ────────────────────────────────────────────────

class _P2PButton extends StatelessWidget {
  const _P2PButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF60A5FA).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF60A5FA).withValues(alpha: 0.2),
                  width: 0.5),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: const Color(0xFF60A5FA), size: 22),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                      fontSize: 9, color: const Color(0xFF60A5FA),
                      letterSpacing: 1.2, height: 1.4)),
            ]),
          ),
        ),
      ),
    );
  }
}
