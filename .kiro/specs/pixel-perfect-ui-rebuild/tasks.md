# Implementation Plan: Pixel-Perfect UI Rebuild

## Overview

This document outlines the implementation tasks for rebuilding the Efoy Flutter application UI to pixel-perfectly match HTML mockups. The implementation covers 8 screens with complete state management, real-time data synchronization, and production-ready business logic integration using Flutter 3.12+, Isar 3.1, and Riverpod 2.5.

**Tech Stack**: Flutter 3.12+, Isar 3.1.0, Riverpod 2.5.1, Material Design 3

**Scope**: Complete UI layer rebuild with providers, repositories, animations, and testing

---

## Tasks

### Phase 1: Foundation Setup

- [x] 1. Setup core theme system and constants
  - Create `lib/core/constants/app_colors.dart` with all HTML color mappings
  - Create `lib/core/constants/app_theme.dart` with Material Design 3 ThemeData
  - Create `lib/core/constants/app_strings.dart` with bilingual (English/Amharic) string constants
  - Define TextStyles matching HTML typography (headline, title, body, caption, numbers)
  - Define spacing constants (padding, gap, rounded corners)
  - Define elevation/shadow specifications
  - Implement dark mode color variants
  - Configure Noto Sans Ethiopic font for Amharic rendering
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6_

- [x] 2. Setup Isar database and models
  - [x] 2.1 Create `lib/data/local/app_database.dart` with Isar initialization
    - Initialize Isar instance with all schemas
    - Configure database path and inspector
    - Implement singleton pattern for database access
    - _Requirements: 5.2_
  
  - [x] 2.2 Create `lib/data/models/product_model.dart`
    - Define ProductModel with @collection annotation
    - Add fields: id, name, description, barcode, sellingPrice, costPrice (WAC), currentStock, lowStockThreshold
    - Add metadata: category, imageUrl, createdAt, updatedAt, isDeleted
    - Implement computed properties: isLowStock, isOutOfStock, inventoryValue, liquidityValue, profitMargin
    - Add indexes on name, barcode, isDeleted
    - _Requirements: 6.2, 6.3, 6.10, 6.13_
  
  - [x] 2.3 Create `lib/data/models/sale_model.dart`
    - Define SaleModel with @collection annotation
    - Define embedded SaleLineItem with @embedded annotation
    - Add fields: id, saleDate, transactionId (UUID), lineItems list
    - Add calculations: totalAmount, totalCost, grossProfit
    - Add payment: paymentMethod enum, amountReceived, changeGiven
    - Add metadata: notes, cashierName, createdAt, isVoided, voidedAt
    - Define PaymentMethod enum: cash, telebirr, cbeBirr, amharaBank, mixed
    - _Requirements: 5.8, 5.22, 5.23, 5.24, 5.25_
  
  - [x] 2.4 Create `lib/data/models/expense_model.dart`
    - Define ExpenseModel with @collection annotation
    - Add fields: id, title, description, amount, category, expenseDate, createdAt
    - Add metadata: receiptImageUrl, notes, isRestockExpense, isDeleted
    - Define ExpenseCategory enum: rent, salary, transport, utilities, airtime, supplies, restock, other
    - Add indexes on category and expenseDate
    - _Requirements: 7.2, 7.5, 7.19_
  
  - [x] 2.5 Create `lib/data/models/restock_log_model.dart`
    - Define RestockLogModel with @collection annotation
    - Add fields: id, productId, productName, quantityAdded, costPerUnit, totalCost
    - Add WAC tracking: oldWAC, newWAC, oldStock, newStock
    - Add timestamp: restockedAt
    - _Requirements: 6.21, 6.22, 6.24_
  
  - [x] 2.6 Create `lib/data/models/user_profile_model.dart`
    - Define UserProfileModel with @collection annotation
    - Add fields: id, password (hashed), isDemoMode
    - Add payment info: phone, telebirr, bankAccount, bankName
    - Add metadata: createdAt, updatedAt
    - _Requirements: 3.25_
  
  - [x] 2.7 Create `lib/data/models/license_model.dart`
    - Define LicenseModel with @collection annotation
    - Add fields: id, licenseKey, deviceId, activatedAt, expiresAt
    - Add validation: isActive, daysRemaining
    - _Requirements: 3.13_

### Phase 2: Business Logic and Services

