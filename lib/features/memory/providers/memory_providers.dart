import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/core/database/database_provider.dart';
import 'package:neurolens/features/memory/data/gallery_sync_service.dart';
import 'package:neurolens/features/memory/data/repositories/gallery_repository_impl.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart';

final galleryRepositoryProvider = Provider<GalleryRepositoryImpl>((ref) {
  return GalleryRepositoryImpl();
});

final memoryRepositoryProvider = Provider<MemoryRepositoryImpl>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return MemoryRepositoryImpl(database);
});

final gallerySyncServiceProvider = Provider<GallerySyncService>((ref) {
  final galleryRepository = ref.watch(galleryRepositoryProvider);
  final memoryRepository = ref.watch(memoryRepositoryProvider);

  return GallerySyncService(
    galleryRepository: galleryRepository,
    memoryRepository: memoryRepository,
  );
});

final memoryTimelineProvider = StreamProvider<List<Memory>>((ref) {
  final repository = ref.watch(memoryRepositoryProvider);

  return repository.watchAllMemories();
});

final memorySearchQueryProvider = StateProvider<String>((ref) => '');

final filteredMemoryTimelineProvider =
    Provider<AsyncValue<List<Memory>>>((ref) {
  final timeline = ref.watch(memoryTimelineProvider);
  final query = ref.watch(memorySearchQueryProvider).trim().toLowerCase();

  return timeline.whenData((memories) {
    if (query.isEmpty) {
      return memories;
    }

    return memories.where((memory) {
      final title = memory.title.toLowerCase();
      final content = memory.content?.toLowerCase() ?? '';

      return title.contains(query) || content.contains(query);
    }).toList();
  });
});