import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/chat_entry.dart';

class OpenAIService {
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _url = 'https://api.openai.com/v1/chat/completions';
  static const String _fallback = '잠시 마음을 고르고 있어요. 잠깐 후에 다시 이야기해 주셔도 괜찮아요.';

  String _buildSystemPrompt(List<ChatEntry> history) {
    final aiTurnCount = history.where((e) => e.role == 'assistant').length;

    final String stageInstruction;
    if (aiTurnCount <= 2) {
      stageInstruction = '아직 초기 단계입니다. 상황 파악을 위해 질문 1개를 할 수 있습니다.';
    } else if (aiTurnCount <= 4) {
      stageInstruction = '중반 단계입니다. 감정 공감을 중심으로 하고, 질문은 꼭 필요한 경우에만 1개 하세요.';
    } else {
      stageInstruction = '충분히 들었습니다. 이번엔 질문 없이 따뜻한 위로와 공감으로만 응답하세요.';
    }

    return '''
당신은 시니어를 위한 따뜻한 경청자입니다.

[핵심 규칙]
- 대화 기록을 반드시 참고하고, 이미 파악된 정보(사람 이름, 관계, 상황)는 절대 다시 묻지 마세요.
- 직전 AI 메시지와 같거나 유사한 질문을 반복하지 마세요.
- 질문은 한 번에 하나만 하세요.
- 절대 판단하지 말고, 조언을 남발하지 마세요.
- 짧고 천천히 읽히는 문장 2~4문장으로 답하세요.
- 말투는 공손하고 부드럽게 유지하세요.

[현재 단계 지시]
$stageInstruction
''';
  }

  Future<String> generateEmpatheticReply(
    String userMessage,
    List<ChatEntry> history,
  ) async {
    if (_apiKey.isEmpty) {
      return '지금은 연결 준비가 필요해요. 개발자가 OPENAI_API_KEY를 넣어주면 더 따뜻하게 들어드릴 수 있어요.';
    }

    // 토큰 관리: 최근 10개 메시지만 전달
    final recentHistory = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'temperature': 0.7,
          'messages': [
            {
              'role': 'system',
              'content': _buildSystemPrompt(history),
            },
            ...recentHistory.map((e) => {
              'role': e.role == 'user' ? 'user' : 'assistant',
              'content': e.text,
            }),
            {
              'role': 'user',
              'content': userMessage,
            },
          ],
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final choices = decoded['choices'];
          if (choices is List && choices.isNotEmpty) {
            final content = choices[0]?['message']?['content'];
            if (content is String && content.trim().isNotEmpty) {
              return content.trim();
            }
          }
        }
      }

      return _fallback;
    } catch (_) {
      return _fallback;
    }
  }
}
