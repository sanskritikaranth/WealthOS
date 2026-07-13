import 'dart:math';
import 'package:flutter/material.dart';

class CalculatorsScreen extends StatefulWidget {
  const CalculatorsScreen({super.key});

  @override
  State<CalculatorsScreen> createState() => _CalculatorsScreenState();
}

class _CalculatorsScreenState extends State<CalculatorsScreen> {
  bool _isSipMode = true; // Toggles between SIP wealth compounding and EMI Debt checking

  // Input Controllers for managing user entries
  final _amountController = TextEditingController(text: '5000'); // Monthly Investment or Loan Principal
  final _rateController = TextEditingController(text: '12');     // Expected Return Rate or Loan Interest Rate
  final _tenureController = TextEditingController(text: '10');   // Investment or Loan Duration in Years

  double _totalDisplayValue = 0.0;
  double _secondaryDisplayValue = 0.0;

  @override
  void initState() {
    super.initState();
    _calculateFinanceMath();
  }

  // Core Math Calculation Suite
  void _calculateFinanceMath() {
    final double amount = double.tryParse(_amountController.text) ?? 0.0;
    final double annualRate = double.tryParse(_rateController.text) ?? 0.0;
    final int years = int.tryParse(_tenureController.text) ?? 0;

    if (amount <= 0 || annualRate <= 0 || years <= 0) return;

    if (_isSipMode) {
      // 1. SIP Wealth Compounding Math Formula
      // Formula: FV = P * [((1 + i)^n - 1) / i] * (1 + i)
      final double monthlyRate = (annualRate / 100) / 12;
      final int months = years * 12;

      final double investedAmount = amount * months;
      final double futureValue = amount * ((pow(1 + monthlyRate, months) - 1) / monthlyRate) * (1 + monthlyRate);

      setState(() {
        _totalDisplayValue = futureValue;            // Estimated Future Wealth
        _secondaryDisplayValue = investedAmount;    // Actual Cash Put In
      });
    } else {
      // 2. EMI Reducing Balance Loan Amortization Math Formula
      // Formula: EMI = [P x R x (1+R)^N] / [((1+R)^N) - 1]
      final double monthlyRate = (annualRate / 100) / 12;
      final int months = years * 12;

      final double emi = (amount * monthlyRate * pow(1 + monthlyRate, months)) / (pow(1 + monthlyRate, months) - 1);
      final double totalRepayment = emi * months;

      setState(() {
        _totalDisplayValue = emi;                   // Monthly Repayment Cost
        _secondaryDisplayValue = totalRepayment;    // Total Cash Payback to Bank
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SEGMENTED TAB SWITCHER: Elegantly switch between SIP and EMI contexts
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('SIP Wealth Predictor')),
                      selected: _isSipMode,
                      selectedColor: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                      onSelected: (val) {
                        setState(() { _isSipMode = true; _amountController.text = '5000'; _rateController.text = '12'; });
                        _calculateFinanceMath();
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('EMI Loan Calculator')),
                      selected: !_isSipMode,
                      selectedColor: const Color(0xFF6C5CE7).withValues(alpha: 0.2),
                      onSelected: (val) {
                        setState(() { _isSipMode = false; _amountController.text = '1000000'; _rateController.text = '9.5'; });
                        _calculateFinanceMath();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // VISUAL CALCULATION HUD CARD
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      _isSipMode ? 'Estimated Future Wealth' : 'Equated Monthly Installment (EMI)',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${_totalDisplayValue.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF6C5CE7)),
                    ),
                    const Divider(height: 24, color: Colors.white10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isSipMode ? 'Total Amount Invested' : 'Total Outstanding Repayment',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        Text(
                          '₹${_secondaryDisplayValue.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // FORM INPUT SHELF
            const Text('Configure Parameters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: _isSipMode ? 'Monthly Investment Amount (₹)' : 'Total Loan Principal Amount (₹)',
                border: const OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              onChanged: (val) => _calculateFinanceMath(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rateController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: _isSipMode ? 'Expected Annual Return Rate (%)' : 'Bank Annual Interest Rate (%)',
                border: const OutlineInputBorder(),
                suffixText: ' %',
              ),
              onChanged: (val) => _calculateFinanceMath(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _tenureController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration Tenure (Years)',
                border: OutlineInputBorder(),
                suffixText: ' Years',
              ),
              onChanged: (val) => _calculateFinanceMath(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    super.dispose();
  }
}