// lib/features/settings/screens/settings_screen.dart
// Veloura Phase 6 — Settings: biometric, theme, security, about

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/screenshot_protection_service.dart';
import '../../../core/identity/identity_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/onboarding/screens/profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricEnabled    = false;
  bool _screenshotProtected = true;
  bool _biometricAvailable  = false;
  bool _loading             = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final biometricOn  = await BiometricService.instance.isEnabled();
    final bioAvailable = await BiometricService.instance.isAvailable();
    if (mounted) setState(() {
      _biometricEnabled    = biometricOn;
      _biometricAvailable  = bioAvailable;
      _loading             = false;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Verify biometric before enabling
      final ok = await BiometricService.instance.authenticate();
      if (!ok) return;
    }
    await BiometricService.instance.setEnabled(value);
    if (mounted) setState(() => _biometricEnabled = value);
  }

  Future<void> _toggleScreenshot(bool value) async {
    if (value) {
      await ScreenshotProtectionService.instance.enable();
    } else {
      await ScreenshotProtectionService.instance.disable();
    }
    if (mounted) setState(() => _screenshotProtected = value);
  }

  Future<void> _clearData(BuildContext context, String what) async {
    try {
      if (what == 'messages') {
        final box = Hive.isBoxOpen('veloura_messages')
            ? Hive.box('veloura_messages')
            : await Hive.openBox('veloura_messages');
        await box.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: const Color(0xFF1E1035),
            content: Text('All messages cleared',
                style: GoogleFonts.cinzel(fontSize: 11, color: Colors.white60)),
          ));
        }
      } else if (what == 'identity') {
        // Clear all boxes
        for (final name in [
          'veloura_messages', 'veloura_memories',
          'veloura_mood', 'veloura_pairing', 'veloura_partner'
        ]) {
          try {
            final box = Hive.isBoxOpen(name)
                ? Hive.box(name) : await Hive.openBox(name);
            await box.clear();
          } catch (_) {}
        }
        // Clear all prefs
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: const Color(0xFF1E1035),
            content: Text('Identity reset — restart app',
                style: GoogleFonts.cinzel(fontSize: 11, color: Colors.white60)),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF1E1035),
          content: Text('Error: $e',
              style: GoogleFonts.cinzel(fontSize: 11, color: Colors.redAccent)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = IdentityService.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: _appBar(context),
      body: Stack(children: [
        Container(decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.3, -0.8), radius: 1.3,
            colors: [Color(0xFF1E1035), Color(0xFF0F172A)],
          ),
        )),

        if (_loading)
          const Center(child: CircularProgressIndicator(
              color: Color(0xFFC084FC), strokeWidth: 2))
        else
          SafeArea(child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Profile section
              _SectionHeader(label: 'IDENTITY').animate().fadeIn(),
              _ProfileTile(
                user: user,
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen())),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 20),

              // Security section
              _SectionHeader(label: 'SECURITY').animate().fadeIn(delay: 150.ms),

              _SettingsTile(
                icon:     Icons.fingerprint_rounded,
                title:    'Biometric Lock',
                subtitle: _biometricAvailable
                    ? 'Require fingerprint/face to open app'
                    : 'Not available on this device',
                trailing: Switch.adaptive(
                  value:          _biometricEnabled,
                  onChanged:      _biometricAvailable ? _toggleBiometric : null,
                  activeColor:    const Color(0xFFC084FC),
                  inactiveThumbColor: Colors.white30,
                ),
              ).animate().fadeIn(delay: 200.ms),

              _SettingsTile(
                icon:     Icons.no_photography_rounded,
                title:    'Screenshot Protection',
                subtitle: 'Block screenshots and screen recording',
                trailing: Switch.adaptive(
                  value:       _screenshotProtected,
                  onChanged:   _toggleScreenshot,
                  activeColor: const Color(0xFFC084FC),
                  inactiveThumbColor: Colors.white30,
                ),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 20),

              // Privacy section
              _SectionHeader(label: 'PRIVACY').animate().fadeIn(delay: 300.ms),

              _SettingsTile(
                icon:     Icons.lock_outline_rounded,
                title:    'End-to-End Encryption',
                subtitle: 'AES-256-GCM • All messages encrypted',
                trailing: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF34D399), size: 20),
              ).animate().fadeIn(delay: 350.ms),

              _SettingsTile(
                icon:     Icons.cloud_off_rounded,
                title:    'No Cloud Storage',
                subtitle: 'Data stays on your devices only',
                trailing: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF34D399), size: 20),
              ).animate().fadeIn(delay: 400.ms),

              _SettingsTile(
                icon:     Icons.wifi_tethering_rounded,
                title:    'P2P Direct Connect',
                subtitle: 'WebRTC — messages never touch a server',
                trailing: const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF34D399), size: 20),
              ).animate().fadeIn(delay: 450.ms),

              const SizedBox(height: 20),

              // About section
              _SectionHeader(label: 'ABOUT').animate().fadeIn(delay: 500.ms),

              _SettingsTile(
                icon:    Icons.info_outline_rounded,
                title:   'Veloura',
                subtitle: 'Version 3.0.0 — Phase 6',
              ).animate().fadeIn(delay: 550.ms),

              _SettingsTile(
                icon:    Icons.security_rounded,
                title:   'Open Source Crypto',
                subtitle: 'PointyCastle • encrypt • cryptography',
              ).animate().fadeIn(delay: 600.ms),

              const SizedBox(height: 20),

              // Danger zone
              _SectionHeader(label: 'DANGER ZONE',
                  color: Colors.redAccent).animate().fadeIn(delay: 650.ms),

              _DangerTile(
                icon:    Icons.delete_outline_rounded,
                title:   'Clear All Messages',
                onTap:   () => _confirmClear(context, 'messages'),
              ).animate().fadeIn(delay: 700.ms),

              _DangerTile(
                icon:    Icons.link_off_rounded,
                title:   'Reset Identity & Pairing',
                onTap:   () => _confirmClear(context, 'identity'),
              ).animate().fadeIn(delay: 750.ms),
            ]),
          )),
      ]),
    );
  }

  void _confirmClear(BuildContext context, String what) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1035),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Are you sure?',
            style: GoogleFonts.cinzel(
                color: Colors.white, fontSize: 16)),
        content: Text(
          what == 'messages'
              ? 'This will delete all your chat history permanently.'
              : 'This will remove your identity and all pairings. Cannot be undone.',
          style: GoogleFonts.cormorantGaramond(
              color: Colors.white60, fontSize: 16, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.cinzel(
                    color: Colors.white38, fontSize: 12)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearData(context, what);
            },
            child: Text('Delete',
                style: GoogleFonts.cinzel(
                    color: Colors.redAccent, fontSize: 12)),
          ),
        ],
      ),
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
          child: SafeArea(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 18, color: Colors.white70),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(child: Text('SETTINGS',
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

// ── Section Header ────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.color});
  final String label;
  final Color? color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(label, style: GoogleFonts.cinzel(
        fontSize: 9,
        color: color ?? const Color(0xFFC084FC).withValues(alpha: 0.7),
        letterSpacing: 2.5)),
  );
}

