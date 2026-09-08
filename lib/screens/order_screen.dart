import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/paper_trading_service.dart';
import '../theme/app_theme.dart';

class OrderScreen extends StatefulWidget {
  final IndexQuote quote;
  final PaperTradingService paperTradingService;

  const OrderScreen({
    super.key,
    required this.quote,
    required this.paperTradingService,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final TextEditingController _qtyController = TextEditingController(text: '1');
  TxnType _type = TxnType.buy;
  bool _submitting = false;
  String? _message;

  @override
  Widget build(BuildContext context) {
    final quote = widget.quote;
    final existingPos = widget.paperTradingService.positions[quote.symbol];

    return Scaffold(
      appBar: AppBar(title: Text(quote.symbol)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('LTP', style: const TextStyle(color: AppColors.secondaryText)),
            Text(
              quote.ltp.toStringAsFixed(2),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${quote.change >= 0 ? '+' : ''}${quote.change.toStringAsFixed(2)} '
              '(${quote.changePercent.toStringAsFixed(2)}%)',
              style: TextStyle(color: AppTheme.pnlColor(quote.change)),
            ),
            const SizedBox(height: 24),
            if (existingPos != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Current position: ${existingPos.quantity} @ '
                        '${existingPos.avgPrice.toStringAsFixed(2)}'),
                    Text(
                      existingPos.unrealizedPnl(quote.ltp).toStringAsFixed(2),
                      style: TextStyle(
                        color: AppTheme.pnlColor(
                            existingPos.unrealizedPnl(quote.ltp)),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Expanded(
                  child: _TypeButton(
                    label: 'BUY',
                    color: AppColors.positiveGreen,
                    selected: _type == TxnType.buy,
                    onTap: () => setState(() => _type = TxnType.buy),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TypeButton(
                    label: 'SELL',
                    color: AppColors.negativeRed,
                    selected: _type == TxnType.sell,
                    onTap: () => setState(() => _type = TxnType.sell),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Virtual cash available: ₹${widget.paperTradingService.cashBalance.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.secondaryText, fontSize: 12),
            ),
            const SizedBox(height: 20),
            if (_message != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_message!,
                    style: const TextStyle(color: AppColors.negativeRed)),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _type == TxnType.buy
                      ? AppColors.positiveGreen
                      : AppColors.negativeRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submitting ? null : _submit,
                child: Text(
                  _submitting
                      ? 'Placing...'
                      : '${_type == TxnType.buy ? 'BUY' : 'SELL'} ${quote.symbol}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Simulated order — no real trade is placed anywhere.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final qty = int.tryParse(_qtyController.text) ?? 0;
    setState(() {
      _submitting = true;
      _message = null;
    });

    final error = await widget.paperTradingService.executeOrder(
      symbol: widget.quote.symbol,
      type: _type,
      quantity: qty,
      price: widget.quote.ltp,
    );

    setState(() => _submitting = false);

    if (error != null) {
      setState(() => _message = error);
    } else if (mounted) {
      Navigator.pop(context);
    }
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : AppColors.surface,
          border: Border.all(color: selected ? color : AppColors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? color : AppColors.secondaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
