import 'dart:convert';

import 'package:neurolens/features/memory/data/image_content_classifier.dart';
import 'package:neurolens/features/memory/data/local_image_labeling_service.dart';
import 'package:neurolens/features/memory/data/mappers/gallery_asset_mapper.dart';
import 'package:neurolens/features/memory/data/ocr_processing_service.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class PhotoImportService {
  PhotoImportService({
    required this._memoryRepository,
    required this._ocrProcessingService,
    required this._imageContentClassifier,
    required this._imageLabelingService,
    GalleryAssetMapper? galleryAssetMapper,
  }) : _galleryAssetMapper = galleryAssetMapper ?? GalleryAssetMapper();

  final MemoryRepositoryImpl _memoryRepository;
  final OcrProcessingService _ocrProcessingService;
  final ImageContentClassifier _imageContentClassifier;
  final LocalImageLabelingService _imageLabelingService;
  final GalleryAssetMapper _galleryAssetMapper;

  Future<int> importPhotos({required List<AssetEntity> selectedAssets}) async {
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

        final labels = await _imageLabelingService.labelAsset(asset: asset);

        await _memoryRepository.updateMemoryVisionMetadata(
          id: memory.id,
          caption: '',
          scene: contentType.name,
          objects: jsonEncode(labels),
          keywords: jsonEncode(labels),
          colors: '[]',
          model: 'mlkit-image-labeling',
          imageHash: '',
          processedAt: DateTime.now(),
        );
      } catch (_) {
        // One failed OCR or local-labeling task must not stop other imports.
      }
    }

    return memories.length;
  }
}
