import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

class VoiceSearchService {
  final SpeechToText _speechToText = SpeechToText();

  bool get isListening => _speechToText.isListening;

  Future<bool> initialize({
    void Function(String status)? onStatus,
  }) {
    return _speechToText.initialize(
      onStatus: (status) {
        debugPrint('Speech status: $status');
        onStatus?.call(status);
      },
      onError: (error) {
        debugPrint('Speech error: ${error.errorMsg}');
      },
    );
  }

  Future<void> startListening({
    required void Function(String words) onWords,
    required VoidCallback onFinished,
  }) async {
    final available = await initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          onFinished();
        }
      },
    );

    if (!available) {
      throw StateError('Speech recognition is not available.');
    }

    await _speechToText.listen(
      onResult: (result) {
        final words = result.recognizedWords.trim();

        debugPrint(
          'Recognized: "$words", final: ${result.finalResult}',
        );

        if (words.isNotEmpty) {
          onWords(words);
        }
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.search,
      ),
    );
  }

  Future<void> stopListening() {
    return _speechToText.stop();
  }

  Future<void> cancelListening() {
    return _speechToText.cancel();
  }
}