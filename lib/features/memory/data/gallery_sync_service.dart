import 'package:neurolens/features/memory/data/ocr_processing_service.dart';
import 'package:neurolens/features/memory/data/repositories/gallery_repository_impl.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';

class GallerySyncService {
  GallerySyncService({
    required GalleryRepositoryImpl galleryRepository,
    required MemoryRepositoryImpl memoryRepository,
    required OcrProcessingService ocrProcessingService,
  })  : _galleryRepository = galleryRepository,
        _memoryRepository = memoryRepository,
        _ocrProcessingService = ocrProcessingService;

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

      // Run OCR in the background for every image.
      // If one image fails, continue processing the rest.
      for (final memory in memories) {
        try {
          await _ocrProcessingService.processImage(
            memoryId: memory.id,
          );
        } catch (error) {
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