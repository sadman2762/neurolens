import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:neurolens/core/database/app_database.dart';
import 'package:neurolens/features/memory/domain/models/memory.dart'
    as domain;
import 'package:neurolens/features/memory/domain/repositories/memory_repository.dart';

class MemoryRepositoryImpl implements MemoryRepository {
  MemoryRepositoryImpl(this._database);

  final AppDatabase _database;

  // ---------------------------------------------------------------------------
  // Memories
  // ---------------------------------------------------------------------------

  @override
  Future<void> saveMemory(
    domain.Memory memory,
  ) {
    return _database.insertMemory(
      _toCompanion(memory),
    );
  }

  @override
  Future<void> saveMemories(
    List<domain.Memory> memories,
  ) {
    return _database.transaction(() async {
      for (final memory in memories) {
        await _database.insertMemory(
          _toCompanion(memory),
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
      (rows) {
        return rows
            .map(_toDomainMemory)
            .toList(growable: false);
      },
    );
  }

  @override
  Future<void> updateMemoryContent({
    required String id,
    required String content,
  }) {
    return _database.updateMemoryContent(
      id: id,
      content: content,
    );
  }

  @override
  Future<void> updateMemoryEmbedding({
    required String id,
    required String embedding,
  }) {
    return _database.updateMemoryEmbedding(
      id: id,
      embedding: embedding,
    );
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
    return _database.setMemoryFavorite(
      id: id,
      isFavorite: isFavorite,
    );
  }

  Future<void> toggleMemoryFavorite(
    domain.Memory memory,
  ) {
    return setMemoryFavorite(
      id: memory.id,
      isFavorite: !memory.isFavorite,
    );
  }

  @override
  Future<void> deleteMemory(
    String id,
  ) {
    return _database.deleteMemory(id);
  }

  @override
  Future<domain.Memory?> getMemoryById(
    String id,
  ) async {
    final row = await _database.getMemoryById(
      id,
    );

    if (row == null) {
      return null;
    }

    return _toDomainMemory(row);
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

  // ---------------------------------------------------------------------------
  // People
  // ---------------------------------------------------------------------------

  Future<void> savePerson({
    required String id,
    String? name,
    String? coverFacePath,
    String? clusterId,
    DateTime? createdAt,
  }) {
    final now = DateTime.now();

    return _database.insertPerson(
      PeopleCompanion(
        id: Value(id),
        name: Value(name),
        coverFacePath: Value(
          coverFacePath,
        ),
        clusterId: Value(
          clusterId,
        ),
        createdAt: Value(
          createdAt ?? now,
        ),
        updatedAt: Value(now),
      ),
    );
  }

  Future<List<PeopleData>> getAllPeople() {
    return _database.getAllPeople();
  }

  Stream<List<PeopleData>> watchAllPeople() {
    return _database.watchAllPeople();
  }

  Future<PeopleData?> getPersonById(
    String personId,
  ) {
    return _database.getPersonById(
      personId,
    );
  }

  Future<List<PeopleData>> getNamedPeople() {
    return _database.getNamedPeople();
  }

  Future<List<PeopleData>>
      getUnnamedPeople() {
    return _database.getUnnamedPeople();
  }

  Future<void> updatePersonName({
    required String personId,
    required String name,
  }) {
    return _database.updatePersonName(
      personId: personId,
      name: name,
    );
  }

  Future<void> updatePersonCoverFace({
    required String personId,
    required String? coverFacePath,
  }) {
    return _database.updatePersonCoverFace(
      personId: personId,
      coverFacePath: coverFacePath,
    );
  }

  Future<void> deletePerson(
    String personId,
  ) {
    return _database.deletePerson(
      personId,
    );
  }

  // ---------------------------------------------------------------------------
  // Face embeddings
  // ---------------------------------------------------------------------------

  Future<void> saveFaceEmbedding({
    required String id,
    required String memoryId,
    String? personId,
    required String embedding,
    required String model,
    required int embeddingDimension,
    required double boundingLeft,
    required double boundingTop,
    required double boundingWidth,
    required double boundingHeight,
    double? detectionConfidence,
    String? faceCropPath,
    String? faceHash,
    DateTime? createdAt,
  }) {
    return _database.insertFaceEmbedding(
      FaceEmbeddingsCompanion(
        id: Value(id),
        memoryId: Value(memoryId),
        personId: Value(personId),
        embedding: Value(embedding),
        model: Value(model),
        embeddingDimension: Value(
          embeddingDimension,
        ),
        boundingLeft: Value(
          boundingLeft,
        ),
        boundingTop: Value(
          boundingTop,
        ),
        boundingWidth: Value(
          boundingWidth,
        ),
        boundingHeight: Value(
          boundingHeight,
        ),
        detectionConfidence: Value(
          detectionConfidence,
        ),
        faceCropPath: Value(
          faceCropPath,
        ),
        faceHash: Value(
          faceHash,
        ),
        createdAt: Value(
          createdAt ?? DateTime.now(),
        ),
      ),
    );
  }

  Future<List<FaceEmbedding>>
      getAllFaceEmbeddings() {
    return _database.getAllFaceEmbeddings();
  }

  Future<FaceEmbedding?>
      getFaceEmbeddingById(
    String faceId,
  ) {
    return _database.getFaceEmbeddingById(
      faceId,
    );
  }

  Future<List<FaceEmbedding>>
      getFaceEmbeddingsForMemory(
    String memoryId,
  ) {
    return _database.getFaceEmbeddingsForMemory(
      memoryId,
    );
  }

  Future<List<FaceEmbedding>>
      getFaceEmbeddingsForPerson(
    String personId,
  ) {
    return _database.getFaceEmbeddingsForPerson(
      personId,
    );
  }

  Future<List<FaceEmbedding>>
      getAssignedFaceEmbeddings() {
    return _database.getAssignedFaceEmbeddings();
  }

  Future<List<FaceEmbedding>>
      getUnassignedFaceEmbeddings() {
    return _database
        .getUnassignedFaceEmbeddings();
  }

  Future<bool> hasProcessedFacesForMemory(
    String memoryId,
  ) {
    return _database.hasProcessedFacesForMemory(
      memoryId,
    );
  }

  Future<void> assignFaceToPerson({
    required String faceId,
    required String personId,
  }) {
    return _database.assignFaceToPerson(
      faceId: faceId,
      personId: personId,
    );
  }

  Future<void> unassignFaceFromPerson({
    required String faceId,
  }) {
    return _database.unassignFaceFromPerson(
      faceId: faceId,
    );
  }

  Future<void> deleteFaceEmbedding(
    String faceId,
  ) {
    return _database.deleteFaceEmbedding(
      faceId,
    );
  }

  Future<void> deleteFaceEmbeddingsForMemory(
    String memoryId,
  ) {
    return _database.deleteFaceEmbeddingsForMemory(
      memoryId,
    );
  }

  // ---------------------------------------------------------------------------
  // Face embedding serialization
  // ---------------------------------------------------------------------------

  String encodeFaceEmbedding(
    List<double> embedding,
  ) {
    return jsonEncode(embedding);
  }

  List<double> decodeFaceEmbedding(
    String encodedEmbedding,
  ) {
    try {
      final decoded =
          jsonDecode(encodedEmbedding);

      if (decoded is! List) {
        throw const FormatException(
          'Face embedding is not a JSON list.',
        );
      }

      return decoded
          .map((value) {
            if (value is! num) {
              throw const FormatException(
                'Face embedding contains a '
                'non-numeric value.',
              );
            }

            return value.toDouble();
          })
          .toList(growable: false);
    } catch (error) {
      throw FaceEmbeddingStorageException(
        'Unable to decode face embedding: '
        '$error',
      );
    }
  }

  List<double> decodeFaceEmbeddingRow(
    FaceEmbedding face,
  ) {
    return decodeFaceEmbedding(
      face.embedding,
    );
  }

  // ---------------------------------------------------------------------------
  // Memory ↔ People
  // ---------------------------------------------------------------------------

  Future<void> linkMemoryToPerson({
    required String memoryId,
    required String personId,
    double? similarity,
  }) {
    return _database.linkMemoryToPerson(
      memoryId: memoryId,
      personId: personId,
      similarity: similarity,
    );
  }

  Future<void> unlinkMemoryFromPerson({
    required String memoryId,
    required String personId,
  }) {
    return _database.unlinkMemoryFromPerson(
      memoryId: memoryId,
      personId: personId,
    );
  }

  Future<void> clearPeopleForMemory(
    String memoryId,
  ) {
    return _database.clearPeopleForMemory(
      memoryId,
    );
  }

  Future<List<MemoryPeopleData>>
      getPeopleForMemory(
    String memoryId,
  ) {
    return _database.getPeopleForMemory(
      memoryId,
    );
  }

  Future<List<MemoryPeopleData>>
      getMemoriesForPerson(
    String personId,
  ) {
    return _database.getMemoriesForPerson(
      personId,
    );
  }

  Future<List<domain.Memory>>
      getMemoryRowsForPerson(
    String personId,
  ) async {
    final rows =
        await _database.getMemoryRowsForPerson(
      personId,
    );

    return rows
        .map(_toDomainMemory)
        .toList(growable: false);
  }

  // ---------------------------------------------------------------------------
  // Mapping
  // ---------------------------------------------------------------------------

  static domain.Memory _toDomainMemory(
    Memory row,
  ) {
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
      visionProcessedAt:
          row.visionProcessedAt,
      isFavorite: row.isFavorite,
      createdAt: row.createdAt,
    );
  }

  static MemoriesCompanion _toCompanion(
    domain.Memory memory,
  ) {
    return MemoriesCompanion(
      id: Value(memory.id),
      type: Value(memory.type),
      title: Value(memory.title),
      content: Value(memory.content),
      embedding: Value(memory.embedding),
      originalPath: Value(
        memory.originalPath,
      ),
      visionCaption: Value(
        memory.visionCaption,
      ),
      visionScene: Value(
        memory.visionScene,
      ),
      visionObjects: Value(
        memory.visionObjects,
      ),
      visionKeywords: Value(
        memory.visionKeywords,
      ),
      visionColors: Value(
        memory.visionColors,
      ),
      visionModel: Value(
        memory.visionModel,
      ),
      visionImageHash: Value(
        memory.visionImageHash,
      ),
      visionProcessedAt: Value(
        memory.visionProcessedAt,
      ),
      isFavorite: Value(
        memory.isFavorite,
      ),
      createdAt: Value(
        memory.createdAt,
      ),
    );
  }
}

class FaceEmbeddingStorageException
    implements Exception {
  const FaceEmbeddingStorageException(
    this.message,
  );

  final String message;

  @override
  String toString() => message;
}