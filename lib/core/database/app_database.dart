import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Memories extends Table {
  TextColumn get id => text()();

  TextColumn get type => text()();

  TextColumn get title => text()();

  TextColumn get originalPath => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [Memories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'neurolens'));

  @override
  int get schemaVersion => 1;

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
}
