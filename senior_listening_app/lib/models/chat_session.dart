import 'chat_entry.dart';

class ChatSession {
  final String id;
  final String mode; // 'listening', 'practical', 'organize'
  final DateTime savedAt;
  final List<ChatEntry> messages;

  ChatSession({
    required this.id,
    required this.mode,
    required this.savedAt,
    required this.messages,
  });

  String get modeLabel => switch (mode) {
        'listening' => '들어드릴게요',
        'practical' => '실용 도움',
        'organize' => '정리해드릴게요',
        _ => mode,
      };

  Map<String, dynamic> toJson() => {
        'id': id,
        'mode': mode,
        'savedAt': savedAt.toIso8601String(),
        'messages': messages.map((m) => m.toJson()).toList(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'] as String,
        mode: json['mode'] as String,
        savedAt: DateTime.parse(json['savedAt'] as String),
        messages: (json['messages'] as List<dynamic>)
            .map((m) => ChatEntry.fromJson(m as Map<String, dynamic>))
            .toList(),
      );
}
