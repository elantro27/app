import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/market_data_service.dart';
import '../services/paper_trading_service.dart';
import '../theme/app_theme.dart';
import 'order_screen.dart';

class WatchlistScreen extends StatefulWidget {
  final PaperTradingService paperTradingService;
  const WatchlistScreen({super.key, required this.paperTradingService});

  @override
  State<WatchlistScreen> createState() => _WatchlistScreenState();
}

class _WatchlistScreenState extends State<WatchlistScreen> {
  final MarketDataService _marketData = MarketDataService();
  Map<String, IndexQuote> _quotes = {};
  StreamSubscription<List<IndexQuote>>? _sub;
  bool _loadedOnce = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sub = _marketData.quoteStream().listen((quotes) {
      if (!mounted) return;
      setState(() {
        for (final q in quotes) {
          _quotes[q.symbol] = q;
        }
        _loadedOnce = true;
        _error = null;
      });
    }, onError: (e) {
      if (mounted) setState(() => _error = e.toString());
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quotes = _quotes.values.toList()
      ..sort((a, b) => a.symbol.compareTo(b.symbol));

    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: !_loadedOnce
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_error != null)
                  Container(
                    width: double.infinity,
                    color: Colors.orange.shade50,
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      'Live feed hiccup — showing last known prices',
                      style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    itemCount: quotes.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, i) => _QuoteRow(
                      quote: quotes[i],
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderScreen(
                            quote: quotes[i],
                            paperTradingService: widget.paperTradingService,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _QuoteRow extends StatelessWidget {
  final IndexQuote quote;
  final VoidCallback onTap;
  const _QuoteRow({required this.quote, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.pnlColor(quote.change);
    final sign = quote.change >= 0 ? '+' : '';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quote.symbol,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(quote.exchange,
                      style: const TextStyle(
                          color: AppColors.secondaryText, fontSize: 11)),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                quote.ltp.toStringAsFixed(2),
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('$sign${quote.change.toStringAsFixed(2)}',
                      style: TextStyle(color: color, fontSize: 13)),
                  Text('$sign${quote.changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(color: color, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