- [x] 3. Implement core calculators
  - [x] 3.1 Create `lib/logic/calculators/wac_calculator.dart`
    - Implement static calculateNewWAC method with formula: (currentStock × currentCost + addedQuantity × purchasePrice) / (currentStock + addedQuantity)
    - Implement calculateInventoryValue method: quantity × wac
    - Implement calculateProfitMargin method: (sellingPrice - wac) / sellingPrice
    - Add edge case handling: zero stock, zero quantity
    - _Requirements: 6.22, 6.23_
  
  - [x] 3.2 Create `lib/logic/calculators/profit_engine.dart`
    - Implement calculateGrossProfit: revenue - COGS
    - Implement calculateNetProfit: grossProfit - opExExpenses (excluding CapEx restock expenses)
    - Implement period filtering: today, week, month
    - Query sales and expenses from Isar with date range filters
    - _Requirements: 4.6, 4.7, 7.19_
    - _Note: Isar queries and period filtering are implemented in `lib/logic/providers/profit_provider.dart`._

- [x] 4. Implement security services
  - [x] 4.1 Create `lib/core/security/device_identity.dart`
    - Implement getDeviceInfo() using device_info_plus package
    - Extract platform, model, manufacturer
    - Implement getDeviceId() with persistent unique identifier
    - Use platform_device_id or generate from hardware fingerprint
    - _Requirements: 3.5, 3.6, 3.7_
  
  - [x] 4.2 Create `lib/core/security/license_verifier.dart`
    - Implement verifyLicense(licenseKey, deviceId) method
    - Parse license key format: XXXX-XXXX-XXXX-XXXX
    - Validate expiry date
    - Validate device ID match
    - Return LicenseVerificationResult with isValid and errorMessage
    - Implement generateLicenseKey(deviceId, expiryDate) for debug mode
    - _Requirements: 3.11, 3.13, 3.14, 3.15_
    - _Note: key format is BASE64(deviceId|expiryDate|signature), not XXXX-XXXX-XXXX-XXXX._

### Phase 3: Data Repositories

- [x] 5. Implement repository layer
  - [x] 5.1 Create `lib/data/repositories/product_repository.dart`
    - Implement BaseRepository interface methods: getById, getAll, create, update, delete
    - Implement watchAll() with Isar stream: filter isDeleted=false, sort by name
    - Implement getLowStockProducts(): filter where currentStock <= lowStockThreshold
    - Implement restock method with atomic transaction:
      - Calculate new WAC using WACCalculator
      - Update product stock and costPrice
      - Create RestockLogModel record
      - Create ExpenseModel record with isRestockExpense=true
    - _Requirements: 6.2, 6.4, 6.21, 6.22, 6.23, 6.24_
  
  - [x] 5.2 Create `lib/data/repositories/sale_repository.dart`
    - Implement BaseRepository interface methods
    - Implement watchAll() with Isar stream: filter isVoided=false, sort by saleDate desc
    - Implement createWithStockUpdate method with atomic transaction:
      - Create Sale record
      - Update product stock for each line item
      - Validate stock availability before commit
      - Rollback on any error
    - Implement getTotalsByPeriod(startDate, endDate)
    - _Requirements: 5.25, 5.26, 5.27_
  
  - [x] 5.3 Create `lib/data/repositories/expense_repository.dart`
    - Implement BaseRepository interface methods
    - Implement watchAll() with Isar stream: filter isDeleted=false, sort by expenseDate desc
    - Implement getByCategory(category)
    - Implement getTotalsByPeriod(startDate, endDate, excludeRestock)
    - Filter out CapEx (isRestockExpense=true) for operating expense calculations
    - _Requirements: 7.2, 7.5, 7.19_

### Phase 4: State Management Providers

