// lib/features/onboarding/screens/setup_screen.dart
// Veloura Phase 2 — Local Identity Setup
// User creates profile → RSA keypair generated → saved securely

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/identity/identity_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key, required this.onComplete});
  final VoidCallback onComplete;
  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _aura;
  final _nameCtrl = TextEditingController();
  String _selectedEmoji = '💜';
  bool _isCreating = false;
  String? _error;
  int _step = 0; // 0=welcome, 1=name, 2=generating

  static const _emojis = [
    '💜','💙','💚','❤️','🧡','💛','🤍','🖤',
    '💗','💌','✨','🌙','🌸','🦋','🌊','⭐',
  ];

  @override
  void initState() {
    super.initState();
    _aura = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _aura.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _createIdentity() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name');
      return;
    }
    setState(() { _isCreating = true; _step = 2; _error = null; });
    try {
      await IdentityService.instance.createIdentity(name);
      if (mounted) widget.onComplete();
    } catch (e) {
      if (mounted) setState(() {
        _isCreating = false;
        _step = 1;
        _error = 'Failed to create identity. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(children: [
        // Animated background
        AnimatedBuilder(
          animation: _aura,
          builder: (_, __) => Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.3 + _aura.value * 0.3, -0.6),
                radius: 1.4,
                colors: const [Color(0xFF1E1035), Color(0xFF0F172A)],
              ),
            ),
          ),
        ),

        SafeArea(
          child: _step == 2
              ? _GeneratingView(name: _nameCtrl.text.trim())
              : _step == 0
                  ? _WelcomeView(onNext: () => setState(() => _step = 1))
                  : _NameView(
                      controller: _nameCtrl,
                      selectedEmoji: _selectedEmoji,
                      emojis: _emojis,
                      error: _error,
                      isCreating: _isCreating,
                      onEmojiSelect: (e) => setState(() => _selectedEmoji = e),
                      onSubmit: _createIdentity,
                    ),
        ),
      ]),
    );
  }
}

// ── Welcome Step ──────────────────────────────────────────────

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💜', style: TextStyle(fontSize: 72))
              .animate().fadeIn(duration: 800.ms)
              .scale(begin: const Offset(0.5, 0.5), duration: 800.ms,
                  curve: Curves.elasticOut),

          const SizedBox(height: 32),

          Text('VELOURA',
              style: GoogleFonts.cinzel(
                  fontSize: 32, color: Colors.white,
                  letterSpacing: 8, fontWeight: FontWeight.w600))
              .animate().fadeIn(delay: 300.ms, duration: 600.ms),

          const SizedBox(height: 12),

          Text('your private universe, together',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 18, color: Colors.white38,
                  fontStyle: FontStyle.italic),
              textAlign: TextAlign.center)
              .animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 60),

          // Feature pills
          ...[
            ('🔒', 'No accounts. No servers.'),
            ('📱', 'Direct device-to-device'),
            ('🛡', 'AES-256 end-to-end encrypted'),
            ('💜', 'Just you and your person'),
          ].asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _FeaturePill(icon: e.value.$1, text: e.value.$2)
                .animate().fadeIn(delay: Duration(milliseconds: 600 + e.key * 100)),
          )),

          const SizedBox(height: 48),

          GestureDetector(
            onTap: onNext,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFC084FC), Color(0xFFF472B6)]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(
                    color: const Color(0xFFC084FC).withValues(alpha: 0.4),
                    blurRadius: 20)],
              ),
              child: Text('Get Started',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                      fontSize: 14, color: Colors.white, letterSpacing: 2)),
            ),
          ).animate().fadeIn(delay: 1000.ms, duration: 600.ms),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.text});
  final String icon, text;
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.1), width: 0.5),
          ),
          child: Row(children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            Text(text, style: GoogleFonts.cormorantGaramond(
                fontSize: 15, color: Colors.white70)),
          ]),
        ),
      ),
    );
  }
}

// ── Name + Emoji Step ─────────────────────────────────────────

class _NameView extends StatelessWidget {
  const _NameView({
    required this.controller, required this.selectedEmoji,
    required this.emojis, required this.error,
    required this.isCreating, required this.onEmojiSelect,
    required this.onSubmit,
  });
  final TextEditingController controller;
  final String selectedEmoji;
  final List<String> emojis;
  final String? error;
  final bool isCreating;
  final ValueChanged<String> onEmojiSelect;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(28, 40, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back header
          Text('CREATE YOUR IDENTITY',
              style: GoogleFonts.cinzel(
                  fontSize: 11, color: const Color(0xFFC084FC),
                  letterSpacing: 3))
              .animate().fadeIn(duration: 500.ms),

          const SizedBox(height: 8),

          Text('Your identity lives only on this device.\nNo account needed.',
              style: GoogleFonts.cormorantGaramond(
                  fontSize: 15, color: Colors.white38, height: 1.5))
              .animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 40),

