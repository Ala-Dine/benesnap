// Covers the search path, which does the most work per keystroke on this
// screen, and the delete confirmation, which is the only destructive action
// reachable from the grid.

import 'dart:io';

import 'package:benesnap/app/theme.dart';
import 'package:benesnap/data/db/app_database.dart';
import 'package:benesnap/data/db/connection.dart';
import 'package:benesnap/data/models/home_text.dart';
import 'package:benesnap/data/models/home_theme.dart';
import 'package:benesnap/data/models/product.dart';
import 'package:benesnap/data/repositories/product_repository.dart';
import 'package:benesnap/providers/database_providers.dart';
import 'package:benesnap/screens/inventory/inventory_screen.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_home_text.dart';

void main() {
  late AppDatabase db;
  late ProductRepository products;
  late Directory tempDir;

  setUp(() async {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.implicitView!;
    view.physicalSize = const Size(1280, 800);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    products = ProductRepository(db);

    tempDir = Directory.systemTemp.createTempSync('benesnap_inventory_');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    await products.create(
      const ProductDraft(
        barcode: 'A0001',
        brandName: 'Aveda',
        productName: 'Shampoo',
        keyIngredients: 'Water',
        coreBenefits: 'Shine',
      ),
    );
    await products.create(
      const ProductDraft(
        barcode: 'B0002',
        brandName: 'Bioderma',
        productName: 'Micellar',
        keyIngredients: 'Glycerin',
        coreBenefits: 'Calm',
      ),
    );
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appStorageProvider.overrideWithValue(AppStorage(tempDir)),
        staticHomeTextOverride(
          const HomeText(
            welcomeTitle: defaultWelcomeTitle,
            extraLine: '',
            themeKey: HomeThemeKey.sand,
          ),
        ),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: GoRouter(
          initialLocation: '/inventory',
          routes: [
            GoRoute(
              path: '/inventory',
              builder: (_, _) => const InventoryScreen(),
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

  /// The search field is debounced and the grid is fed by a drift stream,
  /// so neither a bare `pump()` nor `pumpAndSettle` works here: the first
  /// never advances the clock far enough for the debounce timer, and the
  /// second never settles while the stream's own timers keep rescheduling.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('shows the whole catalogue before any search', (tester) async {
    await tester.pumpWidget(wrap());
    await settle(tester);

    expect(find.text('AVEDA'), findsOneWidget);
    expect(find.text('BIODERMA'), findsOneWidget);
    await disposeAndDrain(tester);
  });

  testWidgets('filters by brand, product name and ingredient', (tester) async {
    await tester.pumpWidget(wrap());
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'bioderma');
    await settle(tester);
    expect(find.text('AVEDA'), findsNothing);
    expect(find.text('BIODERMA'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'shampoo');
    await settle(tester);
    expect(find.text('AVEDA'), findsOneWidget);
    expect(find.text('BIODERMA'), findsNothing);

    await tester.enterText(find.byType(TextField), 'glycerin');
    await settle(tester);
    expect(find.text('BIODERMA'), findsOneWidget);
    expect(find.text('AVEDA'), findsNothing);
    await disposeAndDrain(tester);
  });

  testWidgets('a search matching nothing says so', (tester) async {
    await tester.pumpWidget(wrap());
    await settle(tester);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await settle(tester);

    expect(find.text('AVEDA'), findsNothing);
    expect(find.text('BIODERMA'), findsNothing);
    await disposeAndDrain(tester);
  });

  testWidgets('deleting asks first, and cancelling keeps the product', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());
    await settle(tester);

    await tester.tap(find.byTooltip('حذف').first);
    await settle(tester);
    expect(find.text('حذف هذا المنتج؟'), findsOneWidget);

    await tester.tap(find.text('إلغاء'));
    await settle(tester);

    expect(await products.all(), hasLength(2));
    await disposeAndDrain(tester);
  });

  testWidgets('confirming the delete removes it from the grid', (tester) async {
    await tester.pumpWidget(wrap());
    await settle(tester);

    await tester.tap(find.byTooltip('حذف').first);
    await settle(tester);
    await tester.tap(find.widgetWithText(ElevatedButton, 'حذف'));
    await settle(tester);

    expect(await products.all(), hasLength(1));
    expect(find.text('AVEDA'), findsNothing);
    await disposeAndDrain(tester);
  });
}
