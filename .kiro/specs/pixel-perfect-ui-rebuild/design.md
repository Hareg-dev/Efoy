# Design Document: Efoy Pixel-Perfect UI Rebuild

## Overview

This document specifies the technical design for rebuilding the Efoy (እፎይ) Flutter application's user interface to pixel-perfectly match professional HTML mockups. The design covers complete architecture for 8 screens with real-time state management, offline-first data persistence, and production-ready business logic integration.

**Target**: Flutter 3.12+, Isar 3.1.0, Riverpod 2.5.1, Material Design 3

**Scope**: UI layer rebuild (screens, widgets, animations, state management) integrated with existing backend (Isar database, WAC Calculator, Profit Engine, License Verifier).

---

## Architecture

### High-Level System Architecture

```mermaid
graph TB
    subgraph "UI Layer"
        A[Screens] --> B[Reusable Widgets]
        A --> C[Animations]
    end
    
    subgraph "State Management Layer"
        D[Riverpod Providers]
        E[StateNotifier Classes]
        F[StreamProviders]
    end
    
    subgraph "Business Logic Layer"
        G[Services]
        H[Calculators]
        I[Validators]
    end
    
    subgraph "Data Layer"
        J[Isar Database]
        K[Models]
        L[Repositories]
    end
    
    A --> D
    D --> G
    D --> L
    G --> H
    L --> J
    J --> K
    
    style A fill:#10b981,color:#fff
    style D fill:#0ea5e9,color:#fff
    style G fill:#f59e0b,color:#fff
    style J fill:#8b5cf6,color:#fff
```

### Dependency Flow

```mermaid
graph LR
    UI[UI Widgets] --> SP[State Providers]
    SP --> REP[Repositories]
    SP --> SVC[Services]
    REP --> ISAR[Isar DB]
    SVC --> CALC[Calculators]
    
    style UI fill:#a7f3d0
    style SP fill:#93c5fd
    style REP fill:#fbbf24
    style SVC fill:#fbbf24
    style ISAR fill:#c084fc
```

**Key Principles:**
- **Offline-First**: All operations work without network connectivity
- **Unidirectional Data Flow**: UI → Provider → Repository → Database
- **Reactive Updates**: Isar watchers → StreamProviders → UI auto-rebuild
- **Separation of Concerns**: UI knows only about state; business logic in services

### Package Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          # HTML color mappings
│   │   ├── app_theme.dart           # ThemeData configuration
│   │   └── app_strings.dart         # Bilingual text constants
│   ├── security/
│   │   ├── device_identity.dart     # Hardware fingerprinting
│   │   └── license_verifier.dart    # Offline license validation
│   └── utils/
│       ├── currency_formatter.dart  # Birr formatting
│       └── date_formatter.dart      # Date/time utilities
├── data/
│   ├── local/
│   │   └── app_database.dart        # Isar initialization
│   ├── models/
│   │   ├── product_model.dart       # Product with WAC
│   │   ├── sale_model.dart          # Sale with line items
│   │   ├── expense_model.dart       # Expense with category
│   │   ├── restock_log_model.dart   # Restock audit trail
│   │   ├── user_profile_model.dart  # Merchant profile
│   │   └── license_model.dart       # License activation
│   └── repositories/
│       ├── product_repository.dart  # Product CRUD
│       ├── sale_repository.dart     # Sale transactions
│       └── expense_repository.dart  # Expense tracking
├── logic/
│   ├── calculators/
│   │   ├── wac_calculator.dart      # Weighted Average Cost
│   │   └── profit_engine.dart       # Profit calculations
│   └── providers/
│       ├── profit_provider.dart     # Net profit state
│       ├── cart_provider.dart       # Shopping cart state
│       ├── inventory_provider.dart  # Product filtering
│       └── theme_provider.dart      # Dark mode/language
├── ui/
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── auth_screen.dart
│   │   ├── main_layout.dart         # Bottom nav wrapper
│   │   ├── home_screen.dart
│   │   ├── sell_screen.dart
│   │   ├── inventory_screen.dart
│   │   ├── expenses_screen.dart
│   │   └── profile_screen.dart
│   ├── widgets/
│   │   ├── profit_card.dart         # Home profit display
│   │   ├── alert_card.dart          # Critical alerts
│   │   ├── product_card.dart        # Inventory item
│   │   ├── cart_sheet.dart          # Sell checkout
│   │   ├── restock_modal.dart       # Restock dialog
│   │   └── bottom_nav_bar.dart      # Custom bottom nav
│   └── animations/
│       ├── pulsing_dot.dart         # SYNCED indicator
│       └── pill_transition.dart     # Nav pill animation
└── main.dart
```

---

## Components and Interfaces

### Core Interfaces

#### 1. Repository Pattern

All data access goes through repositories:

```dart
abstract class BaseRepository<T> {
  Future<T?> getById(int id);
  Future<List<T>> getAll();
  Future<int> create(T entity);
  Future<void> update(T entity);
  Future<void> delete(int id);
  Stream<List<T>> watchAll();
}
```

**Implementation Example: ProductRepository**

```dart
class ProductRepository implements BaseRepository<ProductModel> {
  final Isar _isar;
  
  ProductRepository(this._isar);
  
  @override
  Future<ProductModel?> getById(int id) async {
    return await _isar.productModels.get(id);
  }
  
  @override
  Future<List<ProductModel>> getAll() async {
    return await _isar.productModels
      .filter()
      .isDeletedEqualTo(false)
      .sortByName()
      .findAll();
  }
  
  @override
  Stream<List<ProductModel>> watchAll() {
    return _isar.productModels
      .filter()
      .isDeletedEqualTo(false)
      .watch(fireImmediately: true);
  }
  
  Future<List<ProductModel>> getLowStockProducts() async {
    final products = await getAll();
    return products.where((p) => p.isLowStock).toList();
  }
  
