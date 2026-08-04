import 'package:neurolens/features/memory/domain/models/memory.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryAssetMapper {
  Memory toMemory(AssetEntity asset) {
    return Memory(
      id: asset.id,
      type: 'image',
      title: asset.title ?? 'Untitled image',
      originalPath: null,
      createdAt: asset.createDateTime,
    );
  }
}