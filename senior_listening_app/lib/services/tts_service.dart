import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;

  Future<void> init() async {
    try {
      await _tts.setLanguage('ko-KR');
      await _tts.setSpeechRate(0.38);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      _isInitialized = true;
    } catch (_) {
      _isInitialized = false;
    }
  }

  Future<void> speak(String text) async {
    if (!_isInitialized || text.trim().isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> stop() async {
    if (!_isInitialized) return;
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
