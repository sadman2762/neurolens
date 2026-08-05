import 'dart:convert';

import 'package:neurolens/features/memory/data/image_content_classifier.dart';
import 'package:neurolens/features/memory/data/mappers/gallery_asset_mapper.dart';
import 'package:neurolens/features/memory/data/ocr_processing_service.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:neurolens/features/memory/data/vision_service.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class PhotoImportService {
  PhotoImportService({
    required this._memoryRepository,
    required this._ocrProcessingService,
    required this._imageContentClassifier,
    required this._visionService,
    GalleryAssetMapper? galleryAssetMapper,
  }) : _galleryAssetMapper = galleryAssetMapper ?? GalleryAssetMapper();

  final MemoryRepositoryImpl _memoryRepository;
  final OcrProcessingService _ocrProcessingService;
  final ImageContentClassifier _imageContentClassifier;
  final VisionService _visionService;
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

    await _memoryRepository.saveMemories(memories);

    for (var index = 0; index < memories.length; index++) {
      final memory = memories[index];
      final asset = selectedAssets[index];

      try {
        final extractedText = await _ocrProcessingService.processImage(
          memoryId: memory.id,
        );

        final contentType = _imageContentClassifier.classify(extractedText);

        switch (contentType) {
          case ImageContentType.text:
            // Strong OCR result: keep everything local.
            break;

          case ImageContentType.photo:
            // Weak or empty OCR result: use backend vision analysis.
            final metadata = await _visionService.analyzeAsset(
              asset: asset,
            );

            await _memoryRepository.updateMemoryVisionMetadata(
              id: memory.id,
              caption: metadata.caption,
              scene: metadata.scene,
              objects: jsonEncode(metadata.objects),
              keywords: jsonEncode(metadata.keywords),
              colors: jsonEncode(metadata.colors),
              model: metadata.model,
              imageHash: metadata.imageHash,
              processedAt: DateTime.now(),
            );
            break;
        }
      } catch (_) {
        // One failed OCR or vision request must not stop other imports.
      }
    }

    return memories.length;
  }
}