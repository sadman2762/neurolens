import 'dart:convert';

import 'package:neurolens/features/memory/data/image_content_classifier.dart';
import 'package:neurolens/features/memory/data/local_image_labeling_service.dart';
import 'package:neurolens/features/memory/data/mappers/gallery_asset_mapper.dart';
import 'package:neurolens/features/memory/data/ocr_processing_service.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:neurolens/features/people/data/face_processing_service.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class PhotoImportService {
  PhotoImportService({
    required this._memoryRepository,
    required this._ocrProcessingService,
    required this._imageContentClassifier,
    required this._imageLabelingService,
    required this._faceProcessingService,
    GalleryAssetMapper? galleryAssetMapper,
  }) : _galleryAssetMapper =
           galleryAssetMapper ?? GalleryAssetMapper();

  final MemoryRepositoryImpl _memoryRepository;
  final OcrProcessingService _ocrProcessingService;
  final ImageContentClassifier _imageContentClassifier;
  final LocalImageLabelingService _imageLabelingService;
  final FaceProcessingService _faceProcessingService;
  final GalleryAssetMapper _galleryAssetMapper;

  Future<int> importPhotos({
    required List<AssetEntity> selectedAssets,
  }) async {
    if (selectedAssets.isEmpty) {
      return 0;
    }

    final memories = selectedAssets
        .map(_galleryAssetMapper.toMemory)
        .toList(growable: false);

    await _memoryRepository.saveMemories(
      memories,
    );

    for (
      var index = 0;
      index < memories.length;
      index++
    ) {
      final memory = memories[index];
      final asset = selectedAssets[index];

      await _processImportedPhoto(
        memoryId: memory.id,
        asset: asset,
      );
    }

    return memories.length;
  }

  Future<void> _processImportedPhoto({
    required String memoryId,
    required AssetEntity asset,
  }) async {
    String extractedText = '';
    String scene = '';
    List<String> labels = const [];

    // -------------------------------------------------------------------------
    // 1. OCR
    // -------------------------------------------------------------------------

    try {
      extractedText =
          await _ocrProcessingService.processImage(
        memoryId: memoryId,
      );

      final contentType =
          _imageContentClassifier.classify(
        extractedText,
      );

      scene = contentType.name;
    } catch (_) {
      // OCR failure must not stop the remaining
      // local processing pipeline.
    }

    // -------------------------------------------------------------------------
    // 2. Local ML Kit image labeling
    // -------------------------------------------------------------------------

    try {
      labels =
          await _imageLabelingService.labelAsset(
        asset: asset,
      );
    } catch (_) {
      // Image labeling failure must not stop
      // People Search processing.
    }

    // -------------------------------------------------------------------------
    // 3. Store local image metadata
    // -------------------------------------------------------------------------

    try {
      await _memoryRepository.updateMemoryVisionMetadata(
        id: memoryId,
        caption: '',
        scene: scene,
        objects: jsonEncode(labels),
        keywords: jsonEncode(labels),
        colors: '[]',
        model: 'mlkit-image-labeling',
        imageHash: '',
        processedAt: DateTime.now(),
      );
    } catch (_) {
      // Metadata failure must not stop face processing.
    }

    // -------------------------------------------------------------------------
    // 4. People Search
    //
    // Photo
    //   ↓
    // ML Kit face detection
    //   ↓
    // Face crop
    //   ↓
    // EdgeFace embedding
    //   ↓
    // Cosine similarity
    //   ↓
    // Existing person / new cluster
    //   ↓
    // Save FaceEmbedding + MemoryPeople
    // -------------------------------------------------------------------------

    await _processFaces(
      memoryId: memoryId,
      asset: asset,
    );
  }

  Future<void> _processFaces({
    required String memoryId,
    required AssetEntity asset,
  }) async {
    try {
      final file = await asset.file;

      if (file == null) {
        return;
      }

      await _faceProcessingService.processImage(
        memoryId: memoryId,
        imagePath: file.path,
      );
    } catch (_) {
      // A face-recognition failure must never prevent
      // the photo itself from being imported successfully.
    }
  }
}