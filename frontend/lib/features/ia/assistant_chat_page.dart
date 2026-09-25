import 'package:flutter/material.dart';

import 'ai_service.dart';
import '../../core/theme/app_colors.dart';

class AssistantChatPage extends StatefulWidget {
  const AssistantChatPage({super.key});

  @override
  State<AssistantChatPage> createState() => _AssistantChatPageState();
}

class _AssistantChatPageState extends State<AssistantChatPage> {
  final AiService _service = AiService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _sending = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _envoyer() async {
    final texte = _inputController.text.trim();

    if (texte.isEmpty || _sending) return;

    setState(() {
      _messages.add(ChatMessage(role: 'user', content: texte));
      _inputController.clear();
      _sending = true;
    });

    _scrollToBottom();

    setState(() {
      _messages.add(const ChatMessage(role: 'assistant', content: ''));
    });

    try {
      var reponseAccumulee = '';

      await for (final morceau in _service.chatStream(
        _messages.sublist(0, _messages.length - 1),
      )) {
        reponseAccumulee += morceau;

        if (!mounted) return;

        setState(() {
          _messages[_messages.length - 1] = ChatMessage(
            role: 'assistant',
            content: reponseAccumulee,
          );
        });

        _scrollToBottom();
      }

      if (!mounted) return;

      setState(() {
        _sending = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages[_messages.length - 1] = ChatMessage(
          role: 'assistant',
          content: e.toString().replaceFirst('Exception: ', ''),
        );
        _sending = false;
      });

      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.pageBackground,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome_rounded),
            SizedBox(width: 10),
            Text('Assistant IA', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: context.surfaceColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_sending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _messages.length) {
                        return _buildTypingBubble();
                      }
                      return _buildBubble(_messages[index]);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF6366F1),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Posez une question à l\'assistant',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Il connaît le fonctionnement de SS Consulting et peut vous '
              'aider sur la comptabilité, la fiscalité ou l\'utilisation '
              'de l\'application.',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage message) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 560),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF3155D9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isUser ? null : Border.all(color: context.borderColor),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: isUser ? Colors.white : context.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.borderColor),
        ),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _inputController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _envoyer(),
                decoration: InputDecoration(
                  hintText: 'Écrivez votre question...',
                  filled: true,
                  fillColor: context.pageBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Material(
              color: const Color(0xFF3155D9),
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _sending ? null : _envoyer,
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.send_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