- [x] 6. Implement Riverpod providers
  - [x] 6.1 Create `lib/logic/providers/profit_provider.dart`
    - Define ProfitState class: netProfit, grossProfit, revenue, expenses, period
    - Create profitPeriodProvider: StateProvider<Period> (today/week/month)
    - Create profitProvider: StateNotifierProvider watching period and database
    - Calculate net profit: revenue - opExExpenses (exclude restock CapEx)
    - Listen to sale and expense streams for real-time updates
    - _Requirements: 4.4, 4.5, 4.6, 4.7_
    - _Note: implemented with `StreamProvider` + Isar `watchLazy` instead of `StateNotifierProvider`; verified working._
  
  - [x] 6.2 Create `lib/logic/providers/cart_provider.dart`
    - Define CartState class: items list, paymentMethod, amountReceived, total, change
    - Define CartItem class: productId, productName, quantity, unitPrice, unitCost, lineTotal, availableStock
    - Create CartNotifier extending StateNotifier<CartState>
    - Implement addItem: add product to cart or increment if exists
    - Implement incrementQuantity: validate against availableStock
    - Implement decrementQuantity: decrement or remove if quantity=1
    - Implement removeItem: remove from cart and recalculate
    - Implement updatePrice: allow price override with validation
    - Implement completeSale: atomic transaction with stock update and profit calculation
    - Implement clearCart: reset to empty state
    - _Requirements: 5.6, 5.7, 5.11, 5.14, 5.15, 5.16, 5.21, 5.23, 5.24, 5.25, 5.26, 5.27_
  
  - [x] 6.3 Create `lib/logic/providers/inventory_provider.dart`
    - Define InventoryState class: products list, searchQuery, selectedFilter
    - Create InventoryNotifier extending StateNotifier<InventoryState>
    - Watch product stream from ProductRepository
    - Implement search filtering by name and barcode
    - Implement category filtering
    - Implement stock status filtering: all, lowStock, inStock, outOfStock
    - Calculate lowStockCount for alerts
    - _Requirements: 6.2, 6.4, 6.7, 6.8, 6.9_
  
  - [x] 6.4 Create `lib/logic/providers/theme_provider.dart`
    - Create themeProvider: StateProvider<ThemeMode> (light/dark/system)
    - Create localeProvider: StateProvider<Locale> (en/am)
    - Persist theme and locale preferences to shared_preferences
    - Load saved preferences on app init
    - _Requirements: 1.5, 8.1_
    - _Note: preferences are persisted with `flutter_secure_storage`; `themeModeProvider`/`localeProvider` are wired into `MaterialApp`._

### Phase 5: Reusable Widgets

- [x] 7. Create reusable UI components
  - [x] 7.1 Create `lib/ui/widgets/profit_card.dart`
    - Implement gradient background with radial gradient colors
    - Render SYNCED indicator with pulsing animation
    - Render period filter pills with active state
    - Display net profit amount with currency
    - Display revenue and expenses breakdown
    - Watch profitProvider and profitPeriodProvider
    - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_
    - _Note: implemented as `lib/ui/widgets/net_profit_card.dart`; the SYNCED indicator uses `PulsingDot`._
  
  - [x] 7.2 Create `lib/ui/widgets/alert_card.dart`
    - Accept AlertType enum: amber, crimson, dark
    - Apply type-specific styling: background, border, icon color
    - Render icon, title, subtitle, action button
    - Support pulsing dot indicator for live alerts
    - _Requirements: 4.10, 6.5_
  
  - [x] 7.3 Create `lib/ui/widgets/product_card.dart`
    - Render white card with rounded corners
    - Display product icon with colored background
    - Display product name (truncated), price, stock count
    - Apply selected state styling when in cart
    - Show quantity badge when selected
    - Handle tap to add to cart
    - _Requirements: 5.4, 5.5_
  
  - [x] 7.4 Create `lib/ui/widgets/cart_sheet.dart`
    - Implement bottom sheet with slide-up animation
    - Render header with item count badge and clear button
    - Render cart line items with quantity steppers
    - Render price edit button with override modal
    - Render payment method selector pills
    - Render amount received input with change calculation
    - Render complete sale button with validation
    - Watch cartProvider for state updates
    - _Requirements: 5.8, 5.9, 5.10, 5.11, 5.12, 5.13, 5.14, 5.15, 5.16, 5.17, 5.18, 5.19, 5.20, 5.21, 5.22, 5.23, 5.24_
  
  - [x] 7.5 Create `lib/ui/widgets/restock_modal.dart`
    - Display product info card: name, current stock, current WAC
    - Render quantity input with number keyboard
    - Render cost per unit input
    - Calculate and display new WAC preview using WACCalculator
    - Display total cost calculation
    - Render confirm button with loading state
    - Call ProductRepository.restock on confirm
    - _Requirements: 6.18, 6.19, 6.20, 6.21, 6.22, 6.23, 6.24_
  
  - [x] 7.6 Create `lib/ui/widgets/bottom_nav_bar.dart`
    - Render 5 tabs: Home, Sell, Inventory, Expenses, Profile
    - Apply active pill indicator with background color
    - Apply inactive styling with gray text
    - Handle tab selection and navigation
    - Persist selected tab state
    - _Requirements: 4.15, 5.32, 6.1, 7.1, 8.1_

### Phase 6: Animation Components

