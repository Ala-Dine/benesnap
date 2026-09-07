import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/db/app_database.dart';
import '../data/db/connection.dart';
import '../data/repositories/admin_repository.dart';
import '../data/repositories/product_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/tag_repository.dart';
import '../services/image_store.dart';

/// Overridden in `main()` once the app support directory has been resolved.
///
/// Opening the database before `runApp` keeps every downstream provider
/// synchronous, and surfaces a storage failure before any screen is built.
final appStorageProvider = Provider<AppStorage>(
  (ref) => throw StateError('appStorageProvider must be overridden in main()'),
);

final appDatabaseProvider = Provider<AppDatabase>(
  (ref) => throw StateError('appDatabaseProvider must be overridden in main()'),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepository(ref.watch(appDatabaseProvider)),
);

final tagRepositoryProvider = Provider<TagRepository>(
  (ref) => TagRepository(ref.watch(appDatabaseProvider)),
);

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(appDatabaseProvider)),
);

/// Whether any admin account exists — the router's "is setup still needed?"
/// question.
///
/// Cached rather than queried per navigation: the router's redirect ran
/// `AdminRepository.isEmpty()` on every trip to `/login` or `/setup`, making
/// each of those transitions wait on a database round trip for an answer
/// that changes exactly once in the app's lifetime. Invalidated by the setup
/// screen when it creates that first account.
final hasAdminProvider = FutureProvider<bool>(
  (ref) async => !await ref.watch(adminRepositoryProvider).isEmpty(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

final imageStoreProvider = Provider<ImageStore>(
  (ref) => ImageStore(ref.watch(appStorageProvider)),
);
