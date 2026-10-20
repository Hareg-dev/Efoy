import 'package:flutter_test/flutter_test.dart';

import 'package:efoy_retail_app/logic/calculators/wac_calculator.dart';

void main() {
  group('WACCalculator.calculateNewWAC', () {
    test('uses the purchase price when there is no existing stock', () {
      final wac = WACCalculator.calculateNewWAC(
        currentStock: 0,
        currentCost: 12,
        addedQuantity: 50,
        purchasePrice: 18,
      );

      expect(wac, 18);
    });

    test('keeps the current cost when no quantity is added', () {
      final wac = WACCalculator.calculateNewWAC(
        currentStock: 10,
        currentCost: 12.5,
        addedQuantity: 0,
        purchasePrice: 30,
      );

      expect(wac, 12.5);
    });

    test('weights equal quantities evenly', () {
      final wac = WACCalculator.calculateNewWAC(
        currentStock: 10,
        currentCost: 10,
        addedQuantity: 10,
        purchasePrice: 20,
      );

      expect(wac, closeTo(15, 1e-9));
    });

    test('weights unequal quantities by their stock share', () {
      // (5 × 10) + (15 × 20) = 350 over 20 units = 17.5
      final wac = WACCalculator.calculateNewWAC(
        currentStock: 5,
        currentCost: 10,
        addedQuantity: 15,
        purchasePrice: 20,
      );

      expect(wac, closeTo(17.5, 1e-9));
    });

    test('leaves the WAC unchanged when purchase price equals current cost', () {
      final wac = WACCalculator.calculateNewWAC(
        currentStock: 25,
        currentCost: 8.75,
        addedQuantity: 40,
        purchasePrice: 8.75,
      );

      expect(wac, closeTo(8.75, 1e-9));
    });

    test('handles decimal purchase prices without losing precision', () {
      final wac = WACCalculator.calculateNewWAC(
        currentStock: 3,
        currentCost: 10.10,
        addedQuantity: 7,
        purchasePrice: 10.50,
      );

      expect(wac, closeTo(((3 * 10.10) + (7 * 10.50)) / 10, 1e-9));
    });
  });

  group('WACCalculator inventory and margin helpers', () {
    test('calculates inventory value from quantity and WAC', () {
      expect(
        WACCalculator.calculateInventoryValue(quantity: 12, wac: 12.5),
        150,
      );
    });

    test('calculates profit margin from selling price and WAC', () {
      expect(
        WACCalculator.calculateProfitMargin(sellingPrice: 100, wac: 70),
        closeTo(0.30, 1e-9),
      );
    });

    test('returns zero margin for a non-positive selling price', () {
      expect(
        WACCalculator.calculateProfitMargin(sellingPrice: 0, wac: 70),
        0,
      );
      expect(
        WACCalculator.calculateProfitMargin(sellingPrice: -5, wac: 70),
        0,
      );
    });

    test('calculates COGS and gross profit for a sale', () {
      expect(WACCalculator.calculateCOGS(quantity: 4, wac: 15), 60);
      expect(
        WACCalculator.calculateGrossProfit(
          quantity: 4,
          sellingPrice: 25,
          wac: 15,
        ),
        40,
      );
    });

    test('calculates liquidity value at the retail price', () {
      expect(
        WACCalculator.calculateLiquidityValue(
          quantity: 20,
          sellingPrice: 25,
        ),
        500,
      );
    });

    test('recommends a price for a target margin', () {
      expect(
        WACCalculator.calculateRecommendedPrice(wac: 70, desiredMargin: 0.30),
        closeTo(100, 1e-9),
      );
    });

    test('rejects target margins outside 0..1', () {
      expect(
        () => WACCalculator.calculateRecommendedPrice(
          wac: 70,
          desiredMargin: 1,
        ),
        throwsArgumentError,
      );
      expect(
        () => WACCalculator.calculateRecommendedPrice(
          wac: 70,
          desiredMargin: -0.1,
        ),
        throwsArgumentError,
      );
    });

    test('calculates break-even quantity, rounding up', () {
      // 1000 fixed costs / (25 - 15) contribution = 100 units
      expect(
        WACCalculator.calculateBreakEvenQuantity(
          fixedCosts: 1000,
          sellingPrice: 25,
          wac: 15,
        ),
        100,
      );
      // 1001 / 10 = 100.1 → 101
      expect(
        WACCalculator.calculateBreakEvenQuantity(
          fixedCosts: 1001,
          sellingPrice: 25,
          wac: 15,
        ),
        101,
      );
    });

    test('returns -1 when there is no positive contribution margin', () {
      expect(
        WACCalculator.calculateBreakEvenQuantity(
          fixedCosts: 1000,
          sellingPrice: 15,
          wac: 15,
        ),
        -1,
      );
      expect(
        WACCalculator.calculateBreakEvenQuantity(
          fixedCosts: 1000,
          sellingPrice: 10,
          wac: 15,
        ),
        -1,
      );
    });
  });
}
