import 'dart:io';

import 'package:benesnap/app/app.dart';
import 'package:benesnap/app/theme.dart';
import 'package:benesnap/data/db/app_database.dart';
import 'package:benesnap/data/db/connection.dart';
import 'package:benesnap/data/models/home_theme.dart';
import 'package:benesnap/data/repositories/settings_repository.dart';
import 'package:benesnap/providers/database_providers.dart';
import 'package:benesnap/providers/settings_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/drift_settle.dart';

void main() {
  testWidgets(
    'the very first frame already uses the shop\'s saved theme — no flash '
    'of the default while homeTextProvider settles',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      // A theme distinct from the default (sand) is what a real shop would
      // have chosen, and what makes a flash back to the default visible.
      await SettingsRepository(db).updateHomeText(
        welcomeTitle: 'Test',
        extraLine: '',
        themeKey: HomeThemeKey.sky,
      );

      final tempDir = Directory.systemTemp.createTempSync('benesnap_app_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      // Mirrors main(): resolve the row once, before the widget tree exists,
      // and hand it to initialHomeTextProvider — see HomeTextNotifier.build
      // for why. Overriding homeTextProvider directly with a StreamProvider
      // instead (as it used to be) is exactly the bug this test guards
      // against: try that and the assertion below fails, because a
      // Stream's first emission always lands a beat after the widget it
      // feeds has already built once — so the first frame has nothing but
      // the default theme to fall back to.
      final initialHomeText = await SettingsRepository(db).homeText();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            appStorageProvider.overrideWithValue(AppStorage(tempDir)),
            initialHomeTextProvider.overrideWithValue(initialHomeText),
          ],
          child: const BeneSnapApp(),
        ),
      );
      // Deliberately no further `pump()` here: the whole point is to check
      // what's on screen the instant the very first frame is built, before
      // anything has a chance to settle or catch up.

      final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
      final tokens = theme.extension<AppTokens>()!;
      expect(
        tokens.canvasGradientTop,
        AppTheme.forTheme(
          HomeThemeKey.sky,
        ).extension<AppTokens>()!.canvasGradientTop,
      );
      expect(
        tokens.canvasGradientTop,
        isNot(
          AppTheme.forTheme(
            defaultHomeThemeKey,
          ).extension<AppTokens>()!.canvasGradientTop,
        ),
      );

      await disposeAndDrain(tester);
    },
  );
}
