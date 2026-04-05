import 'package:flutter/material.dart';
import '../db/category_dao.dart';
import '../db/transaction_dao.dart';
import '../models/transaction.dart';

class CategorizeSheet extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback onCategorized;

  const CategorizeSheet({
    super.key,
    required this.transaction,
    required this.onCategorized,
  });

  @override
  State<CategorizeSheet> createState() => _CategorizeSheetState();
}

class _CategorizeSheetState extends State<CategorizeSheet> {
  List<Map<String, dynamic>> categories = [];
  final CategoryDao _categoryDao = CategoryDao();
  final TransactionDao _transactionDao = TransactionDao();

  static const _surface = Color(0xFF1C1C1C);
  static const _border = Color(0xFF2A2A2A);
  static const _textPrimary = Color(0xFFEEEEEE);
  static const _textSecondary = Color(0xFF888888);
  static const _accent = Color(0xFFD4AF37);
  static const _debit = Color(0xFFFF6B6B);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await _categoryDao.getAllCategories();
    setState(() => categories = cats);
  }

  Future<void> _selectCategory(int categoryId) async {
    await _transactionDao.updateCategory(widget.transaction.id!, categoryId);
    widget.onCategorized();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final cat in categories) {
      final parent = cat['parent'] as String;
      grouped.putIfAbsent(parent, () => []).add(cat);
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Text('Categorise',
                        style: TextStyle(
                            color: _textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                    const Spacer(),
                    Text(
                      '-Rs.${widget.transaction.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: _debit,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Text(
                      widget.transaction.party,
                      style: const TextStyle(
                          color: _textSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.transaction.date,
                      style: const TextStyle(
                          color: _textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Divider(color: _border, height: 1),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 24),
                  children: grouped.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                          child: Text(
                            entry.key.toUpperCase(),
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        ...entry.value.map((cat) {
                          final isSelected =
                              widget.transaction.categoryId == cat['id'];
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            title: Text(
                              cat['name'],
                              style: TextStyle(
                                color: isSelected ? _accent : _textPrimary,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.w400,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                    color: _accent, size: 18)
                                : null,
                            tileColor: isSelected
                                ? _accent.withAlpha((0.05 * 255).toInt())
                                : null,
                            onTap: () => _selectCategory(cat['id'] as int),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}