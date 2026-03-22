import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../models/chat_entry.dart';
import '../services/history_service.dart';
import '../services/openai_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

Widget chatPreviewWrapper(Widget child) =>
    MaterialApp(theme: AppTheme.build(), home: child);

@Preview(name: '채팅 화면', wrapper: chatPreviewWrapper)
WidgetBuilder previewChatScreen() => (context) => FutureBuilder<void>(
      future: initializeDateFormatting('ko', null),
      builder: (context, snapshot) => snapshot.connectionState == ConnectionState.done
          ? const ChatScreen()
          : const SizedBox.shrink(),
    );

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OpenAIService _openAIService = OpenAIService();
  final HistoryService _historyService = HistoryService();
  final TtsService _ttsService = TtsService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  final List<ChatEntry> _messages = [];

  bool _isLoading = false;
  bool _speechReady = false;
  bool _isListening = false;
  bool _speakReply = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _ttsService.init();
      _speechReady = await _speech.initialize();
    } catch (_) {
      _speechReady = false;
    }
    if (!mounted) return;
    setState(() {
      _messages.add(
        ChatEntry(
          role: 'assistant',
          text: '안녕하세요. 오늘 어떤 마음으로 하루를 보내셨나요?',
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (!_speechReady) {
      _showSnack('음성 인식을 사용할 준비가 아직 되지 않았어요.');
      return;
    }

    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    final started = await _speech.listen(
      localeId: 'ko_KR',
      onResult: (result) {
        setState(() {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        });
      },
    );

    if (started) {
      setState(() => _isListening = true);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    FocusScope.of(context).unfocus();
    _controller.clear();
    await _speech.stop();

    final userEntry = ChatEntry(
      role: 'user',
      text: text,
      timestamp: DateTime.now(),
    );

    setState(() {
      _isListening = false;
      _isLoading = true;
      _messages.add(userEntry);
    });

    await _historyService.addEntry(userEntry);
    _scrollToBottom();

    await Future.delayed(const Duration(seconds: 3));
    final reply = await _openAIService.generateEmpatheticReply(text);

    if (!mounted) return;

    final assistantEntry = ChatEntry(
      role: 'assistant',
      text: reply,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(assistantEntry);
      _isLoading = false;
    });

    await _historyService.addEntry(assistantEntry);
    _scrollToBottom();

    if (!mounted) return;
    if (_speakReply) {
      await _ttsService.speak(reply);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bodyText = Theme.of(context).textTheme.bodyLarge;

    return Scaffold(
      appBar: AppBar(
        title: const Text('이야기 나누기'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        actions: [
          Row(
            children: [
              const Text('읽어주기'),
              Switch(
                value: _speakReply,
                activeColor: AppTheme.secondary,
                onChanged: (value) => setState(() => _speakReply = value),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_isLoading && index == _messages.length) {
                    return const _TypingCard();
                  }

                  final message = _messages[index];
                  final isUser = message.role == 'user';
                  return Align(
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.84,
                      ),
                      child: Card(
                        color: isUser ? const Color(0xFFFFF1E4) : Colors.white,
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.text,
                                style: bodyText,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                DateFormat('a h:mm', 'ko').format(message.timestamp),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
              child: Column(
                children: [
                  TextField(
                    controller: _controller,
                    minLines: 2,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 20, height: 1.5),
                    decoration: const InputDecoration(
                      hintText: '편하게 이야기해 주세요',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _toggleListening,
                          icon: Icon(
                            _isListening ? Icons.stop_circle_outlined : Icons.mic_none_rounded,
                            size: 30,
                          ),
                          label: Text(
                            _isListening ? '듣는 중 멈추기' : '음성으로 말하기',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(64),
                            foregroundColor: AppTheme.text,
                            side: const BorderSide(color: AppTheme.secondary, width: 1.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send_rounded, size: 28),
                          label: const Text('보내기'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(64),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _TypingCard extends StatelessWidget {
  const _TypingCard();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        child: const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              '듣고 있어요...\n천천히 마음을 담아 답하고 있어요.',
              style: TextStyle(fontSize: 20, height: 1.6),
            ),
          ),
        ),
      ),
    );
  }
}