- [x] 8. Implement custom animations
  - [x] 8.1 Create `lib/ui/animations/pulsing_dot.dart`
    - Implement AnimatedWidget with AnimationController
    - Animate opacity between 0.35 and 1.0
    - Duration: 2 seconds with easeInOut curve
    - Repeat infinitely
    - Apply to SYNCED indicator and alert dots
    - _Requirements: 2.4, 4.3, 4.10_
  
  - [x] 8.2 Create `lib/ui/animations/pill_transition.dart`
    - Implement AnimatedContainer for pill indicator
    - Animate position and width based on selected tab
    - Duration: 300ms with easeOut curve
    - Animate color transition for active/inactive states
    - _Requirements: 4.4, 5.18_

### Phase 7: Screen Implementation

- [x] 9. Implement splash screen
  - Create `lib/ui/screens/splash_screen.dart`
  - Implement radial gradient background with specific colors
  - Render brand logo card with shadow and rounded corners
  - Display Amharic brand name "እፎይ" with gradient shader
  - Display subtitle "በእፎይ እርፍ ይበሉ"
  - Implement three-dot pagination with staggered pulsing animation
  - Initialize License_System in background
  - Navigate to /auth or /home after 2 seconds based on session
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_
  - _Note: session is checked against the persisted profile; expired active licenses are marked inactive before redirect. The splash timer is cancelled on dispose._

- [x] 10. Implement authentication screen
  - [x] 10.1 Create `lib/ui/screens/auth_screen.dart` base structure
    - Setup StatefulWidget with TabController for 2 tabs
    - Render brand identity header with logo and names
    - Render two-tab navigation: Login | Activate License
    - Initialize controllers for all input fields
    - Load device info on init using DeviceIdentity
    - _Requirements: 3.1, 3.2, 3.5, 3.6_
  
  - [x] 10.2 Implement login tab
    - Render welcome title and subtitle
    - Render password input field with obscured text
    - Render login button with full width
    - Add link to switch to license tab
    - Validate password on submission
    - Navigate to home on success
    - _Requirements: 3.3, 3.4_
  
  - [x] 10.3 Implement license activation tab
    - Render device information card with platform, model, manufacturer
    - Render device ID section with monospace text and copy button
    - Implement clipboard copy on button tap with snackbar confirmation
    - Render license key input field with uppercase formatting
    - Add test key generator button for debug mode
    - Implement activate button with loading state
    - Call LicenseVerifier.verifyLicense on activation
    - Display error messages in red alert box on failure
    - Transition to onboarding flow on success
    - _Requirements: 3.6, 3.7, 3.8, 3.9, 3.10, 3.11, 3.12, 3.13, 3.14, 3.15_
  
  - [x] 10.4 Implement onboarding flow
    - Display success indicator with green badge
    - Render password setup section (Step 1) with validation
    - Render mode selection section (Step 2) with demo/production toggle
    - Render payment information section (Step 3) with conditional required/optional
    - Implement field validation for each step
    - Render complete setup button with loading state
    - Validate all steps before submission
    - Create UserProfile record in Isar on completion
    - Navigate to home screen on success
    - Add back button to return to license entry
    - _Requirements: 3.16, 3.17, 3.18, 3.19, 3.20, 3.21, 3.22, 3.23, 3.23a, 3.24, 3.25, 3.26, 3.27, 3.28_

- [x] 11. Implement home dashboard screen
  - Create `lib/ui/screens/home_screen.dart`
  - Render header with brand logo, title, subtitle, settings icon
  - Integrate ProfitCard widget with real-time data
  - Render quick metrics grid: transactions and sales cards
  - Render critical alerts section with live indicator
  - Generate alert cards conditionally: low stock, zero transactions, low margin
  - Render command actions section with quick sell button
  - Integrate BottomNavBar with Home tab active
  - Watch profitProvider for real-time updates
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 4.8, 4.9, 4.10, 4.11, 4.12, 4.13, 4.14, 4.15_

