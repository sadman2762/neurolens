import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neurolens/core/database/database_provider.dart';
import 'package:neurolens/features/memory/data/gallery_sync_service.dart';
import 'package:neurolens/features/memory/data/image_content_classifier.dart';
import 'package:neurolens/features/memory/data/local_image_labeling_service.dart';
import 'package:neurolens/features/memory/data/ocr_processing_service.dart';
import 'package:neurolens/features/memory/data/ocr_service.dart';
import 'package:neurolens/features/memory/data/pdf_import_service.dart';
import 'package:neurolens/features/memory/data/pdf_picker_service.dart';
import 'package:neurolens/features/memory/data/pdf_text_extractor_service.dart';
import 'package:neurolens/features/memory/data/photo_import_service.dart';
import 'package:neurolens/features/memory/data/photo_picker_service.dart';
import 'package:neurolens/features/memory/data/repositories/gallery_repository_impl.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart';
import 'package:neurolens/features/memory/providers/memory_filter_provider.dart';
import 'package:neurolens/features/people/data/face_alignment_service.dart';
import 'package:neurolens/features/people/data/face_detection_service.dart';
import 'package:neurolens/features/people/data/face_embedding_service.dart';
import 'package:neurolens/features/people/data/face_matching_service.dart';
import 'package:neurolens/features/people/data/face_processing_service.dart';

// =============================================================================
// GALLERY
// =============================================================================

final galleryRepositoryProvider =
    Provider<GalleryRepositoryImpl>((ref) {
  return GalleryRepositoryImpl();
});

// =============================================================================
// MEMORY REPOSITORY
// =============================================================================

final memoryRepositoryProvider =
    Provider<MemoryRepositoryImpl>((ref) {
  final database = ref.watch(
    appDatabaseProvider,
  );

  return MemoryRepositoryImpl(
    database,
  );
});

// =============================================================================
// OCR
// =============================================================================

final ocrServiceProvider =
    Provider<OcrService>((ref) {
  final service = OcrService();

  ref.onDispose(
    service.dispose,
  );

  return service;
});

final ocrProcessingServiceProvider =
    Provider<OcrProcessingService>((ref) {
  final ocrService = ref.watch(
    ocrServiceProvider,
  );

  final memoryRepository = ref.watch(
    memoryRepositoryProvider,
  );

  return OcrProcessingService(
    ocrService: ocrService,
    memoryRepository: memoryRepository,
  );
});

// =============================================================================
// IMAGE CLASSIFICATION
// =============================================================================

final imageContentClassifierProvider =
    Provider<ImageContentClassifier>((ref) {
  return const ImageContentClassifier();
});

// =============================================================================
// PHOTO PICKER
// =============================================================================

final photoPickerServiceProvider =
    Provider<PhotoPickerService>((ref) {
  return const PhotoPickerService();
});

// =============================================================================
// LOCAL IMAGE LABELING
// =============================================================================

final localImageLabelingServiceProvider =
    Provider<LocalImageLabelingService>((ref) {
  final service = LocalImageLabelingService(
    confidenceThreshold: 0.65,
    maximumLabels: 3,
  );

  ref.onDispose(
    service.dispose,
  );

  return service;
});

// =============================================================================
// PEOPLE SEARCH / FACE RECOGNITION
// =============================================================================

// -----------------------------------------------------------------------------
// Face detection
// -----------------------------------------------------------------------------

