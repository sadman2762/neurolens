import 'package:neurolens/features/memory/data/gallery_permission_service.dart';
import 'package:neurolens/features/memory/data/mappers/gallery_asset_mapper.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart';
import 'package:neurolens/features/memory/domain/repositories/gallery_repository.dart';

class GalleryRepositoryImpl implements GalleryRepository {
  GalleryRepositoryImpl({
    GalleryPermissionService? permissionService,
    GalleryAssetMapper? mapper,
  })  : _permissionService =
            permissionService ?? GalleryPermissionService(),
        _mapper = mapper ?? GalleryAssetMapper();

  final GalleryPermissionService _permissionService;
  final GalleryAssetMapper _mapper;

  @override
  Future<bool> requestPermission() {
    return _permissionService.requestPermission();
  }

  @override
  Future<int> getImageCount() {
    return _permissionService.getImageCount();
  }

  @override
  Future<List<Memory>> getImageBatch({
    required int page,
    int pageSize = 50,
  }) async {
    final assets = await _permissionService.getImageBatch(
      page: page,
      pageSize: pageSize,
    );

    return assets.map(_mapper.toMemory).toList();
  }
}