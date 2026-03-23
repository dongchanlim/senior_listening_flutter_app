import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/chat_entry.dart';
import '../models/chat_session.dart';
import '../services/history_service.dart';
import '../services/openai_service.dart';

enum AssistantMode { listening, practical, organize }

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final OpenAIService _aiService = OpenAIService();
  final HistoryService _historyService = HistoryService();

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  // Per-mode independent conversation lists
  final Map<AssistantMode, List<_ChatMessage>> _modeMessages = {
    AssistantMode.listening: [],
    AssistantMode.practical: [],
    AssistantMode.organize: [],
  };

  AssistantMode _currentMode = AssistantMode.listening;
  bool _isLoading = false;
  bool _readAloud = true;
  bool _speechAvailable = false;
  bool _isListening = false;

  List<_ChatMessage> get _messages => _modeMessages[_currentMode]!;

  static const Map<AssistantMode, String> _modeWelcome = {
    AssistantMode.listening:
        '안녕하세요. 오늘 어떤 이야기든 편하게 꺼내 주세요.\n천천히, 제가 들어드릴게요.',
    AssistantMode.practical:
        '안녕하세요. 도움이 필요한 일이 있으신가요?\n궁금한 것, 해결하고 싶은 것을 편하게 말씀해 주세요.',
    AssistantMode.organize:
        '안녕하세요. 마음속에 정리되지 않은 감정이나 생각이 있으신가요?\n함께 차분히 들여다볼게요.',
  };

  @override
  void initState() {
    super.initState();
    _configureTts();
    _initSpeech();
    _addWelcomeMessage(AssistantMode.listening);
  }

  Future<void> _configureTts() async {
    await _tts.setLanguage('ko-KR');
    await _tts.setSpeechRate(0.38);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  Future<void> _initSpeech() async {
    final available = await _speech.initialize(
      onError: (_) => setState(() => _isListening = false),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );
    setState(() => _speechAvailable = available);
  }

  void _addWelcomeMessage(AssistantMode mode) {
    _modeMessages[mode]!.add(
      _ChatMessage(
        role: MessageRole.assistant,
        text: _modeWelcome[mode]!,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _tts.stop();
    _speech.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!_speechAvailable) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _controller.text = result.recognizedWords;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          });
        },
        localeId: 'ko_KR',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
    }

    final userMessage = _ChatMessage(
      role: MessageRole.user,
      text: text,
      createdAt: DateTime.now(),
    );

    final history = _buildHistory();

    setState(() {
      _messages.add(userMessage);
      _controller.clear();
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      await Future.delayed(const Duration(seconds: 2));

      final reply = await _aiService.generateEmpatheticReply(text, history);

      final assistantMessage = _ChatMessage(
        role: MessageRole.assistant,
        text: reply.trim(),
        createdAt: DateTime.now(),
      );

      if (!mounted) return;

      setState(() {
        _messages.add(assistantMessage);
        _isLoading = false;
      });

      _scrollToBottom();

      if (_readAloud) {
        await _tts.stop();
        await _tts.speak(assistantMessage.text);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          _ChatMessage(
            role: MessageRole.assistant,
            text: '지금은 잠시 연결이 불안정해요. 잠시 후 다시 말씀해 주세요.',
            createdAt: DateTime.now(),
          ),
        );
        _isLoading = false;
      });

      _scrollToBottom();
    }
  }

  List<ChatEntry> _buildHistory() {
    return _messages.map((message) {
      return ChatEntry(
        role: message.role == MessageRole.user ? 'user' : 'assistant',
        text: message.text,
        timestamp: message.createdAt,
      );
    }).toList();
  }

  void _setMode(AssistantMode mode) {
    if (_currentMode == mode) return;

    // If this mode has never been started, add its welcome message
    if (_modeMessages[mode]!.isEmpty) {
      _addWelcomeMessage(mode);
    }

    setState(() {
      _currentMode = mode;
    });

    _scrollToBottom();
  }

  Future<void> _saveSession() async {
    // Exclude the welcome message (index 0) — only save real conversation
    final real = _messages.skip(1).toList();

    if (real.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장할 대화가 없어요. 먼저 이야기를 나눠 주세요.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final modeKey = switch (_currentMode) {
      AssistantMode.listening => 'listening',
      AssistantMode.practical => 'practical',
      AssistantMode.organize => 'organize',
    };

    final session = ChatSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      mode: modeKey,
      savedAt: DateTime.now(),
      messages: real.map((m) {
        return ChatEntry(
          role: m.role == MessageRole.user ? 'user' : 'assistant',
          text: m.text,
          timestamp: m.createdAt,
        );
      }).toList(),
    );

    await _historyService.saveSession(session);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('이야기가 저장되었어요.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$period $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF5F1E8);
    const userBubble = Color(0xFFF3E3D7);
    const assistantBubble = Color(0xFFFFFFFF);
    const olive = Color(0xFFAAB08B);
    const oliveDark = Color(0xFF6F7758);
    const textColor = Color(0xFF2F2A26);
    const borderColor = Color(0xFFE2D8C9);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          '이야기 나누기',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        actions: [
          // Save button
          TextButton.icon(
            onPressed: _saveSession,
            icon: const Icon(Icons.bookmark_add_outlined,
                color: oliveDark, size: 22),
            label: const Text(
              '저장',
              style: TextStyle(
                fontSize: 15,
                color: oliveDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Read aloud toggle
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                const Text(
                  '읽기',
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Switch(
                  value: _readAloud,
                  activeThumbColor: oliveDark,
                  activeTrackColor: olive,
                  onChanged: (value) async {
                    setState(() => _readAloud = value);
                    if (!value) await _tts.stop();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Mode chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeChip(
                      label: '들어드릴게요',
                      selected: _currentMode == AssistantMode.listening,
                      onTap: () => _setMode(AssistantMode.listening),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeChip(
                      label: '실용 도움',
                      selected: _currentMode == AssistantMode.practical,
                      onTap: () => _setMode(AssistantMode.practical),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeChip(
                      label: '정리해드릴게요',
                      selected: _currentMode == AssistantMode.organize,
                      onTap: () => _setMode(AssistantMode.organize),
                    ),
                  ),
                ],
              ),
            ),

            // Message list
            Expanded(
              child: ListView.separated(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  if (_isLoading && index == _messages.length) {
                    return const _TypingBubble();
                  }

                  final message = _messages[index];
                  final isUser = message.role == MessageRole.user;

                  return Align(
                    alignment: isUser
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.86,
                      ),
                      child: Container(
                        padding:
                            const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        decoration: BoxDecoration(
                          color: isUser ? userBubble : assistantBubble,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.text,
                              style: const TextStyle(
                                fontSize: 19,
                                height: 1.5,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _formatTime(message.createdAt),
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor.withOpacity(0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Input area
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              decoration: const BoxDecoration(
                color: background,
                border: Border(
                  top: BorderSide(color: borderColor),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Mic button
                  if (_speechAvailable)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 4),
                      child: GestureDetector(
                        onTap: _toggleListening,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isListening ? oliveDark : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _isListening ? oliveDark : borderColor,
                            ),
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none_rounded,
                            color: _isListening ? Colors.white : oliveDark,
                            size: 24,
                          ),
                        ),
                      ),
                    ),

                  // Text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: _isListening ? olive : borderColor,
                          width: _isListening ? 2 : 1,
                        ),
                      ),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(
                          fontSize: 20,
                          color: textColor,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _isListening
                              ? '듣고 있어요...'
                              : _hintTextByMode(_currentMode),
                          hintStyle: TextStyle(
                            fontSize: 18,
                            color: _isListening
                                ? olive
                                : textColor.withOpacity(0.45),
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Send button
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendMessage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: oliveDark,
                        disabledBackgroundColor: olive,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _hintTextByMode(AssistantMode mode) {
    return switch (mode) {
      AssistantMode.listening => '편하게 이야기해 주세요',
      AssistantMode.practical => '도움이 필요한 점을 말씀해 주세요',
      AssistantMode.organize => '정리하고 싶은 마음이나 상황을 적어 주세요',
    };
  }
}

enum MessageRole { user, assistant }

class _ChatMessage {
  final MessageRole role;
  final String text;
  final DateTime createdAt;

  _ChatMessage({
    required this.role,
    required this.text,
    required this.createdAt,
  });
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const selectedBg = Color(0xFFAAB08B);
    const selectedText = Color(0xFF33402A);
    const normalBg = Colors.white;
    const normalText = Color(0xFF5B554E);
    const borderColor = Color(0xFFE2D8C9);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? selectedBg : normalBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? selectedText : normalText,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    const assistantBubble = Color(0xFFFFFFFF);
    const borderColor = Color(0xFFE2D8C9);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: assistantBubble,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Dot(),
            SizedBox(width: 6),
            _Dot(),
            SizedBox(width: 6),
            _Dot(),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFFAAB08B),
        shape: BoxShape.circle,
      ),
    );
  }
}