final faceDetectionServiceProvider =
    Provider<FaceDetectionService>((ref) {
  final service = FaceDetectionService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// -----------------------------------------------------------------------------
// Face alignment
// -----------------------------------------------------------------------------

final faceAlignmentServiceProvider =
    Provider<FaceAlignmentService>((ref) {
  return const FaceAlignmentService();
});

// -----------------------------------------------------------------------------
// Face embedding
// -----------------------------------------------------------------------------

final faceEmbeddingServiceProvider =
    Provider<FaceEmbeddingService>((ref) {
  return FaceEmbeddingService();
});

// -----------------------------------------------------------------------------
// Face matching
// -----------------------------------------------------------------------------

final faceMatchingServiceProvider =
    Provider<FaceMatchingService>((ref) {
  return const FaceMatchingService(
    matchThreshold: 0.45,
    strongMatchThreshold: 0.60,
  );
});

// -----------------------------------------------------------------------------
// Complete face pipeline
//
// Photo
//   ↓
// ML Kit face detection + landmarks
//   ↓
// 5-point alignment
//   ↓
// EdgeFace embedding
//   ↓
// Cosine similarity
//   ↓
// Existing person / new person
// -----------------------------------------------------------------------------

final faceProcessingServiceProvider =
    Provider<FaceProcessingService>((ref) {
  return FaceProcessingService(
    memoryRepository: ref.watch(
      memoryRepositoryProvider,
    ),
    faceDetectionService: ref.watch(
      faceDetectionServiceProvider,
    ),
    faceEmbeddingService: ref.watch(
      faceEmbeddingServiceProvider,
    ),
    faceMatchingService: ref.watch(
      faceMatchingServiceProvider,
    ),
    faceAlignmentService: ref.watch(
      faceAlignmentServiceProvider,
    ),
  );
});

// =============================================================================
// PHOTO IMPORT
// =============================================================================

final photoImportServiceProvider =
    Provider<PhotoImportService>((ref) {
  return PhotoImportService(
    memoryRepository: ref.watch(
      memoryRepositoryProvider,
    ),
    ocrProcessingService: ref.watch(
      ocrProcessingServiceProvider,
    ),
    imageContentClassifier: ref.watch(
      imageContentClassifierProvider,
    ),
    imageLabelingService: ref.watch(
      localImageLabelingServiceProvider,
    ),
    faceProcessingService: ref.watch(
      faceProcessingServiceProvider,
    ),
  );
});

// =============================================================================
// GALLERY SYNC
// =============================================================================

final gallerySyncServiceProvider =
    Provider<GallerySyncService>((ref) {
  final galleryRepository = ref.watch(
    galleryRepositoryProvider,
  );

  final memoryRepository = ref.watch(
    memoryRepositoryProvider,
  );

  final ocrProcessingService = ref.watch(
    ocrProcessingServiceProvider,
  );

  return GallerySyncService(
    galleryRepository: galleryRepository,
    memoryRepository: memoryRepository,
    ocrProcessingService: ocrProcessingService,
  );
});

// =============================================================================
// MEMORY TIMELINE
// =============================================================================

final memoryTimelineProvider =
    StreamProvider<List<Memory>>((ref) {
  final repository = ref.watch(
    memoryRepositoryProvider,
  );

  return repository.watchAllMemories();
});

// =============================================================================
// PERSON NAME SEARCH INDEX
//
// Builds:
//
// memoryId -> {"sadman", "john", ...}
//
// When updatePersonName() changes a person name,
// watchAllPeople() emits again and this index rebuilds automatically.
// =============================================================================

final peopleSearchIndexProvider =
    StreamProvider<Map<String, Set<String>>>((ref) {
  final repository = ref.watch(
    memoryRepositoryProvider,
  );

  return repository.watchAllPeople().asyncMap(
    (people) async {
      final index =
          <String, Set<String>>{};

      for (final person in people) {
        final rawName =
            person.name?.trim() ?? '';

        if (rawName.isEmpty) {
          continue;
        }

        final normalizedName =
            _normalizeText(
          rawName,
        );

        if (normalizedName.isEmpty) {
          continue;
        }

        final relationships =
            await repository.getMemoriesForPerson(
          person.id,
        );

        for (final relationship in relationships) {
          index
              .putIfAbsent(
                relationship.memoryId,
                () => <String>{},
              )
              .add(
                normalizedName,
              );
        }
      }

      return index;
    },
  );
});

// =============================================================================
// SEARCH
// =============================================================================

final memorySearchQueryProvider =
    StateProvider<String>(
  (ref) => '',
);

final filteredMemoryTimelineProvider =
    Provider<AsyncValue<List<Memory>>>((ref) {
  final timeline = ref.watch(
    memoryTimelineProvider,
  );

  final peopleIndex = ref.watch(
    peopleSearchIndexProvider,
  );

  final rawQuery = ref.watch(
    memorySearchQueryProvider,
  );

  final filter = ref.watch(
    memoryFilterProvider,
  );

  // Wait until both the memory timeline and
  // the person-name index are ready.
  return timeline.when(
    loading: () =>
        const AsyncValue<List<Memory>>.loading(),
    error: (error, stackTrace) =>
        AsyncValue<List<Memory>>.error(
      error,
      stackTrace,
    ),
    data: (memories) {
      return peopleIndex.when(
        loading: () =>
            const AsyncValue<List<Memory>>.loading(),
        error: (error, stackTrace) =>
            AsyncValue<List<Memory>>.error(
          error,
          stackTrace,
        ),
        data: (personNamesByMemory) {
          final filteredByType =
              memories.where(
            (memory) {
              return switch (filter) {
                MemoryFilter.all => true,
                MemoryFilter.images =>
                  memory.type == 'image',
                MemoryFilter.notes =>
                  memory.type == 'note',
                MemoryFilter.pdfs =>
                  memory.type == 'pdf',
              };
            },
          ).toList();

          final normalizedQuery =
              _normalizeText(
            rawQuery,
          );

          if (normalizedQuery.isEmpty) {
            return AsyncValue.data(
              filteredByType,
            );
          }

          final queryTokens =
              _tokenizeQuery(
            normalizedQuery,
          );

          final scoredMemories =
              filteredByType
                  .map(
                    (memory) {
                      final personNames =
                          personNamesByMemory[
                                  memory.id] ??
                              const <String>{};

                      return _ScoredMemory(
                        memory: memory,
                        score:
                            _calculateKeywordScore(
                          memory: memory,
                          normalizedQuery:
                              normalizedQuery,
                          queryTokens:
                              queryTokens,
                          personNames:
                              personNames,
                        ),
                      );
                    },
                  )
                  .where(
                    (result) =>
                        result.score > 0,
                  )
                  .toList()
                ..sort(
                  (first, second) {
                    final scoreComparison =
                        second.score.compareTo(
                      first.score,
                    );

                    if (scoreComparison != 0) {
                      return scoreComparison;
                    }

                    return second
                        .memory.createdAt
                        .compareTo(
                      first.memory.createdAt,
                    );
                  },
                );

          return AsyncValue.data(
            scoredMemories
                .map(
                  (result) =>
                      result.memory,
                )
                .toList(
                  growable: false,
                ),
          );
        },
      );
    },
  );
});

// =============================================================================
// PDF
// =============================================================================

final pdfPickerServiceProvider =
    Provider<PdfPickerService>((ref) {
  return PdfPickerService();
});

final pdfTextExtractorServiceProvider =
    Provider<PdfTextExtractorService>((ref) {
  return PdfTextExtractorService();
});

final pdfImportServiceProvider =
    Provider<PdfImportService>((ref) {
  final pickerService = ref.watch(
    pdfPickerServiceProvider,
  );

  final textExtractorService = ref.watch(
    pdfTextExtractorServiceProvider,
  );

  final memoryRepository = ref.watch(
    memoryRepositoryProvider,
  );

  return PdfImportService(
    pickerService: pickerService,
    textExtractorService:
        textExtractorService,
    memoryRepository:
        memoryRepository,
  );
});

// =============================================================================
// SEARCH SCORING
// =============================================================================

double _calculateKeywordScore({
  required Memory memory,
  required String normalizedQuery,
  required List<String> queryTokens,
  required Set<String> personNames,
}) {
  final normalizedTitle =
      _normalizeText(
    memory.title,
  );

  final normalizedContent =
      _normalizeText(
    memory.content ?? '',
  );

  final normalizedCaption =
      _normalizeText(
    memory.visionCaption ?? '',
  );

  final normalizedScene =
      _normalizeText(
    memory.visionScene ?? '',
  );

  final normalizedObjects =
      _normalizeText(
    memory.visionObjects ?? '',
  );

  final normalizedKeywords =
      _normalizeText(
    memory.visionKeywords ?? '',
  );

  final normalizedColors =
      _normalizeText(
    memory.visionColors ?? '',
  );

  final peopleSearchText =
      personNames.join(' ');

  final visionSearchText = [
    normalizedCaption,
    normalizedScene,
    normalizedObjects,
    normalizedKeywords,
    normalizedColors,
    peopleSearchText,
  ].where(
    (value) => value.isNotEmpty,
  ).join(' ');

  var score = 0.0;

  // ---------------------------------------------------------------------------
  // PERSON NAME MATCHES
  //
  // Person names intentionally receive the highest score.
  //
  // Search:
  // Sadman
  //
  // should rank linked photos before generic OCR/vision matches.
  // ---------------------------------------------------------------------------

  for (final personName in personNames) {
    if (personName == normalizedQuery) {
      score += 20;
    } else if (personName.contains(
      normalizedQuery,
    )) {
      score += 16;
    } else if (normalizedQuery.contains(
      personName,
    )) {
      score += 14;
    }
  }

  // ---------------------------------------------------------------------------
  // Exact phrase matches
  // ---------------------------------------------------------------------------

  if (normalizedTitle.contains(
    normalizedQuery,
  )) {
    score += 10;
  }

  if (normalizedContent.contains(
    normalizedQuery,
  )) {
    score += 6;
  }

  if (normalizedKeywords.contains(
    normalizedQuery,
  )) {
    score += 9;
  }

  if (normalizedObjects.contains(
    normalizedQuery,
  )) {
    score += 8;
  }

  if (normalizedCaption.contains(
    normalizedQuery,
  )) {
    score += 7;
  }

  if (normalizedScene.contains(
    normalizedQuery,
  )) {
    score += 5;
  }

  if (normalizedColors.contains(
    normalizedQuery,
  )) {
    score += 4;
  }

  // ---------------------------------------------------------------------------
  // Individual token matches
  // ---------------------------------------------------------------------------

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

    if (peopleSearchText.contains(token)) {
      score += 6;
    }
  }

  // ---------------------------------------------------------------------------
  // Query coverage
  // ---------------------------------------------------------------------------

  if (queryTokens.isNotEmpty) {
    final matchedTokens =
        queryTokens.where(
      (token) {
        return normalizedTitle.contains(
              token,
            ) ||
            normalizedContent.contains(
              token,
            ) ||
            visionSearchText.contains(
              token,
            );
      },
    ).length;

    final coverage =
        matchedTokens /
        queryTokens.length;

    score += coverage * 5;
  }

  return score;
}

// =============================================================================
// TEXT NORMALIZATION
// =============================================================================

String _normalizeText(
  String value,
) {
  return value
      .toLowerCase()
      .replaceAll(
        RegExp(
          r'[^\p{L}\p{N}\s]',
          unicode: true,
        ),
        ' ',
      )
      .replaceAll(
        RegExp(
          r'\s+',
        ),
        ' ',
      )
      .trim();
}

List<String> _tokenizeQuery(
  String query,
) {
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
      .where(
        (token) =>
            token.length > 1,
      )
      .where(
        (token) =>
            !noiseWords.contains(
          token,
        ),
      )
      .toSet()
      .toList();

  if (tokens.isEmpty &&
      query.isNotEmpty) {
    return query
        .split(' ')
        .where(
          (token) =>
              token.isNotEmpty,
        )
        .toList();
  }

  return tokens;
}

// =============================================================================
// SCORED MEMORY
// =============================================================================

class _ScoredMemory {
  const _ScoredMemory({
    required this.memory,
    required this.score,
  });

  final Memory memory;
  final double score;
}