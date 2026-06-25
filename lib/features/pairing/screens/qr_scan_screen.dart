// lib/features/pairing/screens/qr_scan_screen.dart
// Veloura Phase 3 — QR Scanner Screen

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/pairing_provider.dart';

class QrScanScreen extends ConsumerStatefulWidget {
  const QrScanScreen({super.key});
  @override
  ConsumerState<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends ConsumerState<QrScanScreen> {
  final _ctrl     = MobileScannerController();
  bool  _scanned  = false;
  bool  _torch    = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_scanned) return;
    final barcode = capture.barcodes.firstOrNull;
    final raw     = barcode?.rawValue;
    if (raw == null || raw.isEmpty) return;

    setState(() => _scanned = true);
    await _ctrl.stop();

    if (!mounted) return;
    final notifier = ref.read(pairingProvider.notifier);
    await notifier.processScannedQr(raw);

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [

        // Camera
        MobileScanner(
          controller: _ctrl,
          onDetect: _onDetect,
        ),

        // Overlay
        _ScanOverlay(),

        // Top bar
        Positioned(
          top: 0, left: 0, right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    8, MediaQuery.of(context).padding.top + 8, 8, 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Expanded(child: Text('SCAN PARTNER\'S QR',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cinzel(
                          fontSize: 13, color: Colors.white, letterSpacing: 3))),
                  IconButton(
                    icon: Icon(
                      _torch ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                      color: _torch ? const Color(0xFFFBBF24) : Colors.white54,
                      size: 22,
                    ),
                    onPressed: () {
                      setState(() => _torch = !_torch);
                      _ctrl.toggleTorch();
                    },
                  ),
                ]),
              ),
            ),
          ),
        ),

        // Bottom hint
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    24, 20, 24,
                    MediaQuery.of(context).padding.bottom + 24),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('Point at your partner\'s QR code',
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 18, color: Colors.white70,
                          fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center)
                      .animate().fadeIn(duration: 600.ms),
                  const SizedBox(height: 8),
                  Text('Make sure the entire QR code is inside the frame',
                      style: GoogleFonts.cormorantGaramond(
                          fontSize: 13, color: Colors.white30,
                          fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center)
                      .animate().fadeIn(delay: 300.ms),
                ]),
              ),
            ),
          ),
        ),

        // Scanned indicator
        if (_scanned)
          Center(child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF34D399).withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: Colors.white, size: 40),
          ).animate().scale(
              begin: const Offset(0.5, 0.5),
              duration: 400.ms,
              curve: Curves.elasticOut)),
      ]),
    );
  }
}

// ── Scan frame overlay ────────────────────────────────────────

class _ScanOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final boxSize = size.width * 0.7;
    final top  = (size.height - boxSize) / 2.5;

    return Stack(children: [
      // Dark overlay with cutout
      ColorFiltered(
        colorFilter: const ColorFilter.mode(
            Colors.black54, BlendMode.srcOut),
        child: Stack(children: [
          Container(decoration: const BoxDecoration(
              color: Colors.transparent,
              backgroundBlendMode: BlendMode.dstOut)),
          Positioned(
            top: top, left: (size.width - boxSize) / 2,
            width: boxSize, height: boxSize,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20)),
            ),
          ),
        ]),
      ),

      // Corner brackets
      Positioned(
        top: top, left: (size.width - boxSize) / 2,
        width: boxSize, height: boxSize,
        child: _CornerBrackets(size: boxSize),
      ),
    ]);
  }
}

class _CornerBrackets extends StatefulWidget {
  const _CornerBrackets({required this.size});
  final double size;
  @override
  State<_CornerBrackets> createState() => _CornerBracketsState();
}

class _CornerBracketsState extends State<_CornerBrackets>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this,
        duration: const Duration(seconds: 2))..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final color = Color.lerp(
            const Color(0xFFC084FC),
            const Color(0xFF34D399),
            _c.value)!;
        return CustomPaint(
            painter: _BracketPainter(color: color, size: widget.size));
      },
    );
  }
}

class _BracketPainter extends CustomPainter {
  const _BracketPainter({required this.color, required this.size});
  final Color  color;
  final double size;

  @override
  void paint(Canvas canvas, Size sz) {
    final paint = Paint()
      ..color       = color
      ..strokeWidth = 3
      ..style       = PaintingStyle.stroke
      ..strokeCap   = StrokeCap.round;
    const r   = 20.0; // corner radius
    const len = 30.0; // bracket arm length

    // Top-left
    canvas.drawPath(Path()
      ..moveTo(0, r + len)..lineTo(0, r)
      ..arcToPoint(Offset(r, 0),
          radius: const Radius.circular(r))
      ..lineTo(r + len, 0), paint);

    // Top-right
    canvas.drawPath(Path()
      ..moveTo(sz.width - r - len, 0)..lineTo(sz.width - r, 0)
      ..arcToPoint(Offset(sz.width, r),
          radius: const Radius.circular(r))
      ..lineTo(sz.width, r + len), paint);

    // Bottom-left
    canvas.drawPath(Path()
      ..moveTo(0, sz.height - r - len)..lineTo(0, sz.height - r)
      ..arcToPoint(Offset(r, sz.height),
          radius: const Radius.circular(r), clockwise: false)
      ..lineTo(r + len, sz.height), paint);

    // Bottom-right
    canvas.drawPath(Path()
      ..moveTo(sz.width - r - len, sz.height)
      ..lineTo(sz.width - r, sz.height)
      ..arcToPoint(Offset(sz.width, sz.height - r),
          radius: const Radius.circular(r), clockwise: false)
      ..lineTo(sz.width, sz.height - r - len), paint);
  }

  @override
  bool shouldRepaint(_BracketPainter old) => old.color != color;
}
