import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/product.dart';
import 'database_providers.dart';

/// A single product by id, for the detail and edit screens.
final productByIdProvider = FutureProvider.family<Product?, int>((ref, id) {
  return ref.watch(productRepositoryProvider).findById(id);
});

/// The full catalogue, live — the inventory grid re-renders whenever a
/// product is added, edited, or deleted anywhere in the app.
final productsStreamProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchAll();
});
