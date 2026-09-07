# BeneSnap Architecture

BeneSnap is a Flutter desktop app for a cosmetics/skincare shop counter. A USB
keyboard-wedge barcode/QR scanner drives a kiosk screen showing a product's key
ingredients, core benefits, and skin/hair suitability. Staff who log in as
admin manage the catalogue.

The UI is **Arabic only, right-to-left** — `MaterialApp.locale` is pinned to
`ar` and there is no language switcher, so every user-facing string in `lib/`
is Arabic. The exception is `screens/debug/`, which is a technician's tuning
aid rather than a shop screen.

## Stack

- Flutter desktop (Windows primary; also builds on macOS/Linux)
- **Riverpod** (`flutter_riverpod`) — hand-written providers, no codegen (see
  `pubspec.yaml` for why: the generator versions compatible with this Dart SDK
  need an `analyzer` old enough to force `drift_dev` back several minors)
- **drift** over `sqlite3` for persistence
- **go_router** for navigation
- **bcrypt** for admin password hashing
- **window_manager** for the desktop window (1000×700 minimum)
- **file_picker** + **desktop_drop** for product images (click or drag-and-drop)
- **Readex Pro**, bundled as a single variable font file under `assets/fonts/`
  and declared four times in `pubspec.yaml` at the four weights the design
  uses. Chosen over a Google-Fonts download because it covers Arabic and a
  kiosk shouldn't need the network to render its own text.

## Entry point

- `lib/main.dart` — configures the window, resolves `AppStorage` (the app
  support directory), opens the drift database, reads the saved theme, and
  runs `BeneSnapApp` inside a `ProviderScope` with those overridden to their
  real instances. All of it is wrapped: if the database can't be opened at
  all, `StorageFailureApp` says so rather than leaving a blank window.
  It also closes the database on window close, so SQLite checkpoints its
  write-ahead log into the file the shop's backup copies.

## App shell

