// The product form is the largest and most stateful screen in the app: it
// guards unsaved changes, stages image files it has to clean up if you walk
// away, enforces barcode uniqueness, and suppresses the global scanner while
// it is open. None of that was covered.

import 'dart:io';

import 'package:benesnap/app/theme.dart';
import 'package:benesnap/data/db/app_database.dart';
import 'package:benesnap/data/db/connection.dart';
import 'package:benesnap/data/models/product.dart';
import 'package:benesnap/data/repositories/product_repository.dart';
import 'package:benesnap/providers/database_providers.dart';
import 'package:benesnap/providers/scanner_providers.dart';
import 'package:benesnap/screens/product_form/product_form_screen.dart';
import 'package:benesnap/services/scanner/barcode_scanner_service.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/drift_settle.dart';

void main() {
  late AppDatabase db;
  late ProductRepository products;
  late Directory tempDir;
  late AppStorage storage;
  late BarcodeScannerService scanner;

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

    tempDir = Directory.systemTemp.createTempSync('benesnap_form_');
    addTearDown(() => tempDir.deleteSync(recursive: true));
    storage = AppStorage(tempDir);
    await storage.imagesDirectory.create(recursive: true);

    // Unattached, so the test never registers a real HardwareKeyboard
    // handler — same approach as barcode_scanner_service_test.dart.
    scanner = BarcodeScannerService();
    addTearDown(scanner.dispose);
  });

  Widget wrap({int? productId}) {
    return ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appStorageProvider.overrideWithValue(storage),
        barcodeScannerProvider.overrideWithValue(scanner),
      ],
      child: MaterialApp.router(
        theme: AppTheme.light,
        routerConfig: GoRouter(
          initialLocation: productId == null
              ? '/inventory/new'
              : '/inventory/$productId/edit',
          routes: [
            GoRoute(
              path: '/inventory',
              builder: (_, _) => const Scaffold(body: Text('inventory')),
              routes: [
                GoRoute(
                  path: 'new',
                  builder: (_, _) => const ProductFormScreen(),
                ),
                GoRoute(
                  path: ':id/edit',
                  builder: (_, state) => ProductFormScreen(
                    productId: int.parse(state.pathParameters['id']!),
                  ),
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

  /// The tag chips come from a drift stream, so frames have to be pumped
  /// with the clock actually advancing rather than settled.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 20));
    }
  }

  testWidgets('suppresses the global scanner while open, and releases it '
      'on the way out', (tester) async {
    expect(scanner.enabled, isTrue);

    await tester.pumpWidget(wrap());
    await settle(tester);
    expect(scanner.enabled, isFalse);

    await disposeAndDrain(tester);
    expect(scanner.enabled, isTrue);
  });

  testWidgets('leaving with unsaved edits asks first', (tester) async {
    await tester.pumpWidget(wrap());
    await settle(tester);

    await tester.enterText(find.byType(TextField).first, 'ABC123');
    await settle(tester);

    await tester.tap(find.byTooltip('رجوع'));
    await settle(tester);

    expect(find.text('تجاهل التغييرات؟'), findsOneWidget);
    await disposeAndDrain(tester);
  });

  testWidgets('leaving an untouched form does not ask', (tester) async {
    await tester.pumpWidget(wrap());
    await settle(tester);

    await tester.tap(find.byTooltip('رجوع'));
    await settle(tester);

    expect(find.text('تجاهل التغييرات؟'), findsNothing);
    expect(find.text('inventory'), findsOneWidget);
    await disposeAndDrain(tester);
  });

  testWidgets('a barcode already used by another product is refused with a '
      'message naming it', (tester) async {
    await products.create(
      const ProductDraft(
        barcode: 'TAKEN1',
        brandName: 'Other',
        productName: 'Product',
        keyIngredients: 'Water',
        coreBenefits: 'Shine',
      ),
    );

    await tester.pumpWidget(wrap());
    await settle(tester);

    await tester.enterText(find.byType(TextField).at(0), 'TAKEN1');
    await tester.enterText(find.byType(TextField).at(1), 'Brand');
    await tester.enterText(find.byType(TextField).at(2), 'Product');
    await settle(tester);

    expect(find.textContaining('TAKEN1'), findsWidgets);
    // The catalogue is untouched: still just the one product.
    expect(await products.all(), hasLength(1));

    await disposeAndDrain(tester);
  });

  testWidgets('saving an edit writes the new values', (tester) async {
    final created = await products.create(
      const ProductDraft(
        barcode: 'EDIT01',
        brandName: 'Before',
        productName: 'Product',
        keyIngredients: 'Water',
        coreBenefits: 'Shine',
      ),
    );

    await tester.pumpWidget(wrap(productId: created.id));
    await settle(tester);

    await tester.enterText(find.byType(TextField).at(1), 'After');
    await settle(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'حفظ'));
    await settle(tester);

    expect((await products.findById(created.id))!.brandName, 'After');
    await disposeAndDrain(tester);
  });
}
