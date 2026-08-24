# BeneSnap, explained

This is a walkthrough of how BeneSnap actually works, written for someone who
wants to understand the app, not just skim a file list. If you want the terse
reference version (file paths, one-liners), see `ARCHITECTURE.md` instead —
this document is the "why" and "how it fits together" companion to that one.

---

## 1. What the app is, in one paragraph

A shop keeps a counter with a USB barcode/QR scanner plugged into a desktop
running BeneSnap. A customer or staff member scans a product; the screen
immediately shows its key ingredients, core benefits, and which skin/hair
types it suits. That's **kiosk mode** — no login, always on. A staff member
can tap an account icon, log in, and get **admin mode** — a searchable
inventory grid where they can add, edit, or delete products, including a
photo and a set of skin/hair suitability tags. Both modes are the same app;
what you see depends on whether an admin is signed in.

---

## 2. The four layers

Everything in `lib/` sits in one of four layers, and each layer only talks to
the one below it:

```
screens/          — what you see and tap. No database code lives here.
providers/         — Riverpod glue: exposes repositories and streams to screens.
data/repositories/ — the ONLY place that runs a database query.
data/db/            — the schema itself (drift tables + generated code).
```

Why bother with this separation? Two concrete reasons that came up while
building this:

- **Testability.** `ProductRepository` can be tested against a real in-memory
  database with no Flutter widgets involved at all (see
  `test/data/product_repository_test.dart` — 30-some tests, zero pixels).
- **A single place to translate errors.** A raw SQLite "UNIQUE constraint
  failed" is meaningless to a shop assistant. The repository is the one place
  that catches it and rethrows `DuplicateBarcodeException("Barcode 590... is
  already used by another product...")` — a message the screen can show
  directly. No screen ever sees a raw exception.

---

## 3. The database

BeneSnap uses **drift** (a type-safe layer over SQLite) rather than talking to
SQL strings directly. The schema lives in `lib/data/db/tables.dart`; running
`dart run build_runner build` generates `app_database.g.dart` — the actual
query-building code — from it. You edit `tables.dart`, never the generated
file.

### Where the file lives

Not bundled with the app — created on first launch, in the OS's normal "app
data" folder (e.g. `%APPDATA%\benesnap` on Windows). Right next to the
database file is an `images/` folder holding every product photo. Back up
that whole folder and you have the entire shop's catalogue.

### The four tables

**`products`** — the catalogue itself.

| column | type | notes |
|---|---|---|
| `id` | int, autoincrement | primary key |
| `barcode` | text | **unique** — this is what a scan looks up |
| `brand_name` | text | required |
| `product_name` | text | required |
| `key_ingredients` | text | required, free text |
| `core_benefits` | text | required; stored as one benefit per line |
| `image_path` | text, nullable | just a filename like `img_1234_ab.jpg`, resolved against the `images/` folder at read time — never a full path, so the catalogue survives the app moving to a new machine |
| `created_at`, `updated_at` | int | epoch milliseconds |

The `barcode` column has a **unique index**. That's not a nicety — it's what
makes "scan → exact match → show the product" work at all. If two products
could share a barcode, a scan wouldn't know which one you meant.

**`suitability_tags`** — the fixed vocabulary of skin/hair types. Seeded once
on first launch with 7 skin types (normal, dry, oily, combination, sensitive,
acne-prone, mature) and 10 hair types (straight, wavy, curly, coily, fine,
thick, oily scalp, dry scalp, colour-treated, damaged). The seed re-checks on
every app open (not just the very first one), so a future version that adds a
new tag would pick it up on an existing installation without a migration.

**`product_tags`** — a plain join table (`product_id` + `tag_id`, both
columns together are the primary key) linking products to however many tags
apply. Deleting a product cascades and removes its tag links automatically
(`onDelete: KeyAction.cascade`) — no orphaned rows to clean up by hand.

**`admins`** — one row per staff login. `username` is unique; `password_hash`
is a bcrypt hash, never the plaintext password (see §5).

### How a lookup actually happens

