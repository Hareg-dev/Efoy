# Efoy Testing Guide

## 🧪 Quick Test Commands

### Run App
```bash
# Windows
flutter run -d windows

# Android Device
flutter run -d <device-id>

# Android Emulator
flutter emulators --launch <emulator-id>
flutter run

# iOS Simulator
flutter run -d "iPhone 15"
```

### Generate License Key for Testing
```dart
// Add to lib/core/utils/test_helpers.dart
import '../security/device_identity.dart';
import '../security/license_verifier.dart';

Future<void> generateTestLicense() async {
  final deviceId = await DeviceIdentity.getDeviceId();
  print('Device ID: $deviceId');
  
  // 30-day trial
  final trialKey = LicenseVerifier.generateLicenseKey(
    deviceId: deviceId,
    expiryDate: DateTime.now().add(Duration(days: 30)),
  );
  print('Trial License (30 days): $trialKey');
  
  // Lifetime
  final lifetimeKey = LicenseVerifier.generateLicenseKey(
    deviceId: deviceId,
    expiryDate: DateTime.now().add(Duration(days: 36500)), // 100 years
  );
  print('Lifetime License: $lifetimeKey');
}
```

### Create Sample Data
```dart
// lib/core/utils/sample_data.dart
import 'package:isar/isar.dart';
import '../../data/models/product_model.dart';
import '../../data/models/expense_model.dart';

Future<void> seedDatabase(Isar isar) async {
  await isar.writeTxn(() async {
    // Clear existing
    await isar.clear();
    
    // Add products
    await isar.productModels.putAll([
      ProductModel(
        name: 'Coca-Cola 500ml',
        barcode: '5449000000996',
        sellingPrice: 20.0,
        costPrice: 15.0,
        currentStock: 100,
        lowStockThreshold: 20,
        category: 'Beverages',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        name: 'Bread (White)',
        sellingPrice: 15.0,
        costPrice: 10.0,
        currentStock: 50,
        lowStockThreshold: 10,
        category: 'Food',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        name: 'Eggs (12 pack)',
        sellingPrice: 80.0,
        costPrice: 60.0,
        currentStock: 30,
        lowStockThreshold: 5,
        category: 'Food',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        name: 'Bottled Water 1.5L',
        barcode: '1234567890123',
        sellingPrice: 10.0,
        costPrice: 7.0,
        currentStock: 5, // Low stock!
        lowStockThreshold: 15,
        category: 'Beverages',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      ProductModel(
        name: 'Soap Bar',
        sellingPrice: 25.0,
        costPrice: 18.0,
        currentStock: 0, // Out of stock!
        lowStockThreshold: 10,
        category: 'Hygiene',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ]);
    
    // Add sample expenses
    await isar.expenseModels.putAll([
      ExpenseModel(
        title: 'Shop Rent - October',
        amount: 5000.0,
        category: ExpenseCategory.rent,
        expenseDate: DateTime.now(),
        createdAt: DateTime.now(),
      ),
      ExpenseModel(
        title: 'Staff Salary',
        amount: 3000.0,
        category: ExpenseCategory.salary,
        expenseDate: DateTime.now(),
        createdAt: DateTime.now(),
      ),
      ExpenseModel(
        title: 'Electricity Bill',
        amount: 800.0,
        category: ExpenseCategory.utilities,
        expenseDate: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    ]);
  });
  
  print('✅ Sample data created successfully');
}
```

---

## ✅ Unit Tests

### Test WAC Calculator
```dart
// test/calculators/wac_calculator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:efoy_retail_app/logic/calculators/wac_calculator.dart';

void main() {
  group('WACCalculator', () {
    test('Calculate new WAC - first purchase', () {
      final wac = WACCalculator.calculateNewWAC(
        currentStock: 0,
        currentCost: 0.0,
        addedQuantity: 100,
        purchasePrice: 15.0,
      );
      expect(wac, 15.0);
    });

    test('Calculate new WAC - subsequent purchase', () {
      final wac = WACCalculator.calculateNewWAC(
        currentStock: 100,
        currentCost: 15.0,
        addedQuantity: 50,
        purchasePrice: 18.0,
      );
      expect(wac, 16.0); // (100*15 + 50*18) / 150 = 16
    });

    test('Calculate profit margin', () {
      final margin = WACCalculator.calculateProfitMargin(
        sellingPrice: 20.0,
        wac: 15.0,
      );
      expect(margin, 0.25); // 25%
    });
  });
}
```

