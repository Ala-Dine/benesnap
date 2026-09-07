import 'dart:async';
import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../data/db/connection.dart';
import '../../data/exceptions.dart';
import '../../data/models/product.dart';
import '../../data/models/suitability_tag.dart';
import '../../providers/database_providers.dart';
import '../../providers/product_providers.dart';
import '../../providers/scanner_providers.dart';
import '../../providers/tag_providers.dart';
import '../../services/scanner/barcode_scanner_service.dart';
import '../../widgets/primary_action_button.dart';
import '../../widgets/dashed_border_box.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/labeled_field.dart';
import '../../widgets/product_image.dart';

/// Whether the barcode field is empty, holds an unchecked-but-plausible
/// value, or collides with another product — checked at commit time (Enter
/// or blur), not on every keystroke.
enum _BarcodeState { waiting, filled, duplicate }

/// Add or edit a product. Null [productId] means add; otherwise the form
/// loads that product and edits it in place.
class ProductFormScreen extends ConsumerWidget {
  const ProductFormScreen({super.key, this.productId, this.initialBarcode});

  final int? productId;
  final String? initialBarcode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = productId;
    if (id == null) {
      return _ProductFormBody(product: null, initialBarcode: initialBarcode);
    }

    final productAsync = ref.watch(productByIdProvider(id));
    return productAsync.when(
      data: (product) => product == null
          ? const _NotFoundScreen()
          : _ProductFormBody(key: ValueKey(product.id), product: product),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Text(
            error is AppException ? error.message : 'تعذّر تحميل هذا المنتج.',
          ),
        ),
      ),
    );
  }
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          'هذا المنتج لم يعد موجودًا في الكتالوج.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}

class _ProductFormBody extends ConsumerStatefulWidget {
  const _ProductFormBody({
    super.key,
    required this.product,
    this.initialBarcode,
  });

  final Product? product;
  final String? initialBarcode;

  @override
  ConsumerState<_ProductFormBody> createState() => _ProductFormBodyState();
}

class _ProductFormBodyState extends ConsumerState<_ProductFormBody> {
  late final _barcodeController = TextEditingController(
    text: widget.product?.barcode ?? widget.initialBarcode ?? '',
  );
  late final _brandController = TextEditingController(
    text: widget.product?.brandName ?? '',
  );
  late final _productNameController = TextEditingController(
    text: widget.product?.productName ?? '',
  );
  late final _ingredientsController = TextEditingController(
    text: widget.product?.keyIngredients ?? '',
  );
  late final _benefitsController = TextEditingController(
    text: widget.product?.coreBenefits ?? '',
  );

  final _barcodeFocus = FocusNode();
  final _brandFocus = FocusNode();
  final _productNameFocus = FocusNode();
  final _ingredientsFocus = FocusNode();

  late final Set<int> _selectedTagIds =
      widget.product?.tags.map((t) => t.id).toSet() ?? {};
  String? _imagePath;
  bool _isSaving = false;
  bool _saved = false;
  String? _errorText;

  var _barcodeState = _BarcodeState.waiting;
  Product? _collidingProduct;

