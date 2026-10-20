# Requirements Document

## Introduction

This document specifies the requirements for rebuilding the Efoy (እፎይ) Flutter application's user interface to pixel-perfectly match professional HTML design mockups. Efoy is a bilingual (English/Amharic) retail business management application designed for Ethiopian merchants. The backend systems are complete (Isar database, WAC calculator, profit engine, license verification), and this rebuild focuses exclusively on creating a production-quality UI that exactly matches the provided HTML mockups while integrating with existing business logic.

The rebuild covers seven screens: Splash, Authentication, Home Dashboard, Sell (POS), Inventory Management, Expenses Tracking, and Profile/Settings. Each screen must maintain visual consistency, support bilingual content, implement dark mode, and connect to existing data providers.

## Glossary

- **UI_System**: The Flutter user interface layer including widgets, screens, and visual components
- **Theme_System**: Flutter theme configuration managing colors, typography, spacing, and dark mode
- **Navigation_System**: Bottom navigation bar and screen routing infrastructure
- **Profit_Card**: Primary dashboard widget displaying net profit with period filters and gradients
- **WAC**: Weighted Average Cost calculation system for inventory valuation
- **POS**: Point-of-Sale system for recording sales transactions
- **Cart_Provider**: State management for shopping cart during sales flow
- **Inventory_Provider**: State management for product CRUD operations
- **Period_Filter**: Time range selector (Today/Week/Month) for financial data
- **SYNCED_Indicator**: Animated pulsing dot showing real-time data synchronization status
- **Bottom_Nav**: Bottom navigation bar with 5 tabs and active pill indicator
- **License_System**: Offline license verification for device activation
- **Bilingual_Strings**: English and Amharic text translations
- **OpEx**: Operating Expenses (rent, salary, utilities) - excluded from COGS
- **CapEx**: Capital Expenditures (product restocking) - excluded from daily operating profit
- **Gross_Profit**: Revenue minus Cost of Goods Sold (COGS)
- **Net_Profit**: Gross Profit minus Operating Expenses (OpEx only, not CapEx)
- **Alert_Card**: Critical notification widget on home screen
- **Category_Grid**: 4x2 grid of expense category icons
- **Product_Card**: Inventory item display card with stock badge
- **Restock_Modal**: Dialog for adding inventory with WAC recalculation
- **Cart_Sheet**: Slide-up bottom sheet for checkout flow
- **Payment_Pills**: Horizontal scrollable payment method selector
- **Active_Pill**: Rounded capsule indicator for selected bottom navigation tab

---

## Requirements

### Requirement 1: Design System Implementation

**User Story:** As a developer, I want a complete Flutter theme system matching the HTML mockups, so that all screens maintain visual consistency with exact colors, typography, and spacing.

#### Acceptance Criteria

1. THE Theme_System SHALL define all HTML color codes as named constants:
   - Primary teal: #044c2c, #05583b, #0a6358, #10b981
   - Profit card gradient: #15803d → #0d5c2e → #053b1e
   - Alert red: #ba1a24, #b81d24, #c72b2b
   - Alert orange: #e6690b, #d86818
   - Background: #f2f4f3, #f6f8f8, #f7f8fa
   - Text: #1c252c (dark), #87929d (subtle)

2. THE Theme_System SHALL define TextStyles matching HTML typography:
   - Headline: font-black, 24sp, tracking-tight, uppercase
   - Title: font-extrabold, 16sp, tracking-tight
   - Body: font-medium, 14sp
   - Caption: font-bold, 10sp, tracking-wider, uppercase
   - Numbers: font-black, tabular figures

3. THE Theme_System SHALL define spacing constants matching Tailwind:
   - Padding: p-3 (12dp), p-3.5 (14dp), p-4 (16dp), p-5 (20dp)
   - Gap: gap-2 (8dp), gap-2.5 (10dp), gap-3 (12dp), gap-3.5 (14dp)
   - Rounded: rounded-2xl (16dp), rounded-3xl (24dp), rounded-full

4. THE Theme_System SHALL define elevation/shadow matching HTML:
   - Card shadow: shadow-sm (elevation 2)
   - Alert shadow: shadow-xl with colored tint
   - Bottom nav shadow: shadow-lg with 0 -4px 20px blur

5. WHEN dark mode is enabled, THE Theme_System SHALL apply dark color variants:
   - Background: #0c1a2f, #081323
   - Cards: #1c1d1c with lighter borders
   - Text: white with 90% opacity for body

6. THE Theme_System SHALL support bilingual font rendering:
   - Latin: -apple-system, BlinkMacSystemFont
   - Amharic: Noto Sans Ethiopic with proper metrics

### Requirement 2: Splash Screen

**User Story:** As a user, I want to see an animated brand splash screen on app launch, so that I have a professional first impression while the app initializes.

#### Acceptance Criteria

