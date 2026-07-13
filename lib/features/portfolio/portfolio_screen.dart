import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'portfolio_provider.dart';

class PortfolioScreen extends ConsumerStatefulWidget {
  const PortfolioScreen({super.key});

  @override
  ConsumerState<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends ConsumerState<PortfolioScreen> with SingleTickerProviderStateMixin {
  int? _expandedIndex;
  String _sortBy = "Name"; 
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _triggerRefresh() async {
    _spinController.forward(from: 0.0);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> rawAssets = ref.watch(portfolioProvider);
    final double totalPortfolioValue = ref.read(portfolioProvider.notifier).calculateTotalValue();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    List<Map<String, dynamic>> sortedAssets = [...rawAssets];
    if (_sortBy == "Name") {
      sortedAssets.sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
    } else if (_sortBy == "Value") {
      sortedAssets.sort((a, b) {
        final valA = ((a['shares'] as num? ?? 0) * (a['current_price'] as num? ?? 0));
        final valB = ((b['shares'] as num? ?? 0) * (b['current_price'] as num? ?? 0));
        return valB.compareTo(valA);
      });
    } else if (_sortBy == "Gain") {
      sortedAssets.sort((a, b) {
        final buyA = (a['buy_price'] as num? ?? 1).toDouble();
        final curA = (a['current_price'] as num? ?? 0).toDouble();
        final gainA = ((curA - buyA) / buyA);

        final buyB = (b['buy_price'] as num? ?? 1).toDouble();
        final curB = (b['current_price'] as num? ?? 0).toDouble();
        final gainB = ((curB - buyB) / buyB);
        return gainB.compareTo(gainA);
      });
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x269185F2) : const Color(0xFF6C5CE7),
                borderRadius: BorderRadius.circular(16),
                border: isDark ? Border.all(color: const Color(0x4D9185F2), width: 1) : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOTAL PORTFOLIO HOLDINGS VALUE', 
                    style: TextStyle(
                      fontSize: 10, 
                      color: isDark ? const Color(0xFF9185F2) : Colors.white70, 
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${totalPortfolioValue.toStringAsFixed(2)}', 
                    style: TextStyle(
                      fontSize: 30, 
                      fontWeight: FontWeight.w900, 
                      color: isDark ? const Color(0xFFE2E0FF) : Colors.white, 
                      letterSpacing: -0.5
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text('Sort by: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          isDense: true,
                          dropdownColor: Theme.of(context).cardColor,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                          items: const [
                            DropdownMenuItem(value: "Name", child: Text("Name")),
                            DropdownMenuItem(value: "Value", child: Text("Value")),
                            DropdownMenuItem(value: "Gain", child: Text("Gain %")),
                          ],
                          onChanged: (val) { if (val != null) setState(() => _sortBy = val); },
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    RotationTransition(
                      turns: _spinController,
                      child: IconButton(
                        icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white70 : Colors.black87),
                        onPressed: _triggerRefresh,
                      ),
                    )
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showAddAssetModal(context, ref),
                  icon: const Icon(Icons.add_box_rounded, size: 20),
                  label: const Text('Add Asset', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: isDark ? const Color(0xFF2EE59D) : const Color(0xFF6C5CE7)),
                ),
              ],
            ),
            const SizedBox(height: 12),

            sortedAssets.isEmpty
                ? const Center(child: Padding(
                    padding: EdgeInsets.only(top: 40.0),
                    child: Text('Watchlist empty. Add an asset to begin tracker logs.', style: TextStyle(color: Colors.grey)),
                  ))
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedAssets.length,
                    itemBuilder: (context, index) {
                      final asset = sortedAssets[index];
                      final String assetId = asset['id']?.toString() ?? index.toString();
                      final isExpanded = _expandedIndex == index;

                      final double shares = (asset['shares'] as num? ?? 0).toDouble();
                      final double buyPrice = (asset['buy_price'] as num? ?? 1).toDouble();
                      final double currentPrice = (asset['current_price'] as num? ?? 0).toDouble();
                      final double holdingValue = shares * currentPrice;

                      final double profitPercentage = ((currentPrice - buyPrice) / buyPrice) * 100;
                      final bool isProfit = profitPercentage >= 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(
                          children: [
                            ListTile(
                              onTap: () => setState(() => _expandedIndex = isExpanded ? null : index),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0x08FFFFFF),
                                child: Icon(
                                  asset['type'] == 'Crypto' ? Icons.currency_bitcoin_rounded : Icons.show_chart_rounded,
                                  color: isDark ? const Color(0xFF9185F2) : const Color(0xFF6C5CE7),
                                ),
                              ),
                              title: Text(asset['name'] ?? 'Asset Ticker', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Holdings: $shares units', style: const TextStyle(fontSize: 12, color: Color(0xFF8A8F9F))),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('₹${holdingValue.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isProfit ? const Color(0x1A4CD137) : const Color(0x1AEE5253),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${isProfit ? "▲ +" : "▼ "}${profitPercentage.toStringAsFixed(1)}%',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isProfit ? const Color(0xFF2EE59D) : Colors.redAccent),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (isExpanded) ...[
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('7-DAY TREND TIMELINE (SIMULATED)', style: TextStyle(fontSize: 9, color: Color(0xFF8A8F9F), fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 50,
                                      width: double.infinity,
                                      child: CustomPaint(painter: SimulatedChartPainter(isProfit: isProfit, isDark: isDark)),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Bought at: ₹${buyPrice.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, color: Color(0xFF8A8F9F))),
                                        Text('Current price: ₹${currentPrice.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12, color: Color(0xFF8A8F9F))),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0x1A448AFF), 
                                              foregroundColor: Colors.blueAccent,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                            ),
                                            icon: const Icon(Icons.edit_note_rounded, size: 18, color: Colors.blueAccent),
                                            label: const Text('Edit Shares', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                                            onPressed: () => _showEditAssetModal(context, ref, asset),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0x1AFF5252), 
                                              foregroundColor: Colors.redAccent,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                                            ),
                                            icon: const Icon(Icons.delete_sweep_rounded, size: 18, color: Colors.redAccent),
                                            label: const Text('Delete Ticker', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                                            onPressed: () {
                                              ref.read(portfolioProvider.notifier).deleteAsset(assetId);
                                              setState(() => _expandedIndex = null);
                                            },
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              )
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void _showAddAssetModal(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final sharesController = TextEditingController();
    final buyPriceController = TextEditingController();
    final currentPriceController = TextEditingController();
    String typeSelection = 'Stock';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Add New Asset Holdings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Asset Name (e.g. INFOSYS)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: sharesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Units Owned', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: buyPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Buy Purchase Price (₹)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: currentPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Current Market Value (₹)', border: OutlineInputBorder())),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: typeSelection,
                items: const [DropdownMenuItem(value: 'Stock', child: Text('Equity Stock')), DropdownMenuItem(value: 'Crypto', child: Text('Crypto Token'))],
                onChanged: (val) { if (val != null) typeSelection = val; },
                decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Asset Category Type'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                  onPressed: () {
                    if (nameController.text.isNotEmpty && sharesController.text.isNotEmpty && buyPriceController.text.isNotEmpty && currentPriceController.text.isNotEmpty) {
                      ref.read(portfolioProvider.notifier).addAsset(
                        nameController.text,
                        double.tryParse(sharesController.text) ?? 0,
                        double.tryParse(buyPriceController.text) ?? 0,
                        double.tryParse(currentPriceController.text) ?? 0,
                        typeSelection,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: Text('Add to Watchlist', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  void _showEditAssetModal(BuildContext context, WidgetRef ref, Map<String, dynamic> asset) {
    final sharesController = TextEditingController(text: asset['shares'].toString());
    final currentPriceController = TextEditingController(text: asset['current_price'].toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(top: 24, left: 24, right: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Modify ${asset['name']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: sharesController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Updated Share Count', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: currentPriceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Live Spot Price (₹)', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                  onPressed: () {
                    ref.read(portfolioProvider.notifier).editAsset(
                      asset['id'],
                      double.tryParse(sharesController.text) ?? 0,
                      double.tryParse(currentPriceController.text) ?? 0,
                    );
                    Navigator.pop(context);
                  },
                  child: Text('Save Changes', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

class SimulatedChartPainter extends CustomPainter {
  final bool isProfit;
  final bool isDark;
  SimulatedChartPainter({required this.isProfit, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isProfit 
          ? (isDark ? const Color(0xFF2EE59D) : Colors.green) 
          : Colors.redAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path()..moveTo(0, size.height * 0.5);
    path.lineTo(size.width * 0.25, size.height * (isProfit ? 0.3 : 0.7));
    path.lineTo(size.width * 0.5, size.height * (isProfit ? 0.6 : 0.4));
    path.lineTo(size.width * 0.75, size.height * (isProfit ? 0.2 : 0.8));
    path.lineTo(size.width, size.height * (isProfit ? 0.1 : 0.9));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}