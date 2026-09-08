import 'package:flutter/material.dart';
import 'services/paper_trading_service.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PaperTraderApp());
}

class PaperTraderApp extends StatefulWidget {
  const PaperTraderApp({super.key});

  @override
  State<PaperTraderApp> createState() => _PaperTraderAppState();
}

class _PaperTraderAppState extends State<PaperTraderApp> {
  final PaperTradingService _paperTradingService = PaperTradingService();
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _paperTradingService.load();
    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Paper Trader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: !_ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : HomeShell(paperTradingService: _paperTradingService),
    );
  }
}
