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

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Memories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'neurolens'));

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) async {
        await migrator.createAll();
      },
      onUpgrade: (migrator, from, to) async {
        if (from < 2) {
          await migrator.addColumn(memories, memories.content);
        }

        if (from < 3) {
          await migrator.addColumn(memories, memories.embedding);
        }

        if (from < 4) {
          await migrator.addColumn(memories, memories.visionCaption);
          await migrator.addColumn(memories, memories.visionScene);
          await migrator.addColumn(memories, memories.visionObjects);
          await migrator.addColumn(memories, memories.visionKeywords);
          await migrator.addColumn(memories, memories.visionColors);
          await migrator.addColumn(memories, memories.visionModel);
          await migrator.addColumn(memories, memories.visionImageHash);
          await migrator.addColumn(memories, memories.visionProcessedAt);
        }
      },
    );
  }

  Future<void> insertMemory(MemoriesCompanion memory) {
    return into(memories).insertOnConflictUpdate(memory);
  }

  Stream<List<Memory>> watchAllMemories() {
    return (select(
      memories,
    )..orderBy([(table) => OrderingTerm.desc(table.createdAt)])).watch();
  }

  Future<int> getMemoryCount() async {
    final countExpression = memories.id.count();

    final query = selectOnly(memories)..addColumns([countExpression]);

    final row = await query.getSingle();

    return row.read(countExpression) ?? 0;
  }

  Future<void> updateMemoryContent({
    required String id,
    required String content,
  }) {
    return (update(memories)..where((row) => row.id.equals(id))).write(
      MemoriesCompanion(
        content: Value(content),
      ),
    );
  }

  Future<void> updateMemoryEmbedding({
    required String id,
    required String embedding,
  }) {
    return (update(memories)..where((row) => row.id.equals(id))).write(
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
    return (update(memories)..where((row) => row.id.equals(id))).write(
      MemoriesCompanion(
        visionCaption: Value(caption),
        visionScene: Value(scene),
        visionObjects: Value(objects),
        visionKeywords: Value(keywords),
        visionColors: Value(colors),
        visionModel: Value(model),
        visionImageHash: Value(imageHash),
        visionProcessedAt: Value(processedAt),
      ),
    );
  }

  Future<void> deleteMemory(String id) {
    return (delete(memories)..where((row) => row.id.equals(id))).go();
  }
}