# BeneSnap

A Flutter desktop kiosk for a cosmetics shop counter. A USB barcode/QR
scanner is plugged into the machine; a customer scans a product and the screen
shows its key ingredients, core benefits, and which skin and hair types it
suits. Staff can sign in to manage the catalogue.

The interface is Arabic, right-to-left. Windows is the primary target; it also
builds and runs on Linux and macOS.

## Running it

```bash
flutter pub get
flutter run -d windows        # or -d linux / -d macos
```

The database and product images live in the OS's app-data folder (e.g.
`%APPDATA%\benesnap` on Windows), created on first launch. Copy that folder
and you have the shop's whole catalogue.

On first launch there is no admin account, so the app sends you to a one-time
setup screen to create one. There is no default password anywhere in the code.

## Checks

```bash
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

All three run in CI on every push and pull request
(`.github/workflows/ci.yml`).

## Changing the database schema

`lib/data/db/tables.dart` is the schema; `app_database.g.dart` is generated
from it and committed:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Bump `schemaVersion` in `lib/data/db/app_database.dart`, add the matching
`onUpgrade` step, and extend `test/data/migration_test.dart` — a shop's
installed database is upgraded in place, and that test is what proves it
survives.

## Where to read next

- **`ARCHITECTURE.md`** — the terse reference: what each file is for.
- **`PROJECT_GUIDE.md`** — the walkthrough: how it all fits together, and why.

## Packaging for Windows

```bash
flutter build windows --release
"C:\Program Files (x86)\Inno Setup 6\ISCC.exe" installers\benesnap.iss
```

The installer lands in `installers\Output\`.
