// lib/features/chat/screens/chat_screen.dart
// Veloura Phase 4 — Real P2P Chat
// - Live connection status in header
// - Real typing indicators via WebRTC
// - Delivery receipts: sending → sent → delivered → read
// - Partner name + avatar from identity
// - Offline banner when P2P disconnected

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/reaction_picker.dart';
import '../widgets/typing_indicator.dart';
import '../../../core/p2p/p2p_provider.dart';
import '../../../features/pairing/providers/pairing_provider.dart';
import '../../../features/pairing/screens/webrtc_signal_screen.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _scrollCtrl = ScrollController();
  late final AnimationController _bgCtrl;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollCtrl.dispose();
    _bgCtrl.dispose();
    _typingTimer?.cancel();
    // Stop typing when leaving chat
    ref.read(chatProvider.notifier).sendTyping(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Stop typing indicator when app goes to background
      ref.read(chatProvider.notifier).sendTyping(false);
    }
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final max = _scrollCtrl.position.maxScrollExtent;
      if (animated) {
        _scrollCtrl.animateTo(max,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut);
      } else {
        _scrollCtrl.jumpTo(max);
      }
    });
  }

  void _onTyping(String text) {
    // Debounced typing indicator
    _typingTimer?.cancel();
    if (text.isNotEmpty) {
      ref.read(chatProvider.notifier).sendTyping(true);
      _typingTimer = Timer(const Duration(seconds: 3), () {
        ref.read(chatProvider.notifier).sendTyping(false);
      });
    } else {
      ref.read(chatProvider.notifier).sendTyping(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat    = ref.watch(chatProvider);
    final p2p     = ref.watch(p2pProvider);
    final pairing = ref.watch(pairingProvider);

    // Scroll on new message
    ref.listen(chatProvider, (prev, next) {
      if ((prev?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
      }
    });

    final partnerName = pairing.pairData?.partnerName
        ?? p2p.partner?.displayName
        ?? 'Partner';
    final partnerEmoji = pairing.pairData?.partnerEmoji
        ?? p2p.partner?.avatarEmoji
        ?? '💜';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(context, chat, p2p, partnerName, partnerEmoji),
      body: Stack(children: [
        _AnimBg(controller: _bgCtrl),

        Column(children: [
          // P2P offline banner
          if (!chat.isP2PActive)
            _OfflineBanner(
              pairing:       pairing,
              onConnectTap:  () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) =>
                      const WebRTCSignalScreen(isInitiator: true))),
            ).animate().fadeIn(duration: 300.ms),

          // Message list
          Expanded(
            child: _MessageList(
              messages:      chat.messages,
              isTyping:      chat.isPartnerTyping,
              scrollCtrl:    _scrollCtrl,
              onReact:       (msgId) async {
                final emoji = await ReactionPicker.show(context);
                if (emoji != null) {
                  ref.read(chatProvider.notifier).addReaction(msgId, emoji);
                }
              },
            ),
          ),

          // Typing indicator
          if (chat.isPartnerTyping)
            TypingIndicator(name: partnerName)
                .animate().fadeIn(duration: 300.ms)
                .slideY(begin: 0.5, end: 0),

          // Input bar
          ChatInputBar(
            isSending:  chat.isSending,
            isP2PActive: chat.isP2PActive,
            onSend:     (text) {
              ref.read(chatProvider.notifier).sendMessage(text);
              ref.read(chatProvider.notifier).sendTyping(false);
              _typingTimer?.cancel();
            },
            onTyping:   _onTyping,
          ),
        ]),
      ]),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ChatState chat,
    P2PState p2p,
    String partnerName,
    String partnerEmoji,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withValues(alpha: 0.6),
              border: Border(bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.08), width: 0.5)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                child: Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        size: 18, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  // Partner avatar
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFC084FC).withValues(alpha: 0.15),
                      border: Border.all(
                          color: const Color(0xFFC084FC).withValues(alpha: 0.4),
                          width: 1.5),
                      boxShadow: [BoxShadow(
                          color: const Color(0xFFC084FC).withValues(alpha: 0.3),
                          blurRadius: 10)],
                    ),
                    child: Center(child: Text(partnerEmoji,
                        style: const TextStyle(fontSize: 20))),
                  ),

                  const SizedBox(width: 12),

                  // Name + status
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(partnerName,
                          style: GoogleFonts.cormorantGaramond(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Row(children: [
                        // Connection dot
                        Container(
                          width: 7, height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: chat.isP2PActive
                                ? const Color(0xFF34D399)
                                : p2p.isConnecting
                                    ? const Color(0xFFFBBF24)
                                    : Colors.white24,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          chat.isTyping
                              ? 'typing...'
                              : chat.isP2PActive
                                  ? 'P2P connected · encrypted'
                                  : p2p.isConnecting
                                      ? 'connecting...'
                                      : 'offline',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'Cormorant Garamond',
                            color: chat.isP2PActive
                                ? const Color(0xFF34D399).withValues(alpha: 0.8)
                                : Colors.white38,
                          ),
                        ),
                      ]),
                    ],
                  )),

                  // Connect button if offline
                  if (!chat.isP2PActive)
                    IconButton(
                      icon: const Icon(Icons.wifi_tethering_rounded,
                          size: 22, color: Color(0xFFC084FC)),
                      onPressed: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) =>
                              const WebRTCSignalScreen(isInitiator: true))),
                      tooltip: 'Connect P2P',
                    )
                  else
                    Icon(Icons.lock_rounded,
                        size: 18,
                        color: const Color(0xFF34D399).withValues(alpha: 0.6)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Offline Banner ────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.pairing, required this.onConnectTap});
  final PairingState pairing;
  final VoidCallback onConnectTap;

  @override
  Widget build(BuildContext context) {
    final isPaired = pairing.isPaired;
    return GestureDetector(
      onTap: isPaired ? onConnectTap : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isPaired
              ? const Color(0xFFFBBF24).withValues(alpha: 0.08)
              : Colors.red.withValues(alpha: 0.08),
          border: Border(bottom: BorderSide(
              color: isPaired
                  ? const Color(0xFFFBBF24).withValues(alpha: 0.2)
                  : Colors.red.withValues(alpha: 0.2),
              width: 0.5)),
        ),
        child: Row(children: [
          Icon(
            isPaired ? Icons.wifi_off_rounded : Icons.link_off_rounded,
            size: 14,
            color: isPaired
                ? const Color(0xFFFBBF24)
                : Colors.red.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(
            isPaired
                ? 'Not connected — tap to establish P2P link'
                : 'No partner paired — go to Pairing screen first',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 13,
                color: isPaired
                    ? const Color(0xFFFBBF24)
                    : Colors.red.withValues(alpha: 0.8)),
          )),
          if (isPaired)
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: Color(0xFFFBBF24)),
        ]),
      ),
    );
  }
}

