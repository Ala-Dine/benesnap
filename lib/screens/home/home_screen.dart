import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/exceptions.dart';
import '../../data/models/home_text.dart';
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
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _lookingUp = false;
  String? _unknownBarcode;
  ProviderSubscription<AsyncValue<ScanResult>>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    _scanSubscription = ref.listenManual<AsyncValue<ScanResult>>(
      scanStreamProvider,
      (previous, next) {
        final result = next.value;
        if (result != null) _handleScan(result);
      },
    );
  }

  @override
  void dispose() {
    _scanSubscription?.close();
    super.dispose();
  }

  Future<void> _handleScan(ScanResult result) async {
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
        setState(() => _lookingUp = false);
        await context.pushNamed(
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
    final homeText = ref.watch(homeTextProvider).value;

    return Scaffold(
      body: SafeArea(
        child: unknownBarcode == null
            ? _WelcomeView(
                status: _lookingUp
                    ? ScanIndicatorStatus.lookingUp
                    : ScanIndicatorStatus.listening,
                welcomeTitle: homeText?.welcomeTitle ?? defaultWelcomeTitle,
                extraLine: homeText?.extraLine ?? '',
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
                            shadows: const [
                              Shadow(
                                color: Color(0x38785A23),
                                blurRadius: 18,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                    ),
                    if (extraLine.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        extraLine,
                        textAlign: TextAlign.center,
                        style:
                            AppTheme.weighted(
                              theme.textTheme.headlineSmall,
                              FontWeight.w500,
                            ).copyWith(
                              fontSize: 22,
                              color: Colors.white.withValues(alpha: 0.92),
                              shadows: const [
                                Shadow(
                                  color: Color(0x38785A23),
                                  blurRadius: 14,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
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

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x295A4014), // rgba(90,64,20,.16)
            blurRadius: 16,
            offset: Offset(0, 6),
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
      child: Container(
        width: 520,
        padding: const EdgeInsets.fromLTRB(40, 44, 40, 36),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.all(Radius.circular(26)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x335A4014), // rgba(90,64,20,.2)
              blurRadius: 50,
              offset: Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xFFF6EFE1),
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
    );
  }
}
