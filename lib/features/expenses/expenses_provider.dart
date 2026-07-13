import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/notification_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/wallet_provider.dart';
import '../../core/services/auth_state_provider.dart';

class ExpensesNotifier extends Notifier<List<Map<String, dynamic>>> {
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  List<Map<String, dynamic>> build() {
    ref.watch(authStateProvider); // 👈 rebuilds this notifier on every login/logout

    FirestoreService.seedDefaultExpenses();
    _subscription?.cancel();
    _subscription = FirestoreService.expensesStream.listen((snapshot) {
      state = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    });
    ref.onDispose(() => _subscription?.cancel());
    return [];
  }

  Future<void> addExpense(String title, String category, double amount) async {
    final double budgetLimit = ref.read(walletProvider).budgetLimit;

    final double previousTotal = state.fold(0.0, (sum, item) => sum + (item['amount'] as num? ?? 0).toDouble());
    final double newTotal = previousTotal + amount;

    final newTx = {
      'title': title,
      'category': category,
      'amount': amount,
      'date': DateTime.now().toIso8601String().split('T')[0],
    };

    await FirestoreService.addExpense(newTx);

    final notificationNotifier = ref.read(notificationProvider.notifier);

    if (amount >= 12000) {
      notificationNotifier.triggerCombinedAlert(
        title: '🐳 Big Spend Alert',
        body: 'Big spend alert: ₹${amount.toStringAsFixed(0)} logged for $title',
        type: 'large_spend',
        nativeId: 101,
      );
    }

    final double previousRatio = previousTotal / budgetLimit;
    final double newRatio = newTotal / budgetLimit;

    if (previousRatio < 0.5 && newRatio >= 0.5 && newRatio < 0.8) {
      final int daysInMonth = DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;
      final int daysLeft = daysInMonth - DateTime.now().day;
      notificationNotifier.triggerCombinedAlert(
        title: '⚠️ 50% Budget Used',
        body: "You're halfway through your June budget with $daysLeft days left",
        type: 'budget_half',
        nativeId: 102,
      );
    } else if (previousRatio < 0.8 && newRatio >= 0.8 && newRatio < 1.0) {
      notificationNotifier.triggerCombinedAlert(
        title: '🛑 80% Warning Limit Reached',
        body: 'Approaching monthly threshold. Total spent: ₹${newTotal.toStringAsFixed(0)}.',
        type: 'budget_warn',
        nativeId: 103,
      );
    } else if (previousRatio < 1.0 && newRatio >= 1.0) {
      final double overSpent = newTotal - budgetLimit;
      notificationNotifier.triggerCombinedAlert(
        title: '🚨 Budget Completely Blown',
        body: "Budget exceeded! You've spent ₹${overSpent.toStringAsFixed(0)} over your ₹${budgetLimit.toStringAsFixed(0)} limit",
        type: 'budget_blown',
        nativeId: 104,
      );
    }

    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final double todayTotal = state
        .where((tx) => tx['date'] == todayStr)
        .fold(0.0, (sum, item) => sum + (item['amount'] as num? ?? 0).toDouble()) + amount;

    const double typicalDailyAverage = 1200.0;
    if (todayTotal > (typicalDailyAverage * 2.5)) {
      notificationNotifier.triggerCombinedAlert(
        title: '⚡ Daily Spending Spike Detected',
        body: "You spent ₹${todayTotal.toStringAsFixed(0)} today, higher than your daily average",
        type: 'daily_spike',
        nativeId: 105,
      );
    }
  }

  Future<void> deleteExpense(String id) async {
    await FirestoreService.deleteExpense(id);
  }
}

final expensesProvider = NotifierProvider<ExpensesNotifier, List<Map<String, dynamic>>>(() {
  return ExpensesNotifier();
});