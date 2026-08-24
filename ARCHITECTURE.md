# BeneSnap Architecture

BeneSnap is a Flutter desktop app for a cosmetics/skincare shop counter. A USB
keyboard-wedge barcode/QR scanner drives a kiosk screen showing a product's key
ingredients, core benefits, and skin/hair suitability. Staff who log in as
admin manage the catalogue.

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
- **google_fonts** (Quicksand) for the rounded, kiosk-friendly type

## Entry point

- `lib/main.dart` — configures the window, resolves `AppStorage` (the app
  support directory), opens the drift database, and runs `BeneSnapApp` inside
  a `ProviderScope` with the storage/database providers overridden to their
  real instances.

## App shell

- `lib/app/theme.dart` — `AppTheme.light` is the single source of every
  colour, radius, and shadow (`AppColors`/`AppTokens`). Widgets never
  hardcode a colour; they read `Theme.of(context)` and `AppTokens.of(context)`.
  Palette values were sampled directly from the mockups in `UI\UX/`.
- `lib/app/app.dart` — builds `MaterialApp.router` and registers the global
  Ctrl+Shift+D shortcut that opens the scanner debug screen.
- `lib/app/router.dart` — the `GoRouter` route table. Its `redirect` callback
  is the single place that enforces: admin routes require a signed-in admin;
  `/login` bounces to `/setup` (and vice versa) depending on whether an admin
  account exists yet.

## Data layer (`lib/data/`)

- `db/tables.dart` — drift table definitions: `Products` (barcode has a
  unique index — it's the scan lookup key), `SuitabilityTags`, `ProductTags`
  (join table, cascade delete), `Admins`.
- `db/app_database.dart` — the generated `AppDatabase` (drift codegen output
  lives in `app_database.g.dart`, produced by `dart run build_runner build`).
  `beforeOpen` turns on `PRAGMA foreign_keys` and runs the tag seed.
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
  `DuplicateBarcodeException` (checked proactively before the insert, with a
  raw-`SqliteException` catch as a race-condition backstop — including
  unwrapping `DriftRemoteException`, since the background-isolate connection
  wraps exceptions crossing the isolate boundary).
- `exceptions.dart` — the `AppException` hierarchy. Every user-facing error
  path throws one of these; nothing shows a raw exception string.

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
  only ever stores the relative name.

## Providers (`lib/providers/`)

One file per concern, each thin: `database_providers.dart` wires
repositories to the open `AppDatabase`; `auth_providers.dart` holds the
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
| `product_detail/` | `/product/:id` | Escape, the back button, or 60s of inactivity return to `/`. The inactivity timer is reset by both pointer and raw keyboard activity. |
| `login/` | `/login` | Rate-limited via `AuthService`; a live countdown shows during a lockout. |
| `setup/` | `/setup` | One-time first-admin creation, reachable only when the `admins` table is empty (enforced by the router redirect, not by the screen). |
| `inventory/` | `/inventory` | Admin only. A responsive `GridView` fed by `productsStreamProvider`, client-side filtered by the search field. Delete via right-click, long-press, or a small icon button (the last one exists purely for keyboard/no-mouse reachability — the mockup doesn't show it). |
| `product_form/` | `/inventory/new`, `/inventory/:id/edit` | Add and edit share one screen. Disables the global scanner while open (so a scan fills the barcode field instead of also triggering a lookup elsewhere) and warns on unsaved changes before closing. Newly imported images that are never saved are cleaned up on dispose. |
| `debug/` | `/debug/scanner` (hidden, Ctrl+Shift+D) | Live keystroke/timing table for tuning the scanner thresholds against real hardware. |

## Widgets (`lib/widgets/`)

Shared building blocks used across multiple screens: `AppCard` (the white
rounded card), `LabeledField` (label-above-input, used by login/setup/the
product form), `ScanIndicator` (the pulsing/spinner status square on Home),
`DashedBorderBox` (the "no image" placeholder and drop zone border).

## Tests (`test/`)

- `scanner/` — the scanner's timing/length/enabled-flag logic and the
  normalizer, using a fake clock so nothing sleeps.
- `data/product_repository_test.dart` — create/read/update/delete and the
  unique-barcode conflict, against an in-memory drift database
  (`test/helpers/test_db.dart`).
- `services/auth_service_test.dart` — the lockout counting/timing logic,
  mirroring the scanner tests' fake-clock approach.
