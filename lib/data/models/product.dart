import 'package:flutter/foundation.dart';

import 'suitability_tag.dart';

/// A catalogue entry, with its suitability tags already resolved.
@immutable
class Product {
  const Product({
    required this.id,
    required this.barcode,
    required this.brandName,
    required this.productName,
    required this.keyIngredients,
    required this.coreBenefits,
    required this.createdAt,
    required this.updatedAt,
    this.imagePath,
    this.tags = const [],
  });

  final int id;
  final String barcode;
  final String brandName;
  final String productName;
  final String keyIngredients;
  final String coreBenefits;

  /// Filename relative to the `images/` folder, or null when no picture was
  /// chosen.
  final String? imagePath;

  final DateTime createdAt;
  final DateTime updatedAt;
  final List<SuitabilityTag> tags;

  String get displayName => '$brandName $productName';

  List<SuitabilityTag> tagsIn(TagCategory category) =>
      tags.where((t) => t.category == category).toList();

  /// The detail screen renders benefits as a numbered list. Authors type them
  /// one per line, but a single-line entry should still render as one item.
  List<String> get benefitLines => coreBenefits
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();

  /// The inventory card shows just the first ingredient as a preview.
  /// Authors separate ingredients with a comma — Arabic (،) or Latin (,),
  /// since both are in ordinary use when typing Arabic text.
  String get firstKeyIngredient =>
      keyIngredients.split(RegExp('[,،]')).first.trim();

  @override
  String toString() => 'Product($id, $barcode, $displayName)';
}

/// The editable fields of a product — what the add/edit form produces.
///
/// Separate from [Product] so callers cannot invent an `id` or backdate
/// timestamps; the repository owns both.
@immutable
class ProductDraft {
  const ProductDraft({
    required this.barcode,
    required this.brandName,
    required this.productName,
    required this.keyIngredients,
    required this.coreBenefits,
    this.imagePath,
    this.tagIds = const {},
  });

  final String barcode;
  final String brandName;
  final String productName;
  final String keyIngredients;
  final String coreBenefits;
  final String? imagePath;
  final Set<int> tagIds;

  ProductDraft copyWith({
    String? barcode,
    String? brandName,
    String? productName,
    String? keyIngredients,
    String? coreBenefits,
    String? imagePath,
    Set<int>? tagIds,
  }) {
    return ProductDraft(
      barcode: barcode ?? this.barcode,
      brandName: brandName ?? this.brandName,
      productName: productName ?? this.productName,
      keyIngredients: keyIngredients ?? this.keyIngredients,
      coreBenefits: coreBenefits ?? this.coreBenefits,
      imagePath: imagePath ?? this.imagePath,
      tagIds: tagIds ?? this.tagIds,
    );
  }
}
