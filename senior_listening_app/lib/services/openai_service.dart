import 'dart:convert';

import 'package:http/http.dart' as http;

class OpenAIService {
  static const String _apiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String _url = 'https://api.openai.com/v1/chat/completions';
  static const String _fallback = '잠시 마음을 고르고 있어요. 잠깐 후에 다시 이야기해 주셔도 괜찮아요.';

  Future<String> generateEmpatheticReply(String userMessage) async {
    if (_apiKey.isEmpty) {
      return '지금은 연결 준비가 필요해요. 개발자가 OPENAI_API_KEY를 넣어주면 더 따뜻하게 들어드릴 수 있어요.';
    }

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
              'content': '''
당신은 시니어를 위한 따뜻한 경청자입니다.
절대 판단하지 말고, 조언을 남발하지 마세요.
짧고 천천히 읽히는 문장으로 답하세요.
문장 수는 2~4문장 이내로 유지하세요.
말투는 공손하고 부드럽게 유지하세요.
가능하면 다음 패턴을 따르세요:
1) 감정 공감
2) 아주 짧은 반사 질문 또는 함께 머무는 한 문장
예시 표현:
- 그 마음이 오늘은 더 크게 느껴지셨겠어요.
- 이렇게 이야기해 주셔서 고맙습니다.
- 조금 더 들려주실 수 있을까요?
- 오늘 하루가 길게 느껴지셨나 봐요.
''',
            },
            {
              'role': 'user',
              'content': userMessage,
            }
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
