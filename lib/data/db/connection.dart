import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where the catalogue lives on disk.
///
/// The database and an `images/` folder sit side by side in the app support
/// directory, so backing the shop up is a matter of copying one folder.
class AppStorage {
  const AppStorage(this.root);

  final Directory root;

  File get databaseFile => File(p.join(root.path, 'benesnap.sqlite'));

  Directory get imagesDirectory => Directory(p.join(root.path, 'images'));

  /// Absolute path for a filename stored in `products.image_path`.
  String resolveImage(String relativeName) =>
      p.join(imagesDirectory.path, relativeName);

  static Future<AppStorage> resolve() async {
    final root = await getApplicationSupportDirectory();
    final storage = AppStorage(root);
    await storage.imagesDirectory.create(recursive: true);
    return storage;
  }
}

/// Opens the on-disk database on a background isolate, so a slow query can
/// never jank the kiosk animation.
QueryExecutor openConnection(File file) =>
    NativeDatabase.createInBackground(file);
