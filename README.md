# Efoy · እፎይ

**Offline point-of-sale, inventory and profit tracking for Ethiopian shops.**

Efoy runs entirely on the phone. No account, no server, no internet connection:
goods are sold, stock is counted, expenses are recorded and profit is worked out
from the database on the device. It speaks English and Amharic, and it is built
for a counter that is busy, a shelf that is small, and a network that is not
always there.

<p align="center">
  <em>Android 7.0+ · Flutter 3.44 · ~60 MB release APK · GPL-3.0-or-later</em>
</p>

---

## What the shop can do

### Selling
- Tap products into a cart, change quantities, or override a price (password-protected).
- **Three ways to settle:** paid in full, part payment, or on credit with the customer's name.
- Tenders: cash, Telebirr, CBE Birr, Amhara Bank, or mixed, with change calculated for you.
- Hold an order and resume it later when the queue moves on.

### Credit and receivables
- A credit or part-paid sale keeps its **full invoice value**, so the profit stays on
  the day the goods left the shop.
- The unpaid part becomes a balance on **Who owes me**, oldest first, with the
  customer's name, phone and every instalment taken since.
- Taking a later payment moves only that balance — the original sale is never edited.
- Overpaying is refused, and a balance cannot be deleted away; it is cleared by
  taking the money.

### Inventory
- Weighted-average costing (WAC) recalculated on every restock, so margin is real.
- Stock value, low-stock and out-of-stock alerts on the home screen.
- Restock log for every batch: quantity, purchase price, stock before/after, new WAC.
- Soft delete, so history never lies about what was once on the shelf.

### Expenses and profit
- Category-first expense entry: rent, salaries, transport, utilities, airtime,
  supplies, restock and other.
- Restock is treated as **capital**, not an expense: it becomes stock, so it is
  never subtracted from profit.
- Profit is split by period, because a shop does not pay rent three times a day:
  - **Today** — selling minus the cost of the goods sold.
  - **This week** — that, minus rent, transport, utilities, airtime, supplies and other.
  - **This month** — that, minus salaries too.
- The profit card prints every deducted line, and shows **cash taken** and
  **money still with customers** beside the margin.

### Reports
- Business report from Profile: daily trading bars, best day, product trends ranked
  by profit, operating costs by category, and restock history.

### Store management
- Store name, owner name and photo, used on the home screen.
- Light / dark / follow-system theme, and **six accent palettes** that repaint the
  theme and the money surfaces (Teal, Forest Green, Ocean Blue, Deep Purple, Crimson, Amber).
- English and አማርኛ, switchable inside the app.
- Excel export of products, sales and expenses.
- Full JSON backup and restore, plus password-gated data deletion.

### Undo a mistake
- The last three sales on the home screen each carry **Undo**. It asks first, then
  puts the units back on the shelf and clears any balance the sale opened, in one
  database transaction. The sale stays in the records, marked as undone.

---

## How it is licensed

Efoy is sold with offline activation codes:

- A new installation starts with a short trial.
- A **signed activation code** (Ed25519, verified against a public key embedded in
  the app) unlocks a monthly or lifetime licence. Verification happens on the
  device; the app never contacts a server.
- When a licence ends, **writing stops and nothing is deleted**: sales, expenses,
  restocks, product edits and held orders are refused at the data layer, while
  history, reports, export and backup keep working. Renewing in Profile restores
  writing immediately.
- Moving the device clock backwards by more than a day locks a time-limited
  licence until the clock is corrected.
- The application source contains verification only. It cannot mint codes; the
  signing key is not in this repository.

---

## Privacy

- **No telemetry, no analytics, no ads, no accounts, no cloud.**
- The shop's data is a local Isar database on the device. Nothing is uploaded; it
  leaves the phone only when the merchant exports or shares a backup.
- The app requests a single Android permission: `INTERNET`, and only so the
  optional Inter typeface can be downloaded. Everything works in airplane mode
  with the system font. No camera, location, contacts or storage permission.
- Store listings should declare no anti-features for tracking or ads.

---

## Build it

Requirements: Flutter 3.44+ (Dart 3.12+), Android SDK with build-tools, and Java 17.

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Isar schemas
flutter analyze
flutter test
flutter build apk --release                                # build/app/outputs/flutter-apk/
```

The debug and release builds are accepted side by side; **for publishing, replace
the signing configuration in `android/app/build.gradle.kts` with your own keystore**
(F-Droid signs the APK it builds itself).

### Tests

The suite runs on the host (no emulator) against a real Isar database:

```bash
flutter test
```

It covers the money paths first — WAC maths, credit sales and settle-ups, period
splits, sale undo, licence expiry enforcement, backup/deletion — and the screens
that carry them, in both languages.

---

## Project layout

```
lib/
  core/            money, licensing, backup, export, settings, l10n helpers
  data/
    models/        Isar collections (products, sales, debts, expenses, restock…)
    repositories/  every write path, with licence enforcement inside
    local/         database + JSON export/import
  logic/
    calculators/   WAC and profit engine
    providers/     Riverpod state for screens and reports
  ui/
    screens/       home, sell, inventory, expenses, profile, settings,
                   debts ("Who owes me"), reports
    widgets/       shared cards, headers, cart sheet, profit card
packages/efoy_licensing/   payload codec and Ed25519 verification
test/                      unit, widget and host-database tests
```

---

## Store packaging notes (F-Droid and similar)

The app is free software under the GPL and builds from this tree. Two things are
worth knowing before submitting it to a catalogue that rebuilds from source:

1. **Fonts.** `google_fonts` normally fetches Inter at runtime. The app degrades
   gracefully to the system font offline, but a store that forbids non-free
   network services will flag the runtime fetch. Bundle `Inter` under
   `assets/fonts/` and declare it in `pubspec.yaml` for a fully offline build.
2. **Native binaries.** Isar ships prebuilt native libraries through Maven;
   distributors that require everything to be compiled from source need to
   account for them in their build recipe.

The store listing text is under `fastlane/metadata/android/` (English and Amharic)
for catalogues that read Fastlane metadata.

---

## Support

- Telegram: **[@haregdev](https://t.me/haregdev)**
- Call or SMS: **0988545894** · **0908258915**
- Telebirr: **0988545894** (`@Haregdev Team`)

---

## License

Copyright © 2026 Hareg-dev.

This program is free software: you can redistribute it and/or modify it under the
terms of the **GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.** See [LICENSE](LICENSE).

This program is distributed in the hope that it will be useful, but **without any
warranty**; without even the implied warranty of merchantability or fitness for a
particular purpose.