1. Scanner types a raw string, e.g. `https://shop.example/p/AB12CD`, and
   presses Enter.
2. `BarcodeNormalizer` reduces that to `AB12CD` (uppercased; if it looks like
   a URL, only the last path segment survives — this handles QR codes that
   encode a product page URL instead of a bare code).
3. `ProductRepository.findByBarcode('AB12CD')` runs `SELECT ... WHERE
   barcode = ?` against the unique index — an instant, exact match.
4. Found → push the product detail screen. Not found → show the code inline
   with "This product isn't in the catalogue yet."

---

## 4. The scanner — the part most worth understanding

There's no camera and no barcode-scanning library. A USB barcode scanner is a
**keyboard-wedge device**: to the operating system, it looks exactly like
someone typing on a keyboard very fast, then pressing Enter. BeneSnap has to
tell "a person typed something" apart from "the scanner typed something,"
using nothing but *timing*.

`BarcodeScannerService` (`lib/services/scanner/barcode_scanner_service.dart`)
hooks `HardwareKeyboard.instance.addHandler` — a low-level hook that sees
every keystroke in the whole app, before any text field does — and **always
returns `false`**, meaning it never blocks a keystroke from reaching whatever
you're actually typing into. It just watches.

The logic:

- Every keystroke's gap from the previous one is measured.
- If that gap is under **60ms** (configurable), it's added to a buffer — this
  is "machine speed," faster than any human can type.
- If the gap is *over* 60ms, the buffer is thrown away and started fresh —
  someone's typing normally, not scanning.
- When Enter, numpad Enter, or Tab arrives, if the buffer has **at least 4
  characters**, it's emitted as a completed scan (normalized, then broadcast
  on a stream every screen can listen to).
- A buffer that's gone quiet for **400ms** is discarded even without a
  terminator, so a half-finished scan doesn't linger and get accidentally
  appended to later.

All three numbers (60ms, 4 characters, 400ms) are constructor parameters —
nothing is hardcoded — because real scanner hardware varies. That's what the
hidden **Ctrl+Shift+D debug screen** is for: it shows every raw keystroke and
the exact gap before it, colour-highlighting any gap that exceeded the
threshold, so whoever installs the scanner at the shop can watch real scans
happen and tune the numbers to match their actual device.

One more detail: the service has an `enabled` flag. The add/edit product form
switches it off while open — otherwise, scanning a barcode to fill that
form's barcode field would *also* be picked up by whatever's listening to the
global scan stream elsewhere (e.g. triggering a stray "product not found"
popup on the kiosk screen underneath). Turning the flag off doesn't stop the
scanner's keystrokes from reaching the text field — that happens at a lower
level than this flag — it only stops the *service itself* from broadcasting.

---

## 5. Logins and passwords

There's no hardcoded admin password anywhere in the code — the spec
explicitly ruled that out. Instead:

- On first launch, `AdminRepository.isEmpty()` checks whether the `admins`
  table has any rows. If not, the router redirects `/login` to `/setup`
  automatically — you physically cannot reach a login screen with no account
  to log into.
- The setup screen creates the first account. The password is hashed with
  **bcrypt** (`BCrypt.hashpw`, via the `bcrypt` package) before it ever
  touches the database — `AuthService.createAdmin` never stores the raw
  string.
- Logging in calls `BCrypt.checkpw(typedPassword, storedHash)` — bcrypt
  itself handles the comparison; the app never has the real password in
  reversible form at all.
- `AuthService` also tracks failed attempts **per username, in memory**: 5
  wrong passwords in a row locks that username out for 30 seconds, with a
  live countdown on the login screen. This resets on any successful login and
  is scoped per-username, so a bad guess against one account doesn't lock out
  another.
- Whoever's logged in lives in `authSessionProvider` — just a username string
  in memory. Nothing persists it to disk, so restarting the app always starts
  back in kiosk mode. That's deliberate: a shop shouldn't reopen already
  logged in as whoever used it last.

---

## 6. Screens and how you get between them