- [x] 12. Implement sell (POS) screen
  - [x] 12.1 Create `lib/ui/screens/sell_screen.dart` base structure
    - Render header with "SELL" title and hold button
    - Initialize CartProvider on screen load
    - Load all active products from Isar
    - Setup product grid with 3 columns
    - Integrate BottomNavBar with Sell tab active
    - _Requirements: 5.1, 5.2, 5.3, 5.32_
  
  - [x] 12.2 Implement product grid
    - Render product cards using ProductCard widget
    - Apply selected styling when product in cart
    - Show quantity badge on selected products
    - Handle tap to add product to cart via CartProvider
    - _Requirements: 5.3, 5.4, 5.5, 5.6_
  
  - [x] 12.3 Implement cart functionality
    - Integrate CartSheet widget with slide-up animation
    - Show cart sheet when items exist
    - Implement cart line item rendering with steppers
    - Implement price override modal with password validation
    - Implement quantity increment/decrement with stock validation
    - Implement item removal
    - Display running total with currency
    - _Requirements: 5.8, 5.9, 5.10, 5.11, 5.12, 5.13, 5.14, 5.15, 5.16, 5.17_
  
  - [x] 12.4 Implement checkout flow
    - Render payment method selector with pill styling
    - Implement amount received input with change calculation
    - Display calculated change when applicable
    - Render complete sale button with validation
    - Execute atomic transaction via CartProvider.completeSale
    - Handle validation errors with snackbars
    - Show success animation on completion
    - Navigate to home screen after success
    - _Requirements: 5.18, 5.19, 5.20, 5.21, 5.22, 5.23, 5.24, 5.25, 5.26, 5.27, 5.28_
  
  - [x] 12.5 Implement hold order functionality
    - Save current cart to HeldOrder collection on hold
    - Display held orders list when hold button tapped with empty cart
    - Implement restore from held order with validation
    - _Requirements: 5.29, 5.30, 5.31_

- [x] 13. Implement inventory management screen
  - [x] 13.1 Create `lib/ui/screens/inventory_screen.dart` base structure
    - Render header with title, product count, add button
    - Initialize InventoryProvider on screen load
    - Watch product stream for real-time updates
    - Calculate and display low stock count
    - Integrate BottomNavBar with Inventory tab active
    - _Requirements: 6.1, 6.2, 6.3_
  
  - [x] 13.2 Implement stock alerts card
    - Display alert ribbon with pulsing dot indicator
    - Show low stock count in subtitle
    - Render each low stock product with alert styling
    - Sort alerts by stock level (lowest first)
    - Show only when lowStockCount > 0
    - _Requirements: 6.4, 6.5, 6.6_
  
  - [x] 13.3 Implement search and filters
    - Render search bar with magnifier icon
    - Implement real-time search by name and barcode
    - Render filter pills: All, In Stock, Low Stock, Out of Stock
    - Apply active styling to selected filter
    - Filter products based on search and filter state
    - _Requirements: 6.7, 6.8, 6.9_
  
  - [x] 13.4 Implement product list
    - Render empty state when no products match
    - Display product cards in vertical list with badges
    - Show stock level badge with color coding: green (in stock), amber (low), red (out)
    - Implement tap to show product detail bottom sheet
    - _Requirements: 6.10, 6.11, 6.12_
  
  - [x] 13.5 Implement product detail sheet
    - Display product info: name, description, barcode, prices
    - Show current stock with badge
    - Display inventory value and liquidity value calculations
    - Show profit margin percentage
    - Render edit and delete buttons
    - Render restock button prominently
    - _Requirements: 6.13, 6.14, 6.15, 6.16, 6.17_
  
  - [x] 13.6 Implement restock flow
    - Show RestockModal on restock button tap
    - Display current stock and WAC
    - Render quantity and cost inputs
    - Calculate and preview new WAC in real-time
    - Validate inputs before submission
    - Execute restock via ProductRepository.restock
    - Create restock log and expense records atomically
    - Show success message with new WAC
    - Refresh product list
    - _Requirements: 6.18, 6.19, 6.20, 6.21, 6.22, 6.23, 6.24_
  
  - [x] 13.7 Implement add/edit product functionality
    - Show product form modal on add button tap
    - Render fields: name, description, barcode, category
    - Render price inputs: selling price, initial cost price
    - Render stock inputs: initial stock, low stock threshold
    - Add barcode scanner button (optional)
    - Validate all required fields
    - Save to database via ProductRepository
    - _Requirements: 6.3_

