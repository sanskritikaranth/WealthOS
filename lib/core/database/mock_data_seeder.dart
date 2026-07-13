import 'package:hive_flutter/hive_flutter.dart';
import 'hive_boxes.dart';

class MockDataSeeder {
  static void seedInitialFinancialData() {
    final walletBox = Hive.box(HiveBoxes.userWalletBox);
    final expensesBox = Hive.box(HiveBoxes.expensesBox);
    final portfolioBox = Hive.box(HiveBoxes.portfolioBox);

    // 1. Seed Base Wallet Balance if empty (Used for Net Worth Calculations)
    if (walletBox.isEmpty) {
      walletBox.put('mock_bank_balance', 500000.0); // Starts with ₹5,00,000 base currency
      walletBox.put('monthly_budget_limit', 25000.0); // Monthly spending limit cap
    }

    // 2. Seed Default Expense Category Budgets if empty
    if (expensesBox.isEmpty) {
      final List<Map<String, dynamic>> defaultExpenses = [
        {'id': '1', 'title': 'Dinner out', 'category': 'Food', 'amount': 1200.0, 'date': '2026-06-18'},
        {'id': '2', 'title': 'Monthly Rent', 'category': 'Housing', 'amount': 12000.0, 'date': '2026-06-01'},
        {'id': '3', 'title': 'Coffee run', 'category': 'Food', 'amount': 300.0, 'date': '2026-06-19'},
      ];
      expensesBox.put('transaction_history', defaultExpenses);
    }

    // 3. Seed Default Investment Portfolio Watchlist if empty
    if (portfolioBox.isEmpty) {
      final List<Map<String, dynamic>> defaultStocks = [
        {'symbol': 'AAPL', 'name': 'Apple Inc.', 'shares': 5, 'purchase_price': 175.0, 'current_price': 182.4},
        {'symbol': 'BTC', 'name': 'Bitcoin', 'shares': 0.05, 'purchase_price': 62000.0, 'current_price': 64500.2},
      ];
      portfolioBox.put('asset_watchlist', defaultStocks);
    }
  }
}