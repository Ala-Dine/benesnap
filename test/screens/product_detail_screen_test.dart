import 'dart:async';
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
    'auto-returns home a fixed delay after a product loads, not before',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final created = await ProductRepository(db).create(
        const ProductDraft(
          barcode: 'X1',
          brandName: 'Brand',
          productName: 'Product',
          keyIngredients: 'Water',
          coreBenefits: 'Shine',
        ),
      );

      final tempDir = Directory.systemTemp.createTempSync('benesnap_pd_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('HOME')),
          ),
          GoRoute(
            path: '/product/:id',
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

      // Mirrors HomeScreen's own `context.pushNamed(Routes.productDetail,
      // ...)` after a successful scan — starting `initialLocation` directly
      // on the product route isn't representative of how the app actually
      // gets there.
      await tester.pump();
      expect(find.text('HOME'), findsOneWidget);
      unawaited(router.push('/product/${created.id}'));
      await tester.pump();

      // Let the FutureProvider resolve and the product card build — no
      // real timer involved yet, just drift's async plumbing settling.
      for (var i = 0; i < 10 && find.text('BRAND').evaluate().isEmpty; i++) {
        await tester.pump();
      }

      // The pushed route stacks on top of "/" — its widget stays mounted
      // underneath the whole time, so presence of "BRAND" (only rendered
      // by the product card) is the signal that actually matters here, not
      // "HOME"'s presence/absence.
      expect(find.text('BRAND'), findsOneWidget);
      // The draining countdown bar is only in the tree once the timer has
      // actually started.
      expect(find.byType(AnimatedBuilder), findsWidgets);

      // Comfortably inside the 8-second delay: still showing the product.
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('BRAND'), findsOneWidget);

      // Past the delay: the kiosk should have cycled back on its own. The
      // pop itself fires here, but the route doesn't leave the tree until
      // its own pop *transition* finishes — give that its usual span too.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('BRAND'), findsNothing);
      expect(find.byType(ProductDetailScreen), findsNothing);
    },
  );

  testWidgets(
    'auto-returns home again the second time the same product is scanned, '
    "even though the first scan's lookup is still cached",
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await ProductRepository(db).create(
        const ProductDraft(
          barcode: 'X0001',
          brandName: 'Brand',
          productName: 'Product',
          keyIngredients: 'Water',
          coreBenefits: 'Shine',
        ),
      );

      final tempDir = Directory.systemTemp.createTempSync('benesnap_pd_twice_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final scanner = BarcodeScannerService();
      addTearDown(scanner.dispose);

      // Routed through HomeScreen and using one long-lived ProviderScope for
      // both scans, like the re-scan test below — `productByIdProvider`
      // isn't autoDispose, so its cache persists across this whole test,
      // exactly like it persists across two separate real-world scans of
      // the same barcode. That persistence is the thing this test exists
      // to reproduce, not an artifact to avoid.
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

      // First scan: the lookup is genuinely still loading when this
      // screen's first build registers `ref.listen`, so the loading-to-data
      // transition it watches for actually happens here.
      _scan(scanner, 'X0001');
      for (var i = 0; i < 20 && find.text('BRAND').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.text('BRAND'), findsOneWidget);

      // Let the full countdown play out and confirm it cycles back on its
      // own — the "first time it's back to home" half of the bug report
      // this test guards against.
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.byType(ProductDetailScreen), findsNothing);

      // Second scan of the *same* barcode: `productByIdProvider(id)`'s
      // result is already cached from the first scan, so this new screen's
      // very first build sees `AsyncData` immediately — no loading-to-data
      // transition for `ref.listen` to catch. Without the fix, this leaves
      // `_autoReturnStarted` false forever and the screen never cycles back
      // a second time — the "second time it don't" half of the report.
      _scan(scanner, 'X0001');
      for (var i = 0; i < 20 && find.text('BRAND').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.text('BRAND'), findsOneWidget);

      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.byType(ProductDetailScreen), findsNothing);
    },
  );

  testWidgets(
    'leaving before a product ever loads (an id not in the catalogue, then '
    'Escape) disposes this screen safely instead of crashing',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      final tempDir = Directory.systemTemp.createTempSync('benesnap_pd_nf_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('HOME')),
          ),
          GoRoute(
            path: '/product/:id',
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

      // An id with no matching row: `productByIdProvider` resolves to
      // `AsyncData(null)` rather than erroring, showing the not-found
      // `_StatusCard` — the *product == null* branch that
      // `_maybeStartAutoReturn` deliberately skips, so
      // `_autoReturnController` is never touched. This is a more direct,
      // timing-independent way to reach that state than racing two scans
      // against each other, but the underlying bug is the same one a
      // customer hits by scanning something not in the catalogue and then
      // just walking away, or pressing Escape, before ever scanning
      // something that *is* in it.
      unawaited(router.push('/product/999'));
      for (
        var i = 0;
        i < 10 && find.byType(ProductDetailScreen).evaluate().isEmpty;
        i++
      ) {
        await tester.pump();
      }
      for (
        var i = 0;
        i < 10 &&
            find
                .text('هذا المنتج لم يعد موجودًا في الكتالوج.')
                .evaluate()
                .isEmpty;
        i++
      ) {
        await tester.pump();
      }
      expect(
        find.text('هذا المنتج لم يعد موجودًا في الكتالوج.'),
        findsOneWidget,
      );

      // Escape is the same path a customer's own next scan takes this
      // screen through — `_handleKey`/`_returnHome` today, `_handleScan`'s
      // `pushReplacementNamed` before it. Either way, this screen gets
      // disposed having never touched `_autoReturnController`.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);

      // `pop()`/`pushReplacement` only dispose the outgoing route once its
      // transition finishes, not the instant it's requested — give that
      // its usual span before checking for the exception, or this would
      // pass even against the bug just because dispose() hadn't run yet.
      for (var i = 0; i < 150; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      // No FlutterError ("Looking up a deactivated widget's ancestor is
      // unsafe") means the outgoing screen's dispose() completed cleanly.
      expect(tester.takeException(), isNull);
      expect(find.byType(ProductDetailScreen), findsNothing);
    },
  );

  testWidgets(
    're-scanning the product already on screen restarts the auto-return '
    'countdown instead of leaving the original one running',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await ProductRepository(db).create(
        const ProductDraft(
          barcode: 'X0001',
          brandName: 'Brand',
          productName: 'Product',
          keyIngredients: 'Water',
          coreBenefits: 'Shine',
        ),
      );

      final tempDir = Directory.systemTemp.createTempSync('benesnap_pd_re_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      // Unattached: fed keystrokes directly below, exactly like
      // barcode_scanner_service_test.dart drives the service in isolation.
      final scanner = BarcodeScannerService();
      addTearDown(scanner.dispose);

      // Routed through HomeScreen (rather than `router.push` straight onto
      // `/product/:id`, like the other tests in this file) is deliberate
      // here: HomeScreen reaches this screen via `pushReplacementNamed`,
      // same as a real scan does, which leaves the stack at exactly one
      // entry — `router.push` would leave two ("/" underneath), and with
      // two entries a same-path `pushReplacementNamed` takes a different,
      // uniquely-keyed branch in go_router that doesn't reproduce the bug
      // this test exists to catch.
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
      _scan(scanner, 'X0001');
      for (var i = 0; i < 20 && find.text('BRAND').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.text('BRAND'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.matches, hasLength(1));

      // Mid-countdown: comfortably inside the original 8-second window.
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('BRAND'), findsOneWidget);

      // Re-scan the same barcode. `pushReplacementNamed` would target this
      // exact route again — go_router keys a plain (non-imperative) match
      // by its matched path, and replacing the only entry on the stack
      // (this screen, always) falls back to exactly that kind of match. So
      // without the fix, the Navigator treats the "new" page as identical
      // to the one already on screen — same element, countdown and all,
      // never reset — right up until that untouched original controller
      // completes on its own and fires a *second*, redundant `go('/')`
      // navigation on top of whatever this reused element does next. That
      // second, confused navigation is what left the app with a stale
      // product screen still visible and a fresh, offstage home screen
      // both alive at once: verified by inspecting the live element tree
      // while this test was being written — not a hypothetical, the actual
      // mechanism behind the "stuck" report. Restarting the countdown
      // in-place sidesteps the whole key-reuse question instead of
      // navigating through it.
      _scan(scanner, 'X0001');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('BRAND'), findsOneWidget);
      // The bug this guards against left a stray, fully-built HomeScreen
      // sitting alongside the still-visible product screen at this point.
      expect(find.byType(HomeScreen), findsNothing);
      expect(find.byType(ProductDetailScreen), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.matches, hasLength(1));

      // The countdown is running again, though — comfortably past a fresh
      // 8 seconds *from the re-scan* (0.5s settle + 3s above + 5s here =
      // 8.5s since the re-scan), it should have cycled back on its own.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('BRAND'), findsNothing);
      expect(find.byType(ProductDetailScreen), findsNothing);
    },
  );

  testWidgets(
    'scanning a different product while one is already showing replaces it '
    'directly instead of waiting out the auto-return delay',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ProductRepository(db);
      await repository.create(
        const ProductDraft(
          barcode: 'X0001',
          brandName: 'BrandA',
          productName: 'ProductA',
          keyIngredients: 'Water',
          coreBenefits: 'Shine',
        ),
      );
      await repository.create(
        const ProductDraft(
          barcode: 'X0002',
          brandName: 'BrandB',
          productName: 'ProductB',
          keyIngredients: 'Oil',
          coreBenefits: 'Glow',
        ),
      );

      final tempDir = Directory.systemTemp.createTempSync('benesnap_pd_diff_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      // Unattached, fed keystrokes directly below — same setup as the
      // same-product re-scan test above.
      final scanner = BarcodeScannerService();
      addTearDown(scanner.dispose);

      // Routed through HomeScreen, same reasoning as the re-scan test: this
      // is the only way to reach ProductDetailScreen with exactly one route
      // on the stack, which is what a real scan-to-scan flow looks like.
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
      _scan(scanner, 'X0001');
      for (var i = 0; i < 20 && find.text('BRANDA').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }
      expect(find.text('BRANDA'), findsOneWidget);
      expect(router.routerDelegate.currentConfiguration.matches, hasLength(1));

      // Mid-countdown for product A: comfortably inside its 8-second window.
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('BRANDA'), findsOneWidget);

      // A different product scanned while A is still on screen — this is
      // ProductDetailScreen's *own* scan listener (see `_handleScan`'s doc
      // comment), independent of HomeScreen's, letting a customer scan
      // straight through without waiting out A's auto-return delay.
      _scan(scanner, 'X0002');
      for (var i = 0; i < 40 && find.text('BRANDB').evaluate().isEmpty; i++) {
        await tester.pump(const Duration(milliseconds: 20));
      }

      expect(tester.takeException(), isNull);
      expect(find.text('BRANDB'), findsOneWidget);
      expect(find.text('BRANDA'), findsNothing);
      // pushReplacementNamed, not push: still exactly one route on the
      // stack, not A underneath B.
      expect(router.routerDelegate.currentConfiguration.matches, hasLength(1));

      // The new screen's own countdown must be running fresh for B, not
      // inherited/expired from A's — comfortably past a full 8 seconds
      // *from the scan of B*, it should have cycled back on its own.
      await tester.pump(const Duration(seconds: 8));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      expect(find.text('BRANDB'), findsNothing);
      expect(find.byType(ProductDetailScreen), findsNothing);
    },
  );

  testWidgets(
    'the image panel keeps the same shape regardless of how much text the '
    'product has',
    (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = ProductRepository(db);
      final short = await repository.create(
        const ProductDraft(
          barcode: 'SHORT1',
          brandName: 'Brand',
          productName: 'Short',
          keyIngredients: 'Water',
          coreBenefits: 'One thing',
        ),
      );
      final long = await repository.create(
        const ProductDraft(
          barcode: 'LONG1',
          brandName: 'Brand',
          productName: 'Long',
          keyIngredients:
              'A very long list of ingredients that pushes the text '
              'column far taller than a single short line ever would, '
              'wrapping across several lines of its own.',
          coreBenefits:
              'The first benefit, spelled out at some length\n'
              'A second benefit, also fairly wordy\n'
              'And a third one for good measure',
        ),
      );

      final tempDir = Directory.systemTemp.createTempSync('benesnap_pd_ar_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const Scaffold(body: Text('HOME')),
          ),
          GoRoute(
            path: '/product/:id',
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

      unawaited(router.push('/product/${short.id}'));
      for (
        var i = 0;
        i < 10 && find.byType(AspectRatio).evaluate().isEmpty;
        i++
      ) {
        await tester.pump();
      }
      final shortRatio = tester
          .widget<AspectRatio>(find.byType(AspectRatio))
          .aspectRatio;

      unawaited(router.push('/product/${long.id}'));
      for (
        var i = 0;
        i < 10 && find.byType(AspectRatio).evaluate().length < 2;
        i++
      ) {
        await tester.pump();
      }
      final longRatio = tester
          .widget<AspectRatio>(find.byType(AspectRatio).last)
          .aspectRatio;

      // Same fixed shape either way — a much longer benefits list and
      // ingredients paragraph must never stretch or squash the photo, only
      // change how much space is left over next to it.
      expect(shortRatio, longRatio);
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
