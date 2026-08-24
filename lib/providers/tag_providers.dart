import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/suitability_tag.dart';
import 'database_providers.dart';

/// The full seeded suitability vocabulary, live: the add/edit form's chip
/// groups can create or delete a tag inline without a manual refresh.
final watchAllTagsProvider = StreamProvider<List<SuitabilityTag>>((ref) {
  return ref.watch(tagRepositoryProvider).watchAll();
});
