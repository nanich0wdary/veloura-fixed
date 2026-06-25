// lib/features/chat/widgets/chat_input_bar.dart
// Veloura Phase 4 — Chat Input with typing callback + P2P status

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.onSend,
    required this.onTyping,
    this.isSending   = false,
    this.isP2PActive = false,
  });

  final ValueChanged<String> onSend;
  final ValueChanged<String> onTyping;
  final bool isSending;
  final bool isP2PActive;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final _ctrl  = TextEditingController();
  final _focus = FocusNode();
  bool  _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final has = _ctrl.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
      widget.onTyping(_ctrl.text);
    });
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _ctrl.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 10, 16,
              MediaQuery.of(context).padding.bottom + 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A).withValues(alpha: 0.7),
            border: Border(top: BorderSide(
                color: Colors.white.withValues(alpha: 0.08), width: 0.5)),
          ),
          child: Row(children: [
            // Emoji / attachment button
            _IconBtn(
              icon:  Icons.auto_awesome_rounded,
              color: const Color(0xFFC084FC),
              onTap: () {},
            ),
            const SizedBox(width: 10),

            // Text field
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _focus.hasFocus
                            ? const Color(0xFFC084FC).withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.1),
                        width: 0.5,
                      ),
                    ),
                    child: TextField(
                      controller: _ctrl,
                      focusNode:  _focus,
                      maxLines:   4,
                      minLines:   1,
                      style: const TextStyle(
                        fontFamily: 'Cormorant Garamond',
                        fontSize:   16,
                        color:      Colors.white,
                        height:     1.4,
                      ),
                      decoration: InputDecoration(
                        hintText:  widget.isP2PActive
                            ? 'say something beautiful…'
                            : 'connect P2P to send real messages…',
                        hintStyle: TextStyle(
                          fontFamily: 'Cormorant Garamond',
                          fontSize:   15,
                          color: Colors.white.withValues(alpha: 0.2),
                          fontStyle: FontStyle.italic,
                        ),
                        border:         InputBorder.none,
                        isDense:        true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 10),

            // Send / mic button
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _hasText
                  ? _SendBtn(
                      key:       const ValueKey('send'),
                      onTap:     _send,
                      isLoading: widget.isSending,
                    )
                  : _IconBtn(
                      key:   const ValueKey('mic'),
                      icon:  Icons.mic_none_rounded,
                      color: Colors.white38,
                      onTap: () {},
                    ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SendBtn extends StatelessWidget {
  const _SendBtn({super.key, required this.onTap, this.isLoading = false});
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
            colors: [Color(0xFFC084FC), Color(0xFFF472B6)]),
        boxShadow: [BoxShadow(
            color: const Color(0xFFC084FC).withValues(alpha: 0.35),
            blurRadius: 12)],
      ),
      child: Center(child: isLoading
          ? const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white))
          : const Icon(Icons.send_rounded, color: Colors.white, size: 18)),
    ),
  );
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.1), width: 0.5),
      ),
      child: Icon(icon, color: color, size: 18),
    ),
  );
}
