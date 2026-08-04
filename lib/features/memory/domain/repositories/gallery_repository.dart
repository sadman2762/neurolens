import 'package:neurolens/features/memory/domain/models/memory.dart';

abstract class GalleryRepository {
  Future<bool> requestPermission();

  Future<int> getImageCount();

  Future<List<Memory>> getImageBatch({
    required int page,
    int pageSize = 50,
  });
}