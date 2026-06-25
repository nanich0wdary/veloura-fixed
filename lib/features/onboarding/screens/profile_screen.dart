// lib/features/onboarding/screens/profile_screen.dart
// Veloura — View + edit your local identity

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/identity/identity_service.dart';
import '../../../core/identity/local_user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  LocalUser? _user;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _user = IdentityService.instance.currentUser;
  }

  void _copyFingerprint() {
    if (_user == null) return;
    Clipboard.setData(ClipboardData(text: _user!.fingerprint));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2),
        () { if (mounted) setState(() => _copied = false); });
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: _appBar(context),
      body: Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.8),
              radius: 1.3,
              colors: [Color(0xFF1E1035), Color(0xFF0F172A)],
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(children: [

              // Avatar
              Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC084FC).withValues(alpha: 0.12),
                  border: Border.all(
                      color: const Color(0xFFC084FC).withValues(alpha: 0.4),
                      width: 2),
                  boxShadow: [BoxShadow(
                      color: const Color(0xFFC084FC).withValues(alpha: 0.3),
                      blurRadius: 24)],
                ),
                child: Center(child: Text(user.avatarEmoji,
                    style: const TextStyle(fontSize: 48))),
              ).animate().fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.7, 0.7), duration: 800.ms,
                  curve: Curves.elasticOut),

              const SizedBox(height: 20),

              Text(user.displayName,
                  style: GoogleFonts.cormorantGaramond(
                      fontSize: 28, color: Colors.white,
                      fontWeight: FontWeight.w500))
                  .animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 4),

              Text('YOUR LOCAL IDENTITY',
                  style: GoogleFonts.cinzel(
                      fontSize: 9, color: Colors.white30, letterSpacing: 2))
                  .animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 32),

              // Identity card
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 0.5),
                    ),
                    child: Column(children: [
                      _InfoRow(
                        icon: Icons.fingerprint_rounded,
                        label: 'Device Fingerprint',
                        value: user.fingerprint,
                        onTap: _copyFingerprint,
                        trailing: _copied
                            ? const Icon(Icons.check_rounded,
                                size: 14, color: Color(0xFF34D399))
                            : const Icon(Icons.copy_rounded,
                                size: 14, color: Colors.white30),
                      ),
                      const Divider(color: Colors.white10, height: 20),
                      _InfoRow(
                        icon: Icons.devices_rounded,
                        label: 'Device ID',
                        value: '${user.deviceId.substring(0, 8)}...',
                      ),
                      const Divider(color: Colors.white10, height: 20),
                      _InfoRow(
                        icon: Icons.security_rounded,
                        label: 'Encryption',
                        value: 'RSA-2048 + AES-256-GCM',
                      ),
                      const Divider(color: Colors.white10, height: 20),
                      _InfoRow(
                        icon: Icons.storage_rounded,
                        label: 'Storage',
                        value: 'Local only — no cloud',
                      ),
                    ]),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0, delay: 400.ms),

              const SizedBox(height: 20),

              // Security info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF34D399).withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: const Color(0xFF34D399).withValues(alpha: 0.2),
                      width: 0.5),
                ),
                child: Row(children: [
                  const Icon(Icons.lock_rounded,
                      color: Color(0xFF34D399), size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your private key is stored securely on this device '
                      'and never leaves it. Your identity is yours alone.',
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 13, color: Colors.white54, height: 1.5),
                    ),
                  ),
                ]),
              ).animate().fadeIn(delay: 500.ms),
            ]),
          ),
        ),
      ]),
    );
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
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(child: Text('MY IDENTITY',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.cinzel(
                        fontSize: 13, color: Colors.white, letterSpacing: 4))),
                const SizedBox(width: 48),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon, required this.label, required this.value,
    this.onTap, this.trailing,
  });
  final IconData icon;
  final String label, value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, size: 16, color: const Color(0xFFC084FC).withValues(alpha: 0.7)),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: GoogleFonts.cinzel(
              fontSize: 8, color: Colors.white30, letterSpacing: 1)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.cormorantGaramond(
              fontSize: 14, color: Colors.white70)),
        ]),
        const Spacer(),
        if (trailing != null) trailing!,
      ]),
    );
  }
}