  Future<void> restock({
    required int productId,
    required int quantity,
    required double costPerUnit,
  }) async {
    await _isar.writeTxn(() async {
      final product = await getById(productId);
      if (product == null) throw Exception('Product not found');
      
      // Calculate new WAC
      final newWAC = WACCalculator.calculateNewWAC(
        currentStock: product.currentStock,
        currentCost: product.costPrice,
        addedQuantity: quantity,
        purchasePrice: costPerUnit,
      );
      
      // Update product
      final updated = product.copyWith(
        currentStock: product.currentStock + quantity,
        costPrice: newWAC,
        updatedAt: DateTime.now(),
      );
      
      await _isar.productModels.put(updated);
      
      // Create restock log
      final log = RestockLogModel(
        productId: productId,
        productName: product.name,
        quantityAdded: quantity,
        costPerUnit: costPerUnit,
        totalCost: quantity * costPerUnit,
        oldWAC: product.costPrice,
        newWAC: newWAC,
        oldStock: product.currentStock,
        newStock: product.currentStock + quantity,
        restockedAt: DateTime.now(),
      );
      await _isar.restockLogModels.put(log);
      
      // Create expense record (CapEx)
      final expense = ExpenseModel(
        title: 'Restock · ${product.name}',
        amount: quantity * costPerUnit,
        category: ExpenseCategory.restock,
        isRestockExpense: true,
        expenseDate: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await _isar.expenseModels.put(expense);
    });
  }
}
```

#### 2. Service Layer Pattern

Services encapsulate business logic:

```dart
abstract class Calculator {
  // Pure functions with no side effects
}

class WACCalculator implements Calculator {
  static double calculateNewWAC({
    required int currentStock,
    required double currentCost,
    required int addedQuantity,
    required double purchasePrice,
  }) {
    if (currentStock == 0) return purchasePrice;
    if (addedQuantity == 0) return currentCost;
    
    final totalValue = (currentStock * currentCost) + 
                       (addedQuantity * purchasePrice);
    final totalQuantity = currentStock + addedQuantity;
    
    return totalValue / totalQuantity;
  }
  
  static double calculateInventoryValue({
    required int quantity,
    required double wac,
  }) => quantity * wac;
  
  static double calculateProfitMargin({
    required double sellingPrice,
    required double wac,
  }) {
    if (sellingPrice <= 0) return 0.0;
    return (sellingPrice - wac) / sellingPrice;
  }
}
```

#### 3. State Management Pattern

StateNotifier for complex state:

```dart
// Cart State
class CartState {
  final List<CartItem> items;
  final PaymentMethod paymentMethod;
  final double? amountReceived;
  
  CartState({
    this.items = const [],
    this.paymentMethod = PaymentMethod.cash,
    this.amountReceived,
  });
  
  double get total => items.fold(
    0.0, 
    (sum, item) => sum + item.lineTotal,
  );
  
  double get change => amountReceived != null && amountReceived! > total
      ? amountReceived! - total
      : 0.0;
  
  CartState copyWith({
    List<CartItem>? items,
    PaymentMethod? paymentMethod,
    double? amountReceived,
  }) {
    return CartState(
      items: items ?? this.items,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      amountReceived: amountReceived ?? this.amountReceived,
    );
  }
}

// Cart Notifier
class CartNotifier extends StateNotifier<CartState> {
  final SaleRepository _saleRepository;
  final ProductRepository _productRepository;
  
  CartNotifier(this._saleRepository, this._productRepository) 
      : super(CartState());
  
  void addItem(ProductModel product) {
    final existingIndex = state.items.indexWhere(
      (item) => item.productId == product.id,
    );
    
    if (existingIndex >= 0) {
      incrementQuantity(product.id);
    } else {
      final newItem = CartItem(
        productId: product.id,
        productName: product.name,
        quantity: 1,
        unitPrice: product.sellingPrice,
        unitCost: product.costPrice,
        availableStock: product.currentStock,
      );
      
      state = state.copyWith(
        items: [...state.items, newItem],
      );
    }
  }
  
  void incrementQuantity(int productId) {
    final updatedItems = state.items.map((item) {
      if (item.productId == productId) {
        if (item.quantity < item.availableStock) {
          return item.copyWith(quantity: item.quantity + 1);
        }
      }
      return item;
    }).toList();
    
    state = state.copyWith(items: updatedItems);
  }
  
  Future<void> completeSale() async {
    // Validate
    if (state.items.isEmpty) throw Exception('Cart is empty');
    
    // Create sale record
    final sale = SaleModel(
      saleDate: DateTime.now(),
      transactionId: Uuid().v4(),
      lineItems: state.items.map((item) => SaleLineItem()
        ..productId = item.productId
        ..productName = item.productName
        ..quantity = item.quantity
        ..unitPrice = item.unitPrice
        ..unitCost = item.unitCost
        ..lineTotal = item.lineTotal
        ..lineCost = item.lineCost
        ..lineProfit = item.lineProfit
      ).toList(),
      totalAmount: state.total,
      totalCost: state.items.fold(0.0, (sum, item) => sum + item.lineCost),
      grossProfit: state.items.fold(0.0, (sum, item) => sum + item.lineProfit),
      paymentMethod: state.paymentMethod,
      amountReceived: state.amountReceived,
      changeGiven: state.change,
      createdAt: DateTime.now(),
    );
    
    // Atomic transaction
    await _saleRepository.createWithStockUpdate(sale);
    
    // Clear cart
    state = CartState();
  }
  
  void clearCart() {
    state = CartState();
  }
}
```

### Component Communication Flow

```mermaid
sequenceDiagram
    participant UI as SellScreen
    participant Cart as CartProvider
    participant Repo as SaleRepository
    participant DB as Isar Database
    
    UI->>Cart: addItem(product)
    Cart->>Cart: Update state.items
    Cart-->>UI: Notify listeners (rebuild)
    