- `lib/app/theme.dart` — the single source of every colour, radius and
  shadow. `AppTheme.forTheme(key)` builds the whole `ThemeData` from one
  `HomeThemeKey` (the shop's choice in settings), deriving ~40 `AppTokens`
  from it by HSL shift; the result is cached per key, since there are five and
  rebuilding one on every settings write made `AnimatedTheme` lerp the entire
  app. Widgets never hardcode a colour: they read `Theme.of(context)` and
  `AppTokens.of(context)`. Radii come from `AppRadii`, which is constant
  across themes and so deliberately not part of the extension.
- `lib/app/app.dart` — builds `MaterialApp.router` and registers the global
  Ctrl+Shift+D shortcut that opens the scanner debug screen.
- `lib/app/router.dart` — the `GoRouter` route table. Its `redirect` callback
  is the single place that enforces: admin routes require a signed-in admin;
  `/login` bounces to `/setup` (and vice versa) depending on whether an admin
  account exists yet.

## Data layer (`lib/data/`)

- `db/tables.dart` — drift table definitions: `Products` (barcode has a
  unique index — it's the scan lookup key; `brand_name` is indexed too, since
  every read sorts by it), `SuitabilityTags`, `ProductTags` (join table,
  cascade delete, with an index on `tag_id` for the reverse lookups),
  `SeededTagOffers` (which seed vocabulary slots have already been offered, so
  a tag a shop deleted stays deleted), and `AppSettings` (the one row holding
  the shop's welcome text and chosen theme).
- `db/app_database.dart` — the generated `AppDatabase` (drift codegen output
  lives in `app_database.g.dart`, produced by `dart run build_runner build`).
  `beforeOpen` turns on `PRAGMA foreign_keys` and runs the tag seed.
  `schemaVersion` is 5, with an `onUpgrade` covering every installed version;
  `test/data/migration_test.dart` runs it against frozen snapshots of what
  shops actually have on disk. Note the v1-to-v3 step's `else if`: `createTable`
  builds from the *current* Dart definition, so a v1 database jumping straight
  to the latest must not also run the later column add.
- `db/seed.dart` — idempotent insert of the fixed skin/hair tag vocabulary;
  runs on every open, not just on create, so tags added in a later version
  reach databases created by an earlier one.
- `db/connection.dart` — `AppStorage` (resolves the app support directory,
  and the `images/` folder beside the database) and `openConnection`, which
  opens the database on a background isolate via
  `NativeDatabase.createInBackground`.
- `models/` — plain domain types (`Product`, `ProductDraft`, `SuitabilityTag`)
  with no drift import, so nothing above the repository layer sees a
  generated row type.
- `repositories/` — **all** drift access lives here; no query appears in a
  widget. `ProductRepository` translates a unique-barcode violation into
  `DuplicateBarcodeException` (checked proactively before the insert, with
  `guardStorage`'s `onUniqueViolation` as a race-condition backstop).
  `delete` returns the deleted row's `imagePath` so the caller can remove the
  file too — the row is the only record of which file belonged to it.
- `exceptions.dart` — the `AppException` hierarchy. Every user-facing error
  path throws one of these; nothing shows a raw exception string.
- `repositories/storage_guard.dart` — `guardStorage`, the single place that
  translates a drift/sqlite failure into an `AppException` and unwraps the
  `DriftRemoteException` the background isolate wraps everything in.

## Services (`lib/services/`)

- `scanner/barcode_scanner_service.dart` — the USB scanner listener. Hooks
  `HardwareKeyboard.instance.addHandler` and **always returns false** so
  normal typing and shortcuts are unaffected. Buffers characters, using the
  gap between keystrokes to tell a machine-speed scan from a human typing;
  emits a `ScanResult` on Enter/Tab/numpad-Enter if the buffer clears
  `minCodeLength`. All three timings are constructor parameters, tunable from
  the debug screen. An injectable clock (`now:`) makes the timing logic
  testable without real delays.
- `scanner/barcode_normalizer.dart` — trims, uppercases, and reduces a URL
  payload to its last path segment (handles QR codes that encode a product
  URL rather than a bare code).
- `auth_service.dart` — bcrypt hash/verify plus an in-memory, per-username
  failed-attempt lockout (5 attempts → 30s), with an injectable clock for
  testing. Session state itself (who's signed in) lives in
  `providers/auth_providers.dart`, not here.
- `image_store.dart` — copies a picked/dropped image into the `images/`
  folder under a unique filename and returns that filename; the database
  only ever stores the relative name. `importImage` throws `ImageException`
  on failure; `deleteImage` is best-effort and never throws, because one of
  its callers runs from `dispose()`.

## Providers (`lib/providers/`)

One file per concern, each thin: `database_providers.dart` wires
repositories to the open `AppDatabase` (and caches `hasAdminProvider`, the
router's "does setup still apply?" question); `settings_providers.dart` holds
`homeTextProvider`, seeded synchronously from a pre-`runApp` read so the very
first frame already paints in the shop's chosen theme; `auth_providers.dart` holds the
signed-in-admin session and the `AuthService`; `scanner_providers.dart`
exposes the single app-wide `BarcodeScannerService` and its scan/keystroke
streams; `product_providers.dart` and `tag_providers.dart` expose
`FutureProvider`/`StreamProvider`s the screens watch directly (e.g.
`productsStreamProvider` keeps the inventory grid live as products change
anywhere in the app).

## Screens (`lib/screens/`)

| Screen | Route | Notes |
|---|---|---|
| `home/` | `/` | Kiosk landing screen. Listens to the scan stream; on a hit, pushes product detail; on a miss, shows the barcode inline with an admin-only "Add it" shortcut into the add form. |
| `product_detail/` | `/product/:id` | A shown product auto-returns to `/` after 8s, with a draining bar so the customer can see it coming; Escape returns immediately. The separate 60s inactivity timer is the backstop for the states where the countdown never starts — the "no longer in the catalogue" and load-failure cards — not for the success path. |
| `login/` | `/login` | Rate-limited via `AuthService`; a live countdown shows during a lockout. |
| `setup/` | `/setup` | One-time first-admin creation, reachable only when the `admins` table is empty (enforced by the router redirect, not by the screen). |
| `inventory/` | `/inventory` | Admin only. A responsive `GridView` fed by `productsStreamProvider`, client-side filtered by the search field. Delete via right-click, long-press, or a small icon button (the last one exists purely for keyboard/no-mouse reachability — the mockup doesn't show it). |
| `product_form/` | `/inventory/new`, `/inventory/:id/edit` | Add and edit share one screen. Holds a `BarcodeScannerService.suspend()` handle while open (so a scan fills the barcode field instead of also triggering a lookup elsewhere) and warns on unsaved changes before closing. Newly imported images that are never saved are cleaned up on dispose. |
| `settings/` | `/inventory/settings` | Admin only. Edits the kiosk's welcome title and extra line, picks one of five colour themes (which drives every colour in the app, not just the home screen), and changes the admin's own username and password. Guards unsaved changes the same way the product form does. |
| `debug/` | `/debug/scanner` (hidden, Ctrl+Shift+D) | Live keystroke/timing table for tuning the scanner thresholds against real hardware. |

## Widgets (`lib/widgets/`)

Shared building blocks used across multiple screens: `AppCard` (the white
rounded card), `LabeledField` (label-above-input, used by login/setup/the
product form), `ScanIndicator` (the prompt/spinner status card on Home),
`DashedBorderBox` (the "no image" placeholder and drop zone border),
`ProductImage` (a photo decoded at the size it is drawn — shop photos are
phone-sized and would otherwise blow the image cache), `PrimaryActionButton`,
`CircleIconButton`/`IconBadge`, and `confirm_dialog.dart` (the destructive
confirmations, so the same wording appears wherever an action is reachable
from).

## Tests (`test/`)

- `scanner/` — the scanner's timing/length/suspension logic and the
  normalizer, using a fake clock so nothing sleeps.
- `data/` — every repository against an in-memory drift database
  (`test/helpers/test_db.dart`), plus `migration_test.dart`, which upgrades
  frozen v1 and v3 snapshots (`test/helpers/legacy_schemas.dart`) and checks
  the catalogue survives.
- `services/auth_service_test.dart` — the lockout counting/timing logic,
  mirroring the scanner tests' fake-clock approach.
- `screens/` — widget tests for home, product detail, inventory, the product
  form, settings, and the responsive fallbacks. Any test whose screen reads a
  drift stream must end with `disposeAndDrain` (`test/helpers/drift_settle.dart`)
  or the framework's pending-timer check trips the moment the body returns.
