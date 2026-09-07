import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/exceptions.dart';
import '../../data/models/product.dart';
import '../../data/models/suitability_tag.dart';
import '../../providers/database_providers.dart';
import '../../providers/product_providers.dart';
import '../../providers/scanner_providers.dart';
import '../../services/scanner/scan_event.dart';
import '../../widgets/app_card.dart';
import '../../widgets/product_image.dart';
import '../../widgets/striped_placeholder.dart';

/// Shown after a successful scan. A product that loads successfully cycles
/// back to the scan screen on its own after a short, fixed delay — a kiosk
/// should be ready for the next customer without anyone touching it.
/// Scanning another barcode at any point while this screen is up jumps
/// straight to that product (or back to the scan screen if it isn't in the
/// catalogue), same as scanning from the home screen. Escape leaves
/// immediately; loading/error states instead fall back to a longer
/// 60-second inactivity timeout, since there's no result yet to time out
/// *from*.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  /// The backstop for the states [_autoReturnDelay] never covers.
  ///
  /// Worth being precise about, because it looks like dead code and isn't:
  /// the auto-return below only starts once a product actually loads (see
  /// `_maybeStartAutoReturn`, called with `next.value`). On the success
  /// path this timer is therefore always cancelled by the dispose that
  /// follows the auto-return, and never fires. What it does cover is a
  /// screen showing the "no longer in the catalogue" or load-failure card:
  /// there is no countdown there, so without this an unattended counter
  /// would sit on an error message until someone noticed.
  static const _inactivityTimeout = Duration(seconds: 60);

  /// How long a *successfully shown* product stays on screen before the
  /// kiosk cycles itself back to "امسح الكود" for the next customer.
  ///
  /// Short and unconditional, unlike [_inactivityTimeout]: the whole point
  /// is that nobody has to touch anything for the kiosk to be ready for the
  /// next scan.
  static const _autoReturnDelay = Duration(seconds: 8);

  Timer? _inactivityTimer;
  late final AnimationController _autoReturnController;
  bool _autoReturnStarted = false;
  ProviderSubscription<AsyncValue<ScanResult>>? _scanSubscription;

  @override
  void initState() {
    super.initState();
    // Built here rather than as a lazy `late` field initializer: a screen
    // that never shows a product (an unrecognised barcode, or leaving via
    // Escape or another scan before this one's own product finishes
    // loading) disposes without `_maybeStartAutoReturn` ever touching this
    // controller. A lazy initializer would then construct it for the first
    // time *inside* dispose() — `createTicker` needs this widget's
    // BuildContext to look up TickerMode, which is unsafe once the element
    // is deactivated, and throws "Looking up a deactivated widget's
    // ancestor is unsafe". Building it eagerly here, while the widget is
    // still definitely active, avoids that entirely.
    _autoReturnController = AnimationController(
      vsync: this,
      duration: _autoReturnDelay,
    )..addStatusListener(_onAutoReturnStatusChanged);
    // Hooked at the hardware level, like the scanner service, so any key —
    // not just ones a focused widget would receive — counts as activity.
    HardwareKeyboard.instance.addHandler(_handleKey);
    _resetInactivityTimer();
    // Home's own scan listener only exists while home is on screen — this
    // one is what lets a customer scan straight through to a *different*
    // product without waiting out the auto-return delay first.
    _scanSubscription = ref.listenManual<AsyncValue<ScanResult>>(
      scanStreamProvider,
      (previous, next) {
        // AsyncData only — see HomeScreen's listener for why reading
        // `next.value` would re-navigate to the previous code on an error.
        if (next is AsyncData<ScanResult>) _handleScan(next.value);
      },
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _inactivityTimer?.cancel();
    _autoReturnController.dispose();
    _scanSubscription?.close();
    super.dispose();
  }

  /// Looks up a barcode scanned while this screen is already showing one.
  ///
  /// Replaces, not pushes — same reasoning as `HomeScreen._handleScan`: this
  /// disposes the current instance (and its listener) along with the route,
  /// so the stack never grows no matter how many products get scanned in a
  /// row. An unrecognised barcode goes back to the scan screen and hands it
  /// the code, so the "not in the catalogue" card shows up immediately
  /// instead of leaving the customer looking at the old product.
  ///
  /// Re-scanning the *same* product is a special case: `pushReplacementNamed`
  /// would target this exact route again, and go_router keys a plain
  /// (non-imperative) match by its matched path — replacing the only entry
  /// on the stack, which this screen always is, falls back to exactly that
  /// kind of match. So the "new" page carries the same key as the one
  /// already on screen, the Navigator treats it as the same page, and
  /// nothing about it actually restarts: no new element, no fresh
  /// `initState`, and critically the 8-second auto-return keeps counting
  /// down from whenever it first started rather than from this scan. Scan
  /// the same item again a second before it was about to cycle back on its
  /// own and the screen would auto-return almost immediately after —
  /// looking exactly like the scan did nothing, or that the kiosk got
  /// "stuck" for everything except the countdown. Restarting the countdown
  /// in place sidesteps the whole key-reuse question.
  Future<void> _handleScan(ScanResult result) async {
    try {
      final product = await ref
          .read(productRepositoryProvider)
          .findByBarcode(result.code);
      if (!mounted) return;

      if (product != null) {
        if (product.id == widget.productId) {
          _restartAutoReturn();
        } else {
          context.pushReplacementNamed(
            Routes.productDetail,
            pathParameters: {'id': product.id.toString()},
          );
        }
      } else {
        context.goNamed(Routes.home, extra: result.code);
      }
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _onAutoReturnStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) _returnHome();
  }

  /// Starts the countdown the first time [product] resolves to a real row —
  /// a no-op on every rebuild after that, and never for the loading/error/
  /// not-found states, which keep only the long inactivity backstop.
  void _maybeStartAutoReturn(Product? product) {
    if (product == null || _autoReturnStarted) return;
    setState(() => _autoReturnStarted = true);
    _autoReturnController.forward();
  }

  /// Restarts the 8-second countdown from zero — see `_handleScan` above for
  /// why re-scanning the product already on screen needs this instead of
  /// just navigating again.
  void _restartAutoReturn() {
    if (!_autoReturnStarted) {
      setState(() => _autoReturnStarted = true);
    }
    _autoReturnController.forward(from: 0);
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(_inactivityTimeout, _returnHome);
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      _resetInactivityTimer();
      if (event.logicalKey == LogicalKeyboardKey.escape) _returnHome();
    }
    return false;
  }

  void _returnHome() {
    if (!mounted) return;
    context.popOr('/');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTokens.of(context);
    final productAsync = ref.watch(productByIdProvider(widget.productId));

    ref.listen<AsyncValue<Product?>>(productByIdProvider(widget.productId), (
      previous,
      next,
    ) {
      _maybeStartAutoReturn(next.value);
    });

    // `ref.listen` above only catches a *transition* into data — the normal
    // case for a barcode scanned for the first time this app run, whose
    // lookup is still loading when this screen's first build registers the
    // listener. `productByIdProvider` isn't autoDispose, though: a product
    // scanned once already has its result cached, so re-scanning it later
    // (even long after the countdown returned home) resolves to `AsyncData`
    // on this very first build — no loading-to-data transition for the
    // listener above to ever see, so the countdown would otherwise never
    // start and this screen would sit there forever instead of cycling
    // back. Deferred past this build so `_maybeStartAutoReturn`'s
    // `setState` is safe to call.
    if (!_autoReturnStarted && productAsync.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeStartAutoReturn(productAsync.value);
      });
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetInactivityTimer(),
      child: Scaffold(
        body: Stack(
          children: [
            // The progress bar below animates for 8 seconds after every
            // scan, and it is a sibling of this card in the same Stack.
            // FractionallySizedBox is not a relayout boundary — it takes
            // loose constraints from RenderStack with parentUsesSize — so
            // without a boundary here each of those frames marks this
            // subtree dirty and re-rasterises the whole hero card: a 50px
            // blur shadow, the decoded photo, and StripedPlaceholder's
            // CustomPaint. That is the most expensive thing in the app, on
            // the path it runs on most.
            RepaintBoundary(
              child: SafeArea(
                // The hero card's content (photo, tags, benefits, ingredients)
                // can run taller than the window at the app's own enforced
                // 700px minimum height, or at a larger OS text-scale setting —
                // neither is hypothetical for a shop's own kiosk hardware.
                // LayoutBuilder + a min-height ConstrainedBox keeps everything
                // centered exactly as before when it fits, and lets it scroll
                // instead of hard-overflowing when it doesn't.
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 64,
                      ),
                      child: Center(
                        child: productAsync.when(
                          data: (product) => product == null
                              ? _StatusCard(
                                  message:
                                      'هذا المنتج لم يعد موجودًا في الكتالوج.',
                                  onBack: _returnHome,
                                )
                              : _ProductDetailCard(product: product),
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stack) => _StatusCard(
                            message: error is AppException
                                ? error.message
                                : 'تعذّر تحميل هذا المنتج.',
                            onBack: _returnHome,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // A draining top bar, not a silent auto-navigate: whoever is
            // reading knows a new scan is coming and roughly when, the same
            // way a "next slide" countdown works elsewhere.
            if (_autoReturnStarted)
              PositionedDirectional(
                top: 0,
                start: 0,
                end: 0,
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _autoReturnController,
                    builder: (context, _) => FractionallySizedBox(
                      alignment: AlignmentDirectional.centerStart,
                      widthFactor: 1 - _autoReturnController.value,
                      child: Container(height: 4, color: tokens.gold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProductDetailCard extends ConsumerWidget {
  const _ProductDetailCard({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final storage = ref.watch(appStorageProvider);
    final imagePath = product.imagePath;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 46),
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      // Heavier and warmer than the shared cardShadow default — this is the
      // one full-screen "hero" card in the app.
      boxShadow: [
        BoxShadow(
          color: tokens.shadowColor.withValues(alpha: 0.16),
          blurRadius: 50,
          offset: const Offset(0, 20),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: tokens.divider)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brandName.toUpperCase(),
                    style: AppTheme.weighted(
                      theme.textTheme.labelMedium,
                      FontWeight.w700,
                    ).copyWith(color: tokens.gold, letterSpacing: 2),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.productName,
                    style: AppTheme.weighted(
                      theme.textTheme.headlineLarge,
                      FontWeight.w700,
                    ).copyWith(fontSize: 44, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            // IntrinsicHeight + stretch here is only to give the divider
            // between the two columns a real height to fill (a plain
            // Container can't size itself from siblings otherwise) — the
            // image panel keeps its own fixed aspect ratio regardless, see
            // the comment further down.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (product.tags.isNotEmpty) ...[
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final tag in product.tags)
                                _SuitabilityChip(tag: tag),
                            ],
                          ),
                          const SizedBox(height: 28),
                        ],
                        Text(
                          'ماذا يفعل',
                          style: AppTheme.weighted(
                            theme.textTheme.labelMedium,
                            FontWeight.w700,
                          ).copyWith(color: tokens.muted, fontSize: 13),
                        ),
                        const SizedBox(height: 14),
                        for (final line in product.benefitLines)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 26,
                                  height: 26,
                                  margin: const EdgeInsets.only(top: 2),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: tokens.skinChipBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '✓',
                                    style: AppTheme.weighted(
                                      theme.textTheme.labelSmall,
                                      FontWeight.w700,
                                    ).copyWith(color: tokens.goldDeep),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontSize: 20,
                                      height: 1.35,
                                      color: tokens.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 18),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: tokens.divider),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المكوّنات الرئيسية',
                                style: AppTheme.weighted(
                                  theme.textTheme.labelSmall,
                                  FontWeight.w700,
                                ).copyWith(color: tokens.faint),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                product.keyIngredients,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.8,
                                  color: tokens.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 44),
                  Container(width: 1, color: tokens.divider),
                  const SizedBox(width: 44),
                  Expanded(
                    // A fixed ratio, not the text column's height: with
                    // CrossAxisAlignment.stretch above, an unwrapped image
                    // panel here would stretch to match however tall this
                    // *particular* product's benefit list happens to be —
                    // squat and wide for a short one, tall and narrow for a
                    // long one. Aligning a fixed-ratio box inside the
                    // stretched slot instead keeps every product's photo
                    // the same shape; only the leftover space below it (if
                    // this product's text is taller than the image) varies.
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: AspectRatio(
                        aspectRatio: 6 / 5,
                        child: Container(
                          decoration: BoxDecoration(
                            color: tokens.imagePanelBg,
                            borderRadius: const BorderRadius.all(
                              Radius.circular(22),
                            ),
                            border: Border.all(color: tokens.imagePanelBorder),
                          ),
                          alignment: Alignment.center,
                          clipBehavior: Clip.antiAlias,
                          child: imagePath == null
                              ? StripedPlaceholder(
                                  background: tokens.imagePanelBg,
                                  stripe: tokens.imagePanelBorder,
                                  label: 'صورة المنتج',
                                  labelStyle: theme.textTheme.bodyMedium
                                      ?.copyWith(color: tokens.faint),
                                )
                              : ProductImage(
                                  file: File(storage.resolveImage(imagePath)),
                                  brokenIconSize: 36,
                                  fillBrokenBackground: false,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuitabilityChip extends StatelessWidget {
  const _SuitabilityChip({required this.tag});

  final SuitabilityTag tag;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final isSkin = tag.category == TagCategory.skin;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSkin ? tokens.skinChipBg : tokens.hairChipBg,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
      ),
      child: Text(
        tag.label,
        style: AppTheme.weighted(theme.textTheme.bodyLarge, FontWeight.w600)
            .copyWith(
              fontSize: 18,
              color: isSkin ? tokens.skinChipFg : tokens.hairChipFg,
            ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onBack,
            style: AppTheme.darkButtonStyle(context),
            child: const Text('العودة إلى المسح'),
          ),
        ],
      ),
    );
  }
}
