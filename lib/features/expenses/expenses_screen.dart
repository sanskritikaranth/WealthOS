import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/wallet_provider.dart';
import 'expenses_provider.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _budgetController = TextEditingController();
  final _searchController = TextEditingController();
  bool _budgetControllerInitialized = false;

  bool _isEditingBudget = false;
  String _selectedCategory = "All";
  String _searchQuery = "";

  @override
  void dispose() {
    _budgetController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _saveBudgetThreshold(String value) {
    final double? parsedBudget = double.tryParse(value);
    if (parsedBudget != null && parsedBudget > 0) {
      ref.read(walletProvider.notifier).setBudgetLimit(parsedBudget);
      setState(() {
        _isEditingBudget = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Global budget parameters updated!'), backgroundColor: Color(0xFF30D158)),
      );
    }
  }

  // 🔄 c) Simulated Pull-To-Refresh Async Logic Function
  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _searchController.clear();
        _searchQuery = "";
        _selectedCategory = "All";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double budgetLimit = ref.watch(walletProvider).budgetLimit;
    if (!_budgetControllerInitialized) {
      _budgetController.text = budgetLimit.toStringAsFixed(0);
      _budgetControllerInitialized = true;
    }

    final List<Map<String, dynamic>> transactions = ref.watch(expensesProvider);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final double totalSpent = transactions.fold(0.0, (sum, item) => sum + (item['amount'] as num).toDouble());
    final double budgetProgress = (totalSpent / budgetLimit).clamp(0.0, 1.0);

    // 🔍 a) & d) Live Multi-Filter Cascade Logic Sorting
    final filteredTransactions = transactions.where((tx) {
      final matchesCategory = _selectedCategory == "All" || 
          (tx['category']?.toString().toLowerCase() == _selectedCategory.toLowerCase());
          
      final matchesSearch = _searchQuery.isEmpty || 
          (tx['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
          
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0E17) : const Color(0xFFF9F6EE),
      body: RefreshIndicator(
        color: const Color(0xFF6C5CE7),
        onRefresh: _handleRefresh, // 🔄 Pull-To-Refresh Bind Trigger
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Ensures refreshing works even when list is empty
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // BUDGET CONFIGURATION BLOCK
              Card(
                color: isDark ? const Color(0xFF1F1E26) : Colors.white,
                shape: RoundedRectangleBorder(
                  side: const BorderSide(color: Colors.black, width: 2),
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Monthly Spending Budget',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                          IconButton(
                            icon: Icon(_isEditingBudget ? Icons.check_circle_outline_rounded : Icons.edit_note_rounded, 
                                color: isDark ? const Color(0xFFFF8906) : const Color(0xFF6C5CE7)),
                            onPressed: () {
                              if (_isEditingBudget) {
                                _saveBudgetThreshold(_budgetController.text);
                              } else {
                                setState(() => _isEditingBudget = true);
                              }
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 4),
                      _isEditingBudget
                          ? TextField(
                              controller: _budgetController,
                              keyboardType: TextInputType.number,
                              autofocus: true,
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                              decoration: const InputDecoration(prefixText: '₹ ', isDense: true, border: InputBorder.none),
                              onSubmitted: _saveBudgetThreshold,
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₹${totalSpent.toStringAsFixed(0)} spent',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                                ),
                                Text(
                                  'of ₹${budgetLimit.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: budgetProgress,
                          minHeight: 10,
                          backgroundColor: isDark ? Colors.white10 : Colors.black12,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            budgetProgress >= 0.85 ? Colors.redAccent : const Color(0xFF30D158),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔍 d) NEO-BRUTALIST LIVE INTERACTIVE SEARCH BAR
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F1E26) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black, width: 2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: 'Search merchant or item...',
                    hintStyle: TextStyle(color: Colors.grey.withOpacity(0.7)),
                    border: InputBorder.none,
                    icon: const Icon(Icons.search_rounded, color: Colors.black),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Colors.black),
                          onPressed: () => setState(() { _searchController.clear(); _searchQuery = ""; }),
                        )
                      : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 📊 a) LIVE INTERACTIVE CATEGORY FILTER CHIPS ROW
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ['All', 'Food', 'Housing', 'Entertainment', 'Others'].map((category) {
                    final isSelected = _selectedCategory == category;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(category, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w900)),
                        selected: isSelected,
                        selectedColor: isDark ? const Color(0xFFFF8906) : const Color(0xFF6C5CE7),
                        backgroundColor: isDark ? const Color(0xFF1F1E26) : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                        showCheckmark: false,
                        onSelected: (bool selected) {
                          if (selected) setState(() => _selectedCategory = category);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Transaction Entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  TextButton.icon(
                    onPressed: () => _showAddExpenseModal(context, ref),
                    icon: const Icon(Icons.add_box_rounded, size: 20),
                    label: const Text('Add Item', style: TextStyle(fontWeight: FontWeight.w900)),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF6C5CE7)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // LIVE FILTERED TRANSACTIONS ITERATOR VIEW
              filteredTransactions.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40.0),
                      child: Center(
                        child: Text(
                          _searchQuery.isNotEmpty || _selectedCategory != "All" 
                            ? 'No matches found for active filters.' 
                            : 'No expenses logged yet.',
                          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = filteredTransactions[index];
                        final String txId = tx['id']?.toString() ?? index.toString();

                        return Dismissible(
                          key: Key(txId),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 28),
                          ),
                          onDismissed: (direction) {
                            ref.read(expensesProvider.notifier).deleteExpense(txId);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1F1E26) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.black, width: 2),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDark ? Colors.black12 : Colors.black.withOpacity(0.05),
                                child: Icon(
                                  tx['category'] == 'Food' ? Icons.restaurant_rounded :
                                  tx['category'] == 'Housing' ? Icons.home_rounded : 
                                  tx['category'] == 'Entertainment' ? Icons.confirmation_number_rounded : Icons.wallet_rounded,
                                  color: isDark ? const Color(0xFFFF8906) : const Color(0xFF6C5CE7),
                                ),
                              ),
                              title: Text(tx['title'] ?? 'Expense', style: const TextStyle(fontWeight: FontWeight.w900)),
                              subtitle: Text(tx['date'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                              trailing: Text(
                                '- ₹${(tx['amount'] as num).toDouble().toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.redAccent),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddExpenseModal(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    String selectedCategory = 'Food';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            top: 24, left: 24, right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Log New Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Expense Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: ['Food', 'Housing', 'Entertainment', 'Others']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) { if (val != null) selectedCategory = val; },
                decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C5CE7),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                      final double? parsedAmount = double.tryParse(amountController.text);
                      if (parsedAmount != null) {
                        ref.read(expensesProvider.notifier).addExpense(
                          titleController.text,
                          selectedCategory,
                          parsedAmount,
                        );
                        Navigator.pop(context);
                      }
                    }
                  },
                  child: const Text('Save Expense', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}