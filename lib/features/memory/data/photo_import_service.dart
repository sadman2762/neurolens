import 'package:neurolens/features/memory/data/mappers/gallery_asset_mapper.dart';
import 'package:neurolens/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class PhotoImportService {
  PhotoImportService({
    required this._memoryRepository,
    GalleryAssetMapper? galleryAssetMapper,
  }) : _galleryAssetMapper = galleryAssetMapper ?? GalleryAssetMapper();

  final MemoryRepositoryImpl _memoryRepository;
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

    return memories.length;
  }
}