import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_entry.dart';

class HistoryService {
  static const String _storageKey = 'chat_history_entries';

  Future<List<ChatEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => ChatEntry.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addEntry(ChatEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadEntries();
    current.add(entry);
    final encoded = jsonEncode(current.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
