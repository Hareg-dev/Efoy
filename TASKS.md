# Efoy Development Tasks

## ✅ COMPLETED (Backend Foundation)

- [x] Project setup & dependencies
- [x] Theme system (Light/Dark)
- [x] Bilingual strings (EN/AM)
- [x] Device identity & license verification
- [x] All 5 Isar data models + schemas
- [x] WAC Calculator
- [x] Profit Engine
- [x] Currency & date utilities

---

## 🎯 PHASE 1: Core Navigation (Week 1)

### Task 1.1: Splash Screen ✅ COMPLETED
**File:** `lib/ui/screens/splash_screen.dart`
- [x] Dark gradient background
- [x] Efoy logo card (white rounded)
- [x] Amharic text: እፎይ
- [x] Tagline: በእፎይ እርፍ ይበሉ
- [x] Animated dots at bottom
- [x] Auto-navigate after 2s
- [x] Check license on load

**Test:**
```bash
flutter run
# Should show splash → navigate ✅
```

### Task 1.2: Auth Screen ✅ COMPLETED
**File:** `lib/ui/screens/auth_screen.dart`
- [x] Tab 1: Login (password field)
- [x] Tab 2: License Activation
- [x] Display Device ID with copy button
- [x] License key input (formatted)
- [x] Activate button
- [x] Error/success messages

**Test:**
```dart
// Generate test key - See TESTING.md
final deviceId = await DeviceIdentity.getDeviceId();
final key = LicenseVerifier.generateLicenseKey(
  deviceId: deviceId,
  expiryDate: DateTime.now().add(Duration(days: 30)),
);
print('Test License: $key');
```

### Task 1.3: Main Layout ✅ COMPLETED
**File:** `lib/ui/screens/main_layout.dart`
- [x] BottomNavigationBar with 5 items
- [x] Icons: Home, Sell, Inventory, Expenses, Profile
- [x] Labels in current language
- [x] PageView for screens
- [x] Persistent state

### Task 1.4: Home Screen (Basic) ✅ COMPLETED
**File:** `lib/ui/screens/home_screen.dart`
- [x] Header with brand name
- [x] Net Profit Card placeholder
- [x] Quick metrics cards
- [x] Critical alerts section
- [x] Empty activity state

**Test:**
- [x] Run app end-to-end
- [x] Splash → Auth → Home
- [x] Bottom nav works
- [ ] TODO: Add real data integration

---

## 🎯 PHASE 2: Home Dashboard (Week 1-2)

### Task 2.1: Theme Provider
**File:** `lib/logic/providers/theme_provider.dart`
```dart
final darkModeProvider = StateProvider<bool>((ref) => false);
final languageProvider = StateProvider<String>((ref) => 'en');
final accentColorProvider = StateProvider<Color>((ref) => AppColors.primaryTeal);
```

### Task 2.2: Home Screen
**File:** `lib/ui/screens/home_screen.dart`
- [ ] Header with brand name + settings icon
- [ ] Net Profit Card widget
- [ ] Quick metrics (2 cards)
- [ ] Critical alerts section
- [ ] Activity feed (last 15 items)

### Task 2.3: Net Profit Card Widget
**File:** `lib/ui/widgets/net_profit_card.dart`
- [ ] Green gradient background
- [ ] SYNCED badge (top-right)
- [ ] Period filter chips: Today/Week/Month
- [ ] Large Birr amount (centered)
- [ ] Revenue vs Expenses bar

**Test:**
- [ ] Period filter changes data
- [ ] Tap card → detailed view
- [ ] Synced badge shows status

---

## 🎯 PHASE 3: POS System (Week 2-3)

### Task 3.1: Cart Provider
**File:** `lib/logic/providers/cart_provider.dart`
- [ ] CartItem model (product, qty, price)
- [ ] Add/remove/update items
- [ ] Price override logic
- [ ] Calculate totals
- [ ] Clear cart

### Task 3.2: Sell Screen
**File:** `lib/ui/screens/sell_screen.dart`
- [ ] Search bar (filter products)
- [ ] Product grid (cards)
- [ ] Show: image, name, price, stock
- [ ] Tap → add to cart
- [ ] Cart FAB with badge count

