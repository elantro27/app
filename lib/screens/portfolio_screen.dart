import 'dart:async';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/market_data_service.dart';
import '../services/paper_trading_service.dart';
import '../theme/app_theme.dart';

class PortfolioScreen extends StatefulWidget {
  final PaperTradingService paperTradingService;

  const PortfolioScreen({
    super.key,
    required this.paperTradingService,
  });

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final MarketDataService _marketData = MarketDataService();
  StreamSubscription<List<IndexQuote>>? _sub;
  final Map<String, double> _ltpBySymbol = {};

  @override
  void initState() {
    super.initState();
    _sub = _marketData.quoteStream().listen((quotes) {
      if (!mounted) return;
      setState(() {
        for (final q in quotes) {
          _ltpBySymbol[q.symbol] = q.ltp;
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pt = widget.paperTradingService;
    final positions = pt.positions.values.toList();
    final unrealized = pt.totalUnrealizedPnl(_ltpBySymbol);
    final realized = pt.totalRealizedPnl;
    final netWorth = pt.cashBalance + unrealized;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Reset paper account',
            onPressed: () => _confirmReset(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SummaryCard(
            cash: pt.cashBalance,
            netWorth: netWorth,
            unrealized: unrealized,
            realized: realized,
          ),
          const SizedBox(height: 24),
          const Text('Open Positions',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          if (positions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No open positions',
                  style: TextStyle(color: AppColors.secondaryText)),
            )
          else
            ...positions.map((p) => _PositionTile(
                  position: p,
                  ltp: _ltpBySymbol[p.symbol] ?? p.avgPrice,
                )),
          const SizedBox(height: 24),
          const Text('Recent Trades',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          if (pt.tradeLog.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No trades yet',
                  style: TextStyle(color: AppColors.secondaryText)),
            )
          else
            ...pt.tradeLog.reversed.take(20).map((t) => _TradeTile(trade: t)),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset paper account?'),
        content: const Text(
            'This clears all positions and trade history and resets your virtual balance to ₹10,00,000.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await widget.paperTradingService.resetAccount();
              if (context.mounted) {
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Reset', style: TextStyle(color: AppColors.negativeRed)),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final double cash;
  final double netWorth;
  final double unrealized;
  final double realized;

  const _SummaryCard({
    required this.cash,
    required this.netWorth,
    required this.unrealized,
    required this.realized,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Net Worth', style: TextStyle(color: AppColors.secondaryText)),
          Text('₹${netWorth.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(label: 'Cash', value: '₹${cash.toStringAsFixed(2)}'),
              _Stat(
                label: 'Unrealized P&L',
                value: '₹${unrealized.toStringAsFixed(2)}',
                color: AppTheme.pnlColor(unrealized),
              ),
              _Stat(
                label: 'Realized P&L',
                value: '₹${realized.toStringAsFixed(2)}',
                color: AppTheme.pnlColor(realized),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _Stat({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.secondaryText)),
          Text(value,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _PositionTile extends StatelessWidget {
  final Position position;
  final double ltp;
  const _PositionTile({required this.position, required this.ltp});

  @override
  Widget build(BuildContext context) {
    final pnl = position.unrealizedPnl(ltp);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(position.symbol, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                '${position.quantity} @ ${position.avgPrice.toStringAsFixed(2)} · LTP ${ltp.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
              ),
            ],
          ),
          Text(pnl.toStringAsFixed(2),
              style: TextStyle(color: AppTheme.pnlColor(pnl), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TradeTile extends StatelessWidget {
  final TradeLog trade;
  const _TradeTile({required this.trade});

  @override
  Widget build(BuildContext context) {
    final isBuy = trade.type == TxnType.buy;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isBuy ? AppColors.positiveGreen : AppColors.negativeRed)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isBuy ? 'BUY' : 'SELL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isBuy ? AppColors.positiveGreen : AppColors.negativeRed,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${trade.symbol}  ${trade.quantity} @ ${trade.price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13)),
            ],
          ),
          Text(
            '${trade.time.hour.toString().padLeft(2, '0')}:${trade.time.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 11, color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}
