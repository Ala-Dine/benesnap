import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/exceptions.dart';
import '../../data/models/product.dart';
import '../../data/models/suitability_tag.dart';
import '../../providers/database_providers.dart';
import '../../providers/product_providers.dart';
import '../../widgets/app_card.dart';

/// Shown after a successful scan. Escape or the back arrow return to the
/// scan screen; so does 60 seconds of inactivity, so an unattended counter
/// resets itself for the next customer.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.productId});

  final int productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  static const _inactivityTimeout = Duration(seconds: 60);

  Timer? _inactivityTimer;

  @override
  void initState() {
    super.initState();
    // Hooked at the hardware level, like the scanner service, so any key —
    // not just ones a focused widget would receive — counts as activity.
    HardwareKeyboard.instance.addHandler(_handleKey);
    _resetInactivityTimer();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _inactivityTimer?.cancel();
    super.dispose();
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
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final productAsync = ref.watch(productByIdProvider(widget.productId));

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetInactivityTimer(),
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: productAsync.when(
                    data: (product) => product == null
                        ? _StatusCard(
                            message: 'هذا المنتج لم يعد موجودًا في الكتالوج.',
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
              PositionedDirectional(
                top: 16,
                start: 16,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: _returnHome,
                    // `Icons.arrow_back_rounded` has `matchTextDirection: true`
                    // baked into its IconData, so it mirrors automatically
                    // under this app's ambient RTL Directionality.
                    icon: const Icon(Icons.arrow_back_rounded),
                    iconSize: 22,
                    tooltip: 'رجوع',
                    style: IconButton.styleFrom(
                      shape: const CircleBorder(),
                      fixedSize: const Size(44, 44),
                    ),
                  ),
                ),
              ),
            ],
          ),
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
      boxShadow: const [
        BoxShadow(
          color: Color(0x295A4014), // rgba(90,64,20,.16)
          blurRadius: 50,
          offset: Offset(0, 20),
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
            // A hero image needs room to breathe, so its height follows
            // whatever the text column naturally needs rather than a fixed
            // ratio — IntrinsicHeight is what makes CrossAxisAlignment.stretch
            // resolve that instead of collapsing to zero.
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
                          'الفوائد الأساسية',
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
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF1E5CD),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '✓',
                                    style: AppTheme.weighted(
                                      theme.textTheme.labelSmall,
                                      FontWeight.w700,
                                    ).copyWith(color: const Color(0xFF7A5E27)),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    line,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontSize: 20,
                                      height: 1.35,
                                      color: const Color(0xFF26221A),
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
                                  color: const Color(0xFF948864),
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
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 200),
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
                          ? Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: tokens.muted,
                            )
                          : Image.file(
                              File(storage.resolveImage(imagePath)),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stack) => Icon(
                                Icons.broken_image_outlined,
                                size: 36,
                                color: tokens.muted,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