### Task 3.3: Cart Bottom Sheet
**File:** `lib/ui/widgets/cart_bottom_sheet.dart`
- [ ] Slide-up modal
- [ ] Cart items list
- [ ] Quantity +/- buttons
- [ ] Tap item → edit price
- [ ] Payment method chips
- [ ] Amount received input
- [ ] Change calculation
- [ ] Complete Sale button
- [ ] Void button

**Test:**
- [ ] Add 3 products to cart
- [ ] Change quantity
- [ ] Override price on 1 item
- [ ] Complete sale → success message
- [ ] Void sale → stock restored

---

## 🎯 PHASE 4: Inventory Management (Week 3-4)

### Task 4.1: Inventory Provider
**File:** `lib/logic/providers/inventory_provider.dart`
- [ ] Load all products
- [ ] Filter by stock status
- [ ] Add product (with WAC)
- [ ] Update product
- [ ] Restock with WAC recalculation
- [ ] Delete (soft delete)
- [ ] Low stock alerts count

### Task 4.2: Inventory Screen
**File:** `lib/ui/screens/inventory_screen.dart`
- [ ] Tabs: All / Needs Attention / Out of Stock
- [ ] Alert banner (e.g., "12 items low")
- [ ] Product cards with stock badges
- [ ] FAB: Add Product
- [ ] Tap card → Product Detail

### Task 4.3: Add Product Modal
**File:** `lib/ui/widgets/add_product_modal.dart`
- [ ] Name, description, category
- [ ] Barcode input + scanner button
- [ ] Photo capture button
- [ ] Selling price input
- [ ] Cost price input
- [ ] Initial stock quantity
- [ ] Low stock threshold
- [ ] Save button

### Task 4.4: Product Detail Screen
**File:** `lib/ui/screens/product_detail_screen.dart`
- [ ] Product image, name, category
- [ ] Edit/Delete buttons
- [ ] Financial summary (6 cards):
  - Current stock
  - WAC
  - Selling price
  - Profit margin %
  - Liquidity value
  - Capital invested
- [ ] Restock history list
- [ ] Restock button → modal

### Task 4.5: Barcode Scanner
**File:** `lib/ui/widgets/barcode_scanner_modal.dart`
- [ ] Camera viewfinder
- [ ] Scan detection
- [ ] Result callback
- [ ] Manual entry fallback
- [ ] Close button

**Test:**
- [ ] Add product: "Coca-Cola 500ml"
- [ ] Cost: 15 ብር, Price: 20 ብር, Stock: 100
- [ ] Scan barcode: 5449000000996
- [ ] Restock: +50 @ 18 ብር
- [ ] Verify new WAC: 16.0 ብር ✓
- [ ] Check liquidity: 150 × 20 = 3000 ብር

---

## 🎯 PHASE 5: Expenses & Reports (Week 4-5)

### Task 5.1: Expense Provider
**File:** `lib/logic/providers/expense_provider.dart`
- [ ] Load expenses by period
- [ ] Filter by category
- [ ] Add expense
- [ ] Update expense
- [ ] Delete expense
- [ ] Calculate totals by category

### Task 5.2: Expenses Screen
**File:** `lib/ui/screens/expenses_screen.dart`
- [ ] Total spent header
- [ ] Cost driver insight banner
- [ ] Category grid (8 icons)
- [ ] Add expense form
- [ ] Recent expenses list
- [ ] Edit/delete buttons

**Test:**
- [ ] Add Rent: 5000 ብር
- [ ] Add Salary: 3000 ብር
- [ ] Verify total: 8000 ብር
- [ ] Check Net Profit excludes restock

### Task 5.3: Profile Screen
**File:** `lib/ui/screens/profile_screen.dart`
- [ ] Date range filter
- [ ] 4 metric cards:
  - Revenue
  - Gross Profit
  - Operating Expenses
  - Gross Margin %
- [ ] Decision insights panel
- [ ] Best-selling products list
- [ ] Low-margin products list

