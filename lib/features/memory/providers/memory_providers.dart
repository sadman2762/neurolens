import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/core/database/database_provider.dart';
import 'package:neurolens/features/memory/data/gallery_sync_service.dart';
import 'package:neurolens/features/memory/data/ocr_processing_service.dart';
import 'package:neurolens/features/memory/data/ocr_service.dart';
import 'package:neurolens/features/memory/data/repositories/gallery_repository_impl.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart';
import 'package:neurolens/features/memory/providers/memory_filter_provider.dart';
import 'package:neurolens/features/memory/data/pdf_import_service.dart';
import 'package:neurolens/features/memory/data/pdf_picker_service.dart';
import 'package:neurolens/features/memory/data/pdf_text_extractor_service.dart';

final galleryRepositoryProvider = Provider<GalleryRepositoryImpl>((ref) {
  return GalleryRepositoryImpl();
});

final memoryRepositoryProvider = Provider<MemoryRepositoryImpl>((ref) {
  final database = ref.watch(appDatabaseProvider);

  return MemoryRepositoryImpl(database);
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();

  ref.onDispose(service.dispose);

  return service;
});

final ocrProcessingServiceProvider = Provider<OcrProcessingService>((ref) {
  final ocrService = ref.watch(ocrServiceProvider);
  final memoryRepository = ref.watch(memoryRepositoryProvider);

  return OcrProcessingService(
    ocrService: ocrService,
    memoryRepository: memoryRepository,
  );
});

final gallerySyncServiceProvider = Provider<GallerySyncService>((ref) {
  final galleryRepository = ref.watch(galleryRepositoryProvider);
  final memoryRepository = ref.watch(memoryRepositoryProvider);
  final ocrProcessingService = ref.watch(ocrProcessingServiceProvider);

  return GallerySyncService(
    galleryRepository: galleryRepository,
    memoryRepository: memoryRepository,
    ocrProcessingService: ocrProcessingService,
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
  final filter = ref.watch(memoryFilterProvider);

  return timeline.whenData((memories) {
    return memories.where((memory) {
      final title = memory.title.toLowerCase();
      final content = memory.content?.toLowerCase() ?? '';

      final matchesSearch =
          query.isEmpty || title.contains(query) || content.contains(query);

      final matchesFilter = switch (filter) {
        MemoryFilter.all => true,
        MemoryFilter.images => memory.type == 'image',
        MemoryFilter.notes => memory.type == 'note',
        MemoryFilter.pdfs => memory.type == 'pdf',
      };

      return matchesSearch && matchesFilter;
    }).toList();
  });
});

final pdfPickerServiceProvider = Provider<PdfPickerService>((ref) {
  return PdfPickerService();
});

final pdfImportServiceProvider = Provider<PdfImportService>((ref) {
  final pickerService = ref.watch(pdfPickerServiceProvider);
  final textExtractorService = ref.watch(pdfTextExtractorServiceProvider);
  final memoryRepository = ref.watch(memoryRepositoryProvider);

  return PdfImportService(
    pickerService: pickerService,
    textExtractorService: textExtractorService,
    memoryRepository: memoryRepository,
  );
});

final pdfTextExtractorServiceProvider =
    Provider<PdfTextExtractorService>((ref) {
  return PdfTextExtractorService();
});