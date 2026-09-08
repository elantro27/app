import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// Fully local paper-trading ledger. No real orders are ever sent to
/// Zerodha — this only reads live prices and simulates buys/sells against
/// a virtual cash balance stored on-device.
class PaperTradingService {
  static const double startingBalance = 1000000.0;

  double cashBalance = startingBalance;
  final Map<String, Position> positions = {};
  final List<TradeLog> tradeLog = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    cashBalance = prefs.getDouble('pt_cash') ?? startingBalance;

    final posJson = prefs.getString('pt_positions');
    if (posJson != null) {
      final List list = jsonDecode(posJson);
      positions.clear();
      for (final p in list) {
        final pos = Position.fromJson(p);
        positions[pos.symbol] = pos;
      }
    }

    final logJson = prefs.getString('pt_tradelog');
    if (logJson != null) {
      final List list = jsonDecode(logJson);
      tradeLog.clear();
      tradeLog.addAll(list.map((e) => TradeLog.fromJson(e)));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('pt_cash', cashBalance);
    await prefs.setString(
      'pt_positions',
      jsonEncode(positions.values.map((p) => p.toJson()).toList()),
    );
    await prefs.setString(
      'pt_tradelog',
      jsonEncode(tradeLog.map((t) => t.toJson()).toList()),
    );
  }

  /// Executes a simulated buy or sell at the given live price.
  /// Returns an error string, or null on success.
  Future<String?> executeOrder({
    required String symbol,
    required TxnType type,
    required int quantity,
    required double price,
  }) async {
    if (quantity <= 0) return 'Quantity must be greater than 0';

    final cost = price * quantity;
    final existing = positions[symbol];

    if (type == TxnType.buy) {
      if (cost > cashBalance) return 'Insufficient virtual balance';
      cashBalance -= cost;

      if (existing == null) {
        positions[symbol] = Position(symbol: symbol, quantity: quantity, avgPrice: price);
      } else {
        final totalQty = existing.quantity + quantity;
        if (existing.quantity < 0) {
          // Covering a short position
          final realized = (existing.avgPrice - price) * quantity.clamp(0, -existing.quantity);
          tradeLog.add(TradeLog(
            symbol: symbol, type: type, quantity: quantity, price: price,
            time: DateTime.now(), realizedPnl: realized,
          ));
        }
        existing.avgPrice = totalQty == 0
            ? 0
            : ((existing.avgPrice * existing.quantity) + (price * quantity)) /
                totalQty;
        existing.quantity = totalQty;
        if (existing.quantity == 0) positions.remove(symbol);
      }
    } else {
      // Sell (can open/extend a short if no long position held)
      cashBalance += cost;

      if (existing == null) {
        positions[symbol] = Position(symbol: symbol, quantity: -quantity, avgPrice: price);
      } else {
        if (existing.quantity > 0) {
          final realized = (price - existing.avgPrice) * quantity.clamp(0, existing.quantity);
          tradeLog.add(TradeLog(
            symbol: symbol, type: type, quantity: quantity, price: price,
            time: DateTime.now(), realizedPnl: realized,
          ));
        }
        final totalQty = existing.quantity - quantity;
        existing.avgPrice = totalQty == 0 ? 0 : existing.avgPrice;
        existing.quantity = totalQty;
        if (existing.quantity == 0) positions.remove(symbol);
      }
    }

    if (!tradeLog.any((t) => t.time == tradeLog.last.time)) {
      tradeLog.add(TradeLog(
        symbol: symbol, type: type, quantity: quantity, price: price, time: DateTime.now(),
      ));
    }

    await _save();
    return null;
  }

  double totalUnrealizedPnl(Map<String, double> ltpBySymbol) {
    double total = 0;
    for (final pos in positions.values) {
      final ltp = ltpBySymbol[pos.symbol];
      if (ltp != null) total += pos.unrealizedPnl(ltp);
    }
    return total;
  }

  double get totalRealizedPnl =>
      tradeLog.fold(0.0, (sum, t) => sum + (t.realizedPnl ?? 0));

  Future<void> resetAccount() async {
    cashBalance = startingBalance;
    positions.clear();
    tradeLog.clear();
    await _save();
  }
}
