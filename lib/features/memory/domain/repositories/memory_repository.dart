import 'package:neurolens/features/memory/domain/models/memory.dart';

abstract class MemoryRepository {
  Future<void> saveMemory(Memory memory);

  Future<void> saveMemories(List<Memory> memories);

  Future<int> getMemoryCount();

  Stream<List<Memory>> watchAllMemories();

  Future<void> updateMemoryContent({
    required String id,
    required String content,
  });

  Future<void> updateMemoryEmbedding({
    required String id,
    required String embedding,
  });
}