    UI->>Cart: completeSale()
    Cart->>Repo: createWithStockUpdate(sale)
    Repo->>DB: writeTxn(sale + stock update)
    DB-->>Repo: Success
    Repo-->>Cart: Return
    Cart->>Cart: clearCart()
    Cart-->>UI: Notify (navigate home)
```

---

## Data Models

### Product Model

```dart
@collection
class ProductModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String name;
  
  String? description;
  
  @Index()
  String? barcode;
  
  late double sellingPrice;
  late double costPrice; // WAC
  late int currentStock;
  late int lowStockThreshold;
  
  String? category;
  String? imageUrl;
  
  late DateTime createdAt;
  late DateTime updatedAt;
  
  @Index()
  bool isDeleted = false;
  
  // Computed properties
  @ignore
  bool get isLowStock => currentStock <= lowStockThreshold && currentStock > 0;
  
  @ignore
  bool get isOutOfStock => currentStock <= 0;
  
  @ignore
  double get inventoryValue => currentStock * costPrice;
  
  @ignore
  double get liquidityValue => currentStock * sellingPrice;
  
  @ignore
  double get profitMargin => sellingPrice > 0 
      ? (sellingPrice - costPrice) / sellingPrice 
      : 0;
}
```

### Sale Model with Embedded Line Items

```dart
@collection
class SaleModel {
  Id id = Isar.autoIncrement;

  @Index()
  late DateTime saleDate;
  late String transactionId; // UUID
  
  late List<SaleLineItem> lineItems;
  
  late double totalAmount; // Revenue
  late double totalCost; // COGS
  late double grossProfit;
  
  @enumerated
  late PaymentMethod paymentMethod;
  double? amountReceived;
  double? changeGiven;
  
  String? notes;
  String? cashierName;
  
  late DateTime createdAt;
  bool isVoided = false;
  DateTime? voidedAt;
}

@embedded
class SaleLineItem {
  int productId = 0;
  String productName = '';
  int quantity = 0;
  double unitPrice = 0.0;
  double unitCost = 0.0; // WAC snapshot
  double lineTotal = 0.0; // quantity * unitPrice
  double lineCost = 0.0; // quantity * unitCost
  double lineProfit = 0.0; // lineTotal - lineCost
}

enum PaymentMethod {
  cash,
  telebirr,
  cbeBirr,
  amharaBank,
  mixed,
}
```

### Expense Model

```dart
@collection
class ExpenseModel {
  Id id = Isar.autoIncrement;

  late String title;
  String? description;
  late double amount;
  
  @Index()
  @enumerated
  late ExpenseCategory category;
  
  @Index()
  late DateTime expenseDate;
  late DateTime createdAt;
  
  String? receiptImageUrl;
  String? notes;
  
  // CRITICAL: Separates CapEx from OpEx
  bool isRestockExpense = false;
  bool isDeleted = false;
}

enum ExpenseCategory {
  rent,      // OpEx
  salary,    // OpEx
  transport, // OpEx
  utilities, // OpEx
  airtime,   // OpEx
  supplies,  // OpEx
  restock,   // CapEx (excluded from net profit calculation)
  other,     // OpEx
}
```

---

## Widget Architecture

### 1. Splash Screen

**Purpose**: Animated brand splash with license initialization

**Widget Tree**:
```
SplashScreen (StatefulWidget)
└── Scaffold
    └── Stack
        ├── RadialGradient Container (background)
        ├── Center Column
        │   ├── BrandLogo Card (animated scale)
        │   ├── AmharicText "እፎይ" (gradient)
        │   └── Subtitle Text
        └── Positioned (bottom)
            └── PulsingDots (AnimatedBuilder)
