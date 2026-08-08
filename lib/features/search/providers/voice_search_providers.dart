import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/features/search/data/voice_search_service.dart';

final voiceSearchServiceProvider = Provider<VoiceSearchService>((ref) {
  final service = VoiceSearchService();

  ref.onDispose(() {
    service.cancelListening();
  });

  return service;
});

final voiceListeningProvider = StateProvider<bool>((ref) => false);