// ── Message List ──────────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.messages,
    required this.isTyping,
    required this.scrollCtrl,
    required this.onReact,
  });
  final List<Message>    messages;
  final bool             isTyping;
  final ScrollController scrollCtrl;
  final ValueChanged<String> onReact;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return _EmptyChat();
    }
    return ListView.builder(
      controller:  scrollCtrl,
      physics:     const BouncingScrollPhysics(),
      padding:     const EdgeInsets.fromLTRB(14, 90, 14, 8),
      itemCount:   messages.length,
      itemBuilder: (_, i) {
        final msg      = messages[i];
        final showTime = i == 0 ||
            messages[i].timestamp
                .difference(messages[i - 1].timestamp)
                .inMinutes > 15;
        return ChatBubble(
          message:      msg,
          showTime:     showTime,
          onLongPress:  () => onReact(msg.id),
        );
      },
    );
  }
}

// ── Empty Chat ────────────────────────────────────────────────

class _EmptyChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('💌', style: TextStyle(fontSize: 56))
            .animate().fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.5, 0.5)),
        const SizedBox(height: 20),
        Text('No messages yet',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 22, color: Colors.white38))
            .animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 8),
        Text('Connect P2P above, then say hello 💜',
            style: GoogleFonts.cormorantGaramond(
                fontSize: 14, color: Colors.white24,
                fontStyle: FontStyle.italic),
            textAlign: TextAlign.center)
            .animate().fadeIn(delay: 400.ms),
      ]),
    );
  }
}

// ── Animated Background ───────────────────────────────────────

class _AnimBg extends StatelessWidget {
  const _AnimBg({required this.controller});
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(
                -0.5 + controller.value * 0.4,
                -0.8 + controller.value * 0.3),
            radius: 1.2,
            colors: const [Color(0xFF1E1035), Color(0xFF0F172A)],
          ),
        ),
      ),
    );
  }
}

// helper
extension on ChatState {
  bool get isTyping => isPartnerTyping;
}
