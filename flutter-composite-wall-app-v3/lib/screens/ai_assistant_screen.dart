import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../utils/thermal_engine.dart';
import '../widgets/common_widgets.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  ChatMessage({required this.text, required this.isUser, required this.timestamp});
  Map<String, dynamic> toHistory() => {'text': text, 'isUser': isUser};
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});
  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> {
  final List<ChatMessage> _messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  bool _aiAvailable = false;
  String _aiStatus = 'Checking...';

  final _suggestions = const [
    'What is the ideal insulation thickness for 200°C?',
    'Compare aerogel vs mineral wool performance',
    'How to reduce heat flux below 50 W/m²?',
    'Explain the Biot number result',
    'Best material for 400°C industrial furnace?',
    'Suggest improvements for Pentas wall config',
  ];

  @override
  void initState() {
    super.initState();
    _checkAiStatus();
    _addWelcome();
  }

  Future<void> _checkAiStatus() async {
    try {
      final status = await ApiService.getAiStatus();
      setState(() {
        _aiAvailable = status['available'] == true;
        _aiStatus = _aiAvailable
            ? 'Gemini FREE active'
            : 'Offline mode';
      });
    } catch (_) {
      setState(() { _aiAvailable = false; _aiStatus = 'Offline mode'; });
    }
  }

  void _addWelcome() {
    _messages.add(ChatMessage(
      text: 'Hello! I am your AI Thermal Engineering Assistant, powered by Google Gemini (free).\n\n'
          'I can help with:\n'
          '• Analyzing composite wall performance\n'
          '• Material selection & recommendations\n'
          '• Interpreting CFD results & parameters\n'
          '• Industrial insulation best practices\n\n'
          'What would you like to know?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isTyping = true;
    });
    _scrollToBottom();

    String reply;
    if (_aiAvailable) {
      // Send history (last 10 messages) for context
      final history = _messages
          .take(_messages.length - 1)
          .skip(_messages.length > 11 ? _messages.length - 11 : 0)
          .map((m) => m.toHistory())
          .toList();
      reply = await ApiService.chat(text, history) ?? _fallback(text);
    } else {
      reply = _fallback(text);
    }

    setState(() {
      _isTyping = false;
      _messages.add(ChatMessage(text: reply, isUser: false, timestamp: DateTime.now()));
    });
    _scrollToBottom();
  }

  String _fallback(String q) {
    final ql = q.toLowerCase();
    if (ql.contains('biot'))
      return 'Biot number (Bi = hL/k) determines if temperature is uniform inside a layer.\n\nBi < 0.1: uniform temp assumption valid (lumped capacitance OK)\nBi > 0.1: significant gradients exist\n\nFor your wall, Material 1 (Mineral Wool, k=0.1) at 25mm gives Bi ≈ 0.001 — confirming 1D conduction model is accurate.';
    if (ql.contains('aerogel') || ql.contains('compare'))
      return 'Aerogel (k=0.037 W/mK): 3x better insulator than mineral wool, ultra-thin, but costly.\nMineral Wool (k=0.1 W/mK): cost-effective, fire-resistant, widely available in India.\n\nFor Pentas wall at 200°C: mineral wool is cost-optimal. Use aerogel only when thickness is constrained.';
    if (ql.contains('50') || ql.contains('reduce') || ql.contains('flux'))
      return 'To reduce heat flux below 50 W/m²:\n1. Increase Material 1 (Mineral Wool) from 25mm to 45mm\n2. Add aerogel layer (6mm → 10mm)\n3. Add reflective foil barrier (ε≈0.05)\n\nThickening Material 1 by 20mm reduces flux by ~40%.';
    if (ql.contains('furnace') || ql.contains('400'))
      return 'For 400°C industrial furnaces:\n• Ceramic Fiber Board (k=0.12 W/mK @ 400°C, max 1260°C)\n• High-Temp Mineral Wool (k=0.15 W/mK)\n• Microporous panels (k=0.02 W/mK) for critical areas\n\nAvoid standard aerogel above 300°C — it degrades.';
    if (ql.contains('suggest') || ql.contains('improve') || ql.contains('pentas'))
      return 'For the Pentas 4-layer wall:\n1. Increase Material 1 to 35mm (+40% R-value)\n2. Add 3mm aerogel between M1 and M2\n3. Use foil-faced mineral wool to add radiation resistance\n\nExpected improvement: R from 0.32 to 0.58 m²K/W (+81%)';
    return 'Connect to the backend server for full Gemini AI responses.\n\nI can help with: material selection, heat flux reduction, Biot number, layer optimization, and industrial insulation standards.\n\nTry one of the suggestion chips above!';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (_messages.length <= 1) _buildSuggestions(),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (_, i) {
                  if (_isTyping && i == _messages.length) return _TypingBubble();
                  final msg = _messages[i];
                  return _MessageBubble(message: msg, isNew: i == _messages.length - 1 && !_isTyping);
                },
              ),
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accentAlt.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.accentAlt.withOpacity(0.4)),
            ),
            child: const Text('🤖', style: TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AI Assistant',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
                Text('Thermal Engineering Expert',
                    style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (_aiAvailable ? AppColors.success : AppColors.warning).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: (_aiAvailable ? AppColors.success : AppColors.warning).withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_aiAvailable ? '✨' : '📴', style: const TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Text(_aiStatus,
                    style: GoogleFonts.inter(
                        color: _aiAvailable ? AppColors.success : AppColors.warning,
                        fontSize: 10,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 42,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _suggestions.length,
        itemBuilder: (_, i) => GestureDetector(
          onTap: () => _send(_suggestions[i]),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(_suggestions[i],
                style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 12)),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 12,
          MediaQuery.of(context).viewInsets.bottom > 0 ? 8 : 12),
      decoration: const BoxDecoration(
        color: AppColors.bgCard,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Ask about thermal insulation...',
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
              onSubmitted: _send,
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _send(_controller.text),
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFFFF8C42)]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: AppColors.accent.withOpacity(0.4),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Center(
                child: Text('↑',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isNew;
  const _MessageBubble({required this.message, this.isNew = false});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final bubble = Container(
      margin: EdgeInsets.only(
          bottom: 10, left: isUser ? 52 : 0, right: isUser ? 0 : 52),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isUser
            ? const LinearGradient(colors: [AppColors.accent, Color(0xFFFF8C42)])
            : null,
        color: isUser ? null : AppColors.bgCard,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
        border: isUser ? null : Border.all(color: AppColors.border),
        boxShadow: isUser
            ? [BoxShadow(
                color: AppColors.accent.withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: Text(
        message.text,
        style: GoogleFonts.inter(
            color: isUser ? Colors.white : AppColors.textSecondary,
            fontSize: 13, height: 1.6),
      ),
    );

    if (isNew) {
      return Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble.animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
      );
    }
    return Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: bubble);
  }
}

class _TypingBubble extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 80),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(18), topRight: Radius.circular(18),
            bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
          ),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Container(
              width: 7, height: 7,
              margin: EdgeInsets.only(right: i < 2 ? 5 : 0),
              decoration: const BoxDecoration(
                  color: AppColors.textSecondary, shape: BoxShape.circle),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true),
                    delay: Duration(milliseconds: i * 160))
                .fadeIn(duration: 400.ms)
                .scaleXY(begin: 0.6, end: 1.0),
          ),
        ),
      ),
    );
  }
}