### Test Profit Engine
```dart
// test/calculators/profit_engine_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:efoy_retail_app/logic/calculators/profit_engine.dart';

void main() {
  group('ProfitEngine', () {
    test('Calculate gross profit', () {
      final profit = ProfitEngine.calculateGrossProfit(
        revenue: 50000.0,
        cogs: 30000.0,
      );
      expect(profit, 20000.0);
    });

    test('Calculate net profit (excludes restock)', () {
      final netProfit = ProfitEngine.calculateNetProfit(
        grossProfit: 20000.0,
        operatingExpenses: 5000.0,
      );
      expect(netProfit, 15000.0);
    });

    test('Calculate profit margin', () {
      final margin = ProfitEngine.calculateGrossProfitMargin(
        grossProfit: 20000.0,
        revenue: 50000.0,
      );
      expect(margin, 0.4); // 40%
    });
  });
}
```

### Run Unit Tests
```bash
flutter test
```

---

## 🧩 Widget Tests

### Test Splash Screen
```dart
// test/ui/screens/splash_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:efoy_retail_app/ui/screens/splash_screen.dart';

void main() {
  testWidgets('Splash screen displays branding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen()),
    );

    // Find Amharic brand name
    expect(find.text('እፎይ'), findsOneWidget);
    
    // Find tagline
    expect(find.text('በእፎይ እርፍ ይበሉ'), findsOneWidget);
  });
}
```

### Run Widget Tests
```bash
flutter test test/ui/
```

---

## 🎯 Integration Test Scenarios

### Scenario 1: First-Time Activation
```
1. Launch app
   ✓ Splash screen shows
   ✓ Navigate to Auth screen

2. View Device ID
   ✓ Device ID displays
   ✓ Copy button works

3. Enter License Key
   ✓ Input accepts formatted key
   ✓ Invalid key → error message
   ✓ Valid key → success message
   ✓ Navigate to Home

4. Verify License
   ✓ App remains activated on restart
```

### Scenario 2: Complete Sale Flow
```
1. Add Products to Cart
   ✓ Search "Coca"
   ✓ Find Coca-Cola
   ✓ Tap → added to cart
   ✓ Badge shows count

2. Open Cart
   ✓ Slide-up sheet opens
   ✓ Item shows: name, qty, price

3. Modify Cart
   ✓ Increase quantity → total updates
   ✓ Tap item → price override modal
   ✓ Change 20 → 18 ብር → saves

4. Checkout
   ✓ Select payment: Cash
   ✓ Enter received: 100 ብር
   ✓ Change: 82 ብር calculated
   ✓ Complete Sale button
   ✓ Success message

5. Verify Updates
   ✓ Stock decreased (100 → 99)
   ✓ Sale appears in activity feed
   ✓ Revenue increased
```

### Scenario 3: Restock with WAC
```
1. Initial State
   Product: Coca-Cola
   Stock: 100
   WAC: 15.0 ብር

2. Restock
   ✓ Tap product → detail screen
   ✓ Tap Restock button
   ✓ Enter: Qty = 50, Price = 18.0 ብር
   ✓ Confirm

3. Verify WAC Calculation
   Expected: (100×15 + 50×18) / 150 = 16.0 ብር
   ✓ New WAC: 16.0 ብር ✓
   ✓ New Stock: 150
   ✓ History log shows entry

4. Verify Profit Calculation
   ✓ Net Profit unchanged (restock is CapEx)
   ✓ Inventory value increased
```

### Scenario 4: Financial Accuracy
```
Setup:
- Day 1: Restock 100 items @ 1000 ብር total
- Day 2: Sell 10 items @ 15 ብር each = 150 ብር
- Day 2: Log expenses: Rent 30 ብር, Salary 20 ብር

Expected Results:
✓ Revenue: 150 ብር
✓ COGS: 10 × 10 = 100 ብር
✓ Gross Profit: 150 - 100 = 50 ብር
✓ Operating Expenses: 30 + 20 = 50 ብር
✓ Net Profit: 50 - 50 = 0 ብር

❌ WRONG: Net Profit = -950 ብር (if restock counted as OpEx)
✅ RIGHT: Net Profit = 0 ብር (restock is CapEx)
```

