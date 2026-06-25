// lib/features/pairing/screens/webrtc_signal_screen.dart
// Veloura — Connection screen (Drive sync, no WebRTC)
// Shows how to connect via Google Drive shared pair code

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/sync_provider.dart';

class WebRTCSignalScreen extends ConsumerWidget {
  const WebRTCSignalScreen({super.key, this.isInitiator = true});
  final bool isInitiator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('CONNECT', style: GoogleFonts.cinzel(
            fontSize: 13, color: Colors.white, letterSpacing: 4)),
        centerTitle: true,
      ),
      body: Stack(children: [
        Container(decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.5), radius: 1.3,
            colors: [Color(0xFF1E1035), Color(0xFF0F172A)],
          ),
        )),
        SafeArea(child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('☁️', style: TextStyle(fontSize: 64))
                  .animate().fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.5, 0.5)),

              const SizedBox(height: 24),

              Text('Drive Sync', style: GoogleFonts.cormorantGaramond(
                  fontSize: 28, color: Colors.white,
                  fontWeight: FontWeight.w500))
                  .animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 12),

              Text(
                'Messages sync via encrypted Google Drive.\n'
                'Both devices must be signed in with the same pair code.',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 15, color: Colors.white38,
                    height: 1.6, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 40),

              _StepCard(step: '1', icon: Icons.login_rounded,
                  text: 'Go to Sync tab → Sign in with Google'),
              const SizedBox(height: 12),
              _StepCard(step: '2', icon: Icons.qr_code_rounded,
                  text: 'Share your pair code with your partner'),
              const SizedBox(height: 12),
              _StepCard(step: '3', icon: Icons.sync_rounded,
                  text: 'Enable Drive Sync — messages auto-sync every 30s'),

              const SizedBox(height: 32),

              if (!sync.isSignedIn)
                GestureDetector(
                  onTap: () => ref.read(syncProvider.notifier).signIn(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFC084FC), Color(0xFFF472B6)]),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(
                          color: const Color(0xFFC084FC).withValues(alpha: 0.35),
                          blurRadius: 16)],
                    ),
                    child: Center(child: Text('SIGN IN WITH GOOGLE',
                        style: GoogleFonts.cinzel(
                            fontSize: 12, color: Colors.white,
                            letterSpacing: 2))),
                  ),
                ).animate().fadeIn(delay: 500.ms)
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF34D399).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF34D399).withValues(alpha: 0.3)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF34D399), size: 18),
                    const SizedBox(width: 10),
                    Text('Signed in as ${sync.userEmail}',
                        style: GoogleFonts.cormorantGaramond(
                            fontSize: 14, color: const Color(0xFF34D399))),
                  ]),
                ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        )),
      ]),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.step, required this.icon, required this.text});
  final String step, text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08), width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFC084FC).withValues(alpha: 0.15),
            ),
            child: Center(child: Text(step, style: GoogleFonts.cinzel(
                fontSize: 11, color: const Color(0xFFC084FC)))),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 16,
              color: const Color(0xFFC084FC).withValues(alpha: 0.7)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: GoogleFonts.cormorantGaramond(
              fontSize: 14, color: Colors.white60))),
        ]),
      ),
    ),
  );
}