1. THE UI_System SHALL display splash screen with radial gradient background:
   - Gradient: radial-gradient(circle at 50% 40%, #0e2039 0%, #091322 100%)

2. THE UI_System SHALL render brand logo card:
   - Width: 218dp, Height: 142dp
   - Background: white, rounded-3xl (26dp)
   - Shadow: logo-container-glow (0 10px 40px rgba(16,185,129,0.25))
   - Content: SVG recreation with speed lines + circular arc + checkmark

3. THE UI_System SHALL display Amharic typography:
   - Main text: "እፎይ" at 52sp, font-extrabold, gradient fill
   - Subtitle: "በእፎይ እርፍ ይበሉ" at 16.5sp, color #6be39b
   - Font: Noto Sans Ethiopic

4. THE UI_System SHALL animate three pagination dots:
   - Position: bottom center, pb-14
   - Colors: #18cf67, #1ed76f (center larger)
   - Animation: subtlePulse 2s staggered (0s, 0.3s, 0.6s)
   - Effect: opacity 0.35→1, scale 0.9→1.1

5. WHEN License_System completes initialization, THE Navigation_System SHALL navigate to /auth IF no valid user session exists, OR navigate to /home IF valid session/credential exists, after 2 seconds

6. WHILE splash is visible, THE UI_System SHALL prevent user interaction

### Requirement 3: Authentication and Onboarding Screen

**User Story:** As a merchant, I want to activate my license with my device ID and complete initial setup, so that I can use the app offline with proper configuration.

#### Acceptance Criteria

1. THE UI_System SHALL display brand identity header:
   - Logo container: 100dp square, rounded-xl (20dp), white background
   - Logo image: asset/efoy.jpg, fit contain, 12dp padding
   - Shadow: elevation with teal tint rgba(10,99,88,0.2), blur 20dp, offset (0,4)
   - Brand name: "Efoy" 32sp font-bold, color #0a6358
   - Amharic name: "እፎይ" 20sp, color gray-600

2. THE UI_System SHALL display two-tab navigation:
   - Tab 1: "Login" (password-based authentication)
   - Tab 2: "Activate License" (device activation)
   - Container: gray-100 background, rounded-medium (12dp)
   - Active tab: teal background, white text, rounded indicator
   - Inactive tab: transparent background, gray text
   - Default: License tab active on first launch

3. THE UI_System SHALL render Login tab content:
   - Title: "Welcome Back" 24sp font-bold
   - Subtitle: "Enter your password to continue" gray-600
   - Password field: obscured text, lock icon prefix
   - Login button: full width, 48dp height, teal background
   - Link: "Need to activate? Go to License tab" text button

4. WHEN login button is tapped AND valid password, THE Navigation_System SHALL navigate to home screen

5. THE DeviceIdentity SHALL load device information on screen init:
   - Call `DeviceIdentity.getDeviceInfo()` to retrieve DeviceInfo
   - Call `DeviceIdentity.getDeviceId()` to retrieve persistent device ID
   - Display loading state while retrieving

6. THE UI_System SHALL display device information card:
   - Background: gray-100 (neutralBg), rounded-medium, padding 16dp
   - Border: teal/20 opacity
   - Header: "Device Information" with smartphone icon
   - Fields displayed:
     - Platform: DeviceInfo.platform (e.g., "Android", "iOS")
     - Model: DeviceInfo.model (e.g., "SM-G991B")
     - Manufacturer: DeviceInfo.manufacturer (e.g., "Samsung")

7. THE UI_System SHALL display device ID section:
   - Label: "Device ID" 12sp font-semibold uppercase gray-600
   - Container: white background, rounded (8dp), padding 10dp vertical 12dp horizontal
   - Border: gray/30 opacity
   - ID text: monospace font, 13sp font-semibold, teal color
   - Copy button: icon button, teal background, white icon
   - Instruction: "Share this Device ID to get your license key" 11sp italic gray-tertiary

8. WHEN copy button is tapped, THE UI_System SHALL:
   - Copy device ID to system clipboard via `Clipboard.setData()`
   - Display success snackbar: "Device ID copied to clipboard" 2 seconds duration

9. THE UI_System SHALL display license key input field:
   - Label: "License Key" with key icon prefix
   - Placeholder: "XXXX-XXXX-XXXX-XXXX"
   - Text capitalization: all uppercase
   - Input formatters: allow [A-Za-z0-9-] only
   - Min lines: 1, Max lines: 3 (multiline for long keys)

10. WHEN kDebugMode is true, THE UI_System SHALL display test key generator:
    - Button: "Generate Test Key (30 Days)" with build icon
    - Style: outlined button, amber color scheme
    - Warning: "⚠️ Debug mode only - for testing" 11sp italic

11. WHEN test key button is tapped, THE LicenseVerifier SHALL:
    - Call `LicenseVerifier.generateLicenseKey(deviceId, expiryDate)` with 30-day expiry
    - Populate license key input field with generated key
    - Display snackbar: "Test license key generated (30 days)"

12. THE UI_System SHALL display activate button:
    - Background: teal if license key not empty, gray if empty
    - Text: "Activate License" with padding 4dp vertical
    - Disabled state: null onPressed handler when key empty

13. WHEN activate button is tapped, THE LicenseVerifier SHALL:
    - Set loading state true, clear error/success messages
    - Validate license key is not empty
    - Call `LicenseVerifier.verifyLicense(licenseKey, deviceId)`
    - Receive `LicenseVerificationResult` with `isValid` and `errorMessage`

14. WHEN license verification succeeds, THE UI_System SHALL:
    - Display success message: "License activated successfully!"
    - Transition to onboarding flow (show _buildOnboardingFlow)
    - Keep activate button disabled during onboarding

15. WHEN license verification fails, THE UI_System SHALL:
    - Display error message in red alert box with error icon
    - Show `LicenseVerificationResult.errorMessage` (e.g., "Invalid license key", "License expired", "Device mismatch")
    - Clear success message
    - Re-enable activate button

16. THE UI_System SHALL display onboarding flow after successful activation:
    - Success indicator: green badge with checkmark icon
    - Title: "License Activated!" 18sp font-bold green
    - Subtitle: "Complete your setup to get started" 13sp gray

17. THE UI_System SHALL display password setup section (Step 1):
    - Section header: "Step 1: Create Password" 18sp font-bold
    - Description: "This password will be used to login to your account" 13sp gray
    - New password field: obscured text, lock icon, min 4 characters
    - Confirm password field: obscured text, lock icon, must match
    - Validation: passwords must match, min 4 chars

18. THE UI_System SHALL display mode selection section (Step 2):
    - Section header: "Step 2: Choose Mode" 18sp font-bold
    - Info card with icon, title, description, toggle switch
    - Demo Mode: visibility icon, amber tint, "Testing with sample data (payment info optional)"
    - Production Mode: store icon, teal tint, "Real business mode (payment info required)"
    - Switch: iOS-style toggle, right-aligned

19. WHEN mode toggle is switched, THE UI_System SHALL:
    - Update `_isDemoMode` state
    - Update info card styling (icon, color, description)
    - Update Step 3 optional/required status

20. THE UI_System SHALL display payment information section (Step 3):
    - Section header: "Step 3: Payment Information" 18sp font-bold
    - Optional badge: gray badge with "Optional" text if demo mode
    - Required notice: "Required for accepting customer payments" if production mode
    - Description: "You can add this information later in Settings" if demo mode

21. THE UI_System SHALL display payment input fields:
    - Phone Number: phone keyboard, "+251912345678" placeholder, phone icon
    - TeleBirr Account: phone keyboard, "TeleBirr number" placeholder, payment icon
    - Bank Account Number: text keyboard, "Account number" placeholder, bank icon
    - Bank Name: text keyboard, "e.g., Commercial Bank of Ethiopia" placeholder, business icon

22. THE UI_System SHALL display complete setup button:
    - Text: "Complete Setup & Start" with 4dp vertical padding
    - Background: teal if valid, gray if invalid
    - Loading indicator: circular progress spinner 20dp when processing

23. THE UI_System SHALL validate each onboarding step independently before allowing advancement:
    - Step 1: Password is not empty AND length >= 4 characters AND password matches confirmation
    - Step 2: Mode selection completed (demo or production chosen)
    - Step 3: If production mode, at least one payment method provided; if demo mode, payment methods optional
    - THE UI_System SHALL prevent advancement to next step until current step validation passes

23a. WHEN complete setup button is tapped, THE UI_System SHALL validate all steps are complete

24. WHEN validation fails, THE UI_System SHALL:
    - Display error message in red alert box
    - Highlight invalid fields
    - Keep button enabled for retry

25. WHEN validation succeeds, THE UI_System SHALL:
    - Set loading state true
    - Create UserProfile record in Isar database with:
      - password (hashed with bcrypt or argon2)
      - isDemoMode flag
      - phone, telebirr, bankAccount, bankName (if provided)
      - createdAt timestamp
    - Wait 500ms (simulated save)
    - Navigate to home screen via `Navigator.pushReplacementNamed('/home')`

26. THE UI_System SHALL display back button in onboarding:
    - Text button: "← Back to License Entry"
    - Action: reset to license activation view, clear success message

27. THE UI_System SHALL display all error messages consistently:
    - Container: red/10 background, red/30 border, rounded (8dp), padding 12dp
    - Icon: error_outline icon, red color, 20dp
    - Text: red color, 13sp
    - Spacing: 16dp bottom margin before next element

28. THE UI_System SHALL display all success messages consistently:
    - Container: green/10 background, green/30 border, rounded (8dp), padding 12dp
    - Icon: check_circle_outline icon, green color, 20dp
    - Text: green color, 13sp
    - Spacing: 16dp bottom margin before next element

### Requirement 4: Home Dashboard Screen

**User Story:** As a merchant, I want to see my daily profit and critical alerts at a glance, so that I can quickly understand my business status.

#### Acceptance Criteria

1. THE UI_System SHALL display header with brand logo:
   - Logo container: 44dp square, rounded-2xl, bg #044c2c
   - Icon: white checkmark, 24dp
   - Title: "እፎይ" 20sp font-black, #044a2b
   - Subtitle: "በእፎይ እርፍ ይበሉ" 12sp, gray-400
   - Settings gear icon: right side, 40dp touch target

2. THE Profit_Card SHALL display net profit with gradient:
   - Background: radial-gradient #15803d → #0d5c2e → #053b1e
   - Corner radius: rounded-3xl (24dp)
   - Padding: 20dp
   - Shadow: shadow-xl with green tint
   - Watermark circle: 190dp, bottom-right, rgba(255,255,255,0.08)

3. THE Profit_Card SHALL display SYNCED status indicator:
   - Dot: 8dp circle, #10ef64, position top-left
   - Animation: pulsing opacity 0.7→1 every 2s
   - Label: "SYNCED" 11sp font-extrabold uppercase, #d1fae5

4. THE Profit_Card SHALL display period filter pills:
   - Pills: Today (active), Week, Month
   - Active: bg white/25, font-semibold, shadow
   - Inactive: text white/60, font-medium
   - Container: bg #07321a/70, rounded-full, padding 4dp

5. WHEN user taps period filter pill, THE Profit_Card SHALL update net profit calculation for selected period

6. THE Profit_Card SHALL display net profit amount:
   - Label: "NET PROFIT · TODAY" 11sp font-bold uppercase, emerald-200
   - Amount: 48sp font-black, white, tracking-tight
   - Currency: "ብር" 24sp font-bold, white/90
   - Alignment: left, vertical spacing 32dp from top

7. THE Profit_Card SHALL display revenue and expenses breakdown:
   - Border: top border white/15
   - Grid: 2 columns
   - Revenue: label "REVENUE TODAY" 10sp, amount font-bold white
   - Expenses: label "EXPENSES TODAY" 10sp, amount font-bold rose-300
   - Amounts: real-time from Isar database

8. THE UI_System SHALL display quick metrics grid (2 columns):
   - Card 1: Transactions count (teal icon)
   - Card 2: Sales amount (emerald icon)
   - Each card: white bg, rounded-2xl, padding 14dp, shadow-sm
   - Icon container: 44dp, rounded-xl, colored background
   - Label: 9sp font-bold uppercase tracking-wider gray-400
   - Value: 18sp font-black gray-900

9. THE UI_System SHALL display critical alerts section:
   - Header: "CRITICAL ALERTS" 12sp font-black uppercase
   - Live indicator: red dot + "LIVE" label
   - Spacing: gap-2.5 between cards

10. THE UI_System SHALL display alert cards with priority styling:
    - Amber alert: bg #fff9f0, border #ffecd1, icon #d97706
    - Crimson alert: bg gradient #ba141b → #910d13, white text
    - Dark alert: bg #1c1d1c, white text, emerald icon
    - Each card: rounded-2xl, padding 14dp, icon 40dp

11. WHEN inventory stock falls below threshold, THE UI_System SHALL display "INVENTORY LOW" alert with product list

12. WHEN zero transactions recorded today, THE UI_System SHALL display "0 TRANSACTIONS TODAY" alert

13. WHEN gross profit margin < 5%, THE UI_System SHALL display "PROFIT HEALTH: CAUTION" alert

14. THE UI_System SHALL display command actions section:
    - Button: "Quick Sell & Record" bg #0b5e32, height 56dp
    - Icon: right chevron, emerald-200
    - Text: 12sp font-bold tracking-wide

15. THE Bottom_Nav SHALL display 5 tabs with Home active (pill indicator bg #05583b)

### Requirement 5: Sell (POS) Screen and Complete Transaction Flow

**User Story:** As a merchant, I want to quickly select products, manage cart, and complete sales with accurate stock and profit tracking, so that I can serve customers efficiently with real-time inventory updates.

#### Acceptance Criteria

1. THE UI_System SHALL display header:
   - Title: "SELL" 24sp font-black uppercase gray-900
   - Hold button: rounded-full, gray-200 bg, pause icon + "Hold" text
   - Background: sticky top position

2. THE CartProvider SHALL initialize on screen load:
   - Load held orders from Isar HeldOrder collection if any exist
   - Initialize empty cart state: `items: [], total: 0.0, paymentMethod: cash`
   - Load all active products from Isar: `WHERE isDeleted = false AND currentStock > 0`

3. THE UI_System SHALL display product grid:
   - Layout: 3 columns with gap-2.5 (10dp)
   - Scrollable: vertical with hidden scrollbar
   - Card size: min-height 110dp for top row, 120dp for others
   - Query: `productCollection.filter().isDeletedEqualTo(false).sortByName().findAll()`

4. THE UI_System SHALL render each product card:
   - Background: white, rounded-2xl, padding 12dp
   - Border: gray-100/80
   - Icon: 32dp square, rounded-lg, teal-50 bg, teal-800 icon
   - Name: 12sp font-medium gray-800, truncated
   - Price: 12sp font-black teal-800 with "ብር" suffix
   - Stock: 10sp gray-400 "[n] left"

5. WHEN product is in cart, THE UI_System SHALL apply selected styling:
   - Background: #1b635c (teal-800)
   - Text: white
   - Icon background: white/20
   - Badge: white circle top-right showing quantity, 20dp, centered text

6. WHEN user taps product card, THE CartProvider SHALL:
   - Check if product already in cart via `items.firstWhere((item) => item.productId == product.id)`
   - If found: call `incrementQuantity(productId)`
   - If not found: call `addItem(product, quantity: 1)`
   - Validate: quantity <= product.currentStock (available stock limit)
   - Update total: recalculate sum of all line totals
   - Notify listeners to rebuild UI

7. THE CartProvider SHALL maintain CartItem state:
   - `productId`: int, reference to Product
   - `productName`: String, display name
   - `quantity`: int, units in cart
   - `unitPrice`: double, current selling price (editable)
   - `unitCost`: double, current WAC for COGS calculation
   - `lineTotal`: double, computed as `quantity × unitPrice`
   - `availableStock`: int, maximum quantity allowed

8. WHEN cart has items, THE Cart_Sheet SHALL slide up from bottom:
   - Background: white, rounded-t-3xl (34dp top corners)
   - Shadow: 0 -10px 30px rgba(0,0,0,0.08)
   - Padding: 20dp
   - Border: top border gray-100
   - Animation: 300ms slide up with easeOut curve

9. THE Cart_Sheet SHALL display header:
   - Badge: teal circle with item count (sum of quantities), 24dp
   - Label: "CART" font-extrabold 16sp
   - Clear button: "Clear all" text-rose-700, 14sp font-semibold

10. WHEN clear all button is tapped, THE CartProvider SHALL:
    - Show confirmation dialog: "Clear all items from cart?"
    - On confirm: call `clearCart()`, reset to empty state
    - Notify listeners to close cart sheet and update product cards

11. THE Cart_Sheet SHALL render each cart line item:
    - Product name: 14sp font-bold gray-900
    - Unit price: 12sp font-bold teal-800 with pencil edit icon
    - Quantity stepper: minus button (gray-100 bg) / count / plus button (teal-800 bg)
    - Each stepper button: 28dp circle
    - Count display: 14sp font-bold, 16dp width center, border-bottom dashed gray-400
    - Line total: 14sp font-bold gray-900, right-aligned
    - Remove button: rose-500 X icon, 16dp

12. WHEN edit pencil is tapped, THE UI_System SHALL display price override modal:
    - Title: "Edit Price - [Product Name]"
    - Current price: display read-only
    - New price: number input field
    - If production mode: require password confirmation
    - If demo mode: allow immediate change
    - Buttons: Cancel / Apply (disabled until valid input)

13. WHEN price override is applied, THE CartProvider SHALL:
    - Update `cartItem.unitPrice = newPrice`
    - Recalculate `cartItem.lineTotal = quantity × newPrice`
    - Recalculate cart total
    - Keep unitCost unchanged (for accurate COGS)
    - Log price override for audit trail
    - Notify listeners to update UI

14. WHEN plus stepper is tapped, THE CartProvider SHALL:
    - Call `incrementQuantity(productId)`
    - Check: `newQuantity <= availableStock`
    - If valid: increment quantity, recalculate lineTotal and total
    - If invalid: show snackbar "Only [n] units available"
    - Notify listeners

15. WHEN minus stepper is tapped, THE CartProvider SHALL:
    - Call `decrementQuantity(productId)`
    - If quantity > 1: decrement quantity, recalculate totals
    - If quantity = 1: call `removeItem(productId)` instead
    - Notify listeners to update UI

16. WHEN remove button is tapped, THE CartProvider SHALL:
    - Call `removeItem(productId)`
    - Remove item from cart items list
    - Recalculate cart total
    - If cart becomes empty: close cart sheet
    - Notify listeners

17. THE Cart_Sheet SHALL display total bar:
    - Background: gray-50/80, full width bleed (negative margin 20dp horizontal)
    - Label: "TOTAL" 12sp font-bold uppercase gray-400
    - Amount: 24sp font-black teal-800 "ብር" suffix

18. THE Cart_Sheet SHALL display payment method selector:
    - Label: "PAYMENT METHOD" 10sp font-extrabold uppercase
    - Pills: Cash (default), Telebirr, CBE Birr, Amhara Bank
    - Active style: bg #1b635c white text, shadow
    - Inactive: bg gray-100 gray-700 text
    - Horizontal scroll: hidden scrollbar, gap-2 (8dp)

19. WHEN payment pill is tapped, THE CartProvider SHALL:
    - Update `paymentMethod` state to selected value
    - Notify listeners to update active pill styling

20. THE Cart_Sheet SHALL display amount received input:
    - Background: #f4f5f7, rounded-xl, padding 12dp
    - Prefix: "Birr" gray-400 14sp
    - Input: number keyboard type, placeholder "Amount received"
    - Focus state: border teal-700, background white transition

21. WHEN amount received is entered, THE CartProvider SHALL:
    - Parse double value from input
    - Calculate change: `max(0, amountReceived - total)`
    - If change > 0: display change amount below input
    - Update `amountReceived` and `changeGiven` state

22. THE Cart_Sheet SHALL display calculated change:
    - Container: bg teal-50, rounded-lg, padding 8dp, margin-top 8dp
    - Label: "CHANGE" 10sp font-bold teal-800
    - Amount: 18sp font-black teal-800 with "ብር"
    - Visible only when amountReceived > total

23. THE Cart_Sheet SHALL display complete sale button:
    - Background: #1b635c, height 56dp, rounded-2xl
    - Icon: white circle with checkmark, 20dp, left side
    - Text: "COMPLETE SALE · [amount] ብር" uppercase font-extrabold
    - Shadow: shadow-lg teal-900/10
    - Active state: scale 0.99 on press
    - Disabled: gray background if cart empty

24. WHEN complete sale button is tapped, THE CartProvider SHALL validate:
    - Cart is not empty
    - All products still have sufficient stock (concurrent sale check)
    - Amount received >= total (if cash payment)
    - Payment method is selected

25. WHEN validation passes, THE CartProvider SHALL execute atomic transaction:
    - Start Isar write transaction
    - Create SaleModel with UUID transactionId
    - Set saleDate = DateTime.now()
    - Create SaleLineItem for each cart item with current WAC snapshot
    - Calculate totalAmount = sum of lineTotal
    - Calculate totalCost = sum of lineCost
    - Calculate grossProfit = totalAmount - totalCost
    - Set paymentMethod, amountReceived, changeGiven
    - Save Sale record

26. THE CartProvider SHALL update inventory atomically:
    - For each cart item:
      - Load Product from database
      - Decrement `currentStock` by quantity
      - Update `updatedAt` = DateTime.now()
      - Save Product
    - If any product stock insufficient: rollback entire transaction
    - Show error: "Stock changed. Please review cart."

27. THE CartProvider SHALL finalize checkout:
    - Commit Isar transaction
    - Clear cart state: `items = [], total = 0, amountReceived = null, changeGiven = null`
    - Reset payment method to cash
    - Show success snackbar: "Sale completed - [amount] ብר"
    - Navigate to home screen
    - Notify ProfitProvider to refresh (via Isar watcher)

28. THE UI_System SHALL display success animation:
    - Checkmark icon with scale animation 0 → 1.2 → 1.0
    - Duration: 400ms
    - Color: green, overlayed on cart sheet
    - Auto-dismiss after animation

29. WHEN hold button is tapped, THE CartProvider SHALL:
    - Save current cart state to HeldOrder collection
    - Include timestamp and optional name/label
    - Clear cart state
    - Show success message: "Order held"
    - Close cart sheet

30. THE UI_System SHALL display held orders indicator:
    - Badge on hold button: count of held orders
    - Tapping hold button when cart empty: show held orders list
    - Each held order: timestamp, item count, total, restore button

31. WHEN held order is restored, THE CartProvider SHALL:
    - Load cart items from HeldOrder
    - Verify all products still exist and have stock
    - Update prices to current selling prices
    - Recalculate totals
    - Delete HeldOrder record
    - Show cart sheet

32. THE Bottom_Nav SHALL display with Sell tab active (pill indicator)

### Requirement 6: Inventory Management Screen with Restock Flow

**User Story:** As a merchant, I want to manage my product inventory, track low stock alerts, and restock products with automatic WAC recalculation, so that I can maintain adequate stock levels and accurate cost tracking.

#### Acceptance Criteria

1. THE UI_System SHALL display header:
   - Title: "INVENTORY" 24sp font-black gray-900
   - Count: "[n] products" 14sp font-medium gray-400
   - Add button: rounded-full bg #126857, white text, "+ Add Product"

2. THE InventoryProvider SHALL load on screen init:
   - Query all products: `productCollection.filter().isDeletedEqualTo(false).sortByName().findAll()`
   - Calculate low stock count: `products.where((p) => p.isLowStock).length`
   - Initialize filters: selectedFilter = All, searchQuery = ""

3. WHEN add product button is tapped, THE Navigation_System SHALL show add product modal

4. THE UI_System SHALL display stock alerts card:
   - Header ribbon: bg #b91c24, white text, padding 12dp
   - Icon: white dot pulsing (2dp, animate opacity 0.8→1.0 every 1.5s)
   - Label: "STOCK ALERTS" uppercase font-black tracking-wider 12sp
   - Subtitle: "[n] items need attention" 12sp font-medium white/90
   - Border: red-50 1dp, shadow-xl with red-950/5 tint
   - Visible only when lowStockCount > 0

5. THE UI_System SHALL render each alert item in stock alerts card:
   - Container: divide-y divide-gray-100/90, padding 3dp horizontal
   - Icon: 36dp rounded-xl, bg #fef4e8 (amber-50), orange warning triangle icon 20dp
   - Product name: 14sp font-bold gray-900, leading-snug
   - Stock status: "[currentStock] left" orange-600 font-semibold 12sp
   - Threshold: "(threshold: [lowStockThreshold])" gray-400 font-medium 12sp
   - Badge: "LOW" uppercase font-black 11sp, bg #e6690b orange, white text, rounded-full px-3.5 py-1

6. THE UI_System SHALL sort alerts by ascending currentStock value (lowest stock first), breaking ties by lowStockThreshold percentage (currentStock / lowStockThreshold ratio)

7. THE UI_System SHALL display search bar:
   - Background: white, border gray-100 1dp, rounded-2xl (16dp)
   - Icon: search magnifier gray-400 20dp, left padding 16dp
   - Input: "Search products..." placeholder 14sp font-normal gray-400
   - Padding: 14dp vertical, 11dp left after icon, 16dp right
   - Focus ring: 2dp teal-700, border transparent

8. WHEN user types in search, THE InventoryProvider SHALL:
   - Update searchQuery state
   - Filter products: `name.toLowerCase().contains(searchQuery.toLowerCase())`
   - Debounce: 300ms delay before filtering
   - Notify listeners to rebuild list

9. THE UI_System SHALL display filter pills:
   - Pills: All (default), Needs Attention ([count]), Out of Stock
   - Active: bg black white text, font-bold 12sp, shadow-sm
   - Inactive: bg white gray-800 text, border gray-100/50 1dp, font-bold 12sp
   - Container: flex row gap-2 (8dp), horizontal scroll hidden
   - Padding: 20dp horizontal (each pill), 8dp vertical

10. WHEN filter pill is tapped, THE InventoryProvider SHALL:
    - Update selectedFilter state
    - Apply filter:
      - All: show all products
      - Needs Attention: where isLowStock = true
      - Out of Stock: where isOutOfStock = true
    - Notify listeners to rebuild list

11. THE UI_System SHALL render each product card:
    - Background: white, rounded-3xl (24dp), padding 16dp
    - Border: amber-100/80 1dp if isLowStock, gray-100/80 otherwise
    - Shadow: shadow-sm (elevation 2)
    - Gap: 8dp between elements (flex column)

12. THE ProductCard SHALL display product icon:
    - Container: 48dp square, rounded-2xl (16dp)
    - Background: #fff6ec (orange-50) if low stock, teal-50 if normal
    - Icon: 24dp package icon, orange-700 if low stock, teal-800 if normal

13. THE ProductCard SHALL display product information:
    - Name: 16sp font-extrabold gray-900 leading-tight
    - Badge: "LOW" badge next to name if isLowStock
      - Background: #fff1e5 (amber-100)
      - Text: #d86818 (orange) font-bold 10sp uppercase tracking-wide
      - Padding: 2dp vertical 8dp horizontal, rounded (4dp)
    - Stock: 12sp font-bold, orange-600 if low, gray-600 if normal
      - Text: "[currentStock] in stock"
    - Price: 12sp font-semibold gray-700 with "ብר" suffix
      - Format: "[sellingPrice] ብር"
      - Display: 16dp top margin

14. THE ProductCard SHALL display action buttons:
    - Restock button: rounded-full, bg #d8ede8 (teal-50), text #126857 (teal)
      - Text: "+ Restock" font-bold 12sp
      - Padding: 6dp vertical 12dp horizontal
      - Hover: bg #c9e7e0 (darker teal-50)
    - Category label: 10sp gray-400 font-medium, bottom-right alignment
    - Chevron icon: 16dp gray-300, right arrow, 4dp left margin

15. WHEN product card is tapped, THE Navigation_System SHALL navigate to product detail screen:
    - Pass product ID as route parameter
    - Detail screen shows full information, edit options, transaction history

16. WHEN restock button is tapped, THE UI_System SHALL display restock modal:
    - Background: white, rounded-t-3xl (24dp top corners)
    - Height: max 85% of screen height
    - Padding: 24dp
    - Shadow: shadow-2xl
    - Backdrop: semi-transparent black overlay, opacity 0.5

17. THE RestockModal SHALL display product information header:
    - Title: "Restock Product" 20sp font-bold gray-900
    - Product name: 16sp font-semibold gray-700, 8dp top margin
    - Divider: gray-200 1dp, 16dp vertical margin

18. THE RestockModal SHALL display current WAC (read-only):
    - Label: "Current Weighted Average Cost" 13sp font-semibold gray-700
    - Value: "[costPrice] ብር per unit" 16sp font-bold teal-800
    - Container: bg gray-50, rounded-xl (12dp), padding 12dp
    - Helper text: "This will be recalculated after restocking" 11sp gray-500 italic

19. THE RestockModal SHALL display current stock (read-only):
    - Label: "Current Stock" 13sp font-semibold gray-700
    - Value: "[currentStock] units" 16sp font-bold gray-900
    - Container: same style as WAC

20. THE RestockModal SHALL display quantity input:
    - Label: "Quantity to Add" 13sp font-semibold gray-700
    - Input: number keyboard, min 1, no max (reasonable limit: 999999)
    - Suffix: "units" gray-400 inside field
    - Border: gray-300 1dp, rounded-xl
    - Focus: border teal-700 2dp
    - Validation: required, must be positive integer

21. THE RestockModal SHALL display cost per unit input:
    - Label: "Cost Per Unit (New Purchase Price)" 13sp font-semibold gray-700
    - Input: decimal keyboard, min 0.01
    - Prefix: "ብር" gray-400 inside field
    - Border: gray-300 1dp, rounded-xl
    - Focus: border teal-700 2dp
    - Validation: required, must be positive number

22. THE RestockModal SHALL display calculated total cost:
    - Label: "Total Restock Cost" 13sp font-semibold gray-700
    - Value: "[quantity × costPerUnit] ብር" 20sp font-black orange-600
    - Container: bg orange-50, rounded-xl, padding 12dp
    - Formula display: "[quantity] units × [costPerUnit] ብር"

23. THE RestockModal SHALL display new WAC preview:
    - Label: "New Weighted Average Cost (Preview)" 13sp font-semibold gray-700
    - Calculation: live update using WACCalculator.calculateNewWAC()
    - Display: "[newWAC] ብር per unit" 18sp font-black teal-800
    - Container: bg teal-50, rounded-xl, padding 12dp, border teal-200 2dp dashed
    - Formula explanation: "([currentStock] × [oldWAC] + [quantity] × [costPerUnit]) / ([currentStock] + [quantity])"
    - Helper text: "This is the new cost basis for profit calculations" 11sp gray-500 italic

24. THE RestockModal SHALL display action buttons:
    - Cancel button: outlined, gray-600 text, "Cancel"
    - Confirm button: filled teal bg, white text, "Confirm Restock"
    - Layout: row, gap 12dp, bottom of modal
    - Confirm disabled: if quantity or cost invalid

25. WHEN cancel button is tapped, THE UI_System SHALL dismiss modal without changes

26. WHEN confirm button is tapped, THE InventoryProvider SHALL execute atomic transaction:
    - Start Isar write transaction
    - Calculate new WAC: `WACCalculator.calculateNewWAC(currentStock, costPrice, quantity, costPerUnit)`
    - Update Product:
      - currentStock += quantity
      - costPrice = newWAC
      - updatedAt = DateTime.now()
    - Create RestockLogModel:
      - productId, productName
      - quantityAdded = quantity
      - costPerUnit = input value
      - totalCost = quantity × costPerUnit
      - oldWAC = previous costPrice
      - newWAC = calculated value
      - oldStock = previous currentStock
      - newStock = updated currentStock
      - restockedAt = DateTime.now()
    - Create ExpenseModel:
      - title = "Restock · [productName]"
      - amount = totalCost
      - category = ExpenseCategory.restock
      - isRestockExpense = true (CRITICAL for profit calculation)
      - expenseDate = DateTime.now()
    - Commit transaction

27. WHEN restock transaction succeeds, THE UI_System SHALL:
    - Dismiss modal with slide-down animation
    - Show success snackbar: "Restocked [productName] - New WAC: [newWAC] ብር"
    - Notify InventoryProvider listeners to refresh list
    - If product was in low stock alerts: remove from alerts if now above threshold
    - Notify ProfitProvider via Isar watcher (expenses changed)

28. WHEN restock transaction fails, THE UI_System SHALL:
    - Keep modal open
    - Display error message: "Restock failed. Please try again."
    - Log error for debugging
    - Allow user to retry or cancel

29. THE InventoryProvider SHALL watch Isar for real-time updates:
    - Use `productCollection.watchLazy()` for live inventory changes
    - Automatically update product list when changes detected
    - Update low stock count when products cross threshold
    - Update badge on inventory tab in bottom navigation

30. THE Bottom_Nav SHALL display with Inventory tab active (pill indicator)

### Requirement 7: Add Product Modal

**User Story:** As a merchant, I want to add new products with details and initial stock, so that I can track inventory from the beginning.

#### Acceptance Criteria

1. WHEN add product button is tapped, THE UI_System SHALL display modal:
   - Background: white, rounded-t-3xl
   - Height: 90% viewport
   - Shadow: shadow-2xl

2. THE UI_System SHALL display form fields:
   - Product name: text input, required
   - Description: multiline text input, optional
   - Category: dropdown (Electronics, Food, Beverages, Supplies, Other)
   - Barcode: text input with scanner button icon
   - Photo: camera icon button for image capture
   - Selling price: number input with "ብር" suffix, required
   - Cost price: number input with "ብር" suffix, required
   - Initial stock: IF product has variants configured, display separate quantity input per location/variant combination; IF no variants configured, display single quantity input (number input, required, min 0)
   - Low stock threshold: number input, required, default 5

3. WHEN user taps barcode scanner button, THE UI_System SHALL open camera viewfinder for barcode scanning

4. WHEN barcode is detected, THE UI_System SHALL populate barcode field AND close camera

5. WHEN user taps photo button, THE UI_System SHALL show image source picker (camera / gallery)

6. WHEN image is selected, THE UI_System SHALL display thumbnail in modal

7. THE UI_System SHALL display save button:
   - Background: #0a6358 if form valid, gray if invalid
   - Text: "SAVE PRODUCT" uppercase font-extrabold
   - Height: 48dp, rounded-2xl

8. WHEN save button is tapped AND form is valid, THE Inventory_Provider SHALL:
   - Create Product record in Isar
   - Set initial WAC = cost price
   - IF product has variants configured: record initial stock per location/variant combination
   - IF no variants configured: record single quantity for product overall
   - Save image to local storage if provided
   - Close modal
   - Show success message
   - Refresh product list

9. WHEN save button is tapped AND form is invalid, THE UI_System SHALL highlight validation errors

10. THE UI_System SHALL display cancel button to dismiss modal without saving

### Requirement 8: Expenses Tracking Screen

**User Story:** As a merchant, I want to record operating expenses by category, so that I can calculate accurate net profit excluding capital expenditures.

#### Acceptance Criteria

1. THE UI_System SHALL display header:
   - Title: "EXPENSES" 24sp font-black uppercase
   - Record count: "[n] recorded" 12sp font-semibold gray-subtle
   - Total spent: right-aligned, 20sp font-extrabold text-red
   - Label: "TOTAL SPENT" 10sp uppercase font-bold

2. THE UI_System SHALL display insight banner card:
   - Background: white, rounded-3xl, padding 16dp
   - Icon: 48dp rounded-2xl, teal-50 bg, trend icon
   - Text: 13sp font-bold gray-900
   - Subtext: 12sp font-medium gray-400 with amount
   - Content: "Restock is your biggest expense - [amount] ብር spent"

3. THE UI_System SHALL display expense form card:
   - Background: white, rounded-3xl, padding 20dp
   - Header: "RECORD EXPENSE" 11sp font-black uppercase gray-400

4. THE UI_System SHALL display category grid (4 columns × 2 rows):
   - Categories: Rent, Salary, Transport, Utilities, Airtime, Supplies, Restock, Other
   - Each button: rounded-2xl, padding 10dp vertical
   - Icon: 32dp container, 24dp icon
   - Label: 10sp font-bold tracking-wide uppercase gray-400
   - Inactive: bg #f2f7f6, text #0d594f
   - Active: bg #0a6358, text white, shadow-lg, ring-2

5. WHEN user taps category button, THE UI_System SHALL apply active styling AND update record button text

6. THE UI_System SHALL display amount input:
   - Background: #f7faf9, rounded-2xl, padding 16dp
   - Prefix: "Birr" gray-400 20sp
   - Input: number, 30sp font-extrabold gray-500, placeholder "0.00"

7. THE UI_System SHALL display note input:
   - Background: #f7faf9, rounded-2xl, padding 12dp
   - Placeholder: "Note (optional)" gray-400 16sp

8. THE UI_System SHALL display payment method pills:
   - Pills: Cash (active black bg), Telebirr, CBE Birr, Amhara Bank
   - Active: bg black white text
   - Inactive: bg #f1f4f5 gray-600 text
   - Horizontal scroll: hidden scrollbar

9. THE UI_System SHALL display record button:
   - Background: #dfe4e6 if amount = 0 OR category not selected, teal if valid
   - Text: "RECORD [CATEGORY] EXPENSE" uppercase font-extrabold
   - Icon: wallet icon 20dp
   - Height: 56dp, rounded-2xl
   - Disabled: if amount = 0 OR category not selected

10. WHEN record button is tapped AND category is not selected, THE UI_System SHALL display error message "Please select a category" AND keep record button disabled until category selected

11. WHEN record button is tapped AND amount > 0 AND category is selected, THE Inventory_Provider SHALL:
    - Create Expense record in Isar with category, amount, payment method, note, timestamp
    - Reset form fields
    - Show success message
    - Update expense list

12. THE UI_System SHALL display expense list section:
    - Header: "ALL EXPENSES" 11sp font-black uppercase gray-400
    - Sorted: most recent first

13. THE UI_System SHALL render each expense item:
    - Background: white, rounded-3xl, padding 16dp
    - Icon: 44dp rounded-2xl, category-colored bg
    - Title: "[Category] · [Note]" 14sp font-bold
    - Subtitle: "[Payment] · [Time]" 11sp font-semibold gray-400
    - Amount: 14sp font-extrabold text-red with "ብር" suffix, right-aligned

14. WHEN calculating net profit, THE Profit_Engine SHALL exclude Restock category from operating expenses (treat as CapEx)

15. THE Bottom_Nav SHALL display with Expenses tab active (pill indicator)

### Requirement 9: Profile/Settings Screen

**User Story:** As a merchant, I want to view financial reports and manage app settings, so that I can analyze performance and customize the experience.

#### Acceptance Criteria

1. THE UI_System SHALL display header:
   - Title: "PROFILE" 24sp font-black uppercase
   - Subtitle: "Reports + business identity" 12sp font-medium
   - Share button: 40dp rounded-2xl, gray-100 bg, share icon

2. THE UI_System SHALL display timeframe filter pills:
   - Pills: 7D, 30D (active), 90D, Custom (with calendar icon)
   - Active: bg #0a6358 white text, shadow
   - Inactive: text gray-400, hover gray-600

3. WHEN user taps custom button, THE UI_System SHALL show date range picker modal

4. THE UI_System SHALL display section navigation pills (scrollable):
   - Sections: Overview (active black bg), Trend, Products, Expenses
   - Each pill: icon + label, rounded-full, padding 8dp 16dp
   - Active: bg black white text, shadow
   - Inactive: bg gray-100 gray-400 text

5. THE UI_System SHALL display merchant identity card:
   - Background: white, rounded-3xl, padding 16dp
   - Avatar: 56dp rounded-2xl, teal bg, store icon
   - Name: 16sp font-bold gray-900
   - Contact: 12sp gray-400 (name · phone)
   - License period: 11sp font-semibold teal-800
   - Edit button: 36dp rounded-full, gray-50 bg, pencil icon

6. WHEN user taps edit button, THE UI_System SHALL display profile edit modal

7. THE UI_System SHALL display financial metrics grid (2 columns × 2 rows):
   - Cards: Revenue, Gross Profit, Op. Expenses, Gross Margin
   - Each card: white bg, rounded-3xl, padding 16dp, height 144dp
   - Icon: 24dp, category color
   - Amount: 20sp font-extrabold, colored by metric type
   - Label: 10sp font-extrabold uppercase gray-400

8. THE Profit_Engine SHALL calculate metrics for selected timeframe:
   - Revenue: sum of all sale amounts
   - Gross Profit: Revenue - COGS (using WAC for each sale)
   - Op. Expenses: sum of expenses excluding Restock category
   - Gross Margin: (Gross Profit / Revenue) × 100%

9. THE UI_System SHALL display decision insights section:
   - Header: "DECISION INSIGHTS" 11sp font-black uppercase
   - Background: white, rounded-3xl, padding 20dp

10. THE UI_System SHALL render insight items:
    - Icon: emoji or colored SVG icon
    - Text: 14sp font-medium gray-800, leading-snug
    - Examples:
      - ⚠️ "Gross margin is [n]% - pricing may need attention" (if < 5%)
      - 📈 "Net profit is [amount] ብር after operating expenses"
      - ⭐ "[Product] is your top seller with [n] units sold"

11. WHEN gross margin < 5%, THE UI_System SHALL display margin warning insight

12. WHEN a product has highest sales count, THE UI_System SHALL display top seller insight

13. THE Bottom_Nav SHALL display with Profile tab active (pill indicator)

### Requirement 10: Settings Section

**User Story:** As a merchant, I want to customize app appearance and manage data, so that I can personalize the experience and maintain business data.

#### Acceptance Criteria

1. THE UI_System SHALL display settings grouped in cards:
   - Appearance: Dark mode toggle, Language selector, Accent color picker
   - Data: Backup button, Restore button, Clear data button
   - License: License status card with expiry date
   - About: App version, developer info

2. THE UI_System SHALL display dark mode toggle:
   - Label: "Dark Mode" 14sp font-semibold
   - Switch: iOS-style toggle, teal active color

3. WHEN user toggles dark mode, THE Theme_System SHALL apply dark theme to all screens immediately

4. THE UI_System SHALL display language selector:
   - Label: "Language" 14sp font-semibold
   - Buttons: [EN] / [አማርኛ] pill toggle
   - Active: teal bg white text

5. WHEN user taps language button, THE Bilingual_Strings SHALL switch active language AND update all visible text

6. THE UI_System SHALL display accent color picker:
   - Label: "Accent Color" 14sp font-semibold
   - Swatches: 6 color circles (teal, blue, purple, green, orange, red)
   - Selected: ring-2 white ring, inner ring teal

7. WHEN user taps accent swatch, THE Theme_System SHALL apply new primary color to all components

8. THE UI_System SHALL display backup button:
   - Label: "Backup Data" 14sp font-semibold
   - Icon: download icon
   - Description: "Export all data to JSON file"

9. WHEN backup button is tapped, THE UI_System SHALL:
   - Export all Isar collections to JSON
   - Save file to device storage
   - Show success message with file path

10. THE UI_System SHALL display restore button:
    - Label: "Restore Data" 14sp font-semibold
    - Icon: upload icon
    - Description: "Import data from backup file"

11. WHEN restore button is tapped, THE UI_System SHALL:
    - Show file picker
    - Parse JSON file
    - Validate data structure
    - Import to Isar database
    - Show success message

12. THE UI_System SHALL display clear data button:
    - Label: "Clear All Data" 14sp font-semibold, text-red
    - Icon: trash icon
    - Description: "Delete all products, sales, and expenses"

13. WHEN clear data button is tapped, THE UI_System SHALL display confirmation dialog with:
    - Warning message: "This will permanently delete all business data. Continue?"
    - Two buttons: Cancel / Confirm Delete (destructive red styling)
    - AND only proceed with deletion if user taps Confirm Delete
    - Delete all Isar records (except license)
    - Show success message

14. THE UI_System SHALL display license info card:
    - Background: white, rounded-2xl, padding 16dp
    - Status: "Active" green or "Expired" red badge
    - Device ID: monospace font with copy button
    - Expiry date: formatted date
    - Renew button: if expired or within 7 days

### Requirement 11: Bottom Navigation System

**User Story:** As a user, I want clear visual feedback on which screen is active, so that I always know my current location in the app.

#### Acceptance Criteria

1. THE Bottom_Nav SHALL display fixed at bottom of screen:
   - Background: white/95 with backdrop blur
   - Border: top 1px gray-200
   - Height: 72dp including safe area padding
   - Shadow: 0 -4px 20px rgba(0,0,0,0.03)

2. THE Bottom_Nav SHALL display 5 tab items:
   - Home: grid icon
   - Sell: calculator/register icon
   - Inventory: package icon
   - Expenses: wallet icon
   - Profile: user icon

3. THE Bottom_Nav SHALL render inactive tabs:
   - Icon: 20dp stroke-1.8, gray-400 color
   - Label: 9sp font-bold uppercase tracking-wide gray-400
   - Touch target: 64dp width minimum
   - Hover: text gray-600 transition

4. THE Bottom_Nav SHALL render active tab with pill indicator:
   - Container: rounded-2xl (or rounded-full), colored bg matching screen
   - Icon: 20dp, white or colored
   - Label: 9sp font-extrabold uppercase, colored text
   - Shadow: shadow-md with color tint
   - Padding: 6dp vertical, 16dp horizontal (for pill shape)

5. THE Bottom_Nav SHALL use color coding for active pills:
   - Home: #05583b (dark teal)
   - Sell: #1b635c (medium teal)
   - Inventory: #126857 (forest green)
   - Expenses: #0a6358 (teal)
   - Profile: #0a6358 (teal)

6. WHEN user taps tab item, THE Navigation_System SHALL:
   - Navigate to corresponding screen
   - Update active pill indicator with animation
   - Preserve state of previous screen

7. WHEN user taps currently active tab, THE Navigation_System SHALL reset screen to default state (scroll to top, clear filters, reload data)

8. THE Bottom_Nav SHALL animate pill transition:
   - Duration: 200ms
   - Curve: easeInOut
   - Effect: scale + background color change

9. THE Bottom_Nav SHALL display badge on tabs:
   - Inventory: red dot if any products have low stock
   - Position: top-right of icon

### Requirement 12: Bilingual Support System

**User Story:** As an Ethiopian merchant, I want to use the app in English or Amharic, so that I can work in my preferred language.

#### Acceptance Criteria

1. THE Bilingual_Strings SHALL define translations for all UI text:
   - Screen titles: HOME, SELL, INVENTORY, EXPENSES, PROFILE
   - Button labels: Save, Cancel, Complete Sale, Add Product, Record Expense
   - Field labels: Name, Price, Quantity, Category, Payment Method
   - Messages: Success, Error, Confirmation prompts
   - Amharic equivalents for all English strings

2. THE Bilingual_Strings SHALL use structured format:
   - Class with static methods: getText(key), getTitle(key)
   - Language parameter from provider: getCurrentLanguage()
   - Fallback to English if translation missing

3. THE UI_System SHALL display Amharic numerals:
   - Western Arabic numerals: 0-9 (default)
   - Ethiopic numerals: option in settings (future)

4. THE UI_System SHALL maintain RTL-aware layouts:
   - Text alignment: start/end instead of left/right
   - Icon positions: mirrored for RTL languages (future Arabic support)

5. WHEN language is switched, THE UI_System SHALL update all visible text immediately without screen refresh

6. THE Bilingual_Strings SHALL handle currency formatting:
   - English: "1,234.56 Birr"
   - Amharic: "1,234.56 ብር"
   - Separator: comma for thousands, period for decimal

7. THE Bilingual_Strings SHALL handle date formatting:
   - English: "Jan 15, 2024" or "2024-01-15"
   - Amharic: "መስከረም 15, 2024" (Ethiopian calendar option in future)

### Requirement 13: Dark Mode System

**User Story:** As a user, I want to use dark mode in low-light environments, so that I can reduce eye strain.

#### Acceptance Criteria

1. WHEN dark mode is enabled, THE Theme_System SHALL apply dark color scheme:
   - Background: #0c1a2f, #081323 (gradient for special cards)
   - Cards: #1c1d1c with #2b2c2b highlights
   - Text: white with 90% opacity, gray-300 for secondary
   - Borders: white/10 or gray-800

2. THE Theme_System SHALL adjust profit card in dark mode:
   - Gradient: darker green shades #0d3f2a → #082b1c
   - Text: maintain white for contrast
   - Watermark: adjust opacity to 0.05

3. THE Theme_System SHALL adjust alert cards in dark mode:
   - Amber alert: darker yellow-900 bg, lighter border
   - Crimson alert: maintain high contrast, adjust gradient
   - Dark alert: lighter gray-800 bg to distinguish from background

4. THE Theme_System SHALL maintain accessibility contrast ratios:
   - Text on background: minimum 4.5:1 for body text
   - Text on colored cards: minimum 3:1 for large text
   - Icons: same contrast as text

5. THE Theme_System SHALL adjust shadows in dark mode:
   - Card shadows: lighter with higher opacity
   - Colored shadows: reduce intensity by 50%

6. THE Bottom_Nav SHALL adapt to dark mode:
   - Background: #1c1d1c/95 with backdrop blur
   - Border: white/10
   - Inactive icons: gray-500
   - Active pills: maintain bright colors for visibility

7. WHEN OS-level dark mode changes, THE Theme_System SHALL override user's explicit preference AND force app theme to match OS setting immediately

### Requirement 14: Animation and Interaction System

**User Story:** As a user, I want smooth animations and responsive feedback, so that the app feels polished and professional.

#### Acceptance Criteria

1. THE UI_System SHALL animate SYNCED indicator dot:
   - Animation: pulsing scale 0.95→1.1 and opacity 0.7→1.0
   - Duration: 2 seconds
   - Loop: infinite
   - Timing: ease-in-out

2. THE UI_System SHALL animate period filter pill selection:
   - Duration: 200ms
   - Effect: background color fade, text color fade
   - Curve: easeOut

3. THE UI_System SHALL animate bottom nav pill indicator:
   - Duration: 250ms
   - Effect: position slide, scale grow
   - Curve: spring with damping 0.8

4. THE UI_System SHALL animate splash screen pagination dots:
   - Stagger: 0.3s delay between dots
   - Effect: opacity pulse, scale pulse
   - Duration: 2s per cycle
   - Loop: infinite

5. THE UI_System SHALL animate cart sheet slide:
   - Entry: slide up from bottom, duration 300ms
   - Exit: slide down to bottom, duration 250ms
   - Curve: easeOut
   - Backdrop: fade in/out, opacity 0→0.5

6. THE UI_System SHALL animate modal dialogs:
   - Entry: scale 0.95→1.0 + fade in, duration 200ms
   - Exit: scale 1.0→0.95 + fade out, duration 150ms
   - Backdrop: fade in/out simultaneously

7. THE UI_System SHALL provide button press feedback:
   - Active state: scale 0.95 or 0.98
   - Duration: 100ms
   - Return: 150ms with easeOut
   - Color: slight darken or opacity change

8. THE UI_System SHALL animate list item additions:
   - New item: slide in from right + fade in
   - Duration: 300ms
   - Curve: easeOut

9. THE UI_System SHALL animate alert card appearances:
   - Entry: slide down from top + fade in
   - Duration: 400ms
   - Delay: 100ms after screen load

10. THE UI_System SHALL display loading states:
    - Spinner: circular indeterminate, primary color
    - Skeleton: shimmer effect on card placeholders
    - Duration: show after 300ms delay, hide immediately when loaded

11. THE UI_System SHALL animate success/error messages:
    - Snackbar: slide up from bottom, duration 300ms
    - Display: 3 seconds
    - Exit: slide down or fade out, duration 250ms

### Requirement 15: Data Integration and State Management

**User Story:** As a developer, I want robust state management connecting UI to backend, so that the app displays real-time accurate business data.

#### Acceptance Criteria

1. THE UI_System SHALL use Riverpod providers for state management:
   - ProfitProvider: net profit calculation and period filtering
   - CartProvider: shopping cart state and checkout flow
   - InventoryProvider: product CRUD and filtering
   - ExpenseProvider: expense tracking and categorization
   - ThemeProvider: dark mode and language settings

2. THE ProfitProvider SHALL expose state:
   - netProfit: double (calculated for selected period)
   - revenue: double (sum of sales)
   - expenses: double (sum of OpEx only)
   - grossProfit: double (revenue - COGS)
   - selectedPeriod: enum (Today, Week, Month)
   - isLoading: bool

3. WHEN selectedPeriod changes, THE ProfitProvider SHALL:
   - Query Isar for sales in date range
   - Calculate COGS using WAC for each sale item
   - Query expenses excluding Restock category
   - Emit new state with updated values
   - Notify all listeners (profit card, metrics cards)

4. THE CartProvider SHALL expose state:
   - items: List<CartItem> (product, quantity, unit price)
   - total: double (sum of line totals)
   - paymentMethod: enum (Cash, Telebirr, CBEBirr, AmharaBank)
   - amountReceived: double?
   - change: double? (calculated)

5. WHEN item is added to cart, THE CartProvider SHALL:
   - Check if product already in cart
   - If yes: increment quantity (max = available stock)
   - If no: add new CartItem
   - Recalculate total
   - Notify listeners to update UI

6. WHEN checkout is completed, THE CartProvider SHALL:
   - Create Sale record with timestamp, items, payment method, total
   - For each cart item: decrement product stock in Isar
   - Clear cart state
   - Emit success event for UI navigation

7. THE InventoryProvider SHALL expose state:
   - products: List<Product> (filtered list)
   - lowStockCount: int (products where stock <= threshold)
   - searchQuery: String
   - selectedFilter: enum (All, NeedsAttention, OutOfStock)
   - isLoading: bool

8. WHEN restock is performed, THE InventoryProvider SHALL:
   - Read current product stock and WAC
   - Calculate new WAC: (oldStock × oldWAC + newQty × newCost) / (oldStock + newQty)
   - Update product with new stock and WAC
   - Create RestockLog record
   - Emit updated product list
   - If stock was low, remove from alerts

9. THE ExpenseProvider SHALL expose state:
   - expenses: List<Expense> (sorted by date descending)
   - totalSpent: double (sum of all amounts)
   - largestCategory: String (category with highest total)
   - selectedCategory: enum (Rent, Salary, Transport, etc.)

10. WHEN expense is recorded, THE ExpenseProvider SHALL:
    - Create Expense record in Isar
    - Update totalSpent
    - Re-sort expense list
    - Emit new state
    - Notify ProfitProvider to recalculate net profit

11. THE ThemeProvider SHALL expose state:
    - isDarkMode: bool
    - currentLanguage: enum (English, Amharic)
    - accentColor: Color

12. WHEN theme setting changes, THE ThemeProvider SHALL:
    - Save preference to SharedPreferences
    - Emit new state
    - Trigger MaterialApp theme rebuild

13. THE UI_System SHALL display loading indicators:
    - Show shimmer skeletons for card placeholders
    - Display spinner for long operations (> 300ms)
    - Disable buttons during processing

14. THE UI_System SHALL handle empty states:
    - No products: show illustration + "Add your first product" message
    - No sales: show "No transactions yet" in home activity section
    - No expenses: show "Record your first expense" message

15. THE UI_System SHALL handle error states:
    - Database errors: show error snackbar with retry option
    - Validation errors: highlight fields with red border + message
    - Network errors: not applicable (offline-first app)

### Requirement 16: Responsive Layout System

**User Story:** As a user, I want the app to work well on different phone sizes, so that I have a consistent experience regardless of device.

#### Acceptance Criteria

1. THE UI_System SHALL constrain maximum width:
   - Container: max-width 448dp (md breakpoint)
   - Centered: mx-auto (horizontal center)
   - Full height: min-height 100vh

2. THE UI_System SHALL apply safe area insets:
   - Top: padding for status bar (iOS notch, Android status bar)
   - Bottom: padding for gesture bar (iOS) or navigation bar (Android)
   - Left/Right: padding for curved edges if needed

3. THE UI_System SHALL use flexible layouts:
   - Grids: percentage-based columns (50%, 33%, 25%)
   - Spacing: dp units, not px
   - Font sizes: sp units for accessibility

4. THE UI_System SHALL adapt to different screen heights:
   - Short screens: reduce padding, make content scrollable
   - Tall screens: maintain spacing, add bottom padding
   - Modals: max 90% screen height with scroll

5. WHEN keyboard appears, THE UI_System SHALL resize layout AND scroll content to ensure focused input field remains visible 16dp above keyboard top edge

6. THE UI_System SHALL use responsive font scaling:
   - Support system font size settings
   - Minimum: 10sp for small labels
   - Maximum: 48sp for large amounts
   - Test range: 0.85x to 1.5x scale factor

7. THE Bottom_Nav SHALL adapt to screen width:
   - Narrow (< 360dp): icon only, smaller touch targets
   - Standard (360-448dp): icon + label as designed
   - Wide (> 448dp): maintain max-width constraint

### Requirement 17: Performance and Optimization

**User Story:** As a user, I want the app to be fast and responsive, so that I can complete tasks quickly during busy periods.

#### Acceptance Criteria

1. THE UI_System SHALL render screens within performance targets:
   - Initial render: < 300ms for splash screen
   - Navigation: < 100ms frame time for page transitions
   - List scrolling: 60fps with no jank
   - Product grid: < 500ms to render 50+ items

2. THE UI_System SHALL use efficient list rendering:
   - ListView.builder for product lists (lazy loading)
   - GridView.builder for product grids (viewport-based rendering)
   - Cached item heights when possible

3. THE UI_System SHALL optimize image loading:
   - Thumbnails: resize to display dimensions
   - Cache: in-memory cache for recently viewed images
   - Placeholders: show colored box while loading

4. THE UI_System SHALL optimize database queries:
   - Index: create indexes on Product.name, Sale.timestamp, Expense.category
   - Batch: use Isar batch operations for multi-record updates
   - Stream: use Isar watchers for real-time updates

5. THE UI_System SHALL minimize rebuilds:
   - Use const constructors for static widgets
   - Split large widgets into smaller focused widgets
   - Use Riverpod select for granular state listening

6. THE UI_System SHALL lazy-load data:
   - Home screen: load only today's data initially
   - Profile screen: load reports only when tab selected
   - Expense list: paginate if > 100 records

### Requirement 18: Accessibility Compliance

**User Story:** As a user with accessibility needs, I want the app to work with screen readers and support large text, so that I can use it independently.

#### Acceptance Criteria

1. THE UI_System SHALL provide semantic labels:
   - All buttons: aria-label or tooltip
   - All icons: semantic meaning via labels
   - All images: alt text descriptions
   - All form fields: labels associated with inputs

2. THE UI_System SHALL support screen readers:
   - Reading order: logical top-to-bottom flow
   - Focus order: matches visual layout
   - Announcements: for success/error messages
   - Hints: for complex interactions (e.g., "double tap to edit")

3. THE UI_System SHALL provide sufficient touch targets:
   - Minimum: 44dp × 44dp for all interactive elements
   - Spacing: 8dp minimum between adjacent targets
   - Buttons: 48dp height recommended

4. THE UI_System SHALL support large text:
   - Scale: respect system font size settings
   - Layout: reflow text, no truncation at 200% scale
   - Buttons: grow to fit text, maintain minimum height

5. THE UI_System SHALL provide visual focus indicators:
   - Keyboard: visible focus ring on focused element
   - Color: high contrast against background
   - Width: 2dp border or equivalent

6. THE UI_System SHALL support reduced motion:
   - Detect: system reduced motion setting
   - Animations: disable decorative animations if set
   - Transitions: use instant or fade instead of scale/slide

### Requirement 19: Data Model Integration

**User Story:** As a developer, I want comprehensive data models with proper relationships and business logic, so that the UI can display accurate real-time business data.

#### Acceptance Criteria

1. THE ProductModel SHALL define inventory structure in Isar:
   - `id`: Id auto-increment primary key
   - `name`: String, indexed (IndexType.value) for fast search
   - `description`: String? optional
   - `barcode`: String? optional, indexed for scanner lookup
   - `sellingPrice`: double, retail price per unit
   - `costPrice`: double, Weighted Average Cost (WAC)
   - `currentStock`: int, available quantity
   - `lowStockThreshold`: int, default 10
   - `category`: String? optional grouping
   - `imageUrl`: String? optional local file path
   - `createdAt`: DateTime audit timestamp
   - `updatedAt`: DateTime last modification
   - `isDeleted`: bool, indexed for soft delete filtering

2. THE ProductModel SHALL provide computed properties:
   - `isLowStock`: bool, returns `currentStock <= lowStockThreshold && currentStock > 0`
   - `isOutOfStock`: bool, returns `currentStock <= 0`
   - `liquidityValue`: double, returns `currentStock * sellingPrice` (potential cash if all sold)
   - `inventoryValue`: double, returns `currentStock * costPrice` (capital invested)
   - `potentialProfit`: double, returns `liquidityValue - inventoryValue`
   - `profitMargin`: double, returns `(sellingPrice - costPrice) / sellingPrice` or 0 if sellingPrice = 0

3. THE ProductModel SHALL provide copyWith method:
   - Accept optional parameters for all mutable fields
   - Preserve `id` and `createdAt`
   - Update `updatedAt` to `DateTime.now()` by default
   - Return new ProductModel instance with updated fields

4. THE ProductModel SHALL provide JSON serialization:
   - `toJson()`: convert all fields to Map<String, dynamic>
   - `fromJson()`: construct ProductModel from Map<String, dynamic>
   - DateTime fields: serialize to ISO 8601 string format
   - Handle null fields gracefully with default values

5. THE SaleModel SHALL define transaction structure in Isar:
   - `id`: Id auto-increment primary key
   - `saleDate`: DateTime, indexed for date range queries
   - `transactionId`: String, UUID for unique identification
   - `lineItems`: List<SaleLineItem> embedded line items
   - `totalAmount`: double, revenue (sum of line totals)
   - `totalCost`: double, COGS (sum of line costs using WAC)
   - `grossProfit`: double, totalAmount - totalCost
   - `paymentMethod`: PaymentMethod enum (cash, telebirr, cbeBirr, amharaBank, mixed)
   - `amountReceived`: double? optional
   - `changeGiven`: double? optional
   - `notes`: String? optional transaction notes
   - `cashierName`: String? optional clerk identifier
   - `createdAt`: DateTime audit timestamp
   - `isVoided`: bool, default false, marks cancelled transactions
   - `voidedAt`: DateTime? timestamp when voided

6. THE SaleLineItem SHALL define embedded item structure:
   - `productId`: int, reference to Product.id
   - `productName`: String, snapshot for historical records
   - `quantity`: int, units sold
   - `unitPrice`: double, selling price used in this transaction
   - `unitCost`: double, WAC at time of sale (historical cost)
   - `lineTotal`: double, quantity × unitPrice
   - `lineCost`: double, quantity × unitCost
   - `lineProfit`: double, lineTotal - lineCost

7. THE PaymentMethod enum SHALL define payment types:
   - `cash`: Cash payment
   - `telebirr`: TeleBirr mobile payment
   - `cbeBirr`: Commercial Bank of Ethiopia Birr
   - `amharaBank`: Amhara Bank payment
   - `mixed`: Multiple payment methods used

8. THE ExpenseModel SHALL define expense structure in Isar:
   - `id`: Id auto-increment primary key
   - `title`: String, expense name/description
   - `description`: String? optional detailed notes
   - `amount`: double, expense amount in Birr
   - `category`: ExpenseCategory enum, indexed for filtering
   - `expenseDate`: DateTime, indexed for date range queries
   - `createdAt`: DateTime audit timestamp
   - `receiptImageUrl`: String? optional photo of receipt
   - `notes`: String? optional additional information
   - `isRestockExpense`: bool, default false, CRITICAL flag for profit calculation
   - `isDeleted`: bool, soft delete flag

9. THE ExpenseCategory enum SHALL define expense types:
   - `rent`: Rent/lease payments (OpEx)
   - `salary`: Employee wages (OpEx)
   - `transport`: Transportation costs (OpEx)
   - `utilities`: Electricity, water, internet (OpEx)
   - `airtime`: Phone/mobile airtime (OpEx)
   - `supplies`: Office supplies, consumables (OpEx)
   - `restock`: Inventory restocking (CapEx - excluded from OpEx)
   - `other`: Miscellaneous expenses

10. THE ExpenseCategoryExtension SHALL provide bilingual labels:
    - `displayName`: English category name (e.g., "Rent", "Salary")
    - `displayNameAmharic`: Amharic category name (e.g., "ኪራይ", "ደሞዝ")

11. THE Profit_Engine SHALL exclude restock expenses from OpEx:
    - WHEN calculating operating expenses, THE query SHALL filter `WHERE isRestockExpense = false`
    - WHEN category = restock, THE isRestockExpense SHALL be set true automatically
    - Restock expenses represent CapEx (capital conversion: cash → inventory)
    - Only non-restock expenses reduce net profit

12. THE UserProfileModel SHALL define user configuration:
    - `id`: Id auto-increment primary key
    - `businessName`: String, merchant store name
    - `ownerName`: String, proprietor name
    - `phone`: String? optional contact number
    - `telebirr`: String? optional TeleBirr account
    - `bankAccount`: String? optional bank account number
    - `bankName`: String? optional bank institution name
    - `passwordHash`: String, bcrypt or argon2 hashed password
    - `isDemoMode`: bool, demo vs production mode flag
    - `preferredLanguage`: String, "en" or "am"
    - `isDarkMode`: bool, theme preference
    - `accentColor`: int, custom theme color value
    - `createdAt`: DateTime registration timestamp
    - `updatedAt`: DateTime last modification

13. THE LicenseModel SHALL define activation structure:
    - `id`: Id auto-increment primary key
    - `deviceId`: String, persistent hardware fingerprint
    - `activationKey`: String, cryptographically signed license key
    - `licenseType`: LicenseType enum (monthly, lifetime)
    - `activatedAt`: DateTime activation timestamp
    - `expiryDate`: DateTime license expiration
    - `isActive`: bool, computed property checking expiry < now
    - `lastVerified`: DateTime last verification check

14. THE RestockLogModel SHALL define restock audit trail:
    - `id`: Id auto-increment primary key
    - `productId`: int, reference to Product.id
    - `productName`: String, snapshot
    - `quantityAdded`: int, units restocked
    - `costPerUnit`: double, new purchase price
    - `totalCost`: double, quantityAdded × costPerUnit
    - `oldWAC`: double, WAC before restock
    - `newWAC`: double, WAC after restock calculation
    - `oldStock`: int, stock before restock
    - `newStock`: int, stock after restock
    - `restockedAt`: DateTime timestamp
    - `createdBy`: String? optional user identifier

15. THE Isar database SHALL define indexes for performance:
    - Product: index on `name`, `barcode`, `isDeleted`
    - Sale: index on `saleDate` for date range queries
    - Expense: index on `category`, `expenseDate`, `isDeleted`
    - All timestamps: indexed for date filtering and sorting

16. THE UI_System SHALL use Isar watchers for real-time updates:
    - `productCollection.watchLazy()`: trigger UI rebuild when products change
    - `saleCollection.watchLazy()`: trigger profit card update when sales recorded
    - `expenseCollection.watchLazy()`: trigger profit card update when expenses recorded
    - Stream-based reactivity for live data synchronization

17. THE UI_System SHALL implement soft delete for all records:
    - Delete operations set `isDeleted = true`, preserve data
    - Queries filter `WHERE isDeleted = false` by default
    - Admin restore function can toggle `isDeleted` back to false
    - Hard delete only for data export/backup cleanup

18. THE UI_System SHALL implement JSON backup export:
    - Export all collections: Products, Sales, Expenses, RestockLogs, UserProfile, License
    - Format: `{ "version": "1.0", "exportedAt": "ISO8601", "collections": { ... } }`
    - File name: `efoy_backup_YYYYMMDD_HHMMSS.json`
    - Save to device storage with file_picker package

19. THE UI_System SHALL implement JSON backup restore:
    - Validate JSON structure and version
    - Show confirmation dialog: "This will replace all existing data. Continue?"
    - Clear all collections (except License if valid)
    - Import records using batch operations for performance
    - Update UI with success/error message

20. THE UI_System SHALL validate data integrity on restore:
    - Check required fields are present
    - Validate data types match model definitions
    - Verify foreign key references (e.g., SaleLineItem.productId exists)
    - Skip invalid records, log warnings, continue import

### Requirement 20: Service Integration and Business Logic

**User Story:** As a developer, I want robust business logic services integrated with the UI, so that calculations are accurate and consistent across the application.

#### Acceptance Criteria

1. THE DeviceIdentity service SHALL provide hardware identification:
   - `getDeviceId()`: returns String, persistent hardware fingerprint combining device identifiers
   - `getDeviceInfo()`: returns DeviceInfo object with platform, model, manufacturer, version
   - Implementation: use device_info_plus package
   - Persistence: store generated ID in secure storage
   - Privacy: no PII included, deterministic hash of hardware identifiers

2. THE DeviceInfo data class SHALL contain device metadata:
   - `platform`: String ("Android", "iOS", "Web", "Windows", "macOS", "Linux")
   - `model`: String (device model, e.g., "SM-G991B", "iPhone 13 Pro")
   - `manufacturer`: String (e.g., "Samsung", "Apple", "Google")
   - `version`: String (OS version, e.g., "Android 13", "iOS 16.5")

3. THE LicenseVerifier service SHALL provide offline license validation:
   - `generateLicenseKey(deviceId, expiryDate)`: returns String, cryptographically signed key
   - `verifyLicense(licenseKey, deviceId)`: returns LicenseVerificationResult
   - Signature algorithm: HMAC-SHA256 or RSA for tamper detection
   - No internet required: all verification local
   - Device binding: key only valid for specific deviceId

4. THE LicenseVerificationResult SHALL contain validation outcome:
   - `isValid`: bool, true if key is authentic and not expired
   - `errorMessage`: String?, descriptive error for invalid keys
   - `expiryDate`: DateTime?, parsed expiry from valid keys
   - `licenseType`: LicenseType?, parsed type from valid keys

5. THE LicenseVerifier SHALL validate license key format:
   - Expected format: base64 encoded signed payload
   - Payload contains: deviceId, expiryDate, licenseType, signature
   - Validation checks:
     - Signature verification (authentic, not tampered)
     - Device ID match (key for this device only)
     - Expiry date check (not expired)
     - Format validation (well-formed)

6. THE WACCalculator service SHALL provide inventory valuation functions:
   - `calculateNewWAC(currentStock, currentCost, addedQuantity, purchasePrice)`: returns double
   - Formula: `(currentStock × currentCost + addedQuantity × purchasePrice) / (currentStock + addedQuantity)`
   - Edge case: if currentStock = 0, return purchasePrice (first purchase)
   - Edge case: if addedQuantity = 0, return currentCost (no change)

7. THE WACCalculator SHALL provide inventory value calculation:
   - `calculateInventoryValue(quantity, wac)`: returns double
   - Formula: `quantity × wac`
   - Represents total capital invested in current stock

8. THE WACCalculator SHALL provide profit margin calculation:
   - `calculateProfitMargin(sellingPrice, wac)`: returns double
   - Formula: `(sellingPrice - wac) / sellingPrice`
   - Returns 0 if sellingPrice = 0
   - Result: decimal between 0 and 1 (e.g., 0.25 = 25% margin)

9. THE WACCalculator SHALL provide gross profit calculation:
   - `calculateGrossProfit(quantity, sellingPrice, wac)`: returns double
   - Formula: `(quantity × sellingPrice) - (quantity × wac)`
   - Represents profit from a sale before operating expenses

10. THE WACCalculator SHALL provide COGS calculation:
    - `calculateCOGS(quantity, wac)`: returns double
    - Formula: `quantity × wac`
    - Cost of Goods Sold for a transaction

11. THE WACCalculator SHALL provide recommended price calculation:
    - `calculateRecommendedPrice(wac, desiredMargin)`: returns double
    - Formula: `wac / (1 - desiredMargin)`
    - Throws ArgumentError if desiredMargin >= 1.0 or < 0
    - Example: WAC = 100, margin = 0.30 → price = 142.86

12. THE WACCalculator SHALL provide liquidity value calculation:
    - `calculateLiquidityValue(quantity, sellingPrice)`: returns double
    - Formula: `quantity × sellingPrice`
    - Potential revenue if all stock sold at current price

13. THE WACCalculator SHALL provide break-even quantity calculation:
    - `calculateBreakEvenQuantity(fixedCosts, sellingPrice, wac)`: returns int
    - Formula: `ceil(fixedCosts / (sellingPrice - wac))`
    - Returns -1 if contributionMargin <= 0 (can't break even)
    - Units needed to recover fixed costs

14. THE ProfitEngine service SHALL provide gross profit calculation:
    - `calculateGrossProfit(revenue, cogs)`: returns double
    - Formula: `revenue - cogs`
    - Profit before operating expenses

15. THE ProfitEngine service SHALL provide net profit calculation:
    - `calculateNetProfit(grossProfit, operatingExpenses)`: returns double
    - Formula: `grossProfit - operatingExpenses`
    - CRITICAL: operatingExpenses MUST exclude restock expenses (CapEx)
    - Final profit after all operating costs

16. THE ProfitEngine service SHALL provide gross profit margin calculation:
    - `calculateGrossProfitMargin(grossProfit, revenue)`: returns double
    - Formula: `grossProfit / revenue`
    - Returns 0 if revenue = 0
    - Result: decimal between 0 and 1

17. THE ProfitEngine service SHALL provide net profit margin calculation:
    - `calculateNetProfitMargin(netProfit, revenue)`: returns double
    - Formula: `netProfit / revenue`
    - Returns 0 if revenue = 0
    - Indicates percentage of revenue that becomes profit

18. THE ProfitEngine service SHALL provide OpEx ratio calculation:
    - `calculateOpExRatio(operatingExpenses, revenue)`: returns double
    - Formula: `operatingExpenses / revenue`
    - Returns 0 if revenue = 0
    - Lower is better (less overhead)

19. THE ProfitEngine service SHALL provide ROI calculation:
    - `calculateROI(netProfit, totalInvestment)`: returns double
    - Formula: `netProfit / totalInvestment`
    - Returns 0 if totalInvestment = 0
    - totalInvestment = current inventory value

20. THE ProfitEngine service SHALL provide comprehensive financial summary:
    - `calculateFinancialSummary(revenue, cogs, operatingExpenses, inventoryValue)`: returns FinancialSummary
    - Calls all calculation methods internally
    - Returns data class with all metrics

21. THE FinancialSummary data class SHALL contain:
    - `revenue`: double
    - `cogs`: double
    - `grossProfit`: double
    - `operatingExpenses`: double
    - `netProfit`: double
    - `grossMargin`: double
    - `netMargin`: double
    - `opExRatio`: double
    - `roi`: double
    - `inventoryValue`: double

22. THE ProfitEngine service SHALL provide profit health analysis:
    - `analyzeProfitHealth(netProfit, grossMargin, opExRatio)`: returns ProfitHealthStatus
    - Returns status, message, recommendation based on thresholds

23. THE ProfitHealthStatus data class SHALL contain:
    - `status`: HealthStatus enum (critical, warning, moderate, healthy)
    - `message`: String, human-readable status description
    - `recommendation`: String, actionable advice for merchant

24. THE ProfitEngine SHALL determine health status by rules:
    - CRITICAL: netProfit < 0 → "Business is losing money"
    - WARNING: grossMargin < 0.20 → "Profit margin below 20%"
    - WARNING: opExRatio > 0.40 → "Operating expenses over 40% of revenue"
    - HEALTHY: grossMargin >= 0.30 AND opExRatio <= 0.30 → "Business performing well"
    - MODERATE: default → "Profitable but room for improvement"

25. THE UI_System SHALL call ProfitEngine for all financial displays:
    - Profit card: calculateFinancialSummary for selected period
    - Profile metrics: individual calculation methods
    - Decision insights: analyzeProfitHealth for recommendations

26. THE UI_System SHALL call WACCalculator for inventory operations:
    - Restock flow: calculateNewWAC with old and new values
    - Product card: calculateProfitMargin for display
    - Inventory value: calculateInventoryValue for total capital
    - Pricing suggestions: calculateRecommendedPrice for markup guidance

### Requirement 21: Testing and Quality Assurance

**User Story:** As a developer, I want comprehensive tests verifying UI correctness and business logic, so that I can confidently deploy updates without regressions.

#### Acceptance Criteria

1. THE UI_System SHALL include widget tests for each screen:
   - Rendering: verify all key widgets render without error
   - Interactions: tap buttons, input text, verify callbacks
   - States: test loading, error, empty, and success states

2. THE UI_System SHALL include golden tests for visual regression:
   - Screenshots: capture each screen in light and dark mode
   - Comparison: fail on pixel differences > threshold
   - Coverage: all screens, modals, and key states

3. THE UI_System SHALL include integration tests for user flows:
   - Flow 1: Splash → Auth → Home
   - Flow 2: Add product → View inventory → Restock
   - Flow 3: Select products → Checkout → Complete sale
   - Flow 4: Record expense → View profile reports

4. THE UI_System SHALL include accessibility tests:
   - Guideline scan: run automated accessibility checker
   - Screen reader: manual test with TalkBack/VoiceOver
   - Large text: test at 200% font scale
   - Color contrast: verify all text meets WCAG AA

5. THE UI_System SHALL include performance tests:
   - Benchmark: measure frame render time for scrolling
   - Memory: verify no leaks after 1000 screen navigations
   - Database: test query performance with 10,000 records

6. THE UI_System SHALL include tests for data integration:
   - Providers: unit tests for state management logic
   - Database: integration tests for Isar queries
   - Calculations: property-based tests for WAC and profit engine

7. THE WACCalculator SHALL include property-based tests:
   - Property: calculateNewWAC always returns non-negative value
   - Property: WAC with zero quantity added equals old WAC
   - Property: WAC with zero existing stock equals new purchase price
   - Property: calculateInventoryValue(n, wac) = n × wac for all n >= 0
   - Property: calculateProfitMargin always between 0 and 1

8. THE ProfitEngine SHALL include property-based tests:
   - Property: grossProfit = revenue - cogs for all inputs
   - Property: netProfit = grossProfit - opex for all inputs
   - Property: calculateGrossProfitMargin always between 0 and 1
   - Property: calculateNetProfitMargin always between -∞ and 1
   - Property: analyzeProfitHealth returns valid HealthStatus

9. THE CartProvider SHALL include unit tests:
   - Test: addItem increases cart item count
   - Test: incrementQuantity respects stock limit
   - Test: removeItem decrements total correctly
   - Test: clearCart resets to empty state
   - Test: checkout creates Sale and updates stock

10. THE InventoryProvider SHALL include unit tests:
    - Test: restock increases stock and recalculates WAC
    - Test: search filter matches product names case-insensitive
    - Test: low stock alert includes products below threshold
    - Test: delete marks isDeleted without removing record

### Requirement 22: Transaction Void and Reversal Flow

**User Story:** As a merchant, I want to void incorrect sales transactions and restore inventory, so that I can correct mistakes without manual stock adjustments.

#### Acceptance Criteria

1. THE UI_System SHALL display void button in sale detail view:
   - Location: sale detail screen accessed from transaction history
   - Style: outlined button, red text, "Void Transaction" label
   - Icon: block/cancel icon, red color
   - Visible: only if sale is not already voided

2. WHEN void button is tapped, THE UI_System SHALL display confirmation dialog:
   - Title: "Void Transaction?" 18sp font-bold
   - Message: "This will restore inventory and recalculate profit. This action cannot be undone."
   - Warning: red alert icon
   - Amount: display sale totalAmount for reference
   - Buttons: "Cancel" (secondary) / "Void Transaction" (destructive red)

3. WHEN void is confirmed, THE CartProvider SHALL execute atomic transaction:
   - Start Isar write transaction
   - Load Sale record by ID
   - Verify sale is not already voided
   - For each SaleLineItem:
     - Load Product by productId
     - Restore stock: `product.currentStock += lineItem.quantity`
     - Update `product.updatedAt = DateTime.now()`
     - Save Product
   - Update Sale record:
     - Set `isVoided = true`
     - Set `voidedAt = DateTime.now()`
     - Keep all original data for audit trail
   - Commit transaction

4. WHEN void transaction succeeds, THE UI_System SHALL:
   - Display success snackbar: "Transaction voided - Inventory restored"
   - Navigate back to transaction history
   - Notify ProfitProvider via Isar watcher (recalculate excluding voided sale)
   - Update home screen profit card in real-time

5. WHEN void transaction fails partway through, THE CartProvider SHALL roll back all changes atomically (sale remains isVoided=false, stock unchanged) AND display error message "Void failed - no changes made"

6. THE ProfitProvider SHALL exclude voided sales from calculations:
   - Query: `saleCollection.filter().isVoidedEqualTo(false).findAll()`
   - Revenue: sum of totalAmount WHERE isVoided = false
   - COGS: sum of totalCost WHERE isVoided = false
   - All profit calculations use filtered query

7. THE UI_System SHALL display voided status in transaction history:
   - Badge: "VOIDED" red background, white text, uppercase font-black
   - Strike-through: apply to amount display
   - Timestamp: show voidedAt date below original saleDate
   - Grayed out: reduce opacity to 0.6 for entire row

8. THE UI_System SHALL prevent double-void:
   - Check `sale.isVoided` before showing void button
   - If already voided: hide void button, show "Transaction Voided" message
   - Display void timestamp for reference

9. THE UI_System SHALL track void audit trail:
   - RestockLog: create entry for each voided line item restoration
   - Reason: "Void Transaction #[transactionId]"
   - Include original sale date and void date

### Requirement 23: UI State Management and Feedback

**User Story:** As a user, I want clear visual feedback for loading, success, error, and empty states, so that I always understand what the app is doing.

#### Acceptance Criteria

1. THE UI_System SHALL display loading states consistently:
   - Shimmer placeholders: for card lists (products, sales, expenses)
   - Shimmer style: animated gradient gray-200 → gray-100, 1.5s duration
   - Circular progress: for button actions (e.g., complete sale, save product)
   - Circular progress size: 20dp for buttons, 32dp for full-screen
   - Color: teal primary color
   - Minimum display: 300ms to avoid flicker

2. THE UI_System SHALL display empty states with illustrations:
   - No products: illustration + "Add your first product" message + CTA button
   - No sales: illustration + "No transactions yet - Tap SELL to start" message
   - No expenses: illustration + "Record your first expense" message + CTA button
   - Style: centered, gray-400 text 14sp, 24dp vertical spacing
   - Illustration: 120dp square, gray-300 color, simple line art

3. THE UI_System SHALL display error states with retry actions:
   - Database errors: red alert box + "Failed to load data" + "Retry" button
   - Validation errors: inline red text below field + red border on field
   - Network errors: not applicable (offline-first app)
   - Style: error box with red-50 background, red-700 text, rounded-xl

4. THE UI_System SHALL display success feedback immediately:
   - Snackbars: slide up from bottom, 3s duration, auto-dismiss
   - Style: green-600 background, white text, rounded-xl, shadow-lg
   - Position: bottom center, 16dp from edge
   - Content: icon (checkmark) + message
   - Examples: "Product added", "Sale completed", "Expense recorded"

5. THE UI_System SHALL implement optimistic UI updates:
   - Cart: immediately show item added before database save
   - Stock: immediately decrement display after sale
   - Expense: immediately add to list before database commit
   - Rollback: if database fails, revert UI and show error

6. THE UI_System SHALL use skeleton loaders for initial screen load:
   - Home screen: profit card skeleton + 2 metric card skeletons + 3 alert card skeletons
   - Inventory: 6 product card skeletons in grid
   - Profile: identity card skeleton + 4 metric card skeletons
   - Duration: show until data loaded, minimum 200ms

7. THE UI_System SHALL display inline validation feedback:
   - Valid field: green checkmark icon right side
   - Invalid field: red X icon right side + error message below
   - Validating: spinner icon right side (e.g., checking barcode uniqueness)
   - Update: real-time as user types (300ms debounce)

8. THE UI_System SHALL display progress indicators for multi-step flows:
   - Onboarding: step indicators "Step 1 of 3", "Step 2 of 3", etc.
   - Visual: dots or progress bar, teal active, gray inactive
   - Current step: bold font, larger size
   - Completed steps: checkmark icon

9. THE UI_System SHALL implement pull-to-refresh:
   - Screens: home, inventory, expenses, profile
   - Action: swipe down from top to refresh data
   - Indicator: circular progress, teal color, iOS-style
   - Behavior: reload from Isar database, update UI

10. THE UI_System SHALL defer network status indicators until actual network features are implemented:
    - Note: Network status indicators deferred until actual network features implemented. Current implementation is offline-only.
    - Future implementation: small banner at top when offline, gray-600 background, white text, "Offline Mode" message + sync icon

11. THE UI_System SHALL implement focus management:
    - Auto-focus: first input field when modal opens
    - Tab order: logical top-to-bottom, left-to-right
    - Keyboard submit: pressing enter submits form
    - Focus indicator: 2dp teal border on focused field

12. THE UI_System SHALL provide haptic feedback (mobile):
    - Success: light impact on sale complete, expense recorded
    - Error: medium impact on validation failure
    - Selection: light impact on tab switch, filter selection
    - Long press: medium impact on hold order button

### Requirement 24: Backup and Restore Integration

**User Story:** As a merchant, I want to backup my business data and restore it if needed, so that I can protect against data loss and migrate to new devices.

#### Acceptance Criteria

1. THE UI_System SHALL display backup section in settings:
   - Section header: "Data Management" 16sp font-bold gray-900
   - Card: white background, rounded-2xl, padding 16dp

2. THE UI_System SHALL display backup button:
   - Label: "Backup Data" 14sp font-semibold gray-900
   - Icon: download icon, teal color, 20dp
   - Description: "Export all data to JSON file" 12sp gray-600
   - Style: outlined button, teal border
   - Full width in card

3. WHEN backup button is tapped, THE UI_System SHALL:
   - Show loading indicator: "Preparing backup..."
   - Call BackupService.exportBackup()
   - Generate filename: `efoy_backup_YYYYMMDD_HHMMSS.json`
   - Save to device storage using file_picker

4. THE BackupService SHALL export all Isar collections:
   - Collections: Product, Sale, Expense, RestockLog, UserProfile, License
   - Format: JSON with structure:
     ```json
     {
       "version": "1.0",
       "exportedAt": "2024-01-15T10:30:00.000Z",
       "deviceId": "abc123...",
       "collections": {
         "products": [...],
         "sales": [...],
         "expenses": [...],
         "restockLogs": [...],
         "userProfile": {...},
         "license": {...}
       }
     }
     ```
   - Use model toJson() methods for serialization
   - Include all fields, including soft-deleted records

5. WHEN backup completes successfully, THE UI_System SHALL:
   - Show success snackbar: "Backup saved to [path]"
   - Provide share option: share JSON file via system share sheet
   - Log backup event with timestamp

6. WHEN backup fails, THE UI_System SHALL:
   - Show error snackbar: "Backup failed. Please try again."
   - Log error with details for debugging

7. THE UI_System SHALL display restore button:
   - Label: "Restore Data" 14sp font-semibold gray-900
   - Icon: upload icon, orange color, 20dp
   - Description: "Import data from backup file" 12sp gray-600
   - Style: outlined button, orange border
   - Full width in card

8. WHEN restore button is tapped, THE UI_System SHALL:
   - Show file picker: filter .json files only
   - Allow user to select backup file
   - Read file contents

9. WHEN backup file is selected, THE UI_System SHALL validate:
   - File format: valid JSON structure
   - Version: check "version" field matches supported versions
   - Required fields: verify "collections" object exists
   - Data integrity: check required fields in each record

10. WHEN validation passes, THE UI_System SHALL show confirmation dialog:
    - Title: "Restore Backup?" 18sp font-bold
    - Warning: "⚠️ This will replace ALL existing data"
    - Details: show exportedAt date, record counts per collection
    - Buttons: "Cancel" / "Restore" (destructive red)

11. WHEN restore is confirmed, THE BackupService SHALL execute:
    - Start Isar write transaction
    - Delete all existing records: `collection.clear()`
    - Exception: keep License if currently valid and deviceId matches
    - Import collections in order: UserProfile, Product, Sale, Expense, RestockLog
    - Use model fromJson() methods for deserialization
    - Batch operations for performance (100 records per batch)
    - Commit transaction

12. WHEN restore succeeds, THE UI_System SHALL:
    - Dismiss dialog
    - Show success snackbar: "Data restored - [n] products, [n] sales"
    - Navigate to home screen
    - Force refresh all providers
    - Show restart prompt if needed

13. WHEN restore encounters error during import, THE UI_System SHALL roll back all imported records atomically AND display error message with details AND preserve existing database state unchanged

14. THE BackupService SHALL handle restore errors gracefully:
    - Skip invalid records: log warning, continue with next
    - Foreign key issues: create placeholder if reference missing
    - Duplicate IDs: auto-generate new IDs
    - Data type mismatches: use default values
    - Critical errors: trigger full rollback per criterion 13

15. WHEN restore is initiated, THE UI_System SHALL display warning dialog "Restoring will overwrite all current data. Existing sales, products, and expenses will be replaced. Continue?" AND require explicit confirmation

16. THE UI_System SHALL display restore warnings:
    - License mismatch: "Backup from different device. License may not work."
    - Old version: "Backup from older version. Some features may not import."
    - Partial success: "[n] records imported, [m] skipped due to errors"

17. THE BackupService SHALL preserve data relationships:
   - SaleLineItem.productId: verify Product exists, create if missing
   - RestockLog.productId: verify Product exists
   - Expense.category: validate enum value
   - DateTime fields: parse ISO 8601, handle timezone

18. THE UI_System SHALL provide automatic backup option (future):
    - Setting: "Auto Backup" toggle in settings
    - Frequency: daily, weekly, or monthly
    - Storage: local device storage or cloud (if enabled)
    - Retention: keep last 7 backups, delete older

### Requirement 25: Real-Time Profit Calculation Integration

**User Story:** As a merchant, I want real-time profit calculations that update instantly when I record sales or expenses, so that I always see current accurate financial data on the home screen.

#### Acceptance Criteria

1. THE ProfitProvider SHALL initialize on app start:
   - Load default period filter: Today
   - Calculate date range: start of day (00:00:00) to end of day (23:59:59)
   - Query sales and expenses for range
   - Calculate initial metrics

2. THE ProfitProvider SHALL watch Isar database for changes:
   - Use `saleCollection.watchLazy()`: detect new sales, voided sales
   - Use `expenseCollection.watchLazy()`: detect new expenses, deleted expenses
   - On change event: recalculate metrics for current period
   - Notify listeners to rebuild profit card

3. WHEN ProfitProvider loses Isar watch connection, THE UI_System SHALL continue displaying last known profit metrics without error indicator AND attempt reconnection in background

4. THE ProfitProvider SHALL expose state:
   - `selectedPeriod`: PeriodFilter enum (Today, Week, Month)
   - `revenue`: double (sum of sales)
   - `cogs`: double (cost of goods sold)
   - `grossProfit`: double (revenue - cogs)
   - `operatingExpenses`: double (expenses excluding restock)
   - `netProfit`: double (grossProfit - operatingExpenses)
   - `transactionCount`: int (number of sales)
   - `isLoading`: bool (calculation in progress)

4. WHEN selectedPeriod changes, THE ProfitProvider SHALL:
   - Update date range:
     - Today: start of current day to end of current day
     - Week: start of week (Monday 00:00) to end of week (Sunday 23:59)
     - Month: start of month (1st 00:00) to end of month (last day 23:59)
   - Query sales: `WHERE saleDate >= startDate AND saleDate <= endDate AND isVoided = false`
   - Query expenses: `WHERE expenseDate >= startDate AND expenseDate <= endDate AND isDeleted = false`
   - Recalculate all metrics
   - Notify listeners

5. THE ProfitProvider SHALL calculate revenue:
   - Query: `saleCollection.filter().saleDateBetween(start, end).isVoidedEqualTo(false).findAll()`
   - Sum: `sales.fold(0.0, (sum, sale) => sum + sale.totalAmount)`
   - Result: total revenue for period

6. THE ProfitProvider SHALL calculate COGS:
   - Use same sales query as revenue
   - Sum: `sales.fold(0.0, (sum, sale) => sum + sale.totalCost)`
   - Note: totalCost already calculated using WAC at sale time
   - Result: total cost of goods sold

7. THE ProfitProvider SHALL calculate gross profit:
   - Call: `ProfitEngine.calculateGrossProfit(revenue, cogs)`
   - Formula: revenue - cogs
   - Result: profit before operating expenses

8. THE ProfitProvider SHALL calculate operating expenses:
   - Query: `expenseCollection.filter().expenseDateBetween(start, end).isRestockExpenseEqualTo(false).isDeletedEqualTo(false).findAll()`
   - CRITICAL: exclude restock expenses (isRestockExpense = true)
   - Sum: `expenses.fold(0.0, (sum, exp) => sum + exp.amount)`
   - Result: total operating overhead (OpEx only)

9. THE ProfitProvider SHALL calculate net profit:
   - Call: `ProfitEngine.calculateNetProfit(grossProfit, operatingExpenses)`
   - Formula: grossProfit - operatingExpenses
   - Result: final profit after all operating costs

10. THE ProfitProvider SHALL calculate transaction count:
    - Count: `sales.length` from filtered query
    - Result: number of transactions in period

11. THE Profit_Card SHALL listen to ProfitProvider:
    - Use `ref.watch(profitProvider)` or StreamBuilder
    - Rebuild when any metric changes
    - Display loading shimmer while isLoading = true

12. THE Profit_Card SHALL display metrics in real-time:
    - Net profit: large display at center
    - Revenue: bottom-left sub-metric
    - Operating expenses: bottom-right sub-metric (not including restock)
    - Transaction count: quick metrics section
    - All values update instantly when database changes

13. THE Profit_Card SHALL format currency values:
    - Format: "#,##0.00" with comma thousands separator
    - Suffix: " ብር" Amharic currency
    - Negative values: red color with "-" prefix
    - Zero: display "0.00" not blank

14. THE ProfitProvider SHALL handle edge cases:
    - No sales: revenue = 0, cogs = 0, grossProfit = 0
    - No expenses: operatingExpenses = 0
    - Negative profit: display correctly, trigger health warning
    - Division by zero: return 0 for margin calculations

15. THE ProfitProvider SHALL provide profit health status:
    - Call: `ProfitEngine.analyzeProfitHealth(netProfit, grossMargin, opExRatio)`
    - Display: in home screen critical alerts section
    - Update: whenever metrics recalculated

16. THE UI_System SHALL display profit health alert:
    - CRITICAL status: crimson card, "Business losing money" message
    - WARNING status: amber card, "Profit margin below 20%" or "OpEx over 40%" message
    - MODERATE status: gray card, "Room for improvement" message
    - HEALTHY status: no alert card (or green card with "Business performing well")

17. THE ProfileScreen SHALL use ProfitProvider for metrics cards:
    - Share same provider instance (singleton)
    - Display: revenue, gross profit, operating expenses, gross margin
    - Period selector: same as profit card (Today/Week/Month)
    - Consistency: exact same calculations as home screen

18. THE ProfitProvider SHALL provide decision insights:
    - Top seller: product with highest sales count
    - Largest expense category: category with highest total
    - Margin warning: if grossMargin < 0.05 (5%)
    - OpEx warning: if opExRatio > 0.40 (40%)
    - Profitability: net profit status and trend

19. THE UI_System SHALL display decision insights in profile:
    - Section: "DECISION INSIGHTS" uppercase font-black
    - Each insight: icon + message + actionable recommendation
    - Examples:
      - ⚠️ "Gross margin is 2% - pricing may need attention"
      - 📈 "Net profit is 10,017.00 ብር after operating expenses"
      - ⭐ "[Product] is your top seller with [n] units sold"

20. THE ProfitProvider SHALL cache calculations:
    - Cache: store last calculation result with timestamp
    - Invalidate: when database change detected
    - TTL: no expiry (always fresh via watchers)
    - Performance: avoid recalculating on every UI rebuild

21. THE ProfitProvider SHALL optimize queries:
    - Use indexes: saleDate and expenseDate indexed
    - Batch: group multiple changes before recalculating
    - Debounce: wait 100ms after last change before recalculating
    - Async: run calculations in isolate for large datasets

22. THE UI_System SHALL show calculation progress:
    - Large dataset: show "Calculating..." indicator
    - Threshold: > 1000 sales or expenses
    - Duration: display if calculation takes > 500ms
    - Cancel: allow user to cancel if takes > 5 seconds

---

## Document Summary

This requirements document comprehensively covers:

1. **Complete UI Screens**: 7 main screens + Authentication/Onboarding (8 total)
2. **Data Models**: Product, Sale, Expense, RestockLog, UserProfile, License with full field definitions
3. **Service Integration**: DeviceIdentity, LicenseVerifier, WACCalculator (8 functions), ProfitEngine (8 functions)
4. **Business Flows**: 
   - Complete sell flow with cart management, price override, payment methods
   - Inventory restock with WAC recalculation and preview
   - Transaction void with stock restoration
   - Backup/restore with validation and error handling
5. **Real-time Updates**: Profit calculations, stock alerts, low stock badges via Isar watchers
6. **UI States**: Loading, empty, error, success with consistent styling
7. **Bilingual Support**: English/Amharic throughout
8. **Dark Mode**: Complete theme system with color adaptation
9. **Accessibility**: Touch targets, screen reader labels, large text support
10. **Testing**: Widget, golden, integration, property-based, performance tests

All acceptance criteria are testable and reference actual implementation details from the existing codebase.

**User Story:** As a developer, I want comprehensive tests verifying UI correctness, so that I can confidently deploy updates without regressions.

#### Acceptance Criteria

1. THE UI_System SHALL include widget tests for each screen:
   - Rendering: verify all key widgets render without error
   - Interactions: tap buttons, input text, verify callbacks
   - States: test loading, error, empty, and success states

2. THE UI_System SHALL include golden tests for visual regression:
   - Screenshots: capture each screen in light and dark mode
   - Comparison: fail on pixel differences > threshold
   - Coverage: all screens, modals, and key states

3. THE UI_System SHALL include integration tests for user flows:
   - Flow 1: Splash → Auth → Home
   - Flow 2: Add product → View inventory → Restock
   - Flow 3: Select products → Checkout → Complete sale
   - Flow 4: Record expense → View profile reports

4. THE UI_System SHALL include accessibility tests:
   - Guideline scan: run automated accessibility checker
   - Screen reader: manual test with TalkBack/VoiceOver
   - Large text: test at 200% font scale
   - Color contrast: verify all text meets WCAG AA

5. THE UI_System SHALL include performance tests:
   - Benchmark: measure frame render time for scrolling
   - Memory: verify no leaks after 1000 screen navigations
   - Database: test query performance with 10,000 records

6. THE UI_System SHALL include tests for data integration:
   - Providers: unit tests for state management logic
   - Database: integration tests for Isar queries
   - Calculations: property-based tests for WAC and profit engine

