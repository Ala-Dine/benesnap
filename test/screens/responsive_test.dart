// Guards the fix for hard RenderFlex overflows on the screens that used to
// have no scroll fallback at all (login, setup, product detail) or a hard
// pixel width that couldn't shrink (home's not-found card). None of this is
// hypothetical: the app enforces a 1000x700 *minimum* window size (see
// main.dart's `_configureWindow`), and a shop's own OS text-scale/
// accessibility setting can make any of this content taller than usual —
// neither is a screen size the app can refuse to run at.
//
// Each test constrains the test view well below what the content naturally
// needs and asserts two things: no exception was thrown (the overflow itself
// never happens) and a scrollable actually exists (the fix is a real scroll
// fallback, not an accidental pass).
import 'dart:io';

import 'package:benesnap/app/theme.dart';
import 'package:benesnap/data/db/app_database.dart';
import 'package:benesnap/data/db/connection.dart';
import 'package:benesnap/data/models/home_text.dart';
import 'package:benesnap/data/models/home_theme.dart';
import 'package:benesnap/data/models/product.dart';
import 'package:benesnap/providers/database_providers.dart';
import 'package:benesnap/data/repositories/product_repository.dart';
import 'package:benesnap/screens/home/home_screen.dart';
import 'package:benesnap/screens/login/login_screen.dart';
import 'package:benesnap/screens/product_detail/product_detail_screen.dart';
import 'package:benesnap/screens/setup/setup_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_home_text.dart';

void main() {
  Widget wrap(Widget child, {required AppDatabase db, AppStorage? storage}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        if (storage != null) appStorageProvider.overrideWithValue(storage),
        // Only HomeScreen actually needs this, but overriding it
        // unconditionally is harmless for the other screens — none of them
        // watch homeTextProvider.
        staticHomeTextOverride(
          const HomeText(
            welcomeTitle: defaultWelcomeTitle,
            extraLine: '',
            themeKey: HomeThemeKey.sand,
          ),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: child,
      ),
    );
  }

  /// Shrinks the test view well below the app's own enforced 700px minimum
  /// height — standing in for a shop's larger OS text-scale setting just as
  /// much as for a literally short window, since both leave less room than
  /// the content was designed around.
  void constrainView(WidgetTester tester, {double height = 400}) {
    tester.view.physicalSize = Size(1000, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets(
    'login screen scrolls instead of overflowing at a constrained height',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      constrainView(tester);

      await tester.pumpWidget(wrap(const LoginScreen(), db: db));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsWidgets);
    },
  );

  testWidgets(
    'setup screen scrolls instead of overflowing at a constrained height',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      constrainView(tester);

      await tester.pumpWidget(wrap(const SetupScreen(), db: db));
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(Scrollable), findsWidgets);
    },
  );

  testWidgets('the product detail card scrolls instead of overflowing at a '
      'constrained height', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final created = await ProductRepository(db).create(
      const ProductDraft(
        barcode: 'X1',
        brandName: 'Brand',
        productName: 'Product',
        keyIngredients:
            'A long list of ingredients on purpose, to actually push this '
            'card past a constrained height instead of coasting on how '
            'short the default test fixture usually is.',
        coreBenefits: 'One benefit\nA second benefit\nA third benefit',
      ),
    );

    final tempDir = Directory.systemTemp.createTempSync('benesnap_resp_');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    constrainView(tester, height: 450);

    await tester.pumpWidget(
      wrap(
        ProductDetailScreen(productId: created.id),
        db: db,
        storage: AppStorage(tempDir),
      ),
    );
    for (var i = 0; i < 10 && find.text('BRAND').evaluate().isEmpty; i++) {
      await tester.pump();
    }

    expect(find.text('BRAND'), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsWidgets);
  });

  testWidgets("home's not-found card scrolls instead of overflowing at a "
      'constrained height, and shrinks instead of overflowing sideways at a '
      'constrained width', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    // Narrower than the card's own 520 cap, so a hard `width: 520` (as
    // opposed to a `maxWidth: 520` that's free to shrink) would overflow
    // this test's viewport horizontally, not just vertically.
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      wrap(const HomeScreen(initialUnknownBarcode: '0123456789'), db: db),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(Scrollable), findsWidgets);
  });
}