// ── Profile Tile ──────────────────────────────────────────────

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.user, required this.onTap});
  final dynamic user;
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFFC084FC).withValues(alpha: 0.2),
                  width: 0.5),
            ),
            child: Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFC084FC).withValues(alpha: 0.12),
                  border: Border.all(
                      color: const Color(0xFFC084FC).withValues(alpha: 0.35),
                      width: 1.5),
                ),
                child: Center(child: Text(
                  user?.avatarEmoji ?? '💜',
                  style: const TextStyle(fontSize: 24))),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user?.displayName ?? 'You',
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 18, color: Colors.white,
                          fontWeight: FontWeight.w500)),
                  Text('Device: ${user?.fingerprint ?? '—'}',
                      style: GoogleFonts.cinzel(
                          fontSize: 9, color: Colors.white30,
                          letterSpacing: 1)),
                ],
              )),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Colors.white24),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Settings Tile ─────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon, required this.title,
    required this.subtitle, this.trailing,
  });
  final IconData icon;
  final String title, subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
          color: Colors.white.withValues(alpha: 0.07), width: 0.5),
    ),
    child: Row(children: [
      Icon(icon, size: 18,
          color: const Color(0xFFC084FC).withValues(alpha: 0.7)),
      const SizedBox(width: 14),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.cormorantGaramond(
              fontSize: 16, color: Colors.white)),
          Text(subtitle, style: GoogleFonts.cormorantGaramond(
              fontSize: 12, color: Colors.white38)),
        ],
      )),
      if (trailing != null) trailing!,
    ]),
  );
}

// ── Danger Tile ───────────────────────────────────────────────

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.icon, required this.title, required this.onTap,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.red.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.redAccent.withValues(alpha: 0.7)),
        const SizedBox(width: 14),
        Text(title, style: GoogleFonts.cormorantGaramond(
            fontSize: 16, color: Colors.redAccent.withValues(alpha: 0.8))),
        const Spacer(),
        Icon(Icons.arrow_forward_ios_rounded,
            size: 12, color: Colors.red.withValues(alpha: 0.3)),
      ]),
    ),
  );
}
