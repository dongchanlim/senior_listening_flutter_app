class ChatEntry {
  ChatEntry({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  final String role;
  final String text;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatEntry.fromJson(Map<String, dynamic> json) => ChatEntry(
        role: json['role'] as String,
        text: json['text'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