**Test Financial Accuracy:**
```
Scenario:
- Day 1: Restock 100 items @ 1000 ብር (CapEx)
- Day 2: Sell 10 @ 15 ብር = 150 ብር revenue
  - COGS: 10 × 10 = 100 ብር
  - Gross Profit: 150 - 100 = 50 ብር
  - OpEx: Rent (30) + Salary (20) = 50 ብር
  - Net Profit: 50 - 50 = 0 ብር ✓

Expected: Net Profit = 0 (NOT -950 from including restock!)
```

---

## 🎯 PHASE 6: Settings & Polish (Week 5-6)

### Task 6.1: Settings Screen
**File:** `lib/ui/screens/settings_screen.dart`
- [ ] Store identity card
- [ ] Dark mode toggle
- [ ] Accent color picker (6 swatches)
- [ ] Language toggle [EN]/[አማርኛ]
- [ ] License info card
- [ ] Backup button
- [ ] Restore button
- [ ] Clear data button (with confirmation)
- [ ] About section

**Test:**
- [ ] Toggle dark mode → theme changes
- [ ] Change accent → colors update
- [ ] Switch to Amharic → all text updates
- [ ] Backup → JSON file exported
- [ ] Restore → data loaded

### Task 6.2: Reusable Widgets
- [ ] `lib/ui/widgets/alert_banner_card.dart`
- [ ] `lib/ui/widgets/activity_list_tile.dart`
- [ ] `lib/ui/widgets/product_card.dart`
- [ ] `lib/ui/widgets/metric_summary_card.dart`

---

## 🎯 PHASE 7: Integration Testing (Week 6)

### Complete User Flow Test

1. **First Launch**
   - [ ] Splash screen displays
   - [ ] Navigate to Auth (no license)
   - [ ] Copy Device ID
   - [ ] Enter test license key
   - [ ] Activate → Success
   - [ ] Navigate to Home

2. **Add Products**
   - [ ] Go to Inventory
   - [ ] Add 5 products with barcodes
   - [ ] Verify WAC calculations
   - [ ] Check low stock alerts

3. **Complete Sales**
   - [ ] Go to Sell
   - [ ] Add 3 items to cart
   - [ ] Override 1 price
   - [ ] Select payment: Cash
   - [ ] Complete sale
   - [ ] Verify stock decreased

4. **Log Expenses**
   - [ ] Go to Expenses
   - [ ] Add Rent: 5000 ብր
   - [ ] Add Salary: 3000 ብር
   - [ ] Verify total: 8000 ብር

5. **Check Reports**
   - [ ] Go to Profile
   - [ ] Filter: Today
   - [ ] Verify Net Profit = Gross Profit - OpEx
   - [ ] Verify restocking NOT in OpEx

6. **Settings**
   - [ ] Toggle dark mode
   - [ ] Switch to Amharic
   - [ ] Verify all screens translated
   - [ ] Backup data
   - [ ] Switch back to English

---

## 📊 Testing Checklist per Feature

### For Each Screen:
- [ ] UI matches design specs
- [ ] Responsive to different screen sizes
- [ ] Dark mode works correctly
- [ ] Amharic text displays properly
- [ ] Loading states shown
- [ ] Error states handled
- [ ] Empty states shown
- [ ] Navigation works
- [ ] Back button behaves correctly

### For Each Provider:
- [ ] State updates correctly
- [ ] Database operations work
- [ ] Error handling in place
- [ ] Loading indicators
- [ ] Success feedback

### Financial Accuracy:
- [ ] WAC calculation correct
- [ ] COGS calculation correct
- [ ] Gross Profit correct
- [ ] Net Profit correct (excludes restock)
- [ ] Profit margin correct

---

## 🐛 Known Issues / Future Enhancements

### P2P Sync (Future)
- [ ] WebSocket server
- [ ] Client connection
- [ ] Event broadcasting
- [ ] Conflict resolution

### Advanced Features (Future)
- [ ] Charts & graphs
- [ ] PDF reports
- [ ] Receipt printing
- [ ] Multi-store support
- [ ] Cloud backup

---

## 📝 Progress Tracking

**Current Status:** Phase 0 Complete ✅

**Next Milestone:** Phase 1 - Core Navigation

**Target Completion:** 6 weeks

**Update This File:** Mark tasks with [x] as you complete them
