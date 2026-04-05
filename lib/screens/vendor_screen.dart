import 'package:flutter/material.dart';
import '../models/transaction.dart';

class VendorScreen extends StatelessWidget {
  final List<Transaction> transactions;

  const VendorScreen({super.key, required this.transactions});

  static const _bg = Color(0xFF111111);
  static const _surface = Color(0xFF1C1C1C);
  static const _border = Color(0xFF2A2A2A);
  static const _textPrimary = Color(0xFFEEEEEE);
  static const _textSecondary = Color(0xFF888888);
  static const _accent = Color(0xFFD4AF37);
  static const _debit = Color(0xFFFF6B6B);

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Transaction>> vendorMap = {};
    for (final txn in transactions.where((t) => t.txnType == 'DEBIT')) {
      vendorMap.putIfAbsent(txn.party, () => []).add(txn);
    }

    final sorted = vendorMap.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: _textSecondary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Vendors',
          style: TextStyle(
              color: _textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500),
        ),
      ),
      body: sorted.isEmpty
          ? const Center(
              child: Text('No vendor data yet',
                  style: TextStyle(color: _textSecondary, fontSize: 14)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: _border, height: 1),
              itemBuilder: (context, index) {
                final vendor = sorted[index].key;
                final txns = sorted[index].value;
                final total =
                    txns.fold(0.0, (sum, t) => sum + t.amount);
                final isTop = index == 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isTop
                              ? _accent.withAlpha((0.1 * 255).toInt())
                              : _surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isTop
                                ? _accent.withAlpha((0.1 * 255).toInt())
                                : _border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            vendor[0].toUpperCase(),
                            style: TextStyle(
                              color: isTop ? _accent : _textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vendor,
                                style: const TextStyle(
                                    color: _textPrimary,
                                    fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(
                              '${txns.length} transaction${txns.length > 1 ? 's' : ''}',
                              style: const TextStyle(
                                  color: _textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Rs.${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: _debit,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}