import 'package:neurolens/features/memory/domain/models/memory.dart';

abstract class MemoryRepository {
  Future<void> saveMemory(Memory memory);

  Future<void> saveMemories(List<Memory> memories);

  Future<int> getMemoryCount();

  Stream<List<Memory>> watchAllMemories();

  Future<Memory?> getMemoryById(String id);

  Future<void> updateMemoryContent({
    required String id,
    required String content,
  });

  Future<void> updateMemoryEmbedding({
    required String id,
    required String embedding,
  });

  Future<void> replaceImageMemory({
    required String oldId,
    required String newId,
    required String title,
    required DateTime createdAt,
    required bool isFavorite,
  });

  Future<void> deleteMemory(String id);
}
