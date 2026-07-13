import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firestore_service.dart';
import 'auth_state_provider.dart';

class WalletState {
  final double bankBalance;
  final double budgetLimit;
  const WalletState({this.bankBalance = 500000.0, this.budgetLimit = 25000.0});
}

class WalletNotifier extends Notifier<WalletState> {
  StreamSubscription<DocumentSnapshot>? _subscription;

  @override
  WalletState build() {
    ref.watch(authStateProvider); // 👈 rebuilds this notifier on every login/logout

    FirestoreService.ensureWalletDefaults();
    _subscription?.cancel();
    _subscription = FirestoreService.walletStream.listen((snap) {
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) return;
      state = WalletState(
        bankBalance: (data['bankBalance'] as num?)?.toDouble() ?? 500000.0,
        budgetLimit: (data['budgetLimit'] as num?)?.toDouble() ?? 25000.0,
      );
    });
    ref.onDispose(() => _subscription?.cancel());
    return const WalletState();
  }

  Future<void> setBankBalance(double value) async {
    await FirestoreService.setBankBalance(value);
  }

  Future<void> setBudgetLimit(double value) async {
    await FirestoreService.setBudgetLimit(value);
  }
}

final walletProvider = NotifierProvider<WalletNotifier, WalletState>(() {
  return WalletNotifier();
});