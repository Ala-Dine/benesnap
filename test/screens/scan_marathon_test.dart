// A full counter's worth of scanning, end to end through the real screens.
//
// The individual scan behaviours each have their own focused test; what
// these two cover is the part no single-scan test can, which is what happens
// after the twenty-fifth one. Every product screen registers a
// HardwareKeyboard handler, a scan-stream subscription and an
// AnimationController in initState and gives them all back in dispose, and a
// kiosk runs for a whole shift without ever being restarted — so anything
// that accumulates one-per-scan is a bug that only shows up at this length.
import 'dart:io';

import 'package:benesnap/app/router.dart';
import 'package:benesnap/app/theme.dart';
import 'package:benesnap/data/db/app_database.dart';
import 'package:benesnap/data/db/connection.dart';
import 'package:benesnap/data/models/home_text.dart';
import 'package:benesnap/data/models/home_theme.dart';
import 'package:benesnap/data/models/product.dart';
import 'package:benesnap/data/repositories/product_repository.dart';
import 'package:benesnap/providers/database_providers.dart';
import 'package:benesnap/providers/scanner_providers.dart';
import 'package:benesnap/screens/home/home_screen.dart';
import 'package:benesnap/screens/product_detail/product_detail_screen.dart';
import 'package:benesnap/services/scanner/barcode_scanner_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/drift_settle.dart';
import '../helpers/test_home_text.dart';

/// Enough to outlast any per-scan accumulation, and a plausible morning at a
/// shop counter.
const _productCount = 25;

String _barcodeAt(int i) => 'SCAN${i.toString().padLeft(4, '0')}';
String _brandAt(int i) => 'Brand$i';

void main() {
  /// Creates [_productCount] products, each with a distinct barcode and a
  /// brand name the detail card renders in upper case — so every assertion
  /// can name the exact product it expects to be looking at rather than just
  /// "a product".
  Future<AppDatabase> catalogue() async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final products = ProductRepository(db);

    for (var i = 1; i <= _productCount; i++) {
      await products.create(
        ProductDraft(
          barcode: _barcodeAt(i),
          brandName: _brandAt(i),
          productName: 'Product $i',
          keyIngredients: 'Water, glycerin',
          coreBenefits: 'Hydrates\nSoothes',
        ),
      );
    }
    return db;
  }

  Future<GoRouter> pumpKiosk(
    WidgetTester tester, {
    required AppDatabase db,
    required BarcodeScannerService scanner,
  }) async {
    final tempDir = Directory.systemTemp.createTempSync('benesnap_marathon_');
    addTearDown(() => tempDir.deleteSync(recursive: true));

    // Through HomeScreen rather than straight onto a product route: the
    // kiosk reaches a product by `pushReplacementNamed`, which is what keeps
    // the stack at one entry, and starting anywhere else would not exercise
    // that.
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: Routes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/product/:id',
          name: Routes.productDetail,
          builder: (context, state) => ProductDetailScreen(
            productId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appStorageProvider.overrideWithValue(AppStorage(tempDir)),
          barcodeScannerProvider.overrideWithValue(scanner),
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
          routerConfig: router,
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        ),
      ),
    );
    await tester.pump();
    return router;
  }

  /// Pumps with the clock advancing until [finder] matches, so the database
  /// round trip and go_router's own plumbing — both of which resume from
  /// real timers — get a chance to run.
  Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 60 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('scans 25 products back to back without stacking screens', (
    tester,
  ) async {
    final db = await catalogue();
    final scanner = BarcodeScannerService();
    addTearDown(scanner.dispose);
    final router = await pumpKiosk(tester, db: db, scanner: scanner);

    for (var i = 1; i <= _productCount; i++) {
      // No waiting for the auto-return between scans: this is the queue at
      // the counter, each customer scanning over the last one's product.
      _scan(scanner, _barcodeAt(i));
      await pumpUntilFound(tester, find.text(_brandAt(i).toUpperCase()));

      expect(
        find.text(_brandAt(i).toUpperCase()),
        findsOneWidget,
        reason: 'scan $i should be showing its own product',
      );
      // The heart of it: one screen and one route, however many scans in.
      expect(
        find.byType(ProductDetailScreen),
        findsOneWidget,
        reason: 'scan $i left more than one product screen mounted',
      );
      expect(
        router.routerDelegate.currentConfiguration.matches,
        hasLength(1),
        reason: 'scan $i grew the navigation stack',
      );
      expect(tester.takeException(), isNull, reason: 'scan $i threw');
    }

    await disposeAndDrain(tester);
  });

  testWidgets('scans 25 products with a full auto-return between each', (
    tester,
  ) async {
    final db = await catalogue();
    final scanner = BarcodeScannerService();
    addTearDown(scanner.dispose);
    final router = await pumpKiosk(tester, db: db, scanner: scanner);

    for (var i = 1; i <= _productCount; i++) {
      _scan(scanner, _barcodeAt(i));
      await pumpUntilFound(tester, find.text(_brandAt(i).toUpperCase()));
      expect(
        find.text(_brandAt(i).toUpperCase()),
        findsOneWidget,
        reason: 'scan $i should be showing its own product',
      );

      // Let the countdown run out, so every iteration is a complete
      // build-and-dispose of the product screen — the cycle a leak would
      // accumulate across.
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(
        find.byType(ProductDetailScreen),
        findsNothing,
        reason: 'scan $i did not cycle back to the scan screen',
      );
      expect(
        find.byType(HomeScreen),
        findsOneWidget,
        reason: 'scan $i should have left exactly one scan screen behind',
      );
      expect(
        router.routerDelegate.currentConfiguration.matches,
        hasLength(1),
        reason: 'scan $i grew the navigation stack',
      );
      expect(tester.takeException(), isNull, reason: 'scan $i threw');
    }

    await disposeAndDrain(tester);
  });
}

/// Types [barcode] followed by Enter, mirroring what the HID scanner does to
/// the keyboard queue — see barcode_scanner_service_test.dart.
void _scan(BarcodeScannerService scanner, String barcode) {
  for (final char in barcode.split('')) {
    scanner.handleKeyEvent(_downEvent(character: char));
  }
  scanner.handleKeyEvent(_downEvent(logicalKey: LogicalKeyboardKey.enter));
}

KeyDownEvent _downEvent({String? character, LogicalKeyboardKey? logicalKey}) {
  return KeyDownEvent(
    physicalKey: PhysicalKeyboardKey.keyA,
    logicalKey: logicalKey ?? LogicalKeyboardKey.keyA,
    character: logicalKey == null ? character : null,
    timeStamp: Duration.zero,
  );
}
