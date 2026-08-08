import 'package:neurolens/features/memory/data/ocr_processing_service.dart';
import 'package:neurolens/features/memory/data/repositories/gallery_repository_impl.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';

class GallerySyncService {
  GallerySyncService({
    required this._galleryRepository,
    required this._memoryRepository,
    required this._ocrProcessingService,
  });

  static const int _batchSize = 50;

  final GalleryRepositoryImpl _galleryRepository;
  final MemoryRepositoryImpl _memoryRepository;
  final OcrProcessingService _ocrProcessingService;

  Future<int> syncAllImages() async {
    var page = 0;
    var totalSaved = 0;

    while (true) {
      final memories = await _galleryRepository.getImageBatch(
        page: page,
        pageSize: _batchSize,
      );

      if (memories.isEmpty) {
        break;
      }

      await _memoryRepository.saveMemories(memories);

      for (final memory in memories) {
        try {
          await _ocrProcessingService.processImage(memoryId: memory.id);
        } catch (_) {
          // Ignore OCR failures for individual images.
          // The memory is already saved locally.
        }
      }

      totalSaved += memories.length;
      page++;

      if (memories.length < _batchSize) {
        break;
      }
    }

    return totalSaved;
  }
}
