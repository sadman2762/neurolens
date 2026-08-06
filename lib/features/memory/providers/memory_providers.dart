import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/core/database/database_provider.dart';
import 'package:neurolens/features/memory/data/gallery_sync_service.dart';
import 'package:neurolens/features/memory/data/ocr_processing_service.dart';
import 'package:neurolens/features/memory/data/ocr_service.dart';
import 'package:neurolens/features/memory/data/pdf_import_service.dart';
import 'package:neurolens/features/memory/data/pdf_picker_service.dart';
import 'package:neurolens/features/memory/data/pdf_text_extractor_service.dart';
import 'package:neurolens/features/memory/data/repositories/gallery_repository_impl.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart';
import 'package:neurolens/features/memory/providers/memory_filter_provider.dart';
import 'package:neurolens/features/memory/data/photo_import_service.dart';
import 'package:neurolens/features/memory/data/photo_picker_service.dart';
import 'package:neurolens/features/memory/data/image_content_classifier.dart';
import 'package:neurolens/features/memory/data/local_image_labeling_service.dart';

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

final imageContentClassifierProvider = Provider<ImageContentClassifier>((ref) {
  return const ImageContentClassifier();
});

final photoPickerServiceProvider = Provider<PhotoPickerService>((ref) {
  return const PhotoPickerService();
});

final localImageLabelingServiceProvider =
    Provider<LocalImageLabelingService>((ref) {
  final service = LocalImageLabelingService(
    confidenceThreshold: 0.65,
    maximumLabels: 3,
  );

  ref.onDispose(service.dispose);

  return service;
});

final photoImportServiceProvider = Provider<PhotoImportService>((ref) {
  return PhotoImportService(
    memoryRepository: ref.watch(memoryRepositoryProvider),
    ocrProcessingService: ref.watch(ocrProcessingServiceProvider),
    imageContentClassifier: ref.watch(imageContentClassifierProvider),
    imageLabelingService: ref.watch(
      localImageLabelingServiceProvider,
    ),
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
  final rawQuery = ref.watch(memorySearchQueryProvider);
  final filter = ref.watch(memoryFilterProvider);

  return timeline.whenData((memories) {
    final filteredByType = memories.where((memory) {
      return switch (filter) {
        MemoryFilter.all => true,
        MemoryFilter.images => memory.type == 'image',
        MemoryFilter.notes => memory.type == 'note',
        MemoryFilter.pdfs => memory.type == 'pdf',
      };
    }).toList();

    final normalizedQuery = _normalizeText(rawQuery);

    if (normalizedQuery.isEmpty) {
      return filteredByType;
    }

    final queryTokens = _tokenizeQuery(normalizedQuery);

    final scoredMemories = filteredByType
        .map(
          (memory) => _ScoredMemory(
            memory: memory,
            score: _calculateKeywordScore(
              memory: memory,
              normalizedQuery: normalizedQuery,
              queryTokens: queryTokens,
            ),
          ),
        )
        .where((result) => result.score > 0)
        .toList()
      ..sort((first, second) {
        final scoreComparison = second.score.compareTo(first.score);

        if (scoreComparison != 0) {
          return scoreComparison;
        }

        return second.memory.createdAt.compareTo(
          first.memory.createdAt,
        );
      });

    return scoredMemories
        .map((result) => result.memory)
        .toList(growable: false);
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

double _calculateKeywordScore({
  required Memory memory,
  required String normalizedQuery,
  required List<String> queryTokens,
}) {
  final normalizedTitle = _normalizeText(memory.title);
  final normalizedContent = _normalizeText(memory.content ?? '');
  final normalizedCaption = _normalizeText(memory.visionCaption ?? '');
  final normalizedScene = _normalizeText(memory.visionScene ?? '');
  final normalizedObjects = _normalizeText(memory.visionObjects ?? '');
  final normalizedKeywords = _normalizeText(memory.visionKeywords ?? '');
  final normalizedColors = _normalizeText(memory.visionColors ?? '');

  final visionSearchText = [
    normalizedCaption,
    normalizedScene,
    normalizedObjects,
    normalizedKeywords,
    normalizedColors,
  ].where((value) => value.isNotEmpty).join(' ');

  var score = 0.0;

  // Exact phrase matches.
  if (normalizedTitle.contains(normalizedQuery)) {
    score += 10;
  }

  if (normalizedContent.contains(normalizedQuery)) {
    score += 6;
  }

  if (normalizedKeywords.contains(normalizedQuery)) {
    score += 9;
  }

  if (normalizedObjects.contains(normalizedQuery)) {
    score += 8;
  }

  if (normalizedCaption.contains(normalizedQuery)) {
    score += 7;
  }

  if (normalizedScene.contains(normalizedQuery)) {
    score += 5;
  }

  if (normalizedColors.contains(normalizedQuery)) {
    score += 4;
  }

  // Individual word matches.
  for (final token in queryTokens) {
    if (normalizedTitle.contains(token)) {
      score += 3;
    }

    if (normalizedContent.contains(token)) {
      score += 1.5;
    }

    if (normalizedKeywords.contains(token)) {
      score += 3;
    }

    if (normalizedObjects.contains(token)) {
      score += 2.5;
    }

    if (normalizedCaption.contains(token)) {
      score += 2;
    }

    if (normalizedScene.contains(token)) {
      score += 1.5;
    }

    if (normalizedColors.contains(token)) {
      score += 1;
    }
  }

  // Reward memories that match most query words.
  if (queryTokens.isNotEmpty) {
    final matchedTokens = queryTokens.where((token) {
      return normalizedTitle.contains(token) ||
          normalizedContent.contains(token) ||
          visionSearchText.contains(token);
    }).length;

    final coverage = matchedTokens / queryTokens.length;
    score += coverage * 5;
  }

  return score;
}

String _normalizeText(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

List<String> _tokenizeQuery(String query) {
  const noiseWords = {
    'a',
    'an',
    'the',
    'show',
    'find',
    'search',
    'please',
    'me',
    'my',
    'where',
    'is',
    'are',
    'was',
    'were',
    'of',
    'for',
    'to',
    'from',
    'in',
    'on',
    'with',
    'about',
    'photo',
    'photos',
    'image',
    'images',
    'memory',
    'memories',
  };

  final tokens = query
      .split(' ')
      .where((token) => token.length > 1)
      .where((token) => !noiseWords.contains(token))
      .toSet()
      .toList();

  // Avoid losing the entire query if it only contains ignored words.
  if (tokens.isEmpty && query.isNotEmpty) {
    return query.split(' ').where((token) => token.isNotEmpty).toList();
  }

  return tokens;
}

class _ScoredMemory {
  const _ScoredMemory({
    required this.memory,
    required this.score,
  });

  final Memory memory;
  final double score;
}