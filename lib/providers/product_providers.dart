import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/product.dart';
import 'database_providers.dart';

/// A single product by id, for the detail and edit screens.
final productByIdProvider = FutureProvider.family<Product?, int>((ref, id) {
  return ref.watch(productRepositoryProvider).findById(id);
});

/// The full catalogue, live — the inventory grid re-renders whenever a
/// product is added, edited, or deleted anywhere in the app.
///
/// `distinct` because `watchAll` re-runs on writes to the tag tables too
/// (renaming a tag, say), and most of those leave this list exactly as it
/// was. Without it every such write rebuilt the whole grid — each card with
/// its own decoded image — to paint an identical frame.
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchAll().distinct(listEquals);
});
