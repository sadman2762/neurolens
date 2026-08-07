import 'package:drift/drift.dart';
import 'package:neurolens/core/database/app_database.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart' as domain;
import 'package:neurolens/features/memory/domain/repositories/memory_repository.dart';

class MemoryRepositoryImpl implements MemoryRepository {
  MemoryRepositoryImpl(this._database);

  final AppDatabase _database;

  @override
  Future<void> saveMemory(domain.Memory memory) {
    return _database.insertMemory(_toCompanion(memory));
  }

  @override
  Future<void> saveMemories(List<domain.Memory> memories) {
    return _database.transaction(() async {
      for (final memory in memories) {
        await _database.insertMemory(_toCompanion(memory));
      }
    });
  }

  @override
  Future<int> getMemoryCount() {
    return _database.getMemoryCount();
  }

  @override
  Stream<List<domain.Memory>> watchAllMemories() {
    return _database.watchAllMemories().map((rows) {
      return rows
          .map(
            (row) => domain.Memory(
              id: row.id,
              type: row.type,
              title: row.title,
              content: row.content,
              embedding: row.embedding,
              originalPath: row.originalPath,
              visionCaption: row.visionCaption,
              visionScene: row.visionScene,
              visionObjects: row.visionObjects,
              visionKeywords: row.visionKeywords,
              visionColors: row.visionColors,
              visionModel: row.visionModel,
              visionImageHash: row.visionImageHash,
              visionProcessedAt: row.visionProcessedAt,
              isFavorite: row.isFavorite,
              createdAt: row.createdAt,
            ),
          )
          .toList(growable: false);
    });
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

  Future<void> updateMemoryVisionMetadata({
    required String id,
    required String caption,
    required String scene,
    required String objects,
    required String keywords,
    required String colors,
    required String model,
    required String imageHash,
    required DateTime processedAt,
  }) {
    return _database.updateMemoryVisionMetadata(
      id: id,
      caption: caption,
      scene: scene,
      objects: objects,
      keywords: keywords,
      colors: colors,
      model: model,
      imageHash: imageHash,
      processedAt: processedAt,
    );
  }

  Future<void> setMemoryFavorite({
    required String id,
    required bool isFavorite,
  }) {
    return _database.setMemoryFavorite(id: id, isFavorite: isFavorite);
  }

  Future<void> toggleMemoryFavorite(domain.Memory memory) {
    return setMemoryFavorite(id: memory.id, isFavorite: !memory.isFavorite);
  }

  @override
  Future<void> deleteMemory(String id) {
    return _database.deleteMemory(id);
  }

  @override
  Future<domain.Memory?> getMemoryById(String id) async {
    final row = await _database.getMemoryById(id);

    if (row == null) {
      return null;
    }

    return domain.Memory(
      id: row.id,
      type: row.type,
      title: row.title,
      content: row.content,
      embedding: row.embedding,
      originalPath: row.originalPath,
      visionCaption: row.visionCaption,
      visionScene: row.visionScene,
      visionObjects: row.visionObjects,
      visionKeywords: row.visionKeywords,
      visionColors: row.visionColors,
      visionModel: row.visionModel,
      visionImageHash: row.visionImageHash,
      visionProcessedAt: row.visionProcessedAt,
      isFavorite: row.isFavorite,
      createdAt: row.createdAt,
    );
  }

  @override
  Future<void> replaceImageMemory({
    required String oldId,
    required String newId,
    required String title,
    required DateTime createdAt,
    required bool isFavorite,
  }) {
    return _database.replaceImageMemory(
      oldId: oldId,
      newId: newId,
      title: title,
      createdAt: createdAt,
      isFavorite: isFavorite,
    );
  }

  static MemoriesCompanion _toCompanion(domain.Memory memory) {
    return MemoriesCompanion(
      id: Value(memory.id),
      type: Value(memory.type),
      title: Value(memory.title),
      content: Value(memory.content),
      embedding: Value(memory.embedding),
      originalPath: Value(memory.originalPath),
      visionCaption: Value(memory.visionCaption),
      visionScene: Value(memory.visionScene),
      visionObjects: Value(memory.visionObjects),
      visionKeywords: Value(memory.visionKeywords),
      visionColors: Value(memory.visionColors),
      visionModel: Value(memory.visionModel),
      visionImageHash: Value(memory.visionImageHash),
      visionProcessedAt: Value(memory.visionProcessedAt),
      isFavorite: Value(memory.isFavorite),
      createdAt: Value(memory.createdAt),
    );
  }
}