Navigation is handled by `go_router`. Every route lives in
`lib/app/router.dart`, and there's exactly one router-level rule that decides
who's allowed where — a `redirect` callback that runs before every
navigation:

```
GET /inventory (or /inventory/new, /inventory/:id/edit)
  → not logged in?  bounce to /login

GET /login
  → already logged in?      bounce to /inventory
  → no admin account yet?   bounce to /setup

GET /setup
  → an admin already exists?   bounce to /login  (setup is one-time only)
```

Because this lives in one place instead of being checked inside every
screen, there's no way for a screen to "forget" to check permissions — the
router won't even build the screen if the rule says no.

| Screen | Route | What it does |
|---|---|---|
| Home | `/` | The kiosk landing screen. Listens for scans; shows a pulsing "scan" indicator, a spinner during lookup, and the account icon top-right. |
| Product detail | `/product/:id` | Shown after a successful scan. Escape, the back arrow, or **60 seconds of no activity** (mouse, keyboard, anything) return to Home — so an unattended counter resets itself for the next customer. |
| Login | `/login` | Username/password, rate-limited as above. |
| Setup | `/setup` | One-time first-admin creation. |
| Inventory | `/inventory` | Admin only. A grid of product cards plus a "+" tile; a search box filters by brand, product name, or barcode as you type; right-click, long-press, or a small delete icon removes a product (with a confirmation dialog first). |
| Add/edit product | `/inventory/new`, `/inventory/:id/edit` | Same screen, two modes. Barcode/brand/product name are required and the barcode must be unique (checked before saving, with a clear inline message if it collides). Warns before discarding unsaved changes. The image can be clicked-to-browse or dragged straight onto the drop zone. |
| Scanner debug | `/debug/scanner` (hidden) | Ctrl+Shift+D from anywhere. See §4. |

---

## 7. State management (Riverpod)

Riverpod providers are the wiring between the database and the screens.
There's no code generation for them (see the comment in `pubspec.yaml` for
why — a dependency-version conflict on this particular Flutter SDK), so
they're all hand-written, but simple:

- **`database_providers.dart`** — the open `AppDatabase`, and one provider
  per repository (`productRepositoryProvider`, `tagRepositoryProvider`,
  `adminRepositoryProvider`, `imageStoreProvider`). The database itself is
  opened once in `main()` before the app even starts, and handed in via
  `overrideWithValue` — so if opening it ever failed, you'd know before any
  screen tried to render.
- **`auth_providers.dart`** — who's signed in (`authSessionProvider`), a
  derived `isAdminProvider` boolean the router reads, and the shared
  `AuthService` instance (kept alive for the app's lifetime so the lockout
  timer survives navigating away from the login screen and back).
- **`scanner_providers.dart`** — the single, app-wide
  `BarcodeScannerService`, plus two streams (completed scans, raw keystrokes)
  that screens `watch()` directly.
- **`product_providers.dart`** / **`tag_providers.dart`** — thin
  `FutureProvider`/`StreamProvider`s screens read from. Worth noting:
  `productsStreamProvider` wraps `ProductRepository.watchAll()`, a drift
  *stream* query — so the inventory grid re-renders automatically the moment
  a product is added or deleted anywhere in the app, with no manual refresh
  logic anywhere.

---

## 8. The visual design system

Every colour, corner radius, and shadow in the app comes from exactly one
place: `AppTheme.light` in `lib/app/theme.dart`. No widget hardcodes a
colour. The palette itself wasn't guessed — it was sampled pixel-by-pixel
from the five mockup PNGs in `UI\UX/` (the background/pill/border tan is
`#E9D1A6` in every single mockup; cards are pure white; placeholder text is
`#B1B2B5`). The font is Quicksand via `google_fonts`, matching the rounded
style in the mockups.

---

## 9. Running it yourself

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # regenerates app_database.g.dart if tables.dart changed
flutter run -d windows   # or -d linux / -d macos
```

```bash
flutter analyze   # should report zero issues
flutter test      # 71 tests: scanner timing, normalizer, repository CRUD, auth lockout
```