- [x] 14. Implement expenses tracking screen
  - [x] 14.1 Create `lib/ui/screens/expenses_screen.dart` base structure
    - Render header with title, expense count, add button
    - Load expenses from ExpenseRepository
    - Watch expense stream for real-time updates
    - Integrate BottomNavBar with Expenses tab active
    - _Requirements: 7.1, 7.2_
  
  - [x] 14.2 Implement expense summary card
    - Display daily OpEx total with subtitle
    - Show trend indicator: up/down arrow with percentage change
    - Render with teal gradient background
    - _Requirements: 7.3, 7.4_
  
  - [x] 14.3 Implement category grid
    - Render 4x2 grid of category buttons
    - Display icon and label for each category
    - Apply active styling to selected category
    - Filter expenses by selected category
    - Show "All" option to clear filter
    - _Requirements: 7.5, 7.6, 7.7_
  
  - [x] 14.4 Implement expense list
    - Display expenses in vertical list sorted by date
    - Render each expense card with category icon, title, amount, date
    - Show CapEx badge for restock expenses
    - Show OpEx indicator for operating expenses
    - Display empty state when no expenses
    - _Requirements: 7.8, 7.9, 7.10_
  
  - [x] 14.5 Implement add expense functionality
    - Show expense form modal on add button tap
    - Render title and description fields
    - Render amount input with currency
    - Render category dropdown with icons
    - Render date picker with default today
    - Add receipt image upload option
    - Validate required fields
    - Save to database via ExpenseRepository
    - Mark as OpEx (isRestockExpense=false)
    - _Requirements: 7.11, 7.12, 7.13, 7.14, 7.15, 7.16, 7.17, 7.18_
  
  - [x] 14.6 Implement expense filtering
    - Exclude CapEx (restock) expenses from daily total
    - Display CapEx separately if viewing all expenses
    - Show filter toggle: Operating Expenses vs All Expenses
    - _Requirements: 7.19, 7.20_

- [x] 15. Implement profile and settings screen
  - [x] 15.1 Create `lib/ui/screens/profile_screen.dart` base structure
    - Render header with "PROFILE" title
    - Load user profile from UserProfileModel
    - Integrate BottomNavBar with Profile tab active
    - _Requirements: 8.1_
  
  - [x] 15.2 Implement profile information section
    - Display business name (if set, else "Merchant")
    - Display mode badge: Demo or Production
    - Show account creation date
    - Render edit button to update profile
    - _Requirements: 8.2_
  
  - [x] 15.3 Implement payment information section
    - Display saved payment methods: phone, telebirr, bank
    - Show placeholder if no payment info
    - Render edit button to update payment info
    - Validate required fields for production mode
    - _Requirements: 8.3_
  
  - [x] 15.4 Implement settings section
    - Render theme selector: Light, Dark, System (with ThemeProvider)
    - Render language selector: English, አማርኛ (with LocaleProvider)
    - Show current selections with checkmarks
    - Apply changes immediately on selection
    - _Requirements: 8.4, 8.5_
  
  - [x] 15.5 Implement security section
    - Render change password button
    - Show password change modal with current and new password fields
    - Validate password strength
    - Update hashed password in database
    - _Requirements: 8.6_
  
  - [x] 15.6 Implement data management section
    - Render backup data button with last backup date
    - Implement export to JSON functionality
    - Render restore data button with file picker
    - Implement import from JSON with validation
    - Show confirmation dialogs for destructive actions
    - _Requirements: 8.7_
  
  - [x] 15.7 Implement license information section
    - Display license status: Active, Expired, Invalid
    - Show device ID with copy button
    - Display expiry date and days remaining
    - Show reactivation flow if expired
    - _Requirements: 8.8_

### Phase 8: Navigation and Routing

- [x] 16. Setup navigation system
  - Create `lib/ui/screens/main_layout.dart` as bottom nav wrapper
  - Implement route definitions in main.dart
  - Setup named routes: /splash, /auth, /home, /sell, /inventory, /expenses, /profile
  - Implement navigation guards: check authentication before /home
  - Handle deep linking (optional)
  - _Requirements: 2.5_
  - _Note: protected routes are wrapped in `SessionGuard`, which redirects to `/auth` when no completed profile exists._

### Phase 9: Integration and Polish

- [x] 17. Integrate all screens with data flow
  - [x] 17.1 Wire providers to repositories
    - Connect CartProvider to SaleRepository and ProductRepository
    - Connect InventoryProvider to ProductRepository
    - Connect ProfitProvider to SaleRepository and ExpenseRepository
    - Ensure all CRUD operations trigger Isar watchers
    - _Requirements: 4.6, 5.27, 6.2_
  
  - [x] 17.2 Implement real-time data synchronization
    - Setup Isar stream watchers in all providers
    - Test cross-screen updates: sale updates profit, restock updates inventory
    - Verify SYNCED indicator animates on data changes
    - _Requirements: 4.3, 6.2_
  
  - [x] 17.3 Implement atomic transactions
    - Verify completeSale transaction atomicity
    - Verify restock transaction atomicity
    - Test rollback scenarios: insufficient stock, validation errors
    - _Requirements: 5.25, 5.26, 6.22, 6.23_
    - _Note: rollback behavior is enforced by Isar `writeTxn`; validation throws before commit. Database-level rollback tests remain part of the optional integration suite (24.1/24.2)._

