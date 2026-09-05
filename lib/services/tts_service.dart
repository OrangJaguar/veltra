import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

final ttsServiceProvider = Provider<TtsService>((ref) => TtsService());

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> _ensureInit() async {
    if (_initialized) return;
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    _initialized = true;
  }

  Future<void> speakResult({
    required String workerName,
    required String statusLabel,
  }) async {
    await _ensureInit();
    await _tts.stop();
    await _tts.speak('$workerName. $statusLabel.');
  }

  Future<void> stop() => _tts.stop();
}
