// The settings screen is the only place a shop's own customisations can be
// overwritten, so these focus on the two ways that used to happen silently:
// saving on top of a load that failed, and walking away from unsaved edits.

import 'package:benesnap/app/theme.dart';
import 'package:benesnap/data/db/app_database.dart';
import 'package:benesnap/data/exceptions.dart';
import 'package:benesnap/data/models/home_text.dart';
import 'package:benesnap/data/models/home_theme.dart';
import 'package:benesnap/data/repositories/settings_repository.dart';
import 'package:benesnap/providers/auth_providers.dart';
import 'package:benesnap/providers/database_providers.dart';
import 'package:benesnap/screens/settings/settings_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/test_home_text.dart';

/// A repository whose one-shot read fails the way a corrupt or locked
/// database would, leaving every other method working.
class _FailingReadRepository extends SettingsRepository {
  _FailingReadRepository(super.db);

  @override
  Future<HomeText?> rawHomeText() async => throw const StorageException('x');
}

void main() {
  const savedTitle = 'متجر الأمل';
  const saveButtonText = 'حفظ نصوص الصفحة';

  setUp(() {
    // The app enforces a 1000x700 minimum window (main.dart's
    // _configureWindow); the test view's 800x600 default is a size this
    // screen is never asked to render at. responsive_test.dart is where
    // deliberately-too-small layouts are covered.
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
    view.physicalSize = const Size(1280, 800);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);
  });

  Widget wrap(
    AppDatabase db, {
    HomeThemeKey theme = HomeThemeKey.sand,
    SettingsRepository? repository,
  }) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        authSessionProvider.overrideWith(_SignedIn.new),
        staticHomeTextOverride(
          HomeText(welcomeTitle: savedTitle, extraLine: '', themeKey: theme),
        ),
        if (repository != null)
          settingsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(
        theme: AppTheme.forTheme(theme),
        // The screen pops on its way out, so it needs somewhere to pop to —
        // and `context.canPop()` is a go_router extension, so a plain
        // Navigator wouldn't answer it.
        routerConfig: GoRouter(
          initialLocation: '/inventory/settings',
          routes: [
            GoRoute(
              path: '/inventory',
              builder: (_, _) => const Scaffold(body: Text('inventory')),
              routes: [
                GoRoute(
                  path: 'settings',
                  builder: (_, _) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }

  testWidgets('a failed load disables saving instead of offering to '
      'overwrite the shop\'s text with blanks', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(wrap(db, repository: _FailingReadRepository(db)));
    await tester.pumpAndSettle();

    // The failure is visible...
    expect(find.text(const StorageException('x').message), findsOneWidget);
    // ...and the button that would have written the empty fields over the
    // shop's real welcome text is unreachable.
    final save = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.text(saveButtonText),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('opens on the theme the shop actually saved, not the '
      'default', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await SettingsRepository(db).updateHomeText(
      welcomeTitle: savedTitle,
      extraLine: '',
      themeKey: HomeThemeKey.sky,
    );

    await tester.pumpWidget(wrap(db, theme: HomeThemeKey.sky));
    // A single pump only: the point is what the first frame shows, before
    // _loadHomeText's await has had a chance to come back and correct it.
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('leaving with unsaved edits asks first', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'نص جديد');
    await tester.pump();

    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();

    expect(find.text('تجاهل التغييرات؟'), findsOneWidget);
  });

  testWidgets('leaving with nothing changed does not ask', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(wrap(db));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('رجوع'));
    await tester.pumpAndSettle();

    expect(find.text('تجاهل التغييرات؟'), findsNothing);
    expect(find.byType(SettingsScreen), findsNothing);
  });
}

class _SignedIn extends AuthSession {
  @override
  String? build() => 'owner';
}
