// lib/core/theme/app_colors.dart
// Veloura — Centralized Color Constants
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand ─────────────────────────────────────────────────
  static const primary   = Color(0xFFC084FC); // purple
  static const secondary = Color(0xFFF472B6); // pink
  static const accent    = Color(0xFF60A5FA); // blue

  // ── Background ────────────────────────────────────────────
  static const bgDark    = Color(0xFF0F172A); // main dark bg
  static const bgDeep    = Color(0xFF1E1035); // deeper purple bg

  // ── Status ────────────────────────────────────────────────
  static const success   = Color(0xFF34D399); // green
  static const warning   = Color(0xFFFBBF24); // yellow
  static const error     = Color(0xFFEF4444); // red

  // ── Gradient presets ──────────────────────────────────────
  static const gradientPrimary  = [primary, secondary];
  static const gradientBlue     = [accent, primary];
  static const gradientWarm     = [secondary, warning];
  static const gradientGreen    = [success, accent];

  // ── Glass / overlay helpers ───────────────────────────────
  static Color glass(double opacity)       => Colors.white.withValues(alpha: opacity);
  static Color primaryAlpha(double alpha)  => primary.withValues(alpha: alpha);
  static Color secondaryAlpha(double alpha)=> secondary.withValues(alpha: alpha);
}
