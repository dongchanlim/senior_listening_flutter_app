import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/intl.dart';

import '../models/chat_entry.dart';
import '../services/history_service.dart';
import '../theme/app_theme.dart';

Widget historyPreviewWrapper(Widget child) =>
    MaterialApp(theme: AppTheme.build(), home: child);

@Preview(name: '기록 화면', wrapper: historyPreviewWrapper)
Widget previewHistoryScreen() => const HistoryScreen();

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final HistoryService _historyService = HistoryService();
  late Future<List<ChatEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _historyService.loadEntries();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _historyService.loadEntries();
    });
  }

  Future<void> _confirmClear() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록을 모두 지울까요?'),
        content: const Text('지우면 이 기기에서 저장된 대화 기록이 사라집니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('지우기'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _historyService.clearAll();
      await _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 이야기 보기'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _confirmClear,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: '전체 삭제',
          )
        ],
      ),
      body: FutureBuilder<List<ChatEntry>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final entries = snapshot.data ?? [];
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '아직 저장된 이야기가 없어요.\n천천히 첫 이야기를 시작해 보세요.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                final isAssistant = entry.role == 'assistant';
                return Card(
                  color: isAssistant ? const Color(0xFFE8F3E8) : const Color(0xFFFFEDD8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(18),
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          isAssistant ? AppTheme.secondary : AppTheme.primary,
                      child: Icon(
                        isAssistant ? Icons.favorite_border : Icons.person_outline,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    title: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        isAssistant ? '경청의 답장' : '내 이야기',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.text,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          DateFormat('yyyy.MM.dd  a h:mm', 'ko').format(entry.timestamp),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
