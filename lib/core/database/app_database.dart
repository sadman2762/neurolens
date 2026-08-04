import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Memories extends Table {
  TextColumn get id => text()();

  TextColumn get type => text()();

  TextColumn get title => text()();

  TextColumn get content => text().nullable()();

  TextColumn get originalPath => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Memories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'neurolens'));

  @override
  int get schemaVersion => 2;

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
      },
    );
  }

  Future<void> insertMemory(MemoriesCompanion memory) {
    return into(memories).insertOnConflictUpdate(memory);
  }

  Stream<List<Memory>> watchAllMemories() {
    return (select(
      memories,
    )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();
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
      MemoriesCompanion(content: Value(content)),
    );
  }
}