```

**Implementation**:

```dart
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _dotsController;
  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;

  @override
  void initState() {
    super.initState();
    
    // Staggered dot animation
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    
    _dot1Animation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotsController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );
    
    _dot2Animation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotsController,
        curve: const Interval(0.15, 0.65, curve: Curves.easeInOut),
      ),
    );
    
    _dot3Animation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _dotsController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeInOut),
      ),
    );
    
    _initializeAndNavigate();
  }

  Future<void> _initializeAndNavigate() async {
    await Future.delayed(const Duration(seconds: 2));
    
    // Check license status
    final hasValidSession = false; // TODO: Check from secure storage
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        hasValidSession ? '/home' : '/auth',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.6),
            radius: 1.2,
            colors: [
              Color(0xFF0E2039),
              Color(0xFF091322),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Center logo
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo card
                    Container(
                      width: 218,
                      height: 142,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.successGreen.withOpacity(0.25),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Image.asset(
                          'asset/efoy.jpg',
                          width: 180,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Amharic brand name
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF10B981),
                          Color(0xFF6EE7B7),
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        'እፎይ',
                        style: TextStyle(
                          fontSize: 52,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'NotoSansEthiopic',
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    const Text(
                      'በእፎይ እርፍ ይበሉ',
                      style: TextStyle(
                        fontSize: 16.5,
                        color: Color(0xFF6BE39B),
                        fontFamily: 'NotoSansEthiopic',
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom pagination dots
              Positioned(
                bottom: 56,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _dotsController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildDot(_dot1Animation.value, false),
                        const SizedBox(width: 12),
                        _buildDot(_dot2Animation.value, true),
                        const SizedBox(width: 12),
                        _buildDot(_dot3Animation.value, false),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(double opacity, bool isCenter) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isCenter ? 12 : 8,
      height: isCenter ? 12 : 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.lerp(
          const Color(0xFF18CF67),
          const Color(0xFF1ED76F),
          opacity,
        )!.withOpacity(opacity),
      ),
    );
  }

  @override
  void dispose() {
    _dotsController.dispose();
    super.dispose();
  }
}
```

### 2. Authentication Screen

**Purpose**: License activation and user onboarding

**Widget Tree**:
```
AuthScreen (ConsumerStatefulWidget)
└── Scaffold
    └── SafeArea
        └── Column
            ├── Header (Logo + Brand)
            ├── TabBar (Login | Activate License)
            └── TabBarView
                ├── LoginTab (password form)
                └── LicenseTab
                    ├── DeviceInfoCard (if !showOnboarding)
                    │   ├── Platform/Model/Manufacturer
                    │   └── DeviceID + Copy Button
                    ├── LicenseKeyInput
                    ├── TestKeyGenerator (if kDebugMode)
                    └── ActivateButton
                    OR
                    └── OnboardingFlow (if showOnboarding)
                        ├── SuccessIndicator
                        ├── PasswordSetup (Step 1)
                        ├── ModeSelector (Step 2)
                        ├── PaymentInfo (Step 3)
                        └── CompleteButton
```

**State Management**:

```dart
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Controllers
  final _passwordController = TextEditingController();
  final _licenseKeyController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _telebirrController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankNameController = TextEditingController();
  
  // State
  String? _deviceId;
  DeviceInfo? _deviceInfo;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showOnboarding = false;
  bool _isDemoMode = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final info = await DeviceIdentity.getDeviceInfo();
    final id = await DeviceIdentity.getDeviceId();
    
    setState(() {
      _deviceInfo = info;
      _deviceId = id;
    });
  }

  Future<void> _handleLicenseActivation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final licenseKey = _licenseKeyController.text.trim();
    
    if (licenseKey.isEmpty || _deviceId == null) {
      setState(() {
        _errorMessage = 'Please enter a license key';
        _isLoading = false;
      });
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final result = LicenseVerifier.verifyLicense(
      licenseKey: licenseKey,
      deviceId: _deviceId!,
    );

    setState(() {
      _isLoading = false;
      if (result.isValid) {
        _successMessage = 'License activated successfully!';
        _showOnboarding = true;
      } else {
        _errorMessage = result.errorMessage ?? 'License verification failed';
      }
    });
  }
  
  Future<void> _completeOnboarding() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    
    // Validate password
    if (newPassword.isEmpty || newPassword.length < 4) {
      setState(() {
        _errorMessage = 'Password must be at least 4 characters';
      });
      return;
    }
    
    if (newPassword != confirmPassword) {
      setState(() {
        _errorMessage = 'Passwords do not match';
      });
      return;
    }
    
    // Validate payment info (if production mode)
    if (!_isDemoMode) {
      if (_phoneController.text.trim().isEmpty && 
          _telebirrController.text.trim().isEmpty && 
          _bankAccountController.text.trim().isEmpty) {
        setState(() {
          _errorMessage = 'Please provide at least one payment method';
        });
        return;
      }
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    // TODO: Save user profile to database
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            _buildHeader(),
            
            const SizedBox(height: 32),
            
            _buildTabBar(),
            
            const SizedBox(height: 24),
            
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLoginTab(),
                  _buildLicenseTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryTeal.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Image.asset(
            'asset/efoy.jpg',
            fit: BoxFit.contain,
          ),
        ),
        
        const SizedBox(height: 16),
        
        const Text(
          'Efoy',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryTeal,
          ),
        ),
        
        const Text(
          'እፎይ',
          style: TextStyle(
            fontSize: 20,
            color: AppColors.textSecondary,
            fontFamily: 'NotoSansEthiopic',
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceL),
      decoration: BoxDecoration(
        color: AppColors.neutralBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primaryTeal,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Login'),
          Tab(text: 'Activate License'),
        ],
      ),
    );
  }

  // ... buildLoginTab, buildLicenseTab, buildOnboardingFlow methods
}
```

### 3. Home Dashboard Screen

**Purpose**: Real-time profit display with critical alerts

**Widget Tree**:
```
HomeScreen (ConsumerWidget)
└── Scaffold
    └── SafeArea
        └── CustomScrollView
            ├── SliverAppBar (Header)
            ├── SliverToBoxAdapter
            │   └── Column
            │       ├── ProfitCard
            │       │   ├── SyncedIndicator + PeriodFilterPills
            │       │   ├── NetProfitDisplay
            │       │   └── RevenueExpenseBreakdown
            │       ├── QuickMetricsGrid (2 columns)
            │       │   ├── TransactionCard
            │       │   └── SalesCard
            │       ├── CriticalAlertsSection
            │       │   ├── StockAlertCard (if lowStock)
            │       │   ├── ZeroTransactionsCard (if count==0)
            │       │   └── ProfitCautionCard (if margin<5%)
            │       └── CommandActionsSection
            └── BottomNavBar (Home active)
