import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/models.dart';
import '../services/market_data_service.dart';
import '../theme/app_theme.dart';

class ChartsScreen extends StatefulWidget {
  const ChartsScreen({super.key});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  final MarketDataService _marketData = MarketDataService();
  StreamSubscription<List<IndexQuote>>? _sub;

  // Rolling price history per symbol, capped so the chart stays readable.
  final Map<String, List<FlSpot>> _history = {};
  final Map<String, double> _latestLtp = {};
  static const int _maxPoints = 60;
  int _tick = 0;

  String _selected = 'NIFTY 50';
  final List<String> _symbols = [
    'NIFTY 50',
    'NIFTY BANK',
    'NIFTY FIN SERVICE',
    'SENSEX',
  ];

  @override
  void initState() {
    super.initState();
    _sub = _marketData.quoteStream().listen((quotes) {
      if (!mounted) return;
      setState(() {
        _tick++;
        for (final q in quotes) {
          _latestLtp[q.symbol] = q.ltp;
          final list = _history.putIfAbsent(q.symbol, () => []);
          list.add(FlSpot(_tick.toDouble(), q.ltp));
          if (list.length > _maxPoints) list.removeAt(0);
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
    final points = _history[_selected] ?? [];
    final ltp = _latestLtp[_selected];

    double minY = 0, maxY = 100;
    if (points.isNotEmpty) {
      final ys = points.map((p) => p.y);
      minY = ys.reduce((a, b) => a < b ? a : b);
      maxY = ys.reduce((a, b) => a > b ? a : b);
      final pad = (maxY - minY) * 0.15 + 0.5;
      minY -= pad;
      maxY += pad;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Charts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _symbols.map((s) {
                  final sel = s == _selected;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: sel,
                      onSelected: (_) => setState(() => _selected = s),
                      selectedColor: AppColors.kiteBlue.withOpacity(0.15),
                      labelStyle: TextStyle(
                        color: sel ? AppColors.kiteBlue : AppColors.secondaryText,
                        fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: sel ? AppColors.kiteBlue : AppColors.divider,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          if (ltp != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  ltp.toStringAsFixed(2),
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          const SizedBox(height: 12),
          Expanded(
            child: points.length < 2
                ? const Center(
                    child: Text(
                      'Collecting live data...',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
                    child: LineChart(
                      LineChartData(
                        minY: minY,
                        maxY: maxY,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: (maxY - minY) / 4,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: AppColors.divider,
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 56,
                              interval: (maxY - minY) / 4,
                              getTitlesWidget: (value, meta) => Text(
                                value.toStringAsFixed(0),
                                style: const TextStyle(
                                    fontSize: 10, color: AppColors.secondaryText),
                              ),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: points,
                            isCurved: true,
                            barWidth: 2,
                            color: AppTheme.pnlColor(
                                points.last.y - points.first.y),
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppTheme.pnlColor(
                                      points.last.y - points.first.y)
                                  .withOpacity(0.08),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
