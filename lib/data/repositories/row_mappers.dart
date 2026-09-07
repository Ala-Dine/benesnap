import '../db/app_database.dart';
import '../models/suitability_tag.dart';

/// Drift row to domain model.
///
/// Lives here rather than on [SuitabilityTag] itself because the models
/// deliberately don't import drift — nothing above the repository layer
/// should know a generated row type exists. Both the tag and product
/// repositories need it, and each had its own identical copy.
SuitabilityTag tagFromRow(SuitabilityTagRow row) =>
    SuitabilityTag(id: row.id, label: row.label, category: row.category);
