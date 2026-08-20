import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Memories extends Table {
  TextColumn get id => text()();

  TextColumn get type => text()();

  TextColumn get title => text()();

  TextColumn get content => text().nullable()();

  TextColumn get embedding => text().nullable()();

  TextColumn get originalPath => text().nullable()();

  TextColumn get visionCaption => text().nullable()();

  TextColumn get visionScene => text().nullable()();

  TextColumn get visionObjects => text().nullable()();

  TextColumn get visionKeywords => text().nullable()();

  TextColumn get visionColors => text().nullable()();

  TextColumn get visionModel => text().nullable()();

  TextColumn get visionImageHash => text().nullable()();

  DateTimeColumn get visionProcessedAt => dateTime().nullable()();

  BoolColumn get isFavorite =>
      boolean().withDefault(const Constant(false))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class People extends Table {
  TextColumn get id => text()();

  TextColumn get name => text().nullable()();

  TextColumn get coverFacePath => text().nullable()();

  TextColumn get clusterId => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class FaceEmbeddings extends Table {
  TextColumn get id => text()();

  TextColumn get memoryId =>
      text().references(
        Memories,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get personId =>
      text().nullable().references(
        People,
        #id,
        onDelete: KeyAction.setNull,
      )();

  TextColumn get embedding => text()();

  TextColumn get model => text()();

  IntColumn get embeddingDimension => integer()();

  RealColumn get boundingLeft => real()();

  RealColumn get boundingTop => real()();

  RealColumn get boundingWidth => real()();

  RealColumn get boundingHeight => real()();

  RealColumn get detectionConfidence => real().nullable()();

  TextColumn get faceCropPath => text().nullable()();

  TextColumn get faceHash => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class MemoryPeople extends Table {
  TextColumn get memoryId =>
      text().references(
        Memories,
        #id,
        onDelete: KeyAction.cascade,
      )();

  TextColumn get personId =>
      text().references(
        People,
        #id,
        onDelete: KeyAction.cascade,
      )();

  RealColumn get similarity => real().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {
    memoryId,
    personId,
  };
}

@DriftDatabase(
  tables: [
    Memories,
    People,
    FaceEmbeddings,
    MemoryPeople,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
      : super(
          driftDatabase(
            name: 'neurolens',
          ),
        );

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) async {
        await migrator.createAll();
      },
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.addColumn(
            memories,
            memories.content,
          );
        }

        if (from < 3) {
          await migrator.addColumn(
            memories,
            memories.embedding,
          );
        }

        if (from < 4) {
          await migrator.addColumn(
            memories,
            memories.visionCaption,
          );

          await migrator.addColumn(
            memories,
            memories.visionScene,
          );

          await migrator.addColumn(
            memories,
            memories.visionObjects,
          );

          await migrator.addColumn(
            memories,
            memories.visionKeywords,
          );

          await migrator.addColumn(
            memories,
            memories.visionColors,
          );

          await migrator.addColumn(
            memories,
            memories.visionModel,
          );

          await migrator.addColumn(
            memories,
            memories.visionImageHash,
          );

          await migrator.addColumn(
            memories,
            memories.visionProcessedAt,
          );
        }

        if (from < 5) {
          await migrator.addColumn(
            memories,
            memories.isFavorite,
          );
        }

        if (from < 6) {
          await migrator.createTable(
            people,
          );

          await migrator.createTable(
            faceEmbeddings,
          );

          await migrator.createTable(
            memoryPeople,
          );
        }
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Memories
  // ---------------------------------------------------------------------------

  Future<void> insertMemory(
    MemoriesCompanion memory,
  ) {
    return into(memories).insertOnConflictUpdate(
      memory,
    );
  }

  Stream<List<Memory>> watchAllMemories() {
    return (select(memories)
          ..orderBy([
            (table) =>
                OrderingTerm.desc(
                  table.createdAt,
                ),
          ]))
        .watch();
  }

  Future<int> getMemoryCount() async {
    final countExpression =
        memories.id.count();

    final query =
        selectOnly(memories)
          ..addColumns([
            countExpression,
          ]);

    final row =
        await query.getSingle();

    return row.read(
          countExpression,
        ) ??
        0;
  }

  Future<void> updateMemoryContent({
    required String id,
    required String content,
  }) {
    return (update(memories)
          ..where(
            (row) => row.id.equals(id),
          ))
        .write(
      MemoriesCompanion(
        content: Value(content),
      ),
    );
  }

  Future<void> updateMemoryEmbedding({
    required String id,
    required String embedding,
  }) {
    return (update(memories)
          ..where(
            (row) => row.id.equals(id),
          ))
        .write(
      MemoriesCompanion(
        embedding: Value(embedding),
      ),
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
    return (update(memories)
          ..where(
            (row) => row.id.equals(id),
          ))
        .write(
      MemoriesCompanion(
        visionCaption: Value(caption),
        visionScene: Value(scene),
        visionObjects: Value(objects),
        visionKeywords: Value(keywords),
        visionColors: Value(colors),
        visionModel: Value(model),
        visionImageHash: Value(
          imageHash,
        ),
        visionProcessedAt: Value(
          processedAt,
        ),
      ),
    );
  }

  Future<void> setMemoryFavorite({
    required String id,
    required bool isFavorite,
  }) {
    return (update(memories)
          ..where(
            (row) => row.id.equals(id),
          ))
        .write(
      MemoriesCompanion(
        isFavorite: Value(
          isFavorite,
        ),
      ),
    );
  }

  Future<Memory?> getMemoryById(
    String id,
  ) {
    return (select(memories)
          ..where(
            (row) => row.id.equals(id),
          ))
        .getSingleOrNull();
  }

  Future<void> replaceImageMemory({
    required String oldId,
    required String newId,
    required String title,
    required DateTime createdAt,
    required bool isFavorite,
  }) {
    return transaction(() async {
      await into(memories).insert(
        MemoriesCompanion(
          id: Value(newId),
          type: const Value(
            'image',
          ),
          title: Value(title),
          createdAt: Value(
            createdAt,
          ),
          isFavorite: Value(
            isFavorite,
          ),
          content: const Value(
            null,
          ),
          embedding: const Value(
            null,
          ),
          originalPath: const Value(
            null,
          ),
          visionCaption: const Value(
            null,
          ),
          visionScene: const Value(
            null,
          ),
          visionObjects: const Value(
            null,
          ),
          visionKeywords: const Value(
            null,
          ),
          visionColors: const Value(
            null,
          ),
          visionModel: const Value(
            null,
          ),
          visionImageHash: const Value(
            null,
          ),
          visionProcessedAt: const Value(
            null,
          ),
        ),
        mode: InsertMode.insertOrReplace,
      );

      await (delete(memoryPeople)
            ..where(
              (row) =>
                  row.memoryId.equals(
                oldId,
              ),
            ))
          .go();

      await (delete(faceEmbeddings)
            ..where(
              (row) =>
                  row.memoryId.equals(
                oldId,
              ),
            ))
          .go();

      await (delete(memories)
            ..where(
              (row) =>
                  row.id.equals(
                oldId,
              ),
            ))
          .go();
    });
  }

  Future<void> deleteMemory(
    String id,
  ) {
    return transaction(() async {
      await (delete(memoryPeople)
            ..where(
              (row) =>
                  row.memoryId.equals(
                id,
              ),
            ))
          .go();

      await (delete(faceEmbeddings)
            ..where(
              (row) =>
                  row.memoryId.equals(
                id,
              ),
            ))
          .go();

      await (delete(memories)
            ..where(
              (row) =>
                  row.id.equals(
                id,
              ),
            ))
          .go();
    });
  }

  // ---------------------------------------------------------------------------
  // People
  // ---------------------------------------------------------------------------

  Future<void> insertPerson(
    PeopleCompanion person,
  ) {
    return into(people)
        .insertOnConflictUpdate(
      person,
    );
  }

  Future<List<PeopleData>>
      getAllPeople() {
    return (select(people)
          ..orderBy([
            (row) =>
                OrderingTerm.desc(
                  row.updatedAt,
                ),
          ]))
        .get();
  }

  Stream<List<PeopleData>>
      watchAllPeople() {
    return (select(people)
          ..orderBy([
            (row) =>
                OrderingTerm.desc(
                  row.updatedAt,
                ),
          ]))
        .watch();
  }

  Future<PeopleData?> getPersonById(
    String personId,
  ) {
    return (select(people)
          ..where(
            (row) => row.id.equals(
              personId,
            ),
          ))
        .getSingleOrNull();
  }

  Future<List<PeopleData>>
      getNamedPeople() {
    return (select(people)
          ..where(
            (row) =>
                row.name.isNotNull(),
          )
          ..orderBy([
            (row) =>
                OrderingTerm.asc(
                  row.name,
                ),
          ]))
        .get();
  }

  Future<List<PeopleData>>
      getUnnamedPeople() {
    return (select(people)
          ..where(
            (row) =>
                row.name.isNull(),
          )
          ..orderBy([
            (row) =>
                OrderingTerm.desc(
                  row.createdAt,
                ),
          ]))
        .get();
  }

  Future<void> updatePersonName({
    required String personId,
    required String name,
  }) {
    return (update(people)
          ..where(
            (row) => row.id.equals(
              personId,
            ),
          ))
        .write(
      PeopleCompanion(
        name: Value(name),
        updatedAt: Value(
          DateTime.now(),
        ),
      ),
    );
  }

  Future<void> updatePersonCoverFace({
    required String personId,
    required String? coverFacePath,
  }) {
    return (update(people)
          ..where(
            (row) => row.id.equals(
              personId,
            ),
          ))
        .write(
      PeopleCompanion(
        coverFacePath: Value(
          coverFacePath,
        ),
        updatedAt: Value(
          DateTime.now(),
        ),
      ),
    );
  }

  Future<void> deletePerson(
    String personId,
  ) {
    return transaction(() async {
      await (delete(memoryPeople)
            ..where(
              (row) =>
                  row.personId.equals(
                personId,
              ),
            ))
          .go();

      await (delete(people)
            ..where(
              (row) =>
                  row.id.equals(
                personId,
              ),
            ))
          .go();
    });
  }

  // ---------------------------------------------------------------------------
  // Face embeddings
  // ---------------------------------------------------------------------------

  Future<void> insertFaceEmbedding(
    FaceEmbeddingsCompanion face,
  ) {
    return into(faceEmbeddings)
        .insertOnConflictUpdate(
      face,
    );
  }

  Future<List<FaceEmbedding>>
      getAllFaceEmbeddings() {
    return select(
      faceEmbeddings,
    ).get();
  }

  Future<FaceEmbedding?>
      getFaceEmbeddingById(
    String faceId,
  ) {
    return (select(faceEmbeddings)
          ..where(
            (row) => row.id.equals(
              faceId,
            ),
          ))
        .getSingleOrNull();
  }

  Future<List<FaceEmbedding>>
      getFaceEmbeddingsForMemory(
    String memoryId,
  ) {
    return (select(faceEmbeddings)
          ..where(
            (row) =>
                row.memoryId.equals(
              memoryId,
            ),
          ))
        .get();
  }

  Future<List<FaceEmbedding>>
      getFaceEmbeddingsForPerson(
    String personId,
  ) {
    return (select(faceEmbeddings)
          ..where(
            (row) =>
                row.personId.equals(
              personId,
            ),
          ))
        .get();
  }

  Future<List<FaceEmbedding>>
      getAssignedFaceEmbeddings() {
    return (select(faceEmbeddings)
          ..where(
            (row) =>
                row.personId.isNotNull(),
          ))
        .get();
  }

  Future<List<FaceEmbedding>>
      getUnassignedFaceEmbeddings() {
    return (select(faceEmbeddings)
          ..where(
            (row) =>
                row.personId.isNull(),
          ))
        .get();
  }

  Future<bool> hasProcessedFacesForMemory(
    String memoryId,
  ) async {
    final countExpression =
        faceEmbeddings.id.count();

    final query =
        selectOnly(faceEmbeddings)
          ..addColumns([
            countExpression,
          ])
          ..where(
            faceEmbeddings.memoryId.equals(
              memoryId,
            ),
          );

    final row =
        await query.getSingle();

    return (row.read(
              countExpression,
            ) ??
            0) >
        0;
  }

  Future<void> assignFaceToPerson({
    required String faceId,
    required String personId,
  }) {
    return (update(faceEmbeddings)
          ..where(
            (row) =>
                row.id.equals(
              faceId,
            ),
          ))
        .write(
      FaceEmbeddingsCompanion(
        personId: Value(
          personId,
        ),
      ),
    );
  }

  Future<void> unassignFaceFromPerson({
    required String faceId,
  }) {
    return (update(faceEmbeddings)
          ..where(
            (row) =>
                row.id.equals(
              faceId,
            ),
          ))
        .write(
      const FaceEmbeddingsCompanion(
        personId: Value(
          null,
        ),
      ),
    );
  }

  Future<void> deleteFaceEmbedding(
    String faceId,
  ) {
    return (delete(faceEmbeddings)
          ..where(
            (row) =>
                row.id.equals(
              faceId,
            ),
          ))
        .go();
  }

  Future<void> deleteFaceEmbeddingsForMemory(
    String memoryId,
  ) {
    return (delete(faceEmbeddings)
          ..where(
            (row) =>
                row.memoryId.equals(
              memoryId,
            ),
          ))
        .go();
  }

  // ---------------------------------------------------------------------------
  // Memory ↔ Person relationships
  // ---------------------------------------------------------------------------

  Future<void> linkMemoryToPerson({
    required String memoryId,
    required String personId,
    double? similarity,
  }) {
    return into(memoryPeople)
        .insertOnConflictUpdate(
      MemoryPeopleCompanion(
        memoryId: Value(
          memoryId,
        ),
        personId: Value(
          personId,
        ),
        similarity: Value(
          similarity,
        ),
        createdAt: Value(
          DateTime.now(),
        ),
      ),
    );
  }

  Future<void> unlinkMemoryFromPerson({
    required String memoryId,
    required String personId,
  }) {
    return (delete(memoryPeople)
          ..where(
            (row) =>
                row.memoryId.equals(
                  memoryId,
                ) &
                row.personId.equals(
                  personId,
                ),
          ))
        .go();
  }

  Future<void> clearPeopleForMemory(
    String memoryId,
  ) {
    return (delete(memoryPeople)
          ..where(
            (row) =>
                row.memoryId.equals(
              memoryId,
            ),
          ))
        .go();
  }

  Future<List<MemoryPeopleData>>
      getPeopleForMemory(
    String memoryId,
  ) {
    return (select(memoryPeople)
          ..where(
            (row) =>
                row.memoryId.equals(
              memoryId,
            ),
          ))
        .get();
  }

  Future<List<MemoryPeopleData>>
      getMemoriesForPerson(
    String personId,
  ) {
    return (select(memoryPeople)
          ..where(
            (row) =>
                row.personId.equals(
              personId,
            ),
          ))
        .get();
  }

  Future<List<Memory>>
      getMemoryRowsForPerson(
    String personId,
  ) async {
    final query =
        select(memories).join([
      innerJoin(
        memoryPeople,
        memoryPeople.memoryId
            .equalsExp(
          memories.id,
        ),
      ),
    ]);

    query.where(
      memoryPeople.personId.equals(
        personId,
      ),
    );

    query.orderBy([
      OrderingTerm.desc(
        memories.createdAt,
      ),
    ]);

    final rows =
        await query.get();

    return rows
        .map(
          (row) =>
              row.readTable(
            memories,
          ),
        )
        .toList(
          growable: false,
        );
  }
}