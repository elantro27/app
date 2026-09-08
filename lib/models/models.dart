class IndexQuote {
  final String symbol; // e.g. "NIFTY 50"
  final String exchange; // NSE / BSE
  final int instrumentToken;
  double ltp;
  double change;
  double changePercent;
  double open;
  double high;
  double low;
  double prevClose;

  IndexQuote({
    required this.symbol,
    required this.exchange,
    required this.instrumentToken,
    this.ltp = 0,
    this.change = 0,
    this.changePercent = 0,
    this.open = 0,
    this.high = 0,
    this.low = 0,
    this.prevClose = 0,
  });
}

enum TxnType { buy, sell }

class Position {
  final String symbol;
  int quantity; // net qty, negative = short
  double avgPrice;

  Position({
    required this.symbol,
    required this.quantity,
    required this.avgPrice,
  });

  double unrealizedPnl(double ltp) => (ltp - avgPrice) * quantity;

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'quantity': quantity,
        'avgPrice': avgPrice,
      };

  factory Position.fromJson(Map<String, dynamic> j) => Position(
        symbol: j['symbol'],
        quantity: j['quantity'],
        avgPrice: (j['avgPrice'] as num).toDouble(),
      );
}

class TradeLog {
  final String symbol;
  final TxnType type;
  final int quantity;
  final double price;
  final DateTime time;
  final double? realizedPnl;

  TradeLog({
    required this.symbol,
    required this.type,
    required this.quantity,
    required this.price,
    required this.time,
    this.realizedPnl,
  });

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'type': type.name,
        'quantity': quantity,
        'price': price,
        'time': time.toIso8601String(),
        'realizedPnl': realizedPnl,
      };

  factory TradeLog.fromJson(Map<String, dynamic> j) => TradeLog(
        symbol: j['symbol'],
        type: j['type'] == 'buy' ? TxnType.buy : TxnType.sell,
        quantity: j['quantity'],
        price: (j['price'] as num).toDouble(),
        time: DateTime.parse(j['time']),
        realizedPnl: j['realizedPnl'] == null
            ? null
            : (j['realizedPnl'] as num).toDouble(),
      );
}