  // Captured in initState rather than re-read via `ref` in dispose — by the
  // time dispose runs the widget may already be unmounted, and Riverpod
  // throws on `ref.read`/`ref.watch` at that point. The service itself is a
  // stable singleton, so holding a direct reference is safe to mutate later.
  late final BarcodeScannerService _scanner;
  late final VoidCallback _releaseScanner;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _imagePath = widget.product?.imagePath;
    _barcodeState = _barcodeController.text.trim().isEmpty
        ? _BarcodeState.waiting
        : _BarcodeState.filled;
    _barcodeFocus.addListener(_onBarcodeFocusChange);
    // The barcode field is meant to be filled by a scan; disable the global
    // listener so a scan here doesn't also trigger a lookup elsewhere while
    // this form is open.
    _scanner = ref.read(barcodeScannerProvider);
    _releaseScanner = _scanner.suspend();
  }

  @override
  void dispose() {
    _releaseScanner();
    if (!_saved) _cleanupOrphanedImage();
    _barcodeFocus.removeListener(_onBarcodeFocusChange);
    _barcodeFocus.dispose();
    _barcodeController.dispose();
    _brandController.dispose();
    _productNameController.dispose();
    _ingredientsController.dispose();
    _benefitsController.dispose();
    _brandFocus.dispose();
    _productNameFocus.dispose();
    _ingredientsFocus.dispose();
    super.dispose();
  }

  void _cleanupOrphanedImage() {
    final current = _imagePath;
    final original = widget.product?.imagePath;
    if (current != null && current != original) {
      // Fire-and-forget: a background delete of a file the user never saw
      // referenced anywhere isn't worth surfacing to them.
      unawaited(ref.read(imageStoreProvider).deleteImage(current));
    }
  }

  bool get _hasUnsavedChanges {
    final product = widget.product;
    if (product != null) {
      return _barcodeController.text.trim() != product.barcode ||
          _brandController.text.trim() != product.brandName ||
          _productNameController.text.trim() != product.productName ||
          _ingredientsController.text.trim() != product.keyIngredients ||
          _benefitsController.text.trim() != product.coreBenefits ||
          _imagePath != product.imagePath ||
          !setEquals(_selectedTagIds, product.tags.map((t) => t.id).toSet());
    }
    return _barcodeController.text.trim().isNotEmpty ||
        _brandController.text.trim().isNotEmpty ||
        _productNameController.text.trim().isNotEmpty ||
        _ingredientsController.text.trim().isNotEmpty ||
        _benefitsController.text.trim().isNotEmpty ||
        _imagePath != null ||
        _selectedTagIds.isNotEmpty;
  }

  void _onBarcodeFocusChange() {
    if (!_barcodeFocus.hasFocus) _commitBarcode();
  }

  void _onBarcodeChanged(String text) {
    setState(() {
      _barcodeState = text.trim().isEmpty
          ? _BarcodeState.waiting
          : _BarcodeState.filled;
      _collidingProduct = null;
    });
  }

  /// Looks up the current barcode text and settles the field into
  /// `filled` or `duplicate`. Called on Enter, on blur, and once more right
  /// before save so a race between the two can never let a collision slip
  /// through.
  Future<void> _commitBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) {
      if (_barcodeState != _BarcodeState.waiting || _collidingProduct != null) {
        setState(() {
          _barcodeState = _BarcodeState.waiting;
          _collidingProduct = null;
        });
      }
      return;
    }

    final match = await ref
        .read(productRepositoryProvider)
        .findByBarcode(barcode);
    if (!mounted) return;

    final collides = match != null && match.id != widget.product?.id;
    setState(() {
      _barcodeState = collides ? _BarcodeState.duplicate : _BarcodeState.filled;
      _collidingProduct = collides ? match : null;
    });
  }

  void _rescan() {
    _barcodeController.clear();
    setState(() {
      _barcodeState = _BarcodeState.waiting;
      _collidingProduct = null;
    });
    _barcodeFocus.requestFocus();
  }

  void _openColliding() {
    final product = _collidingProduct;
    if (product == null) return;
    context.pushNamed(
      Routes.productEdit,
      pathParameters: {'id': product.id.toString()},
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      dialogTitle: 'اختر صورة للمنتج',
    );
    final path = result?.files.single.path;
    if (path == null) return;
    await _importImage(path);
  }

  Future<void> _importImage(String sourcePath) async {
    try {
      final newPath = await ref
          .read(imageStoreProvider)
          .importImage(sourcePath);
      final previous = _imagePath;
      // Only clean up a file staged earlier THIS session — the product's
      // original image is only ever removed once the save succeeds.
      if (previous != null && previous != widget.product?.imagePath) {
        await ref.read(imageStoreProvider).deleteImage(previous);
      }
      if (!mounted) return;
      setState(() => _imagePath = newPath);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _errorText = e.message);
    }
  }

  void _toggleTag(int id) {
    setState(() {
      if (!_selectedTagIds.add(id)) _selectedTagIds.remove(id);
    });
  }

  Future<void> _createTag(String label, TagCategory category) async {
    try {
      final created = await ref
          .read(tagRepositoryProvider)
          .createTag(label, category);
      if (!mounted) return;
      setState(() => _selectedTagIds.add(created.id));
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _deleteTag(SuitabilityTag tag) async {
    final repo = ref.read(tagRepositoryProvider);
    final int count;
    try {
      count = await repo.productCountForTag(tag.id);
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (!mounted) return;

    final confirmed = await confirmDestructive(
      context,
      title: 'حذف الوسم "${tag.label}"؟',
      message: count == 0
          ? 'لن يتأثر أي منتج بهذا الحذف.'
          : 'هذا الوسم مستخدم في $count ${count == 1 ? 'منتج' : 'منتجات'}. '
                'سيُزال منها جميعًا.',
      confirmLabel: 'حذف',
    );
    if (!confirmed || !mounted) return;

    try {
      await repo.deleteTag(tag.id);
      // `use_build_context_synchronously` doesn't cover setState, so this
      // one has to be guarded by hand like every other await in this file.
      if (!mounted) return;
      setState(() => _selectedTagIds.remove(tag.id));
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;

    await _commitBarcode();
    if (!mounted) return;

    final barcode = _barcodeController.text.trim();
    final brand = _brandController.text.trim();
    final productName = _productNameController.text.trim();

    if (barcode.isEmpty || brand.isEmpty || productName.isEmpty) {
      setState(
        () =>
            _errorText = 'الرمز الشريطي والعلامة التجارية واسم المنتج مطلوبة.',
      );
      return;
    }

    if (_barcodeState == _BarcodeState.duplicate) {
      setState(() => _errorText = 'عالج تعارض الرمز الشريطي قبل الحفظ.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final draft = ProductDraft(
      barcode: barcode,
      brandName: brand,
      productName: productName,
      keyIngredients: _ingredientsController.text.trim(),
      coreBenefits: _benefitsController.text.trim(),
      imagePath: _imagePath,
      tagIds: _selectedTagIds,
    );

    try {
      final repo = ref.read(productRepositoryProvider);
      final oldImagePath = widget.product?.imagePath;

      if (_isEditing) {
        await repo.update(widget.product!.id, draft);
        // `productByIdProvider` caches for the app's lifetime, so without
        // this the next screen to read this id — including this same form,
        // reopened — would serve the values from before the edit and let a
        // save write them straight back over the newer ones.
        ref.invalidate(productByIdProvider(widget.product!.id));
      } else {
        await repo.create(draft);
      }

      if (oldImagePath != null && oldImagePath != _imagePath) {
        await ref.read(imageStoreProvider).deleteImage(oldImagePath);
      }

      if (!mounted) return;
      _saved = true;
      context.pop();
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = e.message;
      });
    }
  }

  Future<void> _deleteProduct() async {
    final product = widget.product;
    if (product == null) return;
    if (!await confirmDeleteProduct(context, product) || !mounted) return;

    try {
      final store = ref.read(imageStoreProvider);
      final removedImage = await ref
          .read(productRepositoryProvider)
          .delete(product.id);
      ref.invalidate(productByIdProvider(product.id));

      // Both the product's own image and anything staged this session are
      // now unreferenced. `_saved` then skips the dispose-time cleanup,
      // which has nothing left to compare against.
      await store.deleteImage(removedImage);
      final staged = _imagePath;
      if (staged != null && staged != removedImage) {
        await store.deleteImage(staged);
      }
      _saved = true;

      if (!mounted) return;
      context.pop();
    } on AppException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _cancel() async {
    if (_hasUnsavedChanges) {
      final discard = await confirmDestructive(
        context,
        title: 'تجاهل التغييرات؟',
        message: 'ستفقد ما أدخلته في هذا النموذج.',
        confirmLabel: 'تجاهل',
        cancelLabel: 'متابعة التعديل',
      );
      if (!discard) return;
    }
    if (!mounted) return;
    context.pop();
  }

  Widget? _barcodeSuffix(ThemeData theme, AppTokens tokens) {
    if (_barcodeController.text.trim().isEmpty) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          _barcodeState == _BarcodeState.duplicate
              ? Icons.error_rounded
              : Icons.check_circle_rounded,
          size: 18,
          color: _barcodeState == _BarcodeState.duplicate
              ? theme.colorScheme.error
              : tokens.successFg,
        ),
        const SizedBox(width: 4),
        IconButton(
          onPressed: _isSaving ? null : _rescan,
          icon: const Icon(Icons.refresh_rounded),
          iconSize: 18,
          tooltip: 'مسح جديد',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Color? _barcodeBorderColor(AppTokens tokens) => switch (_barcodeState) {
    _BarcodeState.waiting => null,
    _BarcodeState.filled => tokens.successBorder,
    _BarcodeState.duplicate => tokens.dangerBorder,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final tagsAsync = ref.watch(watchAllTagsProvider);
    final storage = ref.watch(appStorageProvider);

    ref.listen<AsyncValue<List<SuitabilityTag>>>(watchAllTagsProvider, (
      previous,
      next,
    ) {
      final liveTags = next.value;
      if (liveTags == null) return;
      final validIds = liveTags.map((t) => t.id).toSet();
      final stale = _selectedTagIds.difference(validIds);
      if (stale.isNotEmpty) {
        setState(() => _selectedTagIds.removeAll(stale));
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _cancel();
      },
      child: Scaffold(
        backgroundColor: tokens.formCanvas,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(40, 22, 40, 0),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: tokens.border, width: 1.5),
                      ),
                      child: IconButton(
                        onPressed: _isSaving ? null : _cancel,
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
                      _isEditing ? 'تعديل المنتج' : 'إضافة منتج جديد',
                      style: AppTheme.weighted(
                        theme.textTheme.headlineSmall,
                        FontWeight.w700,
                      ).copyWith(fontSize: 26),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(40, 36, 40, 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            LabeledField(
                              label: 'الرمز الشريطي',
                              controller: _barcodeController,
                              focusNode: _barcodeFocus,
                              hintText: 'امسح الرمز أو اكتب رمزًا يدويًا',
                              autofocus: true,
                              enabled: !_isSaving,
                              textInputAction: TextInputAction.next,
                              textDirection: TextDirection.ltr,
                              borderColor: _barcodeBorderColor(tokens),
                              suffixIcon: _barcodeSuffix(theme, tokens),
                              onChanged: _onBarcodeChanged,
                              onSubmitted: (_) async {
                                await _commitBarcode();
                                if (mounted) _brandFocus.requestFocus();
                              },
                            ),
                            if (_barcodeState == _BarcodeState.waiting) ...[
                              const SizedBox(height: 6),
                              Text(
                                'امسح الآن وسيمتلئ الحقل تلقائيًا.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: tokens.muted,
                                ),
                              ),
                            ],
                            if (_barcodeState == _BarcodeState.duplicate) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    _collidingProduct == null
                                        ? 'هذا الرمز مستخدم بالفعل. '
                                        : 'هذا الرمز مستخدم في '
                                              '"${_collidingProduct!.displayName}". ',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error,
                                    ),
                                  ),
                                  if (_collidingProduct != null)
                                    InkWell(
                                      onTap: _openColliding,
                                      child: Text(
                                        'فتح هذا المنتج',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color: tokens.goldDeep,
                                              fontWeight: FontWeight.w700,
                                              decoration:
                                                  TextDecoration.underline,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 13),
                            LabeledField(
                              label: 'العلامة التجارية',
                              controller: _brandController,
                              focusNode: _brandFocus,
                              hintText: 'اسم العلامة التجارية',
                              enabled: !_isSaving,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  _productNameFocus.requestFocus(),
                            ),
                            const SizedBox(height: 13),
                            LabeledField(
                              label: 'اسم المنتج',
                              controller: _productNameController,
                              focusNode: _productNameFocus,
                              hintText: 'اسم المنتج',
                              enabled: !_isSaving,
                              textInputAction: TextInputAction.next,
                              onSubmitted: (_) =>
                                  _ingredientsFocus.requestFocus(),
                            ),
                            const SizedBox(height: 13),
                            LabeledField(
                              label: 'المكوّنات الرئيسية',
                              controller: _ingredientsController,
                              focusNode: _ingredientsFocus,
                              hintText: 'حمض الهيالورونيك، فيتامين ب5...',
                              maxLines: 2,
                              enabled: !_isSaving,
                            ),
                            const SizedBox(height: 13),
                            LabeledField(
                              label: 'الفوائد الأساسية',
                              controller: _benefitsController,
                              hintText: 'كل فائدة في سطر منفصل',
                              maxLines: 4,
                              enabled: !_isSaving,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 40),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'صورة المنتج',
                              style: AppTheme.weighted(
                                theme.textTheme.bodyMedium,
                                FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _ImageDropZone(
                              imagePath: _imagePath,
                              storage: storage,
                              onPick: _isSaving ? null : _pickImage,
                              onFileDropped: _isSaving ? null : _importImage,
                            ),
                            const SizedBox(height: 14),
                            tagsAsync.when(
                              data: (tags) => _TagGroups(
                                tags: tags,
                                selected: _selectedTagIds,
                                onToggle: _isSaving ? null : _toggleTag,
                                onCreate: _isSaving ? null : _createTag,
                                onDelete: _isSaving ? null : _deleteTag,
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, _) => const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 12),
                  child: Text(
                    _errorText!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 26),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_isEditing)
                      OutlinedButton(
                        onPressed: _isSaving ? null : _deleteProduct,
                        style: OutlinedButton.styleFrom(
                          backgroundColor: tokens.dangerBg,
                          foregroundColor: theme.colorScheme.error,
                          side: BorderSide(
                            color: tokens.dangerBorder,
                            width: 1.5,
                          ),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                          minimumSize: const Size(0, 46),
                        ),
                        child: const Text('حذف المنتج'),
                      )
                    else
                      const SizedBox.shrink(),
                    Row(
                      children: [
                        TextButton(
                          onPressed: _isSaving ? null : _cancel,
                          style: TextButton.styleFrom(
                            foregroundColor: tokens.muted,
                          ),
                          child: const Text('إلغاء'),
                        ),
                        const SizedBox(width: 12),
                        PrimaryActionButton(
                          label: _isEditing ? 'حفظ' : 'إضافة',
                          busy: _isSaving,
                          onPressed: _save,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageDropZone extends StatelessWidget {
  const _ImageDropZone({
    required this.imagePath,
    required this.storage,
    required this.onPick,
    required this.onFileDropped,
  });

  final String? imagePath;
  final AppStorage storage;
  final VoidCallback? onPick;
  final ValueChanged<String>? onFileDropped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final path = imagePath;
    const radius = AppRadii.card;

    return DropTarget(
      onDragDone: (details) {
        if (onFileDropped == null || details.files.isEmpty) return;
        onFileDropped!(details.files.first.path);
      },
      child: SizedBox(
        height: 152,
        width: double.infinity,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPick,
            borderRadius: radius,
            child: path == null
                ? DashedBorderBox(
                    color: tokens.dropzoneBorder,
                    borderRadius: radius,
                    child: ColoredBox(
                      color: tokens.imagePanelBg,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 40,
                              color: tokens.muted,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'أضف صورة المنتج',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: tokens.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ClipRRect(
                    borderRadius: radius,
                    child: ProductImage(
                      file: File(storage.resolveImage(path)),
                      brokenIconSize: 40,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _TagGroups extends StatelessWidget {
  const _TagGroups({
    required this.tags,
    required this.selected,
    required this.onToggle,
    required this.onCreate,
    required this.onDelete,
  });

  final List<SuitabilityTag> tags;
  final Set<int> selected;
  final ValueChanged<int>? onToggle;
  final void Function(String label, TagCategory category)? onCreate;
  final ValueChanged<SuitabilityTag>? onDelete;

  @override
  Widget build(BuildContext context) {
    final skin = tags.where((t) => t.category == TagCategory.skin).toList();
    final hair = tags.where((t) => t.category == TagCategory.hair).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ChipGroup(
          title: TagCategory.skin.label,
          category: TagCategory.skin,
          tags: skin,
          selected: selected,
          onToggle: onToggle,
          onCreate: onCreate,
          onDelete: onDelete,
        ),
        const SizedBox(height: 16),
        _ChipGroup(
          title: TagCategory.hair.label,
          category: TagCategory.hair,
          tags: hair,
          selected: selected,
          onToggle: onToggle,
          onCreate: onCreate,
          onDelete: onDelete,
        ),
      ],
    );
  }
}

class _ChipGroup extends StatefulWidget {
  const _ChipGroup({
    required this.title,
    required this.category,
    required this.tags,
    required this.selected,
    required this.onToggle,
    required this.onCreate,
    required this.onDelete,
  });

  final String title;
  final TagCategory category;
  final List<SuitabilityTag> tags;
  final Set<int> selected;
  final ValueChanged<int>? onToggle;
  final void Function(String label, TagCategory category)? onCreate;
  final ValueChanged<SuitabilityTag>? onDelete;

  @override
  State<_ChipGroup> createState() => _ChipGroupState();
}

class _ChipGroupState extends State<_ChipGroup> {
  bool _adding = false;
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focus.hasFocus && _adding) _commit();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    // Before the node is disposed: disposing a FocusNode drops its focus,
    // which fires this listener, which would then commit a half-typed label
    // as a brand new tag on the way out.
    _focus.removeListener(_onFocusChange);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool _handleKey(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      _cancelAdding();
    }
    return false;
  }

  void _startAdding() {
    setState(() => _adding = true);
    HardwareKeyboard.instance.addHandler(_handleKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _commit() {
    if (!mounted) return;
    HardwareKeyboard.instance.removeHandler(_handleKey);
    final label = _controller.text.trim();
    _controller.clear();
    setState(() => _adding = false);
    if (label.isNotEmpty) widget.onCreate?.call(label, widget.category);
  }

  void _cancelAdding() {
    HardwareKeyboard.instance.removeHandler(_handleKey);
    _controller.clear();
    setState(() => _adding = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: AppTheme.weighted(theme.textTheme.bodyMedium, FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (final tag in widget.tags)
              _EditableTagChip(
                tag: tag,
                selected: widget.selected.contains(tag.id),
                onToggle: widget.onToggle == null
                    ? null
                    : () => widget.onToggle!(tag.id),
                onDelete: widget.onDelete == null
                    ? null
                    : () => widget.onDelete!(tag),
              ),
            if (_adding)
              SizedBox(
                width: 130,
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    hintText: 'اسم الوسم',
                    border: OutlineInputBorder(
                      borderRadius: AppRadii.pill,
                      borderSide: BorderSide(color: tokens.border),
                    ),
                  ),
                  onSubmitted: (_) => _commit(),
                ),
              )
            else if (widget.onCreate != null)
              _AddChipButton(onTap: _startAdding),
          ],
        ),
      ],
    );
  }
}

class _AddChipButton extends StatelessWidget {
  const _AddChipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);

    return DashedBorderBox(
      color: tokens.dropzoneBorder,
      borderRadius: AppRadii.pill,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const StadiumBorder(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 15, color: tokens.body),
                const SizedBox(width: 4),
                Text(
                  'إضافة',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: tokens.body,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditableTagChip extends StatelessWidget {
  const _EditableTagChip({
    required this.tag,
    required this.selected,
    required this.onToggle,
    required this.onDelete,
  });

  final SuitabilityTag tag;
  final bool selected;
  final VoidCallback? onToggle;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = AppTokens.of(context);
    final bg = selected ? tokens.chipOnBg : tokens.chipOffBg;
    final fg = selected ? tokens.chipOnFg : tokens.chipOffFg;
    final border = selected ? tokens.chipOnBorder : tokens.border;

    return Material(
      color: bg,
      shape: StadiumBorder(side: BorderSide(color: border)),
      child: InkWell(
        onTap: onToggle,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(14, 7, 8, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tag.label,
                style: theme.textTheme.bodyMedium?.copyWith(color: fg),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: 6),
                InkWell(
                  onTap: onDelete,
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tokens.ink.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 12, color: fg),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
