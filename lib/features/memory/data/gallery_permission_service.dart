import 'package:photo_manager/photo_manager.dart';

class GalleryPermissionService {
  static const int batchSize = 50;

  Future<bool> requestPermission() async {
    final permission = await PhotoManager.requestPermissionExtend();
    return permission.hasAccess;
  }

  Future<int> getImageCount() async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) return 0;

    return albums.first.assetCountAsync;
  }

  Future<List<AssetEntity>> getImageBatch({
    required int page,
    int pageSize = batchSize,
  }) async {
    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      onlyAll: true,
    );

    if (albums.isEmpty) return [];

    return albums.first.getAssetListPaged(page: page, size: pageSize);
  }
}
