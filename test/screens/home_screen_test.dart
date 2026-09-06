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

import '../helpers/test_home_text.dart';

void main() {
  testWidgets(
    'a second scan while a product is on screen swaps straight to the new '
    'product instead of stacking another detail screen on top',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ProductRepository(db);
      await repository.create(
        const ProductDraft(
          barcode: 'A0001',
          brandName: 'BrandA',
          productName: 'ProductA',
          keyIngredients: 'Water',
          coreBenefits: 'Shine',
        ),
      );
      await repository.create(
        const ProductDraft(
          barcode: 'B0002',
          brandName: 'BrandB',
          productName: 'ProductB',
          keyIngredients: 'Oil',
          coreBenefits: 'Softness',
        ),
      );
      await repository.create(
        const ProductDraft(
          barcode: 'C0003',
          brandName: 'BrandC',
          productName: 'ProductC',
          keyIngredients: 'Aloe',
          coreBenefits: 'Calm',
        ),
      );

      final tempDir = Directory.systemTemp.createTempSync('benesnap_home_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      // Unattached: fed keystrokes directly below, exactly like
      // barcode_scanner_service_test.dart drives the service in isolation.
      // Overriding the provider with this instance (rather than letting it
      // build its own and call attach()) keeps the test from registering a
      // real HardwareKeyboard handler.
      final scanner = BarcodeScannerService();
      addTearDown(scanner.dispose);

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

      _scan(scanner, 'A0001');
      // Bare `pump()` only drains the microtask queue; the DB round trip and
      // go_router's own route-information plumbing resume from real
      // (fake-clock) timers, which need the clock actually advanced to fire —
      // hence a duration on every pump here, not just a frame.
      for (var i = 0; i < 20 && find.text('BRANDA').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      expect(find.text('BRANDA'), findsOneWidget);
      expect(find.byType(ProductDetailScreen), findsOneWidget);

      // `pushReplacementNamed` only disposes the outgoing route once the
      // incoming one finishes animating in, so HomeScreen — and its own
      // scan listener — lingers for a bit after BRANDA first appears. Wait
      // that out and confirm it's actually gone before scanning again:
      // otherwise a pass here could just mean HomeScreen's listener (not
      // ProductDetailScreen's own, which is the thing this test exists to
      // prove) happened to still be alive and caught the scan — as
      // happened when this was first written and passed even with no
      // listener on ProductDetailScreen at all. Not `pumpAndSettle`: the
      // product card starts its own 8-second auto-return countdown
      // animation as soon as it appears, which never "settles" on its own
      // until that timer runs out.
      for (var i = 0; i < 150; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.byType(HomeScreen), findsNothing);

      // Scanning again well within the 8-second auto-return window used to
      // push a second ProductDetailScreen on top of this one: HomeScreen
      // stayed mounted underneath a pushed route and kept listening for
      // scans, so it pushed a second "/product/:id" match on top of the
      // router's stack instead of showing the new product in place of the
      // old one. ProductDetailScreen now listens for scans itself too, so
      // this should swap straight to product B — checking the router's own
      // match list (rather than what happens to be built into the widget
      // tree yet) is what actually pins the "no stacking" part down:
      // go_router updates it synchronously on push, independent of
      // widget-mounting/transition timing.
      _scan(scanner, 'B0002');
      for (var i = 0; i < 20 && find.text('BRANDB').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      expect(find.text('BRANDB'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.matches, hasLength(1));

      // And a third, to prove this isn't just "the first scan after
      // landing on a fresh product screen still works" — it has to keep
      // responding to every scan, not just the next one.
      _scan(scanner, 'C0003');
      for (var i = 0; i < 20 && find.text('BRANDC').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      expect(find.text('BRANDC'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.matches, hasLength(1));
    },
  );

  testWidgets(
    're-scanning the same product still responds to the next, different scan',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ProductRepository(db);
      await repository.create(
        const ProductDraft(
          barcode: 'A0001',
          brandName: 'BrandA',
          productName: 'ProductA',
          keyIngredients: 'Water',
          coreBenefits: 'Shine',
        ),
      );
      await repository.create(
        const ProductDraft(
          barcode: 'B0002',
          brandName: 'BrandB',
          productName: 'ProductB',
          keyIngredients: 'Oil',
          coreBenefits: 'Softness',
        ),
      );

      final tempDir = Directory.systemTemp.createTempSync('benesnap_home2_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final scanner = BarcodeScannerService();
      addTearDown(scanner.dispose);

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

      _scan(scanner, 'A0001');
      for (var i = 0; i < 20 && find.text('BRANDA').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.text('BRANDA'), findsOneWidget);

      // Re-scan the *same* barcode while it's already showing. Unlike a
      // scan for a different product, `pushReplacementNamed`'s new page
      // resolves to the exact same location as the current one — go_router
      // keys a plain (non-imperative) match by its matched path, and
      // replacing the only entry on the stack falls back to exactly that
      // kind of match, so the new page carries the *same* ValueKey as the
      // one already on screen. The Navigator then treats it as the same
      // page rather than a fresh one: no new element, no rebuild.
      _scan(scanner, 'A0001');
      await tester.pump(const Duration(milliseconds: 500));

      // The real bug report this guards against: after that self-replace,
      // the screen must still answer a *different* scan — it must not be
      // stuck showing product A regardless of what gets scanned next.
      _scan(scanner, 'B0002');
      for (var i = 0; i < 40 && find.text('BRANDB').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      expect(tester.takeException(), isNull);
      expect(find.text('BRANDB'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.matches, hasLength(1));
    },
  );
}

/// Types [barcode] followed by Enter, mirroring what the HID scanner does
/// to the keyboard queue — see barcode_scanner_service_test.dart.
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
