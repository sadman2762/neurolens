import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/core/database/database_provider.dart';
import 'package:neurolens/features/memory/data/repositories/gallery_repository_impl.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:neurolens/features/memory/data/gallery_sync_service.dart';

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

final memoryTimelineProvider = StreamProvider((ref) {
  final repository = ref.watch(memoryRepositoryProvider);
  return repository.watchAllMemories();
});