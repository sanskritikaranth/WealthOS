import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/notification_provider.dart';
import '../../core/services/firestore_service.dart';
import '../../core/services/auth_state_provider.dart';

class PortfolioNotifier extends Notifier<List<Map<String, dynamic>>> {
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  List<Map<String, dynamic>> build() {
    ref.watch(authStateProvider); // 👈 rebuilds this notifier on every login/logout

    FirestoreService.seedDefaultPortfolio();
    _subscription?.cancel();
    _subscription = FirestoreService.portfolioStream.listen((snapshot) {
      state = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();
    });
    ref.onDispose(() => _subscription?.cancel());
    return [];
  }

  Future<void> addAsset(String name, double shares, double buyPrice, double currentPrice, String type) async {
    final newAsset = {
      'name': name.toUpperCase(),
      'shares': shares,
      'buy_price': buyPrice,
      'current_price': currentPrice,
      'type': type,
    };
    await FirestoreService.addAsset(newAsset);
    await _runComprehensivePortfolioAnalysis();
  }

  Future<void> editAsset(String id, double shares, double currentPrice) async {
    final asset = state.firstWhere((a) => a['id'] == id, orElse: () => {});
    if (asset.isNotEmpty) {
      final double oldPrice = (asset['current_price'] as num? ?? 0).toDouble();
      final double changePct = oldPrice > 0 ? ((currentPrice - oldPrice) / oldPrice) * 100 : 0.0;

      if (changePct >= 5.0) {
        final double holdingVal = shares * currentPrice;
        ref.read(notificationProvider.notifier).triggerCombinedAlert(
          title: '🚀 ${asset['name']} Surge Alert',
          body: '${asset['name']} is up ${changePct.toStringAsFixed(1)}% today — your holding is now worth ₹${holdingVal.toStringAsFixed(0)}',
          type: 'asset_surge',
          nativeId: 201,
        );
      }
    }

    await FirestoreService.updateAsset(id, {
      'shares': shares,
      'current_price': currentPrice,
    });

    await _runComprehensivePortfolioAnalysis();
  }

  Future<void> _runComprehensivePortfolioAnalysis() async {
    final double totalValue = calculateTotalValue();
    if (totalValue <= 0) return;

    final notificationNotifier = ref.read(notificationProvider.notifier);

    for (var asset in state) {
      final double shares = (asset['shares'] as num? ?? 0).toDouble();
      final double currentPrice = (asset['current_price'] as num? ?? 0).toDouble();
      final double assetVal = shares * currentPrice;
      final double ratio = assetVal / totalValue;

      if (ratio >= 0.75) {
        notificationNotifier.triggerCombinedAlert(
          title: '⚖️ Portfolio Concentration warning',
          body: '${asset['name']} is ${(ratio * 100).toStringAsFixed(0)}% of your portfolio — consider rebalancing',
          type: 'portfolio_risk',
          nativeId: 202,
        );
      }
    }

    final double historicalHigh = await FirestoreService.getPortfolioAth();
    if (totalValue > historicalHigh) {
      await FirestoreService.setPortfolioAth(totalValue);
      notificationNotifier.triggerCombinedAlert(
        title: '🏆 Portfolio New High Record',
        body: 'New peak! Your total portfolio just crossed ₹${totalValue.toStringAsFixed(0)}',
        type: 'portfolio_ath',
        nativeId: 203,
      );
    }

    double undeployedCash = 11500.0;
    if (undeployedCash > 10000) {
      notificationNotifier.triggerCombinedAlert(
        title: '💸 SIP Deployment Reminder',
        body: 'You have ₹${undeployedCash.toStringAsFixed(0)} undeployed this month — consider a SIP before the 28th',
        type: 'sip_unmet',
        nativeId: 204,
      );
    }
  }

  Future<void> deleteAsset(String id) async {
    await FirestoreService.deleteAsset(id);
  }

  double calculateTotalValue() {
    double runningSum = 0.0;
    for (var asset in state) {
      final double shares = (asset['shares'] as num? ?? 0).toDouble();
      final double price = (asset['current_price'] as num? ?? 0).toDouble();
      runningSum += (shares * price);
    }
    return runningSum;
  }
}

final portfolioProvider = NotifierProvider<PortfolioNotifier, List<Map<String, dynamic>>>(() {
  return PortfolioNotifier();
});