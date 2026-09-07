import 'package:drift/drift.dart';

import '../db/app_database.dart';
import '../exceptions.dart';
import '../models/home_text.dart';
import '../models/home_theme.dart';
import 'storage_guard.dart';

/// The shop's customizable kiosk homepage text — a single row (id fixed at
/// 1), absent until the shop saves it for the first time.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const _rowId = 1;

  /// Emits the current homepage text, and again on every future update.
  ///
  /// Errors arrive as [StorageException] like every other method here — a
  /// raw drift error reaching a listener would be the one place in this
  /// class where [exceptions.dart]'s contract didn't hold.
  Stream<HomeText> watchHomeText() {
    final query = _db.select(_db.appSettings)
      ..where((s) => s.id.equals(_rowId));
    return query
        .watchSingleOrNull()
        .map(_toHomeText)
        .handleError((Object e) => throw StorageException(e));
  }

  /// One-shot read, resolved for display (falls back to the default
  /// welcome text when nothing has been customized yet).
  Future<HomeText> homeText() => guardStorage(() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.id.equals(_rowId))).getSingleOrNull();
    return _toHomeText(row);
  });

  /// The raw stored row, or null if the shop has never customized anything.
  ///
  /// Distinct from [homeText]: that one resolves the *display* fallback a
  /// customer sees on the kiosk, which would wrongly pre-fill the settings
  /// form as if the shop had already typed that text. The form needs to
  /// know the difference between "never customized" (show empty fields)
  /// and "customized to something that happens to match the fallback".
  Future<HomeText?> rawHomeText() => guardStorage(() async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((s) => s.id.equals(_rowId))).getSingleOrNull();
    if (row == null) return null;
    return HomeText(
      welcomeTitle: row.welcomeTitle,
      extraLine: row.extraLine,
      themeKey: homeThemeKeyFromStorage(row.themeKey),
    );
  });

  Future<void> updateHomeText({
    required String welcomeTitle,
    required String extraLine,
    required HomeThemeKey themeKey,
  }) => guardStorage(() async {
    final trimmedTitle = welcomeTitle.trim();
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(
          AppSettingsCompanion(
            id: const Value(_rowId),
            welcomeTitle: Value(
              trimmedTitle.isEmpty ? defaultWelcomeTitle : trimmedTitle,
            ),
            extraLine: Value(extraLine.trim()),
            themeKey: Value(themeKey.name),
          ),
        );
  });

  HomeText _toHomeText(AppSettingsRow? row) => HomeText(
    welcomeTitle: row?.welcomeTitle ?? defaultWelcomeTitle,
    extraLine: row?.extraLine ?? '',
    themeKey: homeThemeKeyFromStorage(row?.themeKey),
  );
}
