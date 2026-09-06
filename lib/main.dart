import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app/app.dart';
import 'data/db/app_database.dart';
import 'data/db/connection.dart';
import 'data/repositories/settings_repository.dart';
import 'providers/database_providers.dart';
import 'providers/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _configureWindow();

  // Opened before runApp so a storage failure surfaces immediately rather than
  // as a broken screen, and so repositories can stay synchronous.
  final storage = await AppStorage.resolve();
  final database = AppDatabase(openConnection(storage.databaseFile));

  // Resolved before runApp so the very first frame already paints in the
  // shop's chosen theme — see HomeTextNotifier.build for why.
  final initialHomeText = await SettingsRepository(database).homeText();

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
