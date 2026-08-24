import 'package:benesnap/data/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// An isolated in-memory database, torn down after the test.
///
/// `beforeOpen` runs the tag seed, so every test starts with the same
/// suitability vocabulary the app ships with.
AppDatabase createTestDatabase() {
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  return db;
}
