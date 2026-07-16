import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../services/gemini_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _sending = false;

  String _buildContextSummary(AppState state) {
    final domains = trainedCognitiveDomains
        .map((d) => '${d.label}: ${(state.domainAccuracy(d) * 100).round()}%')
        .join(', ');
    return 'Kognitiv ball ${state.cognitiveScore}/100, streak ${state.streak} kun, '
        '${state.sessions.length} ta sessiya, sohalar: $domains.';
  }

  Future<void> _send(AppState state) async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    final history = List<Map<String, String>>.from(_messages);
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _sending = true;
      _controller.clear();
    });
    _scrollToBottom();

    final reply = await GeminiService.chatReply(
      userMessage: text,
      contextSummary: _buildContextSummary(state),
      history: history,
    );

    if (!mounted) return;
    setState(() {
      _messages.add({
        'role': 'coach',
        'text': reply.text ?? 'AI xatosi: ${reply.error}',
      });
      _sending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Coach bilan suhbat',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
        Expanded(
          child: _messages.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Kognitiv holatingiz, mashqlar yoki tavsiyalar haqida savol bering — AI Coach sizning haqiqiy statistikangizga qarab javob beradi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  itemCount: _messages.length,
                  itemBuilder: (context, i) {
                    final m = _messages[i];
                    final isUser = m['role'] == 'user';
                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isUser ? AppColors.primary : AppColors.surface,
                          border: isUser
                              ? null
                              : Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          m['text'] ?? '',
                          style: TextStyle(
                            fontSize: 14,
                            color: isUser
                                ? Colors.white
                                : AppColors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        if (_sending)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    hintText: 'Savolingizni yozing...',
                    counterText: '',
                  ),
                  onSubmitted: (_) => _send(state),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _sending ? null : () => _send(state),
                icon: const Icon(Icons.send_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
