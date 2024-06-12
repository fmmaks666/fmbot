import 'package:sqlite_async/sqlite_async.dart'
    show SqliteDatabase, SqliteWriteContext;

// IDEA: Extend SqliteDatabase Object
class DatabaseManager {
  final SqliteDatabase db;

  DatabaseManager(String databasePath)
      : db = SqliteDatabase(path: databasePath);

  Future<void> createTables(
      Future<void> Function(SqliteWriteContext) task) async {
    // TODO: Use migrations
    await db.writeTransaction(task);
  }

  Future<void> dispose() async {
    await db.close();
  }
}
