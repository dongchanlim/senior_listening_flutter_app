import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_entry.dart';
import '../models/chat_session.dart';

class HistoryService {
  static const String _entriesKey = 'chat_history_entries';
  static const String _sessionsKey = 'chat_history_sessions';

  // ── Session methods ────────────────────────────────────────────────────────

  Future<List<ChatSession>> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionsKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw) as List<dynamic>;
      final sessions = <ChatSession>[];
      for (final item in decoded) {
        try {
          sessions.add(ChatSession.fromJson(item as Map<String, dynamic>));
        } catch (_) {}
      }
      sessions.sort((a, b) => b.savedAt.compareTo(a.savedAt));
      return sessions;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSession(ChatSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadSessions();
    current.add(session);
    final encoded = jsonEncode(current.map((s) => s.toJson()).toList());
    await prefs.setString(_sessionsKey, encoded);
  }

  Future<void> clearAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
  }

  // ── Legacy entry methods (kept for backwards compatibility) ────────────────

  Future<List<ChatEntry>> loadEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_entriesKey);
      if (raw == null || raw.isEmpty) return [];

      final decoded = jsonDecode(raw) as List<dynamic>;
      final entries = <ChatEntry>[];
      for (final item in decoded) {
        try {
          entries.add(ChatEntry.fromJson(item as Map<String, dynamic>));
        } catch (_) {}
      }
      entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return entries;
    } catch (_) {
      return [];
    }
  }

  Future<void> addEntry(ChatEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await loadEntries();
    current.add(entry);
    final encoded = jsonEncode(current.map((e) => e.toJson()).toList());
    await prefs.setString(_entriesKey, encoded);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_entriesKey);
    await prefs.remove(_sessionsKey);
  }
}
