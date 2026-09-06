import 'package:benesnap/data/db/app_database.dart';
import 'package:benesnap/data/models/home_text.dart';
import 'package:benesnap/data/models/home_theme.dart';
import 'package:benesnap/data/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_db.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() {
    db = createTestDatabase();
    settings = SettingsRepository(db);
  });

  group('before anything is saved', () {
    test('homeText resolves to the default welcome title and theme', () async {
      final text = await settings.homeText();
      expect(text.welcomeTitle, defaultWelcomeTitle);
      expect(text.extraLine, isEmpty);
      expect(text.themeKey, defaultHomeThemeKey);
    });

    test('rawHomeText is null — nothing has been customized yet', () async {
      expect(await settings.rawHomeText(), isNull);
    });
  });

  group('updateHomeText', () {
    test('stores exactly what was given', () async {
      await settings.updateHomeText(
        welcomeTitle: 'أهلاً بكم في متجر علاء',
        extraLine: 'جودة عالية كل يوم',
        themeKey: HomeThemeKey.sage,
      );

      final raw = await settings.rawHomeText();
      expect(raw!.welcomeTitle, 'أهلاً بكم في متجر علاء');
      expect(raw.extraLine, 'جودة عالية كل يوم');
      expect(raw.themeKey, HomeThemeKey.sage);
    });

    test('trims surrounding whitespace', () async {
      await settings.updateHomeText(
        welcomeTitle: '  Padded Title  ',
        extraLine: '  padded line  ',
        themeKey: defaultHomeThemeKey,
      );

      final raw = await settings.rawHomeText();
      expect(raw!.welcomeTitle, 'Padded Title');
      expect(raw.extraLine, 'padded line');
    });

    test(
      'an empty title falls back to the default rather than storing blank',
      () async {
        await settings.updateHomeText(
          welcomeTitle: '   ',
          extraLine: '',
          themeKey: defaultHomeThemeKey,
        );

        final raw = await settings.rawHomeText();
        expect(raw!.welcomeTitle, defaultWelcomeTitle);
      },
    );

    test('a later update replaces the earlier one — always one row', () async {
      await settings.updateHomeText(
        welcomeTitle: 'First',
        extraLine: '',
        themeKey: HomeThemeKey.sand,
      );
      await settings.updateHomeText(
        welcomeTitle: 'Second',
        extraLine: '',
        themeKey: HomeThemeKey.sky,
      );

      final raw = await settings.rawHomeText();
      expect(raw!.welcomeTitle, 'Second');
      expect(raw.themeKey, HomeThemeKey.sky);

      final rows = await db.select(db.appSettings).get();
      expect(rows, hasLength(1));
    });

    test('stores the theme by its stable key, not a raw colour', () async {
      await settings.updateHomeText(
        welcomeTitle: 'Title',
        extraLine: '',
        themeKey: HomeThemeKey.blush,
      );

      final row = await (db.select(
        db.appSettings,
      )..where((s) => s.id.equals(1))).getSingle();
      expect(row.themeKey, 'blush');
    });
  });

  group('watchHomeText', () {
    test('emits again after an update', () async {
      final emissions = <HomeText>[];
      final sub = settings.watchHomeText().listen(emissions.add);
      addTearDown(sub.cancel);

      await pumpEventQueue();
      expect(emissions.single.welcomeTitle, defaultWelcomeTitle);
      expect(emissions.single.themeKey, defaultHomeThemeKey);

      await settings.updateHomeText(
        welcomeTitle: 'Updated',
        extraLine: '',
        themeKey: HomeThemeKey.vanilla,
      );
      await pumpEventQueue();

      expect(emissions.last.welcomeTitle, 'Updated');
      expect(emissions.last.themeKey, HomeThemeKey.vanilla);
    });
  });
}
