import 'package:flutter/material.dart';
import '../db/budget_dao.dart';
import '../db/transaction_dao.dart';
import '../models/budget.dart';
import '../models/transaction.dart';
import '../services/budget_service.dart';
import '../services/transaction_service.dart';
import '../parsers/parser_registry.dart';
import '../services/sms_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List<Budget> budgets = [];
  List<Transaction> transactions = [];
  bool loading = true;

  static const _bg = Color(0xFF111111);
  static const _surface = Color(0xFF1C1C1C);
  static const _surfaceAlt = Color(0xFF242424);
  static const _border = Color(0xFF2A2A2A);
  static const _textPrimary = Color(0xFFEEEEEE);
  static const _textSecondary = Color(0xFF888888);
  static const _debit = Color(0xFFFF6B6B);
  static const _credit = Color(0xFF51CF66);
  static const _accent = Color(0xFFD4AF37);

  late final BudgetService _budgetService;
  late final TransactionService _transactionService;

  @override
  void initState() {
    super.initState();
    _budgetService = BudgetService(dao: BudgetDao());
    _transactionService = TransactionService(
      smsService: SmsService(
        allowedSenders: ['HDFC'],
        requiredKeywords: ['credited', 'Sent'],
        blockedKeywords: ['OTP'],
      ),
      registry: ParserRegistry(),
      dao: TransactionDao(),
    );
    _load();
  }

  Future<void> _load() async {
    final now = DateTime.now();
    final b = await _budgetService.getBudgetsForMonth(now.month, now.year);
    final t = await _transactionService.getAllTransactions();
    setState(() {
      budgets = b;
      transactions = t;
      loading = false;
    });
  }

  Future<void> _editBudget(Budget budget) async {
    final controller =
        TextEditingController(text: budget.amount.toStringAsFixed(0));
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Edit ${budget.name} Budget',
          style: const TextStyle(color: _textPrimary, fontSize: 16),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: _textPrimary),
          decoration: InputDecoration(
            prefixText: 'Rs. ',
            prefixStyle: const TextStyle(color: _textSecondary),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: _accent),
            ),
            filled: true,
            fillColor: _surfaceAlt,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: _textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount != null) {
                final now = DateTime.now();
                await _budgetService.updateBudgetAmount(
                    budget.name, now.month, now.year, amount);
                if (!mounted) return;
                Navigator.pop(context);
                _load();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _textSecondary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Budgets',
          style: TextStyle(
              color: _textPrimary, fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: budgets.map((budget) {
                final isPersonal = budget.name == 'Personal';
                final billsBudget = budgets.firstWhere(
                  (b) => b.name == 'Bills',
                  orElse: () => budget,
                );

                final effective = isPersonal
                    ? _budgetService.effectivePersonalBudget(
                        budget, billsBudget, now.month, now.year, transactions)
                    : budget.effective;

                final spent = _budgetService.spent(
                    budget.name, now.month, now.year, transactions);
                final remaining = effective - spent;
                final isOver = remaining < 0;
                final progress = (spent / effective).clamp(0.0, 1.0);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            budget.name.toUpperCase(),
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _editBudget(budget),
                            child: const Icon(Icons.edit_outlined,
                                color: _textSecondary, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Rs.${spent.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: _textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'of Rs.${effective.toStringAsFixed(2)} effective budget',
                        style: const TextStyle(
                            color: _textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: _border,
                          valueColor: AlwaysStoppedAnimation(
                              isOver ? _debit : _accent),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _row('Base Limit', budget.amount, _textSecondary),
                      if (budget.carryover != 0)
                        _row(
                          budget.carryover > 0
                              ? 'Surplus (last month)'
                              : 'Overspent (last month)',
                          budget.carryover,
                          budget.carryover > 0 ? _credit : _debit,
                        ),
                      if (isPersonal)
                        _row(
                          'Bills Remainder',
                          effective - budget.effective,
                          _credit,
                        ),
                      const SizedBox(height: 4),
                      _row(
                        isOver ? 'Overspent' : 'Remaining',
                        remaining,
                        isOver ? _debit : _credit,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _row(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(color: _textSecondary, fontSize: 12)),
          Text(
            'Rs.${amount.abs().toStringAsFixed(2)}',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}