- [x] 18. Implement dark mode support
  - Apply dark color variants to all screens
  - Test contrast ratios for accessibility
  - Verify gradient colors in dark mode
  - Test card shadows and borders in dark mode
  - _Requirements: 1.5_
  - _Note: screens and shared widgets use `Theme.of(context).colorScheme`/`scaffoldBackgroundColor`; the auth screen also uses scheme colors for surfaces and labels._

- [x] 19. Implement bilingual support
  - Add Amharic translations to app_strings.dart
  - Apply font fallback for Amharic rendering
  - Test all screens in English and Amharic
  - Verify text overflow handling
  - _Requirements: 1.6, 2.3_
  - _Note: navigation screens, widgets and the auth/onboarding flow use `context.tr`; `localeProvider` is wired into `MaterialApp`. Amharic text relies on platform font fallback._

- [ ] 20. Pixel-perfect refinement pass
  - Compare each screen to HTML mockups side-by-side
  - Verify exact colors, spacing, borders, shadows
  - Check typography: font sizes, weights, tracking
  - Verify rounded corners and padding match Tailwind specs
  - Test on multiple screen sizes and densities
  - _Requirements: 1.1, 1.2, 1.3, 1.4_
  - _Status: pending manual visual review — screens consume the shared `AppColors`/`AppTheme` tokens, but no side-by-side comparison against the HTML mockups has been performed._

- [ ] 21. Checkpoint - Ensure all tests pass
  - Run all unit tests, widget tests, integration tests
  - Verify no regression errors
  - Test all user flows end-to-end
  - Ask the user if questions arise
  - _Status: partial — `flutter analyze` is clean and 48 unit/widget tests pass; device-level end-to-end flows and optional integration tests remain._

### Phase 10: Testing

- [x]* 22. Write unit tests for business logic
  - [x]* 22.1 Test WACCalculator
    - Test calculateNewWAC with various stock and price scenarios
    - Test edge cases: zero stock, zero quantity, equal prices
    - Test calculateInventoryValue and calculateProfitMargin
    - _Requirements: 6.22, 6.23_
  
  - [x]* 22.2 Test ProfitEngine
    - Test calculateGrossProfit with sample sales and COGS
    - Test calculateNetProfit excluding CapEx restock expenses
    - Test period filtering: today, week, month
    - _Requirements: 4.6, 4.7, 7.19_
    - _Note: period filtering is covered by `test/profit_period_test.dart`._
  
  - [x]* 22.3 Test LicenseVerifier
    - Test valid license verification
    - Test expired license detection
    - Test device ID mismatch
    - Test invalid key format
    - Test generateLicenseKey for debug mode
    - _Requirements: 3.13, 3.14, 3.15_

- [ ]* 23. Write widget tests for UI components
  - _Status: partial — NetProfitCard (23.1) and AlertCard (23.4) have widget tests; CartSheet and RestockModal tests are pending._
  - [x]* 23.1 Test ProfitCard
    - Test gradient rendering
    - Test SYNCED indicator animation
    - Test period filter pill selection
    - Test net profit display with mock data
    - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.6_
  
  - [ ]* 23.2 Test CartSheet
    - Test cart item rendering
    - Test quantity stepper increment/decrement
    - Test price override modal
    - Test payment method selection
    - Test change calculation
    - Test complete sale button state
    - _Requirements: 5.8, 5.11, 5.13, 5.18, 5.20, 5.21, 5.23_
  
  - [ ]* 23.3 Test RestockModal
    - Test WAC preview calculation
    - Test input validation
    - Test restock confirmation
    - _Requirements: 6.18, 6.20, 6.21, 6.22_
  
  - [x]* 23.4 Test AlertCard
    - Test type-specific styling rendering
    - Test pulsing dot animation
    - _Requirements: 4.10, 6.5_

- [ ]* 24. Write integration tests for critical flows
  - [ ]* 24.1 Test complete sale flow
    - Add product to cart
    - Increment quantity
    - Select payment method
    - Enter amount received
    - Complete sale
    - Verify stock update
    - Verify profit calculation
    - _Requirements: 5.6, 5.14, 5.19, 5.21, 5.25, 5.26, 5.27_
  
  - [ ]* 24.2 Test restock flow
    - Navigate to inventory
    - Select product
    - Open restock modal
    - Enter quantity and cost
    - Confirm restock
    - Verify WAC update
    - Verify stock update
    - Verify expense creation
    - _Requirements: 6.18, 6.21, 6.22, 6.23, 6.24_
  
  - [ ]* 24.3 Test authentication flow
    - Load splash screen
    - Navigate to auth
    - Generate test license
    - Activate license
    - Complete onboarding
    - Navigate to home
    - _Requirements: 2.5, 3.11, 3.13, 3.14, 3.15, 3.25_

