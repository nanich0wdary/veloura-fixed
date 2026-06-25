// lib/features/lock/app_lock_screen.dart
// Veloura Phase 5 — Biometric app lock

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/biometric_service.dart';

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key, required this.onUnlocked});
  final VoidCallback onUnlocked;
  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _aura;
  bool    _isAuthenticating = false;
  bool    _failed           = false;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _aura = AnimationController(vsync: this,
        duration: const Duration(seconds: 3))..repeat(reverse: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() { _aura.dispose(); super.dispose(); }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    setState(() { _isAuthenticating = true; _failed = false; _errorMsg = null; });
    try {
      final ok = await BiometricService.instance.authenticate();
      if (ok && mounted) {
        widget.onUnlocked();
      } else if (mounted) {
        setState(() {
          _isAuthenticating = false;
          _failed   = true;
          _errorMsg = 'Authentication failed. Try again.';
        });
      }
    } catch (e) {
      if (mounted) setState(() {
        _isAuthenticating = false;
        _failed   = true;
        _errorMsg = 'Biometric unavailable. Use device PIN.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(children: [
        AnimatedBuilder(
          animation: _aura,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -0.5 + _aura.value * 0.2),
                radius: 1.3,
                colors: const [Color(0xFF1E1035), Color(0xFF0F172A)],
              ),
            ),
          ),
        ),
        SafeArea(child: Center(child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            // Lock orb
            AnimatedBuilder(
              animation: _aura,
              builder: (_, __) {
                final glow  = _aura.value;
                final color = _failed ? Colors.red : const Color(0xFFC084FC);
                return Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(
                        color: color.withValues(alpha: 0.2 + glow * 0.3),
                        blurRadius: 30 + glow * 20, spreadRadius: 2)],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: _failed
                          ? [Colors.red.shade700, Colors.red.shade900]
                          : const [Color(0xFFC084FC), Color(0xFFF472B6)]),
                    ),
                    padding: const EdgeInsets.all(3),
                    child: Container(
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle, color: Color(0xFF0F172A)),
                      child: Center(child: Icon(
                        _failed ? Icons.lock_open_rounded : Icons.lock_rounded,
                        color: _failed ? Colors.redAccent : Colors.white,
                        size: 38,
                      )),
                    ),
                  ),
                );
              },
            ).animate().fadeIn(duration: 600.ms).scale(
                begin: const Offset(0.7, 0.7), duration: 800.ms,
                curve: Curves.elasticOut),

            const SizedBox(height: 32),

            Text('VELOURA', style: GoogleFonts.cinzel(
                fontSize: 24, color: Colors.white,
                letterSpacing: 8, fontWeight: FontWeight.w600))
                .animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 8),

            Text('your private universe', style: GoogleFonts.cormorantGaramond(
                fontSize: 15, color: Colors.white38, fontStyle: FontStyle.italic))
                .animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 48),

            if (_isAuthenticating) ...[
              const CircularProgressIndicator(
                  color: Color(0xFFC084FC), strokeWidth: 2),
              const SizedBox(height: 16),
              Text('Authenticating...', style: GoogleFonts.cinzel(
                  fontSize: 11, color: Colors.white38, letterSpacing: 2))
                  .animate().fadeIn(),
            ] else if (_errorMsg != null) ...[
              Text(_errorMsg!, style: GoogleFonts.cormorantGaramond(
                  fontSize: 15, color: Colors.redAccent),
                  textAlign: TextAlign.center)
                  .animate().fadeIn().shakeX(),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _authenticate,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFC084FC), Color(0xFFF472B6)]),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [BoxShadow(
                        color: const Color(0xFFC084FC).withValues(alpha: 0.35),
                        blurRadius: 16)],
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.fingerprint_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Text('Try Again', style: GoogleFonts.cinzel(
                        fontSize: 12, color: Colors.white, letterSpacing: 2)),
                  ]),
                ),
              ).animate().fadeIn(delay: 200.ms),
            ] else
              Text('Touch to unlock', style: GoogleFonts.cormorantGaramond(
                  fontSize: 16, color: Colors.white30,
                  fontStyle: FontStyle.italic))
                  .animate().fadeIn(),

            const SizedBox(height: 40),

            Text('Protected by biometric authentication',
                style: GoogleFonts.cinzel(
                    fontSize: 8, color: Colors.white.withValues(alpha: 0.12), letterSpacing: 1.5),
                textAlign: TextAlign.center)
                .animate().fadeIn(delay: 500.ms),
          ]),
        ))),
      ]),
    );
  }
}
