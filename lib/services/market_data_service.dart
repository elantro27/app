import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Pulls live index data directly from NSE's and BSE's own public website
/// endpoints — the same data their homepages display. No broker account,
/// no API key, no cost.
///
/// Caveats (unofficial source, be aware):
/// - NSE requires a browser-like session cookie or it blocks requests.
/// - Endpoints are undocumented and can change without notice.
/// - Not tick-by-tick exchange feed, but refreshes every few seconds —
///   close enough to real-time for practice trading.
class MarketDataService {
  static const _userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0 Safari/537.36';

  final http.Client _client = http.Client();
  Map<String, String> _nseCookies = {};
  DateTime _cookiesFetchedAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// NSE blocks requests without a valid session cookie from its own
  /// homepage. Fetch (and periodically refresh) that cookie first.
  Future<void> _ensureNseSession() async {
    final stale = DateTime.now().difference(_cookiesFetchedAt) >
        const Duration(minutes: 4);
    if (_nseCookies.isNotEmpty && !stale) return;

    final resp = await _client.get(
      Uri.parse('https://www.nseindia.com'),
      headers: {'User-Agent': _userAgent, 'Accept': 'text/html'},
    );

    final rawCookies = resp.headers['set-cookie'];
    if (rawCookies != null) {
      _nseCookies = {};
      for (final part in rawCookies.split(',')) {
        final kv = part.split(';').first.trim();
        final idx = kv.indexOf('=');
        if (idx > 0) {
          _nseCookies[kv.substring(0, idx)] = kv.substring(idx + 1);
        }
      }
      _cookiesFetchedAt = DateTime.now();
    }
  }

  String get _cookieHeader =>
      _nseCookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

  /// Fetches NIFTY 50, NIFTY BANK, NIFTY FIN SERVICE from NSE's
  /// public "allIndices" endpoint.
  Future<List<IndexQuote>> _fetchNseIndices() async {
    await _ensureNseSession();

    final resp = await _client.get(
      Uri.parse('https://www.nseindia.com/api/allIndices'),
      headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
        'Referer': 'https://www.nseindia.com/market-data/live-market-indices',
        if (_nseCookies.isNotEmpty) 'Cookie': _cookieHeader,
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('NSE request failed: ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);
    final List list = data['data'] ?? [];
    const wanted = {'NIFTY 50', 'NIFTY BANK', 'NIFTY FIN SERVICE'};

    return list
        .where((e) => wanted.contains(e['index']))
        .map<IndexQuote>((e) => IndexQuote(
              symbol: e['index'],
              exchange: 'NSE',
              instrumentToken: 0,
              ltp: (e['last'] as num?)?.toDouble() ?? 0,
              change: (e['variation'] as num?)?.toDouble() ?? 0,
              changePercent: (e['percentChange'] as num?)?.toDouble() ?? 0,
              open: (e['open'] as num?)?.toDouble() ?? 0,
              high: (e['high'] as num?)?.toDouble() ?? 0,
              low: (e['low'] as num?)?.toDouble() ?? 0,
              prevClose: (e['previousClose'] as num?)?.toDouble() ?? 0,
            ))
        .toList();
  }

  /// Fetches SENSEX from BSE's public index snapshot endpoint.
  Future<IndexQuote> _fetchSensex() async {
    final resp = await _client.get(
      Uri.parse(
          'https://api.bseindia.com/BseIndiaAPI/api/GetIndices/w?strIndex=SENSEX'),
      headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
    );

    if (resp.statusCode != 200) {
      throw Exception('BSE request failed: ${resp.statusCode}');
    }

    final data = jsonDecode(resp.body);
    final row = (data is List && data.isNotEmpty) ? data.first : data;

    final ltp = (row['CurrValue'] as num?)?.toDouble() ??
        (row['LastValue'] as num?)?.toDouble() ??
        0;
    final prevClose = (row['PrevClose'] as num?)?.toDouble() ?? ltp;
    final change = ltp - prevClose;
    final changePct = prevClose == 0 ? 0.0 : (change / prevClose) * 100;

    return IndexQuote(
      symbol: 'SENSEX',
      exchange: 'BSE',
      instrumentToken: 0,
      ltp: ltp,
      change: change,
      changePercent: changePct,
      prevClose: prevClose,
    );
  }

  /// Combined fetch for all four tracked indices. If one source fails
  /// (e.g. NSE rate-limits), the other's data still comes through and
  /// the failed entries just keep their last known values upstream.
  Future<List<IndexQuote>> fetchAll() async {
    final results = await Future.wait<List<IndexQuote>>([
      _fetchNseIndices().catchError((_) => <IndexQuote>[]),
      _fetchSensex().then((q) => [q]).catchError((_) => <IndexQuote>[]),
    ]);
    return [...results[0], ...results[1]];
  }

  Stream<List<IndexQuote>> quoteStream({
    Duration interval = const Duration(seconds: 4),
  }) async* {
    while (true) {
      try {
        final quotes = await fetchAll();
        if (quotes.isNotEmpty) yield quotes;
      } catch (_) {
        // keep last known values on the UI side
      }
      await Future.delayed(interval);
    }
  }
}
