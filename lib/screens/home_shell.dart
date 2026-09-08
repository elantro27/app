import 'package:flutter/material.dart';
import '../services/paper_trading_service.dart';
import '../theme/app_theme.dart';
import 'watchlist_screen.dart';
import 'charts_screen.dart';
import 'portfolio_screen.dart';

class HomeShell extends StatefulWidget {
  final PaperTradingService paperTradingService;
  const HomeShell({super.key, required this.paperTradingService});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final screens = [
      WatchlistScreen(paperTradingService: widget.paperTradingService),
      const ChartsScreen(),
      PortfolioScreen(paperTradingService: widget.paperTradingService),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: AppColors.background,
        indicatorColor: AppColors.kiteBlue.withOpacity(0.12),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt, color: AppColors.kiteBlue),
            label: 'Watchlist',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart, color: AppColors.kiteBlue),
            label: 'Charts',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart, color: AppColors.kiteBlue),
            label: 'Portfolio',
          ),
        ],
      ),
    );
  }
}
