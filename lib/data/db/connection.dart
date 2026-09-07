import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
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

  /// The application id this app shipped under before it had its own.
  ///
  /// On Linux and macOS the app-support directory is named after the
  /// application id, so renaming that id silently points a shop at an empty
  /// folder — catalogue, photos and admin account all still on disk, just
  /// not where the app now looks.
  static const _legacyApplicationId = 'com.example.benesnap';

  static Future<AppStorage> resolve() async {
    final root = await getApplicationSupportDirectory();
    final storage = AppStorage(root);
    await adoptLegacyDirectory(root);
    await storage.imagesDirectory.create(recursive: true);
    return storage;
  }

  /// Moves a catalogue left behind under the old application id into [root].
  ///
  /// Runs once and only in the one situation where it is unambiguous: the
  /// new location has no database yet, and the old one does. If the shop has
  /// already used the renamed build, [root] holds the real catalogue and
  /// this does nothing.
  ///
  /// That check works because [resolve] calls this *before* anything opens a
  /// database — so on the first launch of a renamed build there is nothing at
  /// the new path yet, and the adoption happens before an empty one can be
  /// created. (A build that predates this code will have created that empty
  /// database already, and then the catalogue has to be moved by hand.) Copy-then-delete rather than a rename, since the two
  /// directories are not guaranteed to be on the same filesystem, and the
  /// copy is only deleted once it is complete.
  @visibleForTesting
  static Future<void> adoptLegacyDirectory(Directory root) async {
    if (await AppStorage(root).databaseFile.exists()) return;

    final legacy = Directory(p.join(root.parent.path, _legacyApplicationId));
    if (!await AppStorage(legacy).databaseFile.exists()) return;

    try {
      await _copyDirectory(legacy, root);
      await legacy.delete(recursive: true);
    } on Object {
      // A half-copied catalogue is still better than none, and the shop can
      // be pointed at the old folder by hand. Never let this stop startup.
    }
  }

  static Future<void> _copyDirectory(Directory from, Directory to) async {
    await to.create(recursive: true);
    await for (final entity in from.list()) {
      final target = p.join(to.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(target));
      } else if (entity is File) {
        await entity.copy(target);
      }
    }
  }
}

/// Opens the on-disk database on a background isolate, so a slow query can
/// never jank the kiosk animation.
QueryExecutor openConnection(File file) =>
    NativeDatabase.createInBackground(file);
