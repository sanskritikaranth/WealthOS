import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import '../../core/notification_provider.dart';
import '../../core/services/wallet_provider.dart';
import '../expenses/expenses_provider.dart';
import '../portfolio/portfolio_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final _budgetController = TextEditingController();
  final _bankController = TextEditingController();
  late ConfettiController _confettiController;

  bool _isEditingBudget = false;
  bool _isEditingBank = false;
  bool _isAbbreviated = false;
  bool _controllersInitialized = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _bankController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _saveBudgetThreshold(String value) {
    final double? parsedBudget = double.tryParse(value);
    if (parsedBudget != null && parsedBudget > 0) {
      ref.read(walletProvider.notifier).setBudgetLimit(parsedBudget);
      setState(() => _isEditingBudget = false);
    }
  }

  void _saveBankBalance(String value) {
    final double? parsedBank = double.tryParse(value);
    if (parsedBank != null && parsedBank >= 0) {
      ref.read(walletProvider.notifier).setBankBalance(parsedBank);
      setState(() => _isEditingBank = false);
      _confettiController.play();
    }
  }

  String _formatNetWorth(double value) {
    if (!_isAbbreviated) return '₹${value.toStringAsFixed(2)}';
    if (value >= 10000000) return '₹${(value / 10000000).toStringAsFixed(2)}Cr';
    if (value >= 100000) return '₹${(value / 100000).toStringAsFixed(2)}L';
    if (value >= 1000) return '₹${(value / 1000).toStringAsFixed(1)}K';
    return '₹${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX 1: Safely handle null items to prevent "Null is not a subtype of Map" error
    final dynamic rawTransactions = ref.watch(expensesProvider);
    final List<Map<String, dynamic>> transactions = (rawTransactions as List?)
            ?.where((item) => item != null)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList() ?? [];

    final dynamic rawAlerts = ref.watch(notificationProvider);
    final List<Map<String, dynamic>> inAppAlerts = (rawAlerts as List?)
            ?.where((item) => item != null)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList() ?? [];

    ref.watch(portfolioProvider);

    // 👇 Wallet data now comes from Firestore via walletProvider instead of Hive
    final walletState = ref.watch(walletProvider);
    final double startingBankBalance = walletState.bankBalance;
    final double budgetLimit = walletState.budgetLimit;

    // Populate the edit-mode text fields once wallet data first arrives from Firestore
    if (!_controllersInitialized) {
      _budgetController.text = budgetLimit.toStringAsFixed(0);
      _bankController.text = startingBankBalance.toStringAsFixed(0);
      _controllersInitialized = true;
    }

    // ✅ FIX 3: Bulletproof casting for 'amount' to prevent "int is not a subtype of double"
    final double totalExpenses = transactions.fold(0.0, (sum, item) {
      final amount = item['amount'];
      final double safeAmount = (amount is num) ? amount.toDouble() : 0.0;
      return sum + safeAmount;
    });

    final double currentLiquidCash = startingBankBalance - totalExpenses;

    final double totalInvestmentsValue = ref.read(portfolioProvider.notifier).calculateTotalValue();
    final double trueNetWorth = currentLiquidCash + totalInvestmentsValue;

    // Safety check to avoid division by zero if budget limit is 0
    final double budgetProgressRatio = budgetLimit > 0
        ? (totalExpenses / budgetLimit).clamp(0.0, 1.0)
        : 0.0;

    double lastMonthExpenses = 22400.0;
    double expenseVariancePercent = lastMonthExpenses > 0
        ? ((totalExpenses - lastMonthExpenses) / lastMonthExpenses) * 100
        : 0.0;

    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🚨 IN-APP BANNER FEED
                if (inAppAlerts.isNotEmpty) ...[
                  ...inAppAlerts.map((alert) {
                    final String alertId = alert['id']?.toString() ?? '';

                    return Dismissible(
                      key: Key(alertId),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.redAccent.withOpacity(0.2),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      ),
                      onDismissed: (_) {
                        ref.read(notificationProvider.notifier).dismissAlert(alertId);
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(
                            alert['title']?.toString() ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            alert['body']?.toString() ?? '',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF8A8F9F)),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                ],

                // NET WORTH HOLDER
                GestureDetector(
                  onTap: () => setState(() => _isAbbreviated = !_isAbbreviated),
                  child: Card(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AGGREGATED TRUE NET WORTH (TAP TO TOGGLE)',
                            style: TextStyle(fontSize: 10, color: Color(0xFF8A8F9F), fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _formatNetWorth(trueNetWorth),
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${expenseVariancePercent >= 0 ? "▲ +" : "▼ "}${expenseVariancePercent.toStringAsFixed(1)}% expenses vs last month',
                              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // BUDGET BOARD PANEL
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('MONTHLY EXPENDITURE CEILING', style: TextStyle(fontSize: 10, color: Color(0xFF8A8F9F), fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: Icon(_isEditingBudget ? Icons.check_circle : Icons.edit, size: 18, color: Theme.of(context).colorScheme.primary),
                              onPressed: () {
                                if (_isEditingBudget) _saveBudgetThreshold(_budgetController.text);
                                setState(() => _isEditingBudget = !_isEditingBudget);
                              },
                            )
                          ],
                        ),
                        _isEditingBudget
                            ? TextField(
                                controller: _budgetController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                                onSubmitted: _saveBudgetThreshold,
                              )
                            : Text('₹${budgetLimit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: budgetProgressRatio,
                            minHeight: 6,
                            color: Theme.of(context).colorScheme.primary,
                            backgroundColor: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // CASH AND INVESTMENTS TILES SPLIT
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Liquid Cash', style: TextStyle(fontSize: 12, color: Color(0xFF8A8F9F), fontWeight: FontWeight.bold)),
                                  GestureDetector(
                                    onTap: () {
                                      if (_isEditingBank) _saveBankBalance(_bankController.text);
                                      setState(() => _isEditingBank = !_isEditingBank);
                                    },
                                    child: Icon(_isEditingBank ? Icons.check_circle_outline_rounded : Icons.edit_note_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              _isEditingBank
                                  ? TextField(
                                      controller: _bankController,
                                      keyboardType: TextInputType.number,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                      onSubmitted: _saveBankBalance,
                                    )
                                  : Text('₹${currentLiquidCash.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Investments', style: TextStyle(fontSize: 12, color: Color(0xFF8A8F9F), fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              Text('₹${totalInvestmentsValue.toStringAsFixed(0)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }
}