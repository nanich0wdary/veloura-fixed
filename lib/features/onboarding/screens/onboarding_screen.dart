// lib/features/onboarding/screens/onboarding_screen.dart
// Veloura — First-launch onboarding: create local identity

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/identity/identity_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});
  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameCtrl = TextEditingController();
  String _selectedEmoji = '💜';
  bool   _isCreating = false;
  String? _error;

  static const _emojis = ['💜','💙','💚','💛','🧡','❤️','🤍','🖤','💗','💫','⭐','🌙'];

  Future<void> _createProfile() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    if (name.length < 2) {
      setState(() => _error = 'Name must be at least 2 characters');
      return;
    }

    setState(() { _isCreating = true; _error = null; });

    try {
      await IdentityService.instance.createIdentity(name);
      if (mounted) widget.onComplete();
    } catch (e) {
      if (mounted) setState(() {
        _isCreating = false;
        _error = 'Failed to create profile. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter, radius: 1.5,
            colors: [Color(0xFF1E1035), Color(0xFF0F172A)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Logo
                Container(
                  width: 90, height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const SweepGradient(colors: [
                      Color(0xFFC084FC), Color(0xFFF472B6),
                      Color(0xFF60A5FA), Color(0xFFC084FC),
                    ]),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Color(0xFF0F172A)),
                    child: const Center(child: Icon(
                        Icons.favorite_rounded, color: Colors.white, size: 38)),
                  ),
                )
                    .animate().fadeIn(duration: 800.ms)
                    .scale(begin: const Offset(0.5, 0.5),
                        duration: 1000.ms, curve: Curves.elasticOut),

                const SizedBox(height: 24),

                Text('VELOURA',
                    style: GoogleFonts.cinzel(
                        fontSize: 28, color: Colors.white,
                        letterSpacing: 6, fontWeight: FontWeight.w600))
                    .animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 8),
                Text('your private universe, together',
                    style: GoogleFonts.cormorantGaramond(
                        fontSize: 16, color: Colors.white38,
                        fontStyle: FontStyle.italic))
                    .animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 48),

                // Info card
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                            width: 0.5),
                      ),
                      child: Column(children: [
                        Text('NO ACCOUNT NEEDED',
                            style: GoogleFonts.cinzel(fontSize: 10,
                                color: const Color(0xFFC084FC),
                                letterSpacing: 2)),
                        const SizedBox(height: 14),
                        ...[
                          (Icons.lock_outline_rounded,
                            'Your identity is stored only on this device'),
                          (Icons.key_outlined,
                            'A unique cryptographic keypair is generated for you'),
                          (Icons.wifi_tethering_rounded,
                            'Direct P2P connection — no servers'),
                        ].map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(children: [
                            Icon(item.$1, size: 14,
                                color: const Color(0xFFC084FC)
                                    .withValues(alpha: 0.7)),
                            const SizedBox(width: 10),
                            Expanded(child: Text(item.$2,
                                style: GoogleFonts.cormorantGaramond(
                                    fontSize: 14, color: Colors.white54))),
                          ]),
                        )),
                      ]),
                    ),
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 28),

                // Name field
                Text('CHOOSE YOUR NAME',
                    style: GoogleFonts.cinzel(fontSize: 9,
                        color: Colors.white38, letterSpacing: 2))
                    .animate().fadeIn(delay: 600.ms),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                            width: 0.5),
                      ),
                      child: TextField(
                        controller: _nameCtrl,
                        autofocus: false,
                        textCapitalization: TextCapitalization.words,
                        style: GoogleFonts.cormorantGaramond(
                            fontSize: 20, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'your name...',
                          hintStyle: GoogleFonts.cormorantGaramond(
                              fontSize: 18, color: Colors.white24,
                              fontStyle: FontStyle.italic),
                          border: InputBorder.none, isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          prefixIcon: const Icon(Icons.person_outline_rounded,
                              color: Colors.white38, size: 20),
                        ),
                        onSubmitted: (_) => _createProfile(),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 700.ms),

                const SizedBox(height: 20),

                // Avatar emoji picker
                Text('CHOOSE YOUR AVATAR',
                    style: GoogleFonts.cinzel(fontSize: 9,
                        color: Colors.white38, letterSpacing: 2))
                    .animate().fadeIn(delay: 750.ms),
                const SizedBox(height: 10),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _emojis.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final selected = _emojis[i] == _selectedEmoji;
                      return GestureDetector(
                        onTap: () => setState(() =>
                            _selectedEmoji = _emojis[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? const Color(0xFFC084FC).withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.06),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFFC084FC)
                                  : Colors.white.withValues(alpha: 0.1),
                              width: selected ? 1.5 : 0.5,
                            ),
                          ),
                          child: Center(child: Text(_emojis[i],
                              style: const TextStyle(fontSize: 22))),
                        ),
                      );
                    },
                  ),
                ).animate().fadeIn(delay: 800.ms),

                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
                          width: 0.5),
                    ),
                    child: Row(children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!,
                          style: GoogleFonts.cormorantGaramond(
                              fontSize: 14, color: Colors.redAccent))),
                    ]),
                  ).animate().shakeX(),
                ],

                const SizedBox(height: 28),

                // Create button
                GestureDetector(
                  onTap: _isCreating ? null : _createProfile,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [
                        Color(0xFFC084FC), Color(0xFFF472B6)]),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [BoxShadow(
                        color: const Color(0xFFC084FC).withValues(alpha: 0.4),
                        blurRadius: 20)],
                    ),
                    child: Center(child: _isCreating
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text('CREATE MY IDENTITY',
                            style: GoogleFonts.cinzel(
                                fontSize: 13, color: Colors.white,
                                letterSpacing: 2.5))),
                  ),
                ).animate().fadeIn(delay: 900.ms),

                const SizedBox(height: 12),
                Text('No account, no email, no server',
                    style: GoogleFonts.cormorantGaramond(
                        fontSize: 12, color: Colors.white24,
                        fontStyle: FontStyle.italic))
                    .animate().fadeIn(delay: 1000.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
