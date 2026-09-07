import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/exceptions.dart';
import '../../providers/auth_providers.dart';
import '../../providers/database_providers.dart';
import '../../providers/scanner_providers.dart';
import '../../providers/settings_providers.dart';
import '../../services/scanner/scan_event.dart';
import '../../widgets/scan_indicator.dart';

/// The kiosk landing screen. Scan a product to see it; tap the account icon
/// to sign in as admin (or go straight to the inventory if already signed
/// in). An unrecognised barcode swaps the whole screen to a dedicated
/// not-found card rather than showing a small inline message.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.initialUnknownBarcode});

  /// Set when arriving here because a barcode scanned *elsewhere* (the
  /// product detail screen) turned out not to be in the catalogue — shows
  /// the not-found card immediately instead of the plain welcome view for a
  /// beat first.
  final String? initialUnknownBarcode;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _lookingUp = false;
  late String? _unknownBarcode = widget.initialUnknownBarcode;
  ProviderSubscription<AsyncValue<ScanResult>>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _scanSubscription = ref.listenManual<AsyncValue<ScanResult>>(
      scanStreamProvider,
      (previous, next) {
        // Matched on AsyncData rather than read through `next.value`: an
        // AsyncError keeps the previous value, so reading it would hand the
        // *last* scanned code back as if it had just been scanned again and
        // navigate a second time.
        if (next is AsyncData<ScanResult>) {
          _handleScan(next.value);
        } else if (next is AsyncError) {
          _reportScannerFault();
        }
      },
    );
  }

  @override
  void dispose() {
    _scanSubscription?.close();
    super.dispose();
  }

  /// A faulted scan stream means the counter has quietly stopped scanning,
  /// which nothing else on this screen would show.
  void _reportScannerFault() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تعذّر تشغيل الماسح. أعد تشغيل التطبيق.'),
        duration: Duration(days: 1),
      ),
    );
  }

  Future<void> _handleScan(ScanResult result) async {
    // A customer can sweep two products past the reader faster than the
    // first lookup returns. Without this, both continuations reach
    // pushReplacementNamed — this screen isn't disposed synchronously by the
    // first one, so the second still sees `mounted` and replaces again.
    if (_lookingUp) return;

    setState(() {
      _lookingUp = true;
      _unknownBarcode = null;
    });

    try {
      final product = await ref
          .read(productRepositoryProvider)
          .findByBarcode(result.code);
      if (!mounted) return;

      if (product != null) {
        // Replace, not push: this screen stays mounted underneath a pushed
        // route and keeps listening for scans, so a customer scanning again
        // before the previous product's auto-return delay elapses would
        // otherwise stack another product detail screen on top instead of
        // showing it — "back to home" would then only peel off one layer at
        // a time. Replacing disposes this HomeScreen along with its scan
        // listener, so a scan mid-display is simply dropped until the kiosk
        // cycles itself back to a fresh, listening HomeScreen. No
        // `setState` afterwards: this instance is going away, not merely
        // covered, so `_lookingUp` no longer matters.
        context.pushReplacementNamed(
          Routes.productDetail,
          pathParameters: {'id': product.id.toString()},
        );
      } else {
        setState(() {
          _lookingUp = false;
          _unknownBarcode = result.code;
        });
      }
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _lookingUp = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _openAccount() {
    if (ref.read(isAdminProvider)) {
      context.pushNamed(Routes.inventory);
    } else {
      context.pushNamed(Routes.login);
    }
  }

  void _scanAgain() => setState(() => _unknownBarcode = null);

  void _addUnknownProduct(String barcode) {
    context.pushNamed(Routes.productNew, extra: barcode);
  }

  @override
  Widget build(BuildContext context) {
    final unknownBarcode = _unknownBarcode;
    final isAdmin = ref.watch(isAdminProvider);
    final homeText = ref.watch(homeTextProvider);

    return Scaffold(
      body: SafeArea(
        child: unknownBarcode == null
            ? _WelcomeView(
                status: _lookingUp
                    ? ScanIndicatorStatus.lookingUp
                    : ScanIndicatorStatus.listening,
                welcomeTitle: homeText.welcomeTitle,
                extraLine: homeText.extraLine,
                onAccountPressed: _openAccount,
              )
            : _NotFoundView(
                barcode: unknownBarcode,
                canAdd: isAdmin,
                onScanAgain: _scanAgain,
                onAddProduct: () => _addUnknownProduct(unknownBarcode),
              ),
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView({
    required this.status,
    required this.welcomeTitle,
    required this.extraLine,
    required this.onAccountPressed,
  });

  final ScanIndicatorStatus status;
  final String welcomeTitle;
  final String extraLine;
  final VoidCallback onAccountPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          // "circle at 50% 38%" in the design — pulled up from dead centre.
          center: const Alignment(0, -0.24),
          radius: 1.0,
          colors: [tokens.canvasGradientTop, theme.colorScheme.secondary],
          stops: const [0.0, 0.62],
        ),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(34, 26, 34, 34),
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: _AccountButton(onPressed: onAccountPressed),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      welcomeTitle,
                      textAlign: TextAlign.center,
                      style:
                          AppTheme.weighted(
                            theme.textTheme.displaySmall,
                            FontWeight.w700,
                          ).copyWith(
                            fontSize: 54,
                            height: 1.3,
                            color: Colors.white,
                            // Derived from the active theme, not a fixed
                            // tan: this was the one colour the theming
                            // pass missed, so the white headline kept a
                            // warm brown glow on sage, sky and blush.
                            shadows: [
                              Shadow(
                                color: tokens.label.withValues(alpha: 0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                    ),
                    if (extraLine.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        extraLine,
                        textAlign: TextAlign.center,
                        style: AppTheme.weighted(
                          theme.textTheme.headlineSmall,
                          FontWeight.w500,
                        ).copyWith(fontSize: 22, color: tokens.muted),
                      ),
                    ],
                    const SizedBox(height: 52),
                    ScanIndicator(status: status),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: tokens.shadowColor.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.person_outline_rounded),
        iconSize: 24,
        tooltip: 'الحساب',
        color: theme.colorScheme.onSurface,
        style: IconButton.styleFrom(
          shape: const CircleBorder(),
          fixedSize: const Size(54, 54),
        ),
      ),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView({
    required this.barcode,
    required this.canAdd,
    required this.onScanAgain,
    required this.onAddProduct,
  });

  final String barcode;
  final bool canAdd;
  final VoidCallback onScanAgain;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return Center(
      // width: 520 as a hard size, not a cap, would force this off the edge
      // of a narrower window instead of shrinking to fit; SingleChildScrollView
      // covers the same "doesn't fit" case vertically, at a larger OS
      // text-scale setting.
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(40, 44, 40, 36),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: AppRadii.kioskCard,
              boxShadow: [
                BoxShadow(
                  color: tokens.shadowColor.withValues(alpha: 0.20),
                  blurRadius: 50,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.iconBadgeBg,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(15),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 26,
                      color: tokens.goldDeep,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                // A barcode is Latin/numeric content inside an otherwise Arabic
                // screen — force LTR so it reads left-to-right regardless of the
                // ambient RTL direction, matching what staff see printed on the
                // product's own label.
                Text(
                  barcode,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontFamily: 'monospace',
                    fontFamilyFallback: const ['Readex Pro'],
                    letterSpacing: 1.2,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Text(
                    'هذا المنتج غير متوفر في الكتالوج حتى الآن.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: tokens.body,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: onScanAgain,
                      child: const Text('مسح منتج آخر'),
                    ),
                    if (canAdd)
                      ElevatedButton(
                        onPressed: onAddProduct,
                        style: AppTheme.darkButtonStyle(context),
                        child: const Text('إضافة هذا المنتج'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