```

**Profit Card Implementation**:

```dart
class ProfitCard extends ConsumerWidget {
  const ProfitCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profitState = ref.watch(profitProvider);
    final selectedPeriod = ref.watch(profitPeriodProvider);
    
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment(0.8, -0.2),
          radius: 1.0,
          colors: [
            AppColors.profitGradStart,
            AppColors.profitGradMid,
            AppColors.profitGradEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryGreen.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Watermark circle
          Positioned(
            right: -20,
            bottom: -40,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.08),
                    Colors.white.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: SYNCED + Period filters
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSyncedIndicator(),
                    _buildPeriodFilters(context, ref, selectedPeriod),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Net profit metric
                _buildProfitMetric(profitState, selectedPeriod),
                
                const SizedBox(height: 32),
                
                // Revenue & Expenses breakdown
                _buildBreakdown(profitState),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncedIndicator() {
    return Row(
      children: [
        const PulsingDot(
          size: 8,
          color: AppColors.syncGreen,
        ),
        const SizedBox(width: 8),
        Text(
          'SYNCED',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppColors.emerald200,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodFilters(
    BuildContext context,
    WidgetRef ref,
    ProfitPeriod selected,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF07321A).withOpacity(0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildPeriodPill(ref, ProfitPeriod.today, 'Today', selected),
          _buildPeriodPill(ref, ProfitPeriod.week, 'Week', selected),
          _buildPeriodPill(ref, ProfitPeriod.month, 'Month', selected),
        ],
      ),
    );
  }

  Widget _buildPeriodPill(
    WidgetRef ref,
    ProfitPeriod period,
    String label,
    ProfitPeriod selected,
  ) {
    final isActive = period == selected;
    
    return GestureDetector(
      onTap: () {
        ref.read(profitPeriodProvider.notifier).state = period;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isActive 
              ? Colors.white.withOpacity(0.25) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: isActive ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
            ),
          ] : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive 
                ? Colors.white 
                : Colors.white.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildProfitMetric(
    AsyncValue<ProfitState> profitState,
    ProfitPeriod period,
  ) {
    return profitState.when(
      data: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NET PROFIT · ${period.name.toUpperCase()}',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AppColors.emerald200.withOpacity(0.9),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  CurrencyFormatter.formatBirr(state.netProfit),
                  style: GoogleFonts.inter(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.0,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ብር',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(color: Colors.white),
      error: (err, stack) => Text('Error: $err'),
    );
  }

  Widget _buildBreakdown(AsyncValue<ProfitState> profitState) {
    return profitState.when(
      data: (state) {
        return Container(
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildSubMetric(
                  'REVENUE TODAY',
                  state.revenue,
                  Colors.white,
                ),
              ),
              Expanded(
                child: _buildSubMetric(
                  'EXPENSES TODAY',
                  state.operatingExpenses,
                  AppColors.rose300,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }

  Widget _buildSubMetric(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppColors.emerald200.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${CurrencyFormatter.formatBirr(amount)} ብር',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Pulsing dot animation
class PulsingDot extends StatefulWidget {
  final double size;
  final Color color;
  
  const PulsingDot({
    super.key,
    required this.size,
    required this.color,
  });

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(_animation.value),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
```

### 4. Sell (POS) Screen

**Purpose**: Product selection, cart management, and checkout

**Widget Tree**:
```
SellScreen (ConsumerStatefulWidget)
└── Scaffold
    └── Column
        ├── Header (Title + Hold button)
        ├── ProductGrid (GridView.builder 3 columns)
        │   └── ProductCard (tap to add to cart)
        └── CartSheet (DraggableScrollableSheet)
            ├── Header (Cart badge + Clear button)
            ├── LineItems (ListView)
            │   └── CartLineItem
            │       ├── ProductName + EditPrice button
            │       ├── QuantityStepper (- count +)
            │       └── LineTotal + Remove button
            ├── TotalBar (gray background)
            ├── PaymentMethodPills (horizontal scroll)
            ├── AmountReceivedInput
            ├── ChangeDisplay (if change > 0)
            └── CompleteSaleButton
```

**Cart Implementation**:

```dart
class SellScreen extends ConsumerStatefulWidget {
  const SellScreen({super.key});

  @override
  ConsumerState<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends ConsumerState<SellScreen> {
  final _amountReceivedController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(activeProductsProvider);
    final cartState = ref.watch(cartProvider);
    
    return Scaffold(
      backgroundColor: AppColors.bgHome,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            
            Expanded(
              child: products.when(
                data: (productList) => GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: productList.length,
                  itemBuilder: (context, index) {
                    final product = productList[index];
                    final inCart = cartState.items.any(
                      (item) => item.productId == product.id,
                    );
                    final quantity = inCart
                        ? cartState.items
                            .firstWhere((item) => item.productId == product.id)
                            .quantity
                        : 0;
                    
                    return ProductCard(
                      product: product,
                      isSelected: inCart,
                      quantity: quantity,
                      onTap: () {
                        ref.read(cartProvider.notifier).addItem(product);
                      },
                    );
                  },
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
              ),
            ),
            
            if (cartState.items.isNotEmpty)
              _buildCartSheet(cartState),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'SELL',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          
          OutlinedButton.icon(
            onPressed: () {
              // TODO: Hold order
            },
            icon: const Icon(Icons.pause, size: 18),
            label: const Text('Hold'),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.grey[200],
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartSheet(CartState cartState) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      snap: true,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(34),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 30,
                offset: Offset(0, -10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${cartState.items.fold<int>(0, (sum, item) => sum + item.quantity)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    Text(
                      'CART',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    
                    const Spacer(),
                    
                    TextButton(
                      onPressed: () {
                        _showClearCartDialog();
                      },
                      child: Text(
                        'Clear all',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.alertRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Line items
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: cartState.items.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final item = cartState.items[index];
                    return CartLineItem(item: item);
                  },
                ),
              ),
              
              // Total bar
              Container(
                color: const Color(0xFFF9FAFB).withOpacity(0.8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOTAL',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          CurrencyFormatter.formatBirr(cartState.total),
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'ብር',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Payment method, amount received, complete button
              _buildCheckoutSection(cartState),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCheckoutSection(CartState cartState) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment method pills
          Text(
            'PAYMENT METHOD',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
              color: AppColors.textTertiary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: PaymentMethod.values.map((method) {
                final isActive = cartState.paymentMethod == method;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildPaymentPill(method, isActive),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Amount received
          TextField(
            controller: _amountReceivedController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              fillColor: const Color(0xFFF4F5F7),
              hintText: 'Amount received',
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 8),
                child: Text(
                  'Birr',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(),
            ),
            onChanged: (value) {
              final amount = double.tryParse(value);
              ref.read(cartProvider.notifier).updateAmountReceived(amount);
            },
          ),
          
          // Change display
          if (cartState.change > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.tealTint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'CHANGE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  Text(
                    '${CurrencyFormatter.formatBirr(cartState.change)} ብር',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Complete sale button
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: cartState.items.isEmpty
                  ? null
                  : () async {
                      try {
                        await ref.read(cartProvider.notifier).completeSale();
                        
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Sale completed - ${CurrencyFormatter.formatBirr(cartState.total)} ብር',
                              ),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                          
                          Navigator.of(context).pushReplacementNamed('/home');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: AppColors.alertRed,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 14,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Text(
                    'COMPLETE SALE · ${CurrencyFormatter.formatBirr(cartState.total)} ብር',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentPill(PaymentMethod method, bool isActive) {
    return GestureDetector(
      onTap: () {
        ref.read(cartProvider.notifier).updatePaymentMethod(method);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryLight : Colors.grey[100],
          borderRadius: BorderRadius.circular(999),
          boxShadow: isActive ? [
            BoxShadow(
              color: AppColors.primaryLight.withOpacity(0.3),
              blurRadius: 8,
            ),
          ] : null,
        ),
        child: Text(
          method.displayName,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text('This will remove all items from the cart.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cartProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.alertRed,
            ),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// Extension for payment method display names
extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.telebirr:
        return 'Telebirr';
      case PaymentMethod.cbeBirr:
        return 'CBE Birr';
      case PaymentMethod.amharaBank:
        return 'Amhara Bank';
      case PaymentMethod.mixed:
        return 'Mixed';
    }
  }
}
```

### 5. Inventory Management Screen

**Purpose**: Product listing, filtering, search, and restock

**Widget Tree**:
```
InventoryScreen (ConsumerStatefulWidget)
└── Scaffold
    └── Column
        ├── Header (Title + Count + Add Button)
        ├── StockAlertsCard (if lowStockCount > 0)
        │   └── ListView (low stock products)
        ├── SearchBar (debounced)
        ├── FilterPills (All | Needs Attention | Out of Stock)
        └── ProductList (ListView.builder)
            └── ProductCard
                ├── Icon + Name + Badge
                ├── Stock count
                ├── Price
                └── RestockButton → RestockModal
```

**Restock Modal**:

```dart
class RestockModal extends ConsumerStatefulWidget {
  final ProductModel product;
  
  const RestockModal({super.key, required this.product});

  @override
  ConsumerState<RestockModal> createState() => _RestockModalState();
}

class _RestockModalState extends ConsumerState<RestockModal> {
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  
  double? _newWAC;

  void _calculateNewWAC() {
    final quantity = int.tryParse(_quantityController.text);
    final cost = double.tryParse(_costController.text);
    
    if (quantity != null && cost != null && quantity > 0 && cost > 0) {
      setState(() {
        _newWAC = WACCalculator.calculateNewWAC(
          currentStock: widget.product.currentStock,
          currentCost: widget.product.costPrice,
          addedQuantity: quantity,
          purchasePrice: cost,
        );
      });
    } else {
      setState(() {
        _newWAC = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCost = (int.tryParse(_quantityController.text) ?? 0) *
        (double.tryParse(_costController.text) ?? 0.0);
    
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Restock Product',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              widget.product.name,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
            
            const Divider(height: 32),
            
            // Current WAC (read-only)
            _buildInfoBox(
              label: 'Current Weighted Average Cost',
              value: '${CurrencyFormatter.formatBirr(widget.product.costPrice)} ብር per unit',
              helperText: 'This will be recalculated after restocking',
            ),
            
            const SizedBox(height: 16),
            
            // Current stock (read-only)
            _buildInfoBox(
              label: 'Current Stock',
              value: '${widget.product.currentStock} units',
            ),
            
            const SizedBox(height: 16),
            
            // Quantity input
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity to Add',
                hintText: 'Enter quantity',
                suffixText: 'units',
              ),
              onChanged: (_) => _calculateNewWAC(),
            ),
            
            const SizedBox(height: 16),
            
            // Cost per unit input
            TextField(
              controller: _costController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Cost Per Unit (New Purchase Price)',
                hintText: 'Enter cost',
                prefixText: 'ብር ',
              ),
              onChanged: (_) => _calculateNewWAC(),
            ),
            
            const SizedBox(height: 16),
            
            // Total cost display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Restock Cost',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${CurrencyFormatter.formatBirr(totalCost)} ብር',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.alertAmber,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_quantityController.text} units × ${CurrencyFormatter.formatBirr(double.tryParse(_costController.text) ?? 0)} ብር',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // New WAC preview
            if (_newWAC != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.tealTint,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primaryLight.withOpacity(0.3),
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Weighted Average Cost (Preview)',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${CurrencyFormatter.formatBirr(_newWAC!)} ብር per unit',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryLight,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '(${widget.product.currentStock} × ${CurrencyFormatter.formatBirr(widget.product.costPrice)} + ${_quantityController.text} × ${CurrencyFormatter.formatBirr(double.tryParse(_costController.text) ?? 0)}) / (${widget.product.currentStock} + ${_quantityController.text})',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This is the new cost basis for profit calculations',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: ElevatedButton(
                    onPressed: _newWAC != null
                        ? () async {
                            try {
                              await ref
                                  .read(productRepositoryProvider)
                                  .restock(
                                    productId: widget.product.id,
                                    quantity: int.parse(_quantityController.text),
                                    costPerUnit: double.parse(_costController.text),
                                  );
                              
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Restocked ${widget.product.name} - New WAC: ${CurrencyFormatter.formatBirr(_newWAC!)} ብር',
                                    ),
                                    backgroundColor: AppColors.successGreen,
                                  ),
                                );
                                
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: AppColors.alertRed,
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                    child: const Text('Confirm Restock'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox({
    required String label,
    required String value,
    String? helperText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (helperText != null) ...[
            const SizedBox(height: 4),
            Text(
              helperText,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
```

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Profit Card Real-Time Synchronization

*For any* database change event (sale recorded, expense added, transaction voided), the profit card SHALL update within 100ms to reflect the new net profit calculation.

**Validates: Requirements 4.4, 4.5, 4.6, 4.7, 25.3**

### Property 2: WAC Calculation Correctness

*For any* product restock operation, the new Weighted Average Cost SHALL equal `(oldStock × oldWAC + newQty × newCost) / (oldStock + newQty)` within floating-point precision tolerance of 0.01.

**Validates: Requirements 6.18, 6.19, 6.20, 6.21, 6.22, 19.6, 20.6**

### Property 3: Cart Stock Constraint

*For any* product in the cart, the quantity SHALL never exceed the product's available stock, and attempting to increment beyond available stock SHALL display "Only [n] units available" feedback.

**Validates: Requirements 5.6, 5.14**

### Property 4: Sale Transaction Atomicity

*For any* sale completion, either ALL of (sale record created AND all product stocks decremented AND cart cleared) succeed atomically, OR the entire transaction rolls back with no partial state changes.

**Validates: Requirements 5.25, 5.26**

### Property 5: Operating Expense Exclusion

*For any* net profit calculation, expenses with `isRestockExpense = true` SHALL be excluded from operating expenses, ensuring restock costs (CapEx) do not reduce daily net profit.

**Validates: Requirements 8.14, 11.8, 19.11, 20.15, 25.8**

### Property 6: Void Transaction Stock Restoration

*For any* voided sale transaction, the product stock SHALL increase by exactly the voided line item quantities, and the sale's `isVoided` flag SHALL be set to true with `voidedAt` timestamp.

**Validates: Requirements 22.3, 22.4**

### Property 7: Price Override Audit

*For any* cart line item with price override applied, the `unitPrice` SHALL differ from the product's current `sellingPrice`, while `unitCost` remains equal to the product's `costPrice` at time of sale for accurate COGS calculation.

**Validates: Requirements 5.12, 5.13**

### Property 8: Low Stock Alert Threshold

*For any* product where `currentStock <= lowStockThreshold AND currentStock > 0`, the product SHALL appear in the low stock alerts list on both home screen and inventory screen.

**Validates: Requirements 4.11, 6.4, 6.5, 6.10**

### Property 9: Bilingual Currency Formatting

*For any* currency amount displayed in the UI, the format SHALL be "#,##0.00 ብር" in Amharic context OR "#,##0.00 Birr" in English context, with comma thousands separator and exactly 2 decimal places.

**Validates: Requirements 12.6, 15.14**

### Property 10: Backup Restore Data Integrity

*For any* backup restore operation, all imported records SHALL match the JSON structure exactly (same field names, types, and values), OR the entire import SHALL rollback with error message indicating which records failed validation.

**Validates: Requirements 24.8, 24.9, 24.11, 24.14**

---

## Error Handling

### Input Validation Strategy

```dart
class Validators {
  static String? requiredField(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  static String? positiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    final num = double.tryParse(value);
    if (num == null) {
      return '$fieldName must be a valid number';
    }
    
    if (num <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    return null;
  }
  
  static String? minLength(String? value, int min, String fieldName) {
    if (value == null || value.length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }
  
  static String? matchPassword(String? value, String? original) {
    if (value != original) {
      return 'Passwords do not match';
    }
    return null;
  }
}
```

### Database Error Handling

```dart
Future<T> _safeDbOperation<T>(
  Future<T> Function() operation, {
  required String errorMessage,
  T? fallbackValue,
}) async {
  try {
    return await operation();
  } on IsarError catch (e) {
    debugPrint('Database error: $e');
    throw Exception('$errorMessage: ${e.message}');
  } catch (e) {
    debugPrint('Unexpected error: $e');
    throw Exception('$errorMessage: $e');
  }
}
```

### Transaction Rollback Pattern

```dart
Future<void> completeSaleWithRollback() async {
  final isar = ref.read(databaseProvider);
  
  try {
    await isar.writeTxn(() async {
      // 1. Create sale record
      final sale = _buildSaleModel();
      await isar.saleModels.put(sale);
      
      // 2. Update stock for each item
      for (var item in state.items) {
        final product = await isar.productModels.get(item.productId);
        
        if (product == null) {
          throw Exception('Product ${item.productId} not found');
        }
        
        if (product.currentStock < item.quantity) {
          throw Exception('Insufficient stock for ${product.name}');
        }
        
        final updated = product.copyWith(
          currentStock: product.currentStock - item.quantity,
        );
        
        await isar.productModels.put(updated);
      }
    });
    
    // Success: clear cart
    state = CartState();
    
  } catch (e) {
    // Transaction automatically rolled back
    rethrow;
  }
}
```

---

## Testing Strategy

### Unit Tests

**WAC Calculator Tests**:
```dart
void main() {
  group('WACCalculator', () {
    test('first purchase returns purchase price', () {
      final wac = WACCalculator.calculateNewWAC(
        currentStock: 0,
        currentCost: 0,
        addedQuantity: 10,
        purchasePrice: 50.0,
      );
      
      expect(wac, equals(50.0));
    });
    
    test('adding same price maintains WAC', () {
      final wac = WACCalculator.calculateNewWAC(
        currentStock: 10,
        currentCost: 50.0,
        addedQuantity: 10,
        purchasePrice: 50.0,
      );
      
      expect(wac, equals(50.0));
    });
    
    test('adding higher price increases WAC', () {
      final wac = WACCalculator.calculateNewWAC(
        currentStock: 10,
        currentCost: 50.0,
        addedQuantity: 10,
        purchasePrice: 60.0,
      );
      
      expect(wac, equals(55.0));
    });
    
    test('calculates correct WAC for complex scenario', () {
      // Stock: 5 units @ 100 birr = 500 birr
      // Add: 15 units @ 80 birr = 1200 birr
      // Total: 20 units @ 85 birr = 1700 birr
      final wac = WACCalculator.calculateNewWAC(
        currentStock: 5,
        currentCost: 100.0,
        addedQuantity: 15,
        purchasePrice: 80.0,
      );
      
      expect(wac, closeTo(85.0, 0.01));
    });
  });
}
```

**Profit Engine Tests**:
```dart
void main() {
  group('ProfitEngine', () {
    test('gross profit equals revenue minus cogs', () {
      final grossProfit = ProfitEngine.calculateGrossProfit(
        revenue: 1000.0,
        cogs: 600.0,
      );
      
      expect(grossProfit, equals(400.0));
    });
    
    test('net profit equals gross profit minus opex', () {
      final netProfit = ProfitEngine.calculateNetProfit(
        grossProfit: 400.0,
        operatingExpenses: 150.0,
      );
      
      expect(netProfit, equals(250.0));
    });
    
    test('margin calculation handles zero revenue', () {
      final margin = ProfitEngine.calculateGrossProfitMargin(
        grossProfit: 100.0,
        revenue: 0.0,
      );
      
      expect(margin, equals(0.0));
    });
    
    test('profit health identifies critical status', () {
      final health = ProfitEngine.analyzeProfitHealth(
        netProfit: -50.0,
        grossMargin: 0.10,
        opExRatio: 0.35,
      );
      
      expect(health.status, equals(HealthStatus.critical));
      expect(health.message, contains('losing money'));
    });
  });
}
```

### Widget Tests

**ProfitCard Tests**:
```dart
void main() {
  testWidgets('ProfitCard displays net profit correctly', (tester) async {
    final container = ProviderContainer(
      overrides: [
        profitProvider.overrideWith((ref) => AsyncValue.data(
          ProfitState(
            netProfit: 12500.50,
            revenue: 50000.0,
            operatingExpenses: 37499.50,
          ),
        )),
      ],
    );
    
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ProfitCard(),
          ),
        ),
      ),
    );
    
    expect(find.text('12,500.50'), findsOneWidget);
    expect(find.text('ብር'), findsWidgets);
  });
  
  testWidgets('Period filter pills update on tap', (tester) async {
    final container = ProviderContainer(
      overrides: [
        profitPeriodProvider.overrideWith((ref) => ProfitPeriod.today),
      ],
    );
    
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ProfitCard(),
          ),
        ),
      ),
    );
    
    // Tap Week filter
    await tester.tap(find.text('Week'));
    await tester.pumpAndSettle();
    
    expect(
      container.read(profitPeriodProvider),
      equals(ProfitPeriod.week),
    );
  });
}
```

### Integration Tests

**Complete Sale Flow**:
```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Complete sale flow', (tester) async {
    await tester.pumpWidget(const EfoyApp());
    await tester.pumpAndSettle();
    
    // Navigate to Sell screen
    await tester.tap(find.text('SELL'));
    await tester.pumpAndSettle();
    
    // Add product to cart
    await tester.tap(find.byType(ProductCard).first);
    await tester.pumpAndSettle();
    
    // Verify cart sheet appears
    expect(find.text('CART'), findsOneWidget);
    
    // Enter amount received
    await tester.enterText(
      find.byType(TextField),
      '1000',
    );
    await tester.pumpAndSettle();
    
    // Complete sale
    await tester.tap(find.text('COMPLETE SALE'));
    await tester.pumpAndSettle();
    
    // Verify success message
    expect(find.text('Sale completed'), findsOneWidget);
    
    // Verify navigation to home
    expect(find.text('HOME'), findsOneWidget);
  });
}
```

---

## Build & Deployment

### Build Configuration

**build.gradle (Android)**:
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        applicationId "com.efoy.retail"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
        
        debug {
            applicationIdSuffix ".debug"
            debuggable true
        }
    }
}
```

**Info.plist (iOS)**:
```xml
<key>CFBundleDisplayName</key>
<string>Efoy</string>
<key>CFBundleName</key>
<string>efoy_retail_app</string>
<key>NSCameraUsageDescription</key>
<string>Camera access required for barcode scanning</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>Photo library access for receipt images</string>
```

### Asset Management

```yaml
flutter:
  uses-material-design: true
  
  assets:
    - asset/efoy.jpg
    - assets/icons/
    - assets/i18n/
  
  fonts:
    - family: NotoSansEthiopic
      fonts:
        - asset: assets/fonts/NotoSansEthiopic-Regular.ttf
        - asset: assets/fonts/NotoSansEthiopic-Bold.ttf
          weight: 700
```

### Release Checklist

- [ ] All unit tests passing
- [ ] All widget tests passing
- [ ] All integration tests passing
- [ ] Golden tests reviewed (visual regression)
- [ ] Accessibility audit completed
- [ ] Performance benchmarks met (60fps scrolling)
- [ ] Build variants tested (debug/release)
- [ ] Backup/restore tested with real data
- [ ] License verification tested (valid/expired/invalid)
- [ ] Dark mode verified on all screens
- [ ] Bilingual text verified (English/Amharic)
- [ ] App icons and splash screen finalized
- [ ] Release notes prepared

---

## Document Summary

This design document comprehensively covers:

1. **Complete Architecture**: 3-layer architecture (UI → State → Data) with Riverpod state management and Isar database
2. **All 8 Screens**: Detailed widget trees, state management, and implementation for Splash, Auth, Home, Sell, Inventory, Expenses, Profile, Settings
3. **25+ Reusable Components**: ProfitCard, AlertCard, ProductCard, CartSheet, RestockModal, PulsingDot, etc.
4. **15+ Riverpod Providers**: profitProvider, cartProvider, inventoryProvider, themeProvider, etc.
5. **Data Models**: Product, Sale, Expense, RestockLog, UserProfile, License with complete field definitions
6. **Business Logic**: WACCalculator (8 functions), ProfitEngine (8 functions), Validators, Formatters
7. **10 Correctness Properties**: Real-time sync, WAC correctness, stock constraints, atomicity, OpEx exclusion, etc.
8. **Complete Animation Specs**: Pulsing dots, pill transitions, cart sheet, success feedback
9. **Error Handling**: Validation patterns, transaction rollback, error boundaries
10. **Testing Strategy**: Unit tests (WAC, Profit), widget tests (ProfitCard), integration tests (sale flow)
11. **Accessibility**: Screen reader support, touch targets, contrast ratios, font scaling
12. **Build Configuration**: Android/iOS settings, asset management, release checklist

All specifications are implementation-ready with code examples, architecture diagrams, and clear technical decisions.
