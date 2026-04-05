import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../parsers/hdfc_credit_parser.dart';
import '../parsers/hdfc_debit_parser.dart';
import '../parsers/parser_registry.dart';
import '../db/transaction_dao.dart';
import '../services/sms_service.dart';
import '../services/transaction_service.dart';
import 'budget_screen.dart';
import 'categorize_sheet.dart';
import 'vendor_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> transactions = [];
  bool loading = true;
  DateTime _selectedMonth = DateTime.now();

  late final TransactionService _transactionService;

  static const _bg = Color(0xFF111111);
  static const _surface = Color(0xFF1C1C1C);
  static const _surfaceAlt = Color(0xFF242424);
  static const _border = Color(0xFF2A2A2A);
  static const _textPrimary = Color(0xFFEEEEEE);
  static const _textSecondary = Color(0xFF888888);
  static const _debit = Color(0xFFFF6B6B);
  static const _credit = Color(0xFF51CF66);
  static const _accent = Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _transactionService = TransactionService(
      smsService: SmsService(
        allowedSenders: ['HDFC'],
        requiredKeywords: ['credited', 'Sent'],
        blockedKeywords: ['OTP'],
      ),
      registry: ParserRegistry()
        ..register(HdfcDebitParser())
        ..register(HdfcCreditParser()),
      dao: TransactionDao(),
    );
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final granted = await _transactionService.requestPermission();
    if (!granted) {
      setState(() => loading = false);
      return;
    }
    await _transactionService.syncFromSms();
    final all = await _transactionService.getAllTransactions();
    setState(() {
      transactions = all;
      loading = false;
    });
  }

  List<Transaction> get _filteredTransactions {
    return transactions.where((t) {
      final parts = t.date.replaceAll('-', '/').split('/');
      if (parts.length < 3) return false;
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(
          parts[2].length == 2 ? '20${parts[2]}' : parts[2]);
      return m == _selectedMonth.month && y == _selectedMonth.year;
    }).toList();
  }

  static const _monthNames = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTransactions;
    final totalDebit = filtered
        .where((t) => t.txnType == 'DEBIT')
        .fold(0.0, (sum, t) => sum + t.amount);
    final totalCredit = filtered
        .where((t) => t.txnType == 'CREDIT')
        .fold(0.0, (sum, t) => sum + t.amount);
    final net = totalCredit - totalDebit;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        title: const Text(
          'Expense Tracker',
          style: TextStyle(
            color: _textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined,
                color: _textSecondary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.store_outlined, color: _textSecondary),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => VendorScreen(transactions: transactions)),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: _accent))
          : Column(
              children: [
                _buildSummaryCard(totalDebit, totalCredit, net),
                _buildMonthPicker(),
                const Divider(color: _border, height: 1),
                Expanded(child: _buildTransactionList(filtered)),
              ],
            ),
    );
  }

  Widget _buildSummaryCard(
      double totalDebit, double totalCredit, double net) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_monthNames[_selectedMonth.month - 1].toUpperCase()} ${_selectedMonth.year}',
              style: TextStyle(
                  color: _textSecondary,
                  fontSize: 10,
                  letterSpacing: 1.5)),
          const SizedBox(height: 4),
          Text(
            'Rs.${totalDebit.toStringAsFixed(2)}',
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const Text('total spent',
              style: TextStyle(color: _textSecondary, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              _summaryPill('Received', totalCredit, _credit),
              const SizedBox(width: 8),
              _summaryPill(
                  net >= 0 ? 'Net Surplus' : 'Net Deficit', net, _accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withAlpha((0.08 * 255).toInt()),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withAlpha((0.2 * 255).toInt())),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    color: color.withAlpha((0.8 * 255).toInt()), fontSize: 10,
                    letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(
              'Rs.${amount.abs().toStringAsFixed(2)}',
              style: TextStyle(
                  color: color, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthPicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('TRANSACTIONS',
              style: TextStyle(
                  color: _textSecondary,
                  fontSize: 10,
                  letterSpacing: 1.5)),
          Row(
            children: [
              _monthNavBtn(Icons.chevron_left, () {
                setState(() => _selectedMonth =
                    DateTime(_selectedMonth.year, _selectedMonth.month - 1));
              }),
              const SizedBox(width: 8),
              Text(
                '${_monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              _monthNavBtn(Icons.chevron_right, () {
                setState(() => _selectedMonth =
                    DateTime(_selectedMonth.year, _selectedMonth.month + 1));
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _monthNavBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _surfaceAlt,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: _textSecondary, size: 16),
      ),
    );
  }

  Widget _buildTransactionList(List<Transaction> filtered) {
    if (filtered.isEmpty) {
      return const Center(
        child: Text('No transactions this month',
            style: TextStyle(color: _textSecondary, fontSize: 14)),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, _) =>
          const Divider(color: _border, height: 1),
      itemBuilder: (context, index) {
        final txn = filtered[index];
        final isDebit = txn.txnType == 'DEBIT';
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDebit
                  ? _debit.withAlpha((0.1 * 255).toInt())
                  : _credit.withAlpha((0.1 * 255).toInt()),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isDebit ? Icons.arrow_upward : Icons.arrow_downward,
              color: isDebit ? _debit : _credit,
              size: 16,
            ),
          ),
          title: Text(
            txn.party,
            style: const TextStyle(
                color: _textPrimary, fontSize: 14, fontWeight: FontWeight.w400),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Text(txn.date,
                    style: const TextStyle(
                        color: _textSecondary, fontSize: 11)),
                const SizedBox(width: 8),
                txn.categoryName != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accent.withAlpha((0.1 * 255).toInt()),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: _accent.withAlpha((0.1 * 255).toInt())),
                        ),
                        child: Text(
                          txn.categoryName!,
                          style: const TextStyle(
                              color: _accent, fontSize: 10),
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Uncategorised',
                          style: TextStyle(
                              color: _textSecondary, fontSize: 10),
                        ),
                      ),
              ],
            ),
          ),
          trailing: Text(
            '${isDebit ? '-' : '+'}Rs.${txn.amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isDebit ? _debit : _credit,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          onTap: isDebit
              ? () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: _surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => CategorizeSheet(
                      transaction: txn,
                      onCategorized: _loadTransactions,
                    ),
                  )
              : null,
        );
      },
    );
  }
}