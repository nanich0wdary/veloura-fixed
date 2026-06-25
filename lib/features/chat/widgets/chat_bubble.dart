// lib/features/chat/widgets/chat_bubble.dart
// Veloura Phase 4 — Chat Bubble with delivery receipts + partner avatar

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/message.dart';
import '../../../features/pairing/providers/pairing_provider.dart';

class ChatBubble extends ConsumerWidget {
  const ChatBubble({
    super.key,
    required this.message,
    required this.onLongPress,
    this.showTime = false,
  });

  final Message  message;
  final VoidCallback onLongPress;
  final bool     showTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pairing     = ref.watch(pairingProvider);
    final partnerEmoji = pairing.pairData?.partnerEmoji ?? '💜';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: message.isMine
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Time separator
          if (showTime)
            Padding(
              padding: const EdgeInsets.only(bottom: 6, top: 10),
              child: Center(
                child: Text(
                  _formatTime(message.timestamp),
                  style: const TextStyle(
                      fontSize: 10, color: Colors.white30, letterSpacing: 0.5),
                ),
              ),
            ),

          GestureDetector(
            onLongPress: onLongPress,
            child: Row(
              mainAxisAlignment: message.isMine
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Partner emoji avatar
                if (!message.isMine) ...[
                  _PartnerAvatar(emoji: partnerEmoji),
                  const SizedBox(width: 8),
                ],

                // Bubble
                _Bubble(message: message),

                // My delivery status tick
                if (message.isMine) ...[
                  const SizedBox(width: 4),
                  _StatusIcon(status: message.status),
                ],
              ],
            ),
          ),

          // Reaction
          if (message.reaction != null)
            Padding(
              padding: EdgeInsets.only(
                top:   4,
                left:  message.isMine ? 0 : 48,
                right: message.isMine ? 8 : 0,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1), width: 0.5),
                ),
                child: Text(message.reaction!,
                    style: const TextStyle(fontSize: 14)),
              ),
            ).animate().scale(
                begin: const Offset(0, 0),
                duration: 300.ms,
                curve: Curves.elasticOut),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(
          begin: message.isMine ? 0.2 : -0.2,
          end:   0,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

// ── Partner avatar ────────────────────────────────────────────

class _PartnerAvatar extends StatelessWidget {
  const _PartnerAvatar({required this.emoji});
  final String emoji;

  @override
  Widget build(BuildContext context) => Container(
    width: 30, height: 30,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: const Color(0xFFC084FC).withValues(alpha: 0.15),
      border: Border.all(
          color: const Color(0xFFC084FC).withValues(alpha: 0.35), width: 1),
      boxShadow: [BoxShadow(
          color: const Color(0xFFC084FC).withValues(alpha: 0.2),
          blurRadius: 6)],
    ),
    child: Center(child: Text(emoji,
        style: const TextStyle(fontSize: 14))),
  );
}

// ── Glass bubble ──────────────────────────────────────────────

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final Message message;

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final maxW   = MediaQuery.of(context).size.width * 0.68;

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxW),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft:     const Radius.circular(18),
          topRight:    const Radius.circular(18),
          bottomLeft:  Radius.circular(isMine ? 18 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 18),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: isMine ? LinearGradient(
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
                colors: [
                  const Color(0xFFC084FC).withValues(alpha: 0.25),
                  const Color(0xFFF472B6).withValues(alpha: 0.18),
                ],
              ) : null,
              color: isMine ? null
                  : Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.only(
                topLeft:     const Radius.circular(18),
                topRight:    const Radius.circular(18),
                bottomLeft:  Radius.circular(isMine ? 18 : 4),
                bottomRight: Radius.circular(isMine ? 4 : 18),
              ),
              border: Border.all(
                color: isMine
                    ? const Color(0xFFC084FC).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
              boxShadow: isMine ? [BoxShadow(
                  color: const Color(0xFFC084FC).withValues(alpha: 0.15),
                  blurRadius: 12)] : null,
            ),
            child: Text(
              message.text,
              style: TextStyle(
                fontFamily: 'Cormorant Garamond',
                fontSize:   16,
                height:     1.5,
                color: isMine ? Colors.white
                    : Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Delivery status icon ──────────────────────────────────────

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});
  final MessageStatus status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return const SizedBox(width: 14, height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 1.5, color: Colors.white30));
      case MessageStatus.sent:
        return const Icon(Icons.check_rounded,
            size: 14, color: Colors.white38);
      case MessageStatus.delivered:
        return const Icon(Icons.done_all_rounded,
            size: 14, color: Colors.white38);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded,
            size: 14, color: Color(0xFFC084FC));
    }
  }
}
