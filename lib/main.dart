import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'app/storage_failure_app.dart';
import 'data/db/app_database.dart';
import 'data/db/connection.dart';
import 'data/models/home_text.dart';
import 'data/repositories/settings_repository.dart';
import 'providers/database_providers.dart';
import 'providers/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureWindow();

  final AppStorage storage;
  final AppDatabase database;
  final HomeText initialHomeText;
  try {
    // Opened before runApp so a storage failure surfaces immediately rather
    // than as a broken screen, and so repositories can stay synchronous.
    storage = await AppStorage.resolve();
    database = AppDatabase(openConnection(storage.databaseFile));

    // Resolved before runApp so the very first frame already paints in the
    // shop's chosen theme — see HomeTextNotifier.build for why. Being the
    // first query, it is also what actually opens the database, so schema
    // migrations run here too.
    initialHomeText = await SettingsRepository(database).homeText();
  } catch (error) {
    // Everything above is unreachable-in-practice until the day it isn't: an
    // unwritable app-data folder, a corrupt file, a migration that fails.
    // Letting it throw out of main() means runApp is never called at all and
    // the shop stares at an empty window with nothing to report to anyone —
    // the exact outcome opening the database early was meant to avoid.
    runApp(StorageFailureApp(error: error));
    return;
  }

  await _closeDatabaseOnExit(database);

  runApp(
    ProviderScope(
      overrides: [
        appStorageProvider.overrideWithValue(storage),
        appDatabaseProvider.overrideWithValue(database),
        initialHomeTextProvider.overrideWithValue(initialHomeText),
      ],
      child: const BeneSnapApp(),
    ),
  );
}

/// Closes the database on the way out so SQLite checkpoints its
/// write-ahead log into the database file itself.
///
/// Nothing committed is at risk either way, but the shop's whole backup
/// story is "copy this folder" (see [AppStorage]) — and a folder copied
/// while a `-wal` sidecar still holds recent writes is a copy that silently
/// predates them.
Future<void> _closeDatabaseOnExit(AppDatabase database) async {
  if (!_isDesktop) return;
  await windowManager.setPreventClose(true);
  windowManager.addListener(_CloseHandler(database));
}

class _CloseHandler extends WindowListener {
  _CloseHandler(this._database);

  final AppDatabase _database;

  @override
  void onWindowClose() async {
    await _database.close();
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }
}

/// The kiosk layout assumes a reasonably wide window; below 1000x700 the
/// two-column product screens stop fitting.
Future<void> _configureWindow() async {
  if (!_isDesktop) return;

  await windowManager.ensureInitialized();

  const options = WindowOptions(
    size: Size(1280, 800),
    minimumSize: Size(1000, 700),
    center: true,
    title: 'BeneSnap',
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(options, () async {
    await windowManager.show();
    await windowManager.focus();
  });
}

bool get _isDesktop =>
    Platform.isWindows || Platform.isMacOS || Platform.isLinux;
