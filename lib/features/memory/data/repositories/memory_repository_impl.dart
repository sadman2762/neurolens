import 'package:drift/drift.dart';
import 'package:neurolens/core/database/app_database.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart' as domain;
import 'package:neurolens/features/memory/domain/repositories/memory_repository.dart';

class MemoryRepositoryImpl implements MemoryRepository {
  MemoryRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<void> saveMemory(domain.Memory memory) {
    return _database.insertMemory(
      MemoriesCompanion(
        id: Value(memory.id),
        type: Value(memory.type),
        title: Value(memory.title),
        content: Value(memory.content),
        originalPath: Value(memory.originalPath),
        createdAt: Value(memory.createdAt),
      ),
    );
  }

  @override
  Future<void> saveMemories(List<domain.Memory> memories) {
    return _database.transaction(() async {
      for (final memory in memories) {
        await _database.insertMemory(
          MemoriesCompanion(
            id: Value(memory.id),
            type: Value(memory.type),
            title: Value(memory.title),
            content: Value(memory.content),
            embedding: Value(memory.embedding),
            originalPath: Value(memory.originalPath),
            createdAt: Value(memory.createdAt),
          ),
        );
      }
    });
  }

  @override
  Future<int> getMemoryCount() {
    return _database.getMemoryCount();
  }

  @override
  Stream<List<domain.Memory>> watchAllMemories() {
    return _database.watchAllMemories().map(
      (rows) => rows
          .map(
            (row) => domain.Memory(
              id: row.id,
              type: row.type,
              title: row.title,
              content: row.content,
              embedding: row.embedding,
              originalPath: row.originalPath,
              createdAt: row.createdAt,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> updateMemoryContent({
    required String id,
    required String content,
  }) {
    return _database.updateMemoryContent(id: id, content: content);
  }

  @override
  Future<void> updateMemoryEmbedding({
    required String id,
    required String embedding,
  }) {
    return _database.updateMemoryEmbedding(id: id, embedding: embedding);
  }

  @override
  Future<void> deleteMemory(String id) {
    return _database.deleteMemory(id);
  }
}