- [ ]* 25. Write golden tests for visual regression
  - Generate golden images for each screen in light mode
  - Generate golden images for each screen in dark mode
  - Compare against reference images on test runs
  - Test on multiple device sizes
  - _Requirements: 1.1, 1.5, 20_

### Phase 11: Performance and Optimization

- [ ]* 26. Performance optimization
  - Profile app startup time
  - Optimize Isar queries with proper indexes
  - Implement pagination for large product/sale lists
  - Lazy load images with caching
  - Reduce widget rebuilds with proper provider scoping
  - Test on low-end devices
  - _Requirements: 6.2, 5.3_

- [ ]* 27. Accessibility compliance
  - Add semantic labels to all interactive widgets
  - Test with screen reader (TalkBack/VoiceOver)
  - Verify color contrast ratios meet WCAG AA
  - Add keyboard navigation support
  - Test with large font sizes
  - _Requirements: 1.1_

### Phase 12: Documentation and Handoff

- [ ]* 28. Write developer documentation
  - Document project structure and architecture
  - Document state management patterns
  - Document database schema and relationships
  - Document business logic calculations
  - Add inline code comments for complex logic
  - Create README with setup instructions

- [ ]* 29. Write user documentation
  - Create user guide for each screen
  - Document sale flow with screenshots
  - Document restock process
  - Document expense tracking
  - Document backup and restore
  - Create FAQ for common issues

- [ ] 30. Final checkpoint - Comprehensive review
  - Verify all 530+ acceptance criteria are met
  - Run full test suite
  - Perform manual QA on all screens
  - Test on physical devices (Android + iOS)
  - Verify offline functionality
  - Test error handling and edge cases
  - Ask the user if questions arise
  - _Status: partial — `flutter analyze` is clean and all 48 unit/widget tests pass. Manual QA, physical-device testing and offline verification remain._

---

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability from requirements.md
- Checkpoints (tasks 21, 30) ensure incremental validation
- All database operations must use atomic transactions to maintain data integrity
- Real-time updates via Isar watchers ensure UI always reflects current data
- Dark mode and bilingual support must be tested on all screens
- WAC calculator is critical for accurate inventory valuation and profit calculation
- CapEx (restock) expenses must be excluded from operating profit calculations

---

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1", "2.1"] },
    { "id": 1, "tasks": ["2.2", "2.3", "2.4", "2.5", "2.6", "2.7"] },
    { "id": 2, "tasks": ["3.1", "3.2", "4.1", "4.2"] },
    { "id": 3, "tasks": ["5.1", "5.2", "5.3"] },
    { "id": 4, "tasks": ["6.1", "6.2", "6.3", "6.4"] },
    { "id": 5, "tasks": ["7.1", "7.2", "7.3", "8.1", "8.2"] },
    { "id": 6, "tasks": ["7.4", "7.5", "7.6", "9"] },
    { "id": 7, "tasks": ["10.1", "10.2", "10.3", "10.4"] },
    { "id": 8, "tasks": ["11", "16"] },
    { "id": 9, "tasks": ["12.1", "12.2"] },
    { "id": 10, "tasks": ["12.3", "12.4", "12.5"] },
    { "id": 11, "tasks": ["13.1", "13.2", "13.3"] },
    { "id": 12, "tasks": ["13.4", "13.5"] },
    { "id": 13, "tasks": ["13.6", "13.7"] },
    { "id": 14, "tasks": ["14.1", "14.2", "14.3"] },
    { "id": 15, "tasks": ["14.4", "14.5", "14.6"] },
    { "id": 16, "tasks": ["15.1", "15.2", "15.3"] },
    { "id": 17, "tasks": ["15.4", "15.5", "15.6", "15.7"] },
    { "id": 18, "tasks": ["17.1", "17.2", "17.3"] },
    { "id": 19, "tasks": ["18", "19", "20"] },
    { "id": 20, "tasks": ["22.1", "22.2", "22.3", "23.1", "23.2", "23.3", "23.4"] },
    { "id": 21, "tasks": ["24.1", "24.2", "24.3", "25"] },
    { "id": 22, "tasks": ["26", "27", "28", "29"] }
  ]
}
```