          // Selected emoji big
          Center(
            child: GestureDetector(
              child: Container(
                width: 90, height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC084FC).withValues(alpha: 0.12),
                  border: Border.all(
                      color: const Color(0xFFC084FC).withValues(alpha: 0.4),
                      width: 1.5),
                ),
                child: Center(child: Text(selectedEmoji,
                    style: const TextStyle(fontSize: 44))),
              ),
            ),
          ).animate().fadeIn(delay: 200.ms)
              .scale(begin: const Offset(0.7, 0.7), duration: 500.ms,
              curve: Curves.elasticOut),

          const SizedBox(height: 20),

          // Emoji grid
          Text('CHOOSE YOUR AVATAR',
              style: GoogleFonts.cinzel(
                  fontSize: 8, color: Colors.white30, letterSpacing: 2)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: emojis.map((e) => GestureDetector(
              onTap: () => onEmojiSelect(e),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44, height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: e == selectedEmoji
                      ? const Color(0xFFC084FC).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.05),
                  border: Border.all(
                    color: e == selectedEmoji
                        ? const Color(0xFFC084FC).withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.08),
                    width: e == selectedEmoji ? 1.5 : 0.5,
                  ),
                ),
                child: Center(child: Text(e,
                    style: const TextStyle(fontSize: 20))),
              ),
            )).toList(),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 28),

          // Name field
          Text('YOUR NAME',
              style: GoogleFonts.cinzel(
                  fontSize: 8, color: Colors.white30, letterSpacing: 2)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFFC084FC).withValues(alpha: 0.3),
                      width: 0.5),
                ),
                child: TextField(
                  controller: controller,
                  autofocus: true,
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
                  ),
                  onSubmitted: (_) => onSubmit(),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),

          if (error != null) ...[
            const SizedBox(height: 10),
            Text(error!,
                style: const TextStyle(
                    fontSize: 13, color: Colors.redAccent))
                .animate().fadeIn().shakeX(),
          ],

          const SizedBox(height: 32),

          GestureDetector(
            onTap: isCreating ? null : onSubmit,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFFC084FC), Color(0xFFF472B6)]),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(
                    color: const Color(0xFFC084FC).withValues(alpha: 0.35),
                    blurRadius: 16)],
              ),
              child: Center(
                child: isCreating
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('CREATE MY IDENTITY',
                        style: GoogleFonts.cinzel(
                            fontSize: 13, color: Colors.white,
                            letterSpacing: 2)),
              ),
            ),
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 16),
          Center(
            child: Text('Your identity is stored only on this device',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 12, color: Colors.white24,
                    fontStyle: FontStyle.italic)),
          ),
        ],
      ),
    );
  }
}

// ── Generating Step ───────────────────────────────────────────

class _GeneratingView extends StatefulWidget {
  const _GeneratingView({required this.name});
  final String name;
  @override
  State<_GeneratingView> createState() => _GeneratingViewState();
}

class _GeneratingViewState extends State<_GeneratingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin;
  int _stepIndex = 0;

  static const _steps = [
    'Generating RSA-2048 keypair...',
    'Creating device identity...',
    'Securing private key...',
    'Setting up encryption...',
    'Almost ready...',
  ];

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(vsync: this,
        duration: const Duration(seconds: 2))..repeat();
    _advanceSteps();
  }

  void _advanceSteps() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) setState(() => _stepIndex = i);
    }
  }

  @override
  void dispose() { _spin.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RotationTransition(
              turns: _spin,
              child: Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [
                    Color(0xFFC084FC), Color(0xFFF472B6),
                    Color(0xFF60A5FA), Color(0xFFC084FC),
                  ]),
                ),
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF0F172A)),
                  child: const Center(
                    child: Icon(Icons.lock_outline_rounded,
                        color: Colors.white, size: 32)),
                ),
              ),
            ),
            const SizedBox(height: 36),
            Text('Creating your identity, ${widget.name}',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 22, color: Colors.white,
                    fontWeight: FontWeight.w500),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(_steps[_stepIndex],
                style: GoogleFonts.cinzel(
                    fontSize: 10, color: const Color(0xFFC084FC),
                    letterSpacing: 2),
                textAlign: TextAlign.center)
                .animate(key: ValueKey(_stepIndex)).fadeIn(duration: 400.ms),
            const SizedBox(height: 32),
            Text('This only happens once.\nYour private key never leaves this device.',
                style: GoogleFonts.cormorantGaramond(
                    fontSize: 13, color: Colors.white30, height: 1.6),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
