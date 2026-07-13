import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  // Box names acting as our NoSQL table identifiers
  static const String userWalletBox = 'user_wallet_box';
  static const String expensesBox = 'expenses_box';
  static const String portfolioBox = 'portfolio_box';
  static const String authBox = 'auth_box'; // 👈 new

  /// Global initialization function to clear old instances and open standard sandboxes
  static Future<void> initializeAndOpen() async {
    await Hive.initFlutter();

    // Open the boxes in memory so they are ready for reading/writing instantly across tabs
    await Hive.openBox(userWalletBox);
    await Hive.openBox(expensesBox);
    await Hive.openBox(portfolioBox);
    await Hive.openBox(authBox); // 👈 new
  }
}