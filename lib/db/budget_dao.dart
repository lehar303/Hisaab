import 'database_helper.dart';

class BudgetDao {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getBudgetsForMonth(int month, int year) async {
    final db = await _helper.db;
    final results = await db.query(
      'budgets',
      where: 'month = ? AND year = ?',
      whereArgs: [month, year],
    );

    // If no budgets exist for this month, create them with carryover
    if (results.isEmpty) {
      await _rolloverBudgets(month, year);
      return db.query(
        'budgets',
        where: 'month = ? AND year = ?',
        whereArgs: [month, year],
      );
    }

    return results;
  }

  Future<void> _rolloverBudgets(int month, int year) async {
    final db = await _helper.db;

    // Get previous month
    final prevMonth = month == 1 ? 12 : month - 1;
    final prevYear = month == 1 ? year - 1 : year;

    final prevBudgets = await db.query(
      'budgets',
      where: 'month = ? AND year = ?',
      whereArgs: [prevMonth, prevYear],
    );

    for (final prev in prevBudgets) {
      final name = prev['name'] as String;
      final amount = prev['amount'] as double;
      final prevCarryover = prev['carryover'] as double;
      final prevEffective = amount + prevCarryover;

      // Get what was spent last month for this budget
      final spentRows = await db.rawQuery('''
        SELECT COALESCE(SUM(t.amount), 0) as total
        FROM transactions t
        LEFT JOIN categories c ON t.category_id = c.id
        WHERE t.txn_type = 'DEBIT'
        AND c.parent = ?
        AND substr(t.date, 4, 2) = ?
        AND ('20' || substr(t.date, 7, 2)) = ?
      ''', [name, prevMonth.toString().padLeft(2, '0'), prevYear.toString()]);

      final spent = (spentRows.first['total'] as num).toDouble();
      final carryover = prevEffective - spent;

      await db.insert('budgets', {
        'name': name,
        'amount': amount,
        'month': month,
        'year': year,
        'carryover': carryover,
      });
    }
  }

  Future<void> updateBudgetAmount(String name, int month, int year, double amount) async {
    final db = await _helper.db;
    await db.update(
      'budgets',
      {'amount': amount},
      where: 'name = ? AND month = ? AND year = ?',
      whereArgs: [name, month, year],
    );
  }
}