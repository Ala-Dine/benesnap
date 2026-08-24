import 'package:flutter/foundation.dart';

/// Which part of a routine a suitability tag describes.
///
/// Declared here rather than beside the drift table so the domain models stay
/// free of any drift import.
enum TagCategory {
  skin,
  hair;

  String get label => switch (this) {
    TagCategory.skin => 'أنواع البشرة',
    TagCategory.hair => 'أنواع الشعر',
  };
}

/// A skin or hair type a product is suitable for.
@immutable
class SuitabilityTag {
  const SuitabilityTag({
    required this.id,
    required this.label,
    required this.category,
  });

  final int id;
  final String label;
  final TagCategory category;

  @override
  bool operator ==(Object other) =>
      other is SuitabilityTag &&
      other.id == id &&
      other.label == label &&
      other.category == category;

  @override
  int get hashCode => Object.hash(id, label, category);

  @override
  String toString() => 'SuitabilityTag($id, $label, ${category.name})';
}
