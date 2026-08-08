import 'package:neurolens/features/memory/data/ocr_service.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';

class OcrProcessingService {
  OcrProcessingService({
    required this._ocrService,
    required this._memoryRepository,
  });

  final OcrService _ocrService;
  final MemoryRepositoryImpl _memoryRepository;

  Future<String> processImage({required String memoryId}) async {
    final extractedText = await _ocrService.extractTextFromAsset(memoryId);

    if (extractedText.isNotEmpty) {
      await _memoryRepository.updateMemoryContent(
        id: memoryId,
        content: extractedText,
      );
    }

    return extractedText;
  }
}