### Scenario 5: Language Switching
```
1. Open Settings
   ✓ Tap Settings icon

2. Switch to Amharic
   ✓ Tap Language toggle
   ✓ Select አማርኛ

3. Verify Translation
   ✓ Bottom nav: ዋና ገጽ, ሽያጭ, እቃዎች, ወጪዎች, መገለጫ
   ✓ Net Profit → ተጣራ ትርፍ
   ✓ Currency: ብር shown correctly

4. Switch Back
   ✓ Toggle to English
   ✓ All text reverts
```

---

## 🐛 Bug Reporting Template

```markdown
## Bug Title
Brief description of the issue

**Environment:**
- Platform: [Android/iOS/Windows]
- Device: [Model/Emulator]
- App Version: 1.0.0

**Steps to Reproduce:**
1. Go to...
2. Click on...
3. See error

**Expected Behavior:**
What should happen

**Actual Behavior:**
What actually happens

**Screenshots:**
[If applicable]

**Logs:**
```
[Paste error logs from console]
```

**Priority:**
[Critical / High / Medium / Low]
```

---

## 📊 Performance Testing

### Database Performance
```dart
// Test with 1000 products
final stopwatch = Stopwatch()..start();

// Add 1000 products
await isar.writeTxn(() async {
  await isar.productModels.putAll(products);
});

stopwatch.stop();
print('Insert 1000 products: ${stopwatch.elapsedMilliseconds}ms');
// Target: < 500ms

// Query low stock
stopwatch.reset();
stopwatch.start();

final lowStock = await isar.productModels
    .filter()
    .currentStockLessThan(10)
    .findAll();

stopwatch.stop();
print('Query low stock: ${stopwatch.elapsedMilliseconds}ms');
// Target: < 50ms
```

### UI Performance
```
- Target: 60 FPS
- Check: DevTools > Performance
- Rebuild count: Minimize unnecessary rebuilds
- Image optimization: Compress product images
```

---

## ✅ Acceptance Criteria Checklist

### MVP Complete When:
- [ ] User can activate app offline
- [ ] User can add 10+ products
- [ ] User can scan barcodes
- [ ] User can complete 5 sales
- [ ] Net Profit calculation correct
- [ ] WAC calculation correct
- [ ] Low stock alerts work
- [ ] Expenses logged correctly
- [ ] Dark mode works
- [ ] Amharic translation complete
- [ ] No crashes during normal flow
- [ ] Data persists after restart
- [ ] Backup/restore works

---

## 🚀 Release Testing

### Before Release:
1. **Clean Install Test**
   - [ ] Uninstall app
   - [ ] Install fresh
   - [ ] Complete first-time flow

2. **Upgrade Test**
   - [ ] Install v1.0
   - [ ] Add data
   - [ ] Upgrade to v1.1
   - [ ] Verify data preserved

3. **Edge Cases**
   - [ ] No internet connection
   - [ ] Low storage
   - [ ] Large dataset (1000+ products)
   - [ ] Expired license
   - [ ] Invalid license key

4. **Platform-Specific**
   - [ ] Android: Back button behavior
   - [ ] iOS: Swipe gestures
   - [ ] Windows: Keyboard shortcuts

---

## 📝 Test Log Template

```markdown
# Test Session - [Date]

**Tester:** [Name]
**Build:** v1.0.0-beta.1
**Platform:** Android / Pixel 6 Emulator

## Tests Executed:
- [x] Splash screen
- [x] License activation
- [x] Add products
- [ ] Complete sale (FAILED - See Bug #001)
- [x] Dark mode

## Bugs Found:
1. Bug #001: Cart total incorrect when price overridden
   - Severity: High
   - Steps: [Link to bug report]

## Notes:
- Performance good on emulator
- Amharic font renders correctly
- Need to test on real device

**Overall Status:** 80% Pass
```

---

## 🎯 Daily Testing Routine

### During Development:
1. Run `flutter test` before commits
2. Manual test on 1 platform
3. Check console for errors
4. Verify database changes

### Before PR/Merge:
1. Full unit test suite
2. Test on Android + Windows
3. Manual integration test
4. Check for regressions

### Before Release:
1. All automated tests pass
2. Complete integration scenarios
3. Test on 3+ devices
4. User acceptance testing

---

**Keep this file updated as you find issues!**
