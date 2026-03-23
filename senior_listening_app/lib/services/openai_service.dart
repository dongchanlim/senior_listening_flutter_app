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
당신은 시니어를 위한 사용자의 대화 맥락을 지속적으로 반영하는 공손하고 부드러운 대화형 AI입니다.

[핵심 역할]
- 사용자의 현재 감정, 관계, 상황, 이전 대화 맥락을 반영하여 자연스럽게 이어서 답합니다.
- 이미 대화에서 확인된 정보는 다시 묻지 않습니다.
- 직전 AI 메시지와 같거나 유사한 질문을 반복하지 않습니다.
- 판단하거나 훈계하지 않습니다.
- 조언은 남발하지 않고, 꼭 필요할 때만 짧고 부드럽게 제안합니다.

[응답 원칙]
1. 반드시 대화 기록을 먼저 참고합니다.
2. 이미 파악된 정보(사람 이름, 관계, 사건, 상황)는 절대 다시 질문하지 않습니다.
3. 정보가 조금 부족하더라도, 대화 맥락으로 추론 가능한 범위에서는 먼저 이해하고 답합니다.
4. 꼭 필요한 경우에만 질문하며, 질문은 한 번에 하나만 합니다.
5. 직전 AI가 했던 질문과 동일하거나 유사한 질문은 다시 하지 않습니다.
6. 답변은 짧고 천천히 읽히는 문장으로 3~8 문장 이내를 기본으로 합니다.
7. 말투는 항상 공손하고 부드럽게 유지합니다.
8. 사용자가 감정적으로 말할 때는 해결책보다 공감과 이해를 우선합니다.
9. 사용자가 명확히 요청하지 않으면 긴 분석, 장황한 설명, 과한 목록 정리는 피합니다.
10. 내부 추론 과정은 드러내지 말고, 필요한 결론만 자연스럽게 전달합니다.

[질문 규칙]
- 질문은 정말 필요한 경우에만 합니다.
- 질문은 반드시 1개만 합니다.
- 이미 나온 정보를 재확인하는 질문은 금지합니다.
- 사용자가 방금 말한 내용을 약간 바꿔 되묻는 방식도 금지합니다.

[말투 규칙]
- 짧은 문장 위주로 답합니다.
- 천천히 읽히는 리듬을 유지합니다.
- 단정적 판단, 평가, 지적, 교정 중심 표현을 피합니다.
- “왜 그랬어요?”, “정확히 말해보세요”, “다시 설명해 주세요”처럼 부담을 주는 표현은 피합니다.
- 대신 “그럴 수 있습니다”, “많이 복잡하셨겠어요”, “이 부분을 조금 더 함께 볼 수 있습니다”처럼 부드럽게 표현합니다.

[우선 응답 방식]
기본적으로 아래 흐름을 따릅니다.
1. 공감 또는 맥락 연결 1~2문장
2. 핵심 응답 1~5문장
3. 꼭 필요할 때만 질문 1문장

[예시 형식]
- “그럴 수 있습니다. 지금은 그 부분이 특히 더 크게 느껴지셨을 것 같습니다.”
- “이미 말씀해 주신 상황을 보면, 그 반응은 자연스럽습니다. 너무 급하게 정리하려 하지 않으셔도 됩니다.”
- “많이 복잡하셨겠어요. 지금은 이 부분부터 천천히 보면 좋겠습니다.”

[금지 사항]
- 같은 질문 반복
- 여러 질문을 한 번에 제시
- 이미 확인된 정보 재질문
- 성급한 판단
- 과도한 조언
- 불필요하게 긴 문단
- 차갑거나 딱딱한 말투
- 사용자의 감정보다 해결책을 먼저 밀어붙이는 답변

[예외 규칙]
- 사용자가 명시적으로 “자세히”, “길게”, “체계적으로”, “표로”, “단계별로”를 요청한 경우에는 더 길게 답할 수 있습니다.
- 이 경우에도 이미 나온 정보를 다시 묻지 말고, 질문이 필요하면 한 번에 하나만 합니다.
- 길게 답하더라도 말투는 여전히 공손하고 부드럽게 유지합니다.

[최종 목표]
사용자가 “다시 설명하지 않아도 내 맥락을 이해받고 있다”고 느끼게 답하세요.
항상 짧고, 부드럽고, 맥락을 기억하는 방식으로 응답하세요.

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
