import 'package:neurolens/features/memory/data/repositories/gallery_repository_impl.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';

class GallerySyncService {
  GallerySyncService({
    required GalleryRepositoryImpl galleryRepository,
    required MemoryRepositoryImpl memoryRepository,
  })  : _galleryRepository = galleryRepository,
        _memoryRepository = memoryRepository;

  static const int _batchSize = 50;

  final GalleryRepositoryImpl _galleryRepository;
  final MemoryRepositoryImpl _memoryRepository;

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

      totalSaved += memories.length;
      page++;

      if (memories.length < _batchSize) {
        break;
      }
    }

    return totalSaved;
  }
}