import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/navigation.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/exceptions.dart';
import '../../data/models/product.dart';
import '../../providers/database_providers.dart';
import '../../providers/product_providers.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/product_image.dart';
import '../../widgets/striped_placeholder.dart';

/// Admin-only catalogue management: a searchable, responsive grid of
/// products. Delete via right-click, long-press, or the card's own delete
/// icon (kept for keyboard/no-mouse reachability — the design doesn't show
/// one, but every interactive action must stay Tab-reachable).
class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _searchFocused = false;

  /// The live search text. A ValueNotifier rather than setState so a
  /// keystroke rebuilds the grid and nothing else — the header, the back and
  /// settings buttons, and the search field itself all stayed identical
  /// while being rebuilt on every character.
  final _query = ValueNotifier<String>('');
  Timer? _debounce;

  /// Lowercased search text per product, rebuilt only when the catalogue
  /// itself changes. Filtering used to lowercase three fields per product
  /// per keystroke.
  List<Product>? _haystackSource;
  List<String> _haystacks = const [];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_onSearchFocusChange);
  }

  void _onSearchFocusChange() {
    if (_searchFocused != _searchFocusNode.hasFocus) {
      setState(() => _searchFocused = _searchFocusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _searchController.dispose();
    _searchFocusNode.removeListener(_onSearchFocusChange);
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _goBack() => context.popOr('/');

  /// Typing runs ahead of filtering: a shop assistant types a brand name
  /// faster than it is worth re-filtering the catalogue for each letter, and
  /// the intermediate results are never read.
  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      _query.value = value.trim();
    });
  }

  List<Product> _filter(List<Product> products, String query) {
    // A pure cache: same input list, same output. Rebuilt by identity rather
    // than equality because a new list means new haystacks regardless.
    if (!identical(_haystackSource, products)) {
      _haystackSource = products;
      _haystacks = [
        for (final p in products)
          '${p.brandName} ${p.productName} ${p.keyIngredients}'.toLowerCase(),
      ];
    }

    if (query.isEmpty) return products;
    final needle = query.toLowerCase();
    return [
      for (var i = 0; i < products.length; i++)
        if (_haystacks[i].contains(needle)) products[i],
    ];
  }

  Future<void> _confirmDelete(Product product) async {
    if (!await confirmDeleteProduct(context, product) || !mounted) return;

    try {
      final removedImage = await ref
          .read(productRepositoryProvider)
          .delete(product.id);
      ref.invalidate(productByIdProvider(product.id));
      // Nothing references this file any more, and nothing else knows which
      // file the deleted row was pointing at.
      await ref.read(imageStoreProvider).deleteImage(removedImage);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _openProduct(Product product) {
    context.pushNamed(
      Routes.productEdit,
      pathParameters: {'id': product.id.toString()},
    );
  }

  void _addProduct() {
    context.pushNamed(Routes.productNew);
  }

  void _openSettings() {
    context.pushNamed(Routes.settings);
  }

  Widget _buildSearchBar(ThemeData theme, AppTokens tokens) {
    final query = _searchController.text.trim();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          // The border lives here — and only here. It used to also
          // live on the TextField's own focusedBorder, but that field
          // is sized to its content (isCollapsed), not stretched to
          // this Container's full height, so its border drew a
          // visibly smaller rounded rect nested inside this one: a
          // "rectangle inside the pill". One border, driven by focus
          // state, replaces both.
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(999)),
            border: Border.all(
              color: _searchFocused ? tokens.borderFocus : tokens.border,
              width: _searchFocused ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: tokens.shadowColor.withValues(alpha: 0.10),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
              // The focus ring: a static border alone can't react to
              // focus (the TextField's own InputDecoration owns that),
              // so this list is rebuilt from _searchFocused instead —
              // a spreadRadius shadow is Flutter's equivalent of CSS's
              // `box-shadow: 0 0 0 3px` glow-ring trick.
              if (_searchFocused)
                BoxShadow(
                  color: tokens.borderFocus.withValues(alpha: 0.22),
                  spreadRadius: 3,
                ),
            ],
          ),
          child: Semantics(
            textField: true,
            label: 'ابحث بالعلامة التجارية أو المنتج أو المكوّن',
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: _onQueryChanged,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                contentPadding: const EdgeInsetsDirectional.fromSTEB(
                  18,
                  0,
                  18,
                  0,
                ),
                hintText: 'ابحث بالعلامة التجارية أو المنتج أو المكوّن',
                hintStyle: TextStyle(color: tokens.faint, fontSize: 15),
                // Material reserves a minimum tap-target box around a
                // prefix/suffix icon (historically 48x48) regardless
                // of the icon's own size, and that box is what
                // centers vertically — not the icon itself. Left
                // alone, it's taller than the text's line height, so
                // the icon and the text center within two
                // different-height boxes and visibly disagree.
                // Tightening it to the icon's actual size, plus a
                // little extra, doubles as the icon-to-text gap.
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 28,
                  minHeight: 18,
                ),
                prefixIcon: Icon(Icons.search, size: 18, color: tokens.muted),
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 24,
                  minHeight: 24,
                ),
                suffixIcon: query.isEmpty
                    ? null
                    : Padding(
                        padding: const EdgeInsetsDirectional.only(end: 14),
                        child: Tooltip(
                          message: 'مسح البحث',
                          child: InkWell(
                            onTap: () => setState(_searchController.clear),
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: tokens.iconBadgeBg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: tokens.body,
                              ),
                            ),
                          ),
                        ),
                      ),
                // No border here in any state, including focused —
                // that's owned entirely by the outer Container now
                // (see above), which sizes correctly to the full
                // pill; this field only ever sizes to its own text.
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final productsAsync = ref.watch(productsStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(34, 22, 34, 18),
              child: Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _goBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      iconSize: 19,
                      tooltip: 'رجوع',
                      style: IconButton.styleFrom(
                        shape: const CircleBorder(),
                        fixedSize: const Size(40, 40),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'المخزون',
                    style: AppTheme.weighted(
                      theme.textTheme.headlineSmall,
                      FontWeight.w700,
                    ).copyWith(fontSize: 26),
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: _buildSearchBar(theme, tokens)),
                  const SizedBox(width: 16),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tokens.shadowColor.withValues(alpha: 0.10),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _openSettings,
                      icon: const Icon(Icons.settings_outlined),
                      iconSize: 19,
                      tooltip: 'الإعدادات',
                      color: tokens.body,
                      style: IconButton.styleFrom(
                        shape: const CircleBorder(),
                        fixedSize: const Size(44, 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _addProduct,
                    style: AppTheme.darkButtonStyle(context),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('منتج جديد'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: productsAsync.when(
                data: (products) => ValueListenableBuilder<String>(
                  valueListenable: _query,
                  builder: (context, query, _) => _InventoryGrid(
                    products: _filter(products, query),
                    isSearching: query.isNotEmpty,
                    query: query,
                    onAdd: _addProduct,
                    onOpen: _openProduct,
                    onDelete: _confirmDelete,
                  ),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Text(
                    error is AppException
                        ? error.message
                        : 'تعذّر تحميل الكتالوج.',
                    style: theme.textTheme.titleMedium,
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

/// The grid's own left/right padding. Used both as the padding itself and to
/// work out how much width is left for the cells, which is why it can't be
/// written out twice — changing one and not the other silently mis-sizes
/// every card.
const _gridHorizontalPadding = 34.0;

class _InventoryGrid extends StatelessWidget {
  const _InventoryGrid({
    required this.products,
    required this.isSearching,
    required this.query,
    required this.onAdd,
    required this.onOpen,
    required this.onDelete,
  });

  final List<Product> products;
  final bool isSearching;
  final String query;
  final VoidCallback onAdd;
  final ValueChanged<Product> onOpen;
  final ValueChanged<Product> onDelete;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return _EmptyState(isSearching: isSearching, query: query, onAdd: onAdd);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 1100 ? 3 : 4;
        const horizontalPadding = _gridHorizontalPadding * 2;
        const gap = 18.0;
        final cellWidth =
            (constraints.maxWidth - horizontalPadding - gap * (columns - 1)) /
            columns;
        // A small inset so the card itself sits a little smaller than its
        // grid cell — narrower, and (since the image is square) shorter
        // too — instead of filling the cell edge to edge.
        const cardInset = 20.0;
        final cardWidth = cellWidth - cardInset * 2;
        // The image sits inside the card's own 14px-a-side padding, so it
        // only ever gets cardWidth minus that — not the full cardWidth.
        // Sizing the row on the untrimmed cardWidth reserved 28px more
        // than the (square) image plus chrome actually use, which is
        // exactly the dead strip that showed up at the bottom of the card.
        final imageWidth = cardWidth - _ProductCard.imageHorizontalPadding;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(
            _gridHorizontalPadding,
            4,
            _gridHorizontalPadding,
            30,
          ),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 18,
            crossAxisSpacing: 18,
            mainAxisExtent: imageWidth + _ProductCard.chromeHeightFor(context),
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => Center(
            child: SizedBox(
              width: cardWidth,
              child: _ProductCard(
                // Keyed by product, not position: _ProductCard is stateful
                // (it tracks hover) and holds a FileImage. Without this,
                // filtering or deleting re-associates both with whatever
                // product now sits at that index — a card left looking
                // "lifted" over a different product, or briefly showing the
                // previous row's photo.
                key: ValueKey(products[index].id),
                product: products[index],
                onTap: () => onOpen(products[index]),
                onDelete: () => onDelete(products[index]),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.isSearching,
    required this.query,
    required this.onAdd,
  });

  final bool isSearching;
  final String query;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(17),
                child: Icon(Icons.search, size: 24, color: tokens.label),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isSearching ? 'لا توجد نتائج لـ "$query"' : 'لا يوجد شيء هنا بعد',
              textAlign: TextAlign.center,
              style: AppTheme.weighted(
                theme.textTheme.titleLarge,
                FontWeight.w700,
              ).copyWith(color: tokens.ink, fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'جرّب كلمة مختلفة، أو أضف إلى الرف.'
                  : 'ابدأ بإضافة أول منتج إلى الكتالوج.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.chipOffFg,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAdd,
              style: AppTheme.darkButtonStyle(context),
              child: const Text('إضافة منتج جديد'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A product card that lifts slightly on hover, matching the design's
/// `translateY(-3px)` interaction.
class _ProductCard extends ConsumerStatefulWidget {
  const _ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  /// The card's own left+right padding (14px each) — eats into the width
  /// available to the square image, so the grid needs to subtract it
  /// before using the card's width to predict the image's height.
  static const imageHorizontalPadding = 28.0;

  /// Vertical chrome around the square image: 14px padding top and bottom,
  /// a 12px gap, and three single-line text rows. The grid adds this to the
  /// image's own (width-derived) height to get a fixed `mainAxisExtent` up
  /// front, so it stays in hand-computed sync with the paddings/gaps/font
  /// sizes below.
  ///
  /// The text rows are scaled by [TextScaler] rather than assumed: a shop
  /// running its OS at a larger accessibility text size makes all three
  /// taller at once, and a fixed extent would then overflow in every card
  /// in the grid simultaneously.
  static double chromeHeightFor(BuildContext context) {
    // 100 is the measured value at the default text scale — paddings, gap
    // and three rows, plus the few pixels of ascent/descent rounding that
    // recomputing the rows from font sizes alone doesn't account for. Rather
    // than re-derive it and lose that slack, add only what a larger text
    // scale grows the three rows *by*, so the default case stays exactly as
    // it was.
    const atDefaultScale = 100.0;
    const rowSizes = [12.0, 17.0, 12.0];
    const lineHeight = 1.3;

    final scaler = MediaQuery.textScalerOf(context);
    var extra = 0.0;
    for (final size in rowSizes) {
      extra += (scaler.scale(size) - size) * lineHeight;
    }
    return atDefaultScale + extra;
  }

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final storage = ref.watch(appStorageProvider);
    final imagePath = widget.product.imagePath;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 120),
        offset: _hovering ? const Offset(0, -0.02) : Offset.zero,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            boxShadow: _hovering ? tokens.prominentShadow : tokens.cardShadow,
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              onLongPress: widget.onDelete,
              onSecondaryTap: widget.onDelete,
              child: Padding(
                // The photo sits inset within the card, not full-bleed to its
                // edges — its own 14px corner radius is visibly smaller than
                // the card's 20px, which only this outer padding reveals.
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(14),
                          ),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: imagePath == null
                                ? StripedPlaceholder(
                                    background: tokens.imagePanelBg,
                                    stripe: tokens.imagePanelBorder,
                                    label: 'صورة المنتج',
                                    labelStyle: theme.textTheme.labelSmall
                                        ?.copyWith(color: tokens.faint),
                                  )
                                : ProductImage(
                                    file: File(storage.resolveImage(imagePath)),
                                  ),
                          ),
                        ),
                        PositionedDirectional(
                          top: 4,
                          end: 4,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface.withValues(
                                alpha: 0.85,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              onPressed: widget.onDelete,
                              icon: const Icon(Icons.delete_outline_rounded),
                              iconSize: 16,
                              tooltip: 'حذف',
                              visualDensity: VisualDensity.compact,
                              style: IconButton.styleFrom(
                                shape: const CircleBorder(),
                                fixedSize: const Size(28, 28),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Content-hugging, not centered in leftover flex space —
                    // the whole card's height (chromeHeightFor)
                    // is already computed to fit exactly this, no more.
                    Text(
                      widget.product.brandName.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tokens.muted,
                        letterSpacing: 0.5,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.product.productName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.weighted(
                        theme.textTheme.bodyLarge,
                        FontWeight.w700,
                      ).copyWith(fontSize: 17, height: 1.3),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.product.firstKeyIngredient,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.muted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
