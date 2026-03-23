import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:intl/intl.dart';

import '../models/chat_session.dart';
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
  late Future<List<ChatSession>> _future;

  @override
  void initState() {
    super.initState();
    _future = _historyService.loadSessions();
  }

  Future<void> _reload() async {
    setState(() {
      _future = _historyService.loadSessions();
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
    const background = Color(0xFFF5F1E8);
    const textColor = Color(0xFF2F2A26);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          '내 이야기 보기',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _confirmClear,
            icon: const Icon(Icons.delete_outline_rounded, color: textColor),
            tooltip: '전체 삭제',
          ),
        ],
      ),
      body: FutureBuilder<List<ChatSession>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final sessions = snapshot.data ?? [];
          if (sessions.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '아직 저장된 이야기가 없어요.\n이야기를 나누고 저장 버튼을 눌러 주세요.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: textColor, height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _SessionCard(session: sessions[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _SessionCard extends StatefulWidget {
  final ChatSession session;

  const _SessionCard({required this.session});

  @override
  State<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends State<_SessionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFFFFFFF);
    const borderColor = Color(0xFFE2D8C9);
    const olive = Color(0xFFAAB08B);
    const oliveDark = Color(0xFF6F7758);
    const textColor = Color(0xFF2F2A26);
    const userBubble = Color(0xFFF3E3D7);

    final session = widget.session;
    final dateStr = DateFormat('yyyy년 M월 d일  a h:mm', 'ko')
        .format(session.savedAt);
    final previewMsg = session.messages
        .firstWhere((m) => m.role == 'user', orElse: () => session.messages.first);

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
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
          // Header
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: olive,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      session.modeLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withOpacity(0.55),
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: oliveDark,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),

          // Preview (shown when collapsed)
          if (!_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                previewMsg.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withOpacity(0.75),
                  height: 1.5,
                ),
              ),
            ),

          // Full conversation (shown when expanded)
          if (_expanded) ...[
            const Divider(height: 1, color: Color(0xFFE2D8C9)),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: session.messages.map((entry) {
                  final isUser = entry.role == 'user';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isUser
                              ? userBubble
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: borderColor),
                        ),
                        child: Text(
                          entry.text,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
