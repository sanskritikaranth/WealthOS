import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import '../features/dashboard/dashboard_screen.dart';
import '../features/expenses/expenses_screen.dart';
import '../features/chatbot/chatbot_screen.dart';
import '../features/calculators/calculators_screen.dart';
import '../features/portfolio/portfolio_screen.dart';
import 'theme_provider.dart'; 
import 'services/auth_service.dart';
import 'auth_gate.dart';

class NavigationShell extends ConsumerStatefulWidget {
  const NavigationShell({super.key});

  @override
  ConsumerState<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends ConsumerState<NavigationShell> {
  int _currentIndex = 0;
  bool _isChatExpanded = false;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // ✅ FIXED: Renamed local variable to satisfy "no_leading_underscores_for_local_identifiers"
    final List<Widget> screens = [
      const DashboardScreen(),
      const ExpensesScreen(),
      const ChatbotScreen(), 
      const CalculatorsScreen(),
      const PortfolioScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: Text(
          _currentIndex == 0 ? 'Dashboard' :
          _currentIndex == 1 ? 'Expenses' :
          _currentIndex == 2 ? 'AI Insights' :
          _currentIndex == 3 ? 'Predictor' : 'Portfolio',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: Icon(_isChatExpanded ? Icons.chat_bubble_rounded : Icons.chat_bubble_outline_rounded),
            color: const Color(0xFF6C5CE7),
            onPressed: () => setState(() => _isChatExpanded = !_isChatExpanded),
          ), // IconButton
          IconButton(
            icon: Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
            onPressed: () {
              // ✅ FIXED: Triggers public action method interface layer instead of unsafe direct `.state` tampering
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ), // IconButton
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await AuthService.logOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthGate()),
                  (route) => false,
                );
              }
            },
          ), // IconButton — new logout button
        ],
      ), // 👈 ADD THIS LINE — closes AppBar(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), 
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            children: screens,
          ),

          if (_isChatExpanded)
            Positioned(
              top: 0, bottom: 0, left: 0, right: 0,
              child: Container(
                // ✅ FIXED: Used modern non-deprecated Color transparency allocation rules
                color: const Color(0x66000000),
                child: ManagedChatWindow(
                  onClose: () => setState(() => _isChatExpanded = false),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.black, width: 2)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF6C5CE7),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Expenses'),
            BottomNavigationBarItem(icon: Icon(Icons.smart_toy_rounded), label: 'AI Chat'),
            BottomNavigationBarItem(icon: Icon(Icons.calculate_rounded), label: 'Predictor'),
            BottomNavigationBarItem(icon: Icon(Icons.pie_chart_rounded), label: 'Portfolio'),
          ],
        ),
      ),
    );
  }
}

class ManagedChatWindow extends StatelessWidget {
  final VoidCallback onClose;
  const ManagedChatWindow({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Colors.black, width: 2),
      ),
      child: Column(
        children: [
          AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            automaticallyImplyLeading: false,
            leading: const Icon(Icons.smart_toy_rounded, color: Color(0xFF6C5CE7)),
            title: const Text('AI Financial Advisor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            actions: [
              IconButton(icon: const Icon(Icons.close_rounded, color: Colors.black), onPressed: onClose),
            ],
          ),
          const Expanded(child: ChatbotScreen()),
        ],
      ),
    );
  }
}