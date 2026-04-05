import '../db/budget_dao.dart';
import '../models/budget.dart';
import '../models/transaction.dart';

class BudgetService {
  final BudgetDao _dao;

  BudgetService({required BudgetDao dao}) : _dao = dao;

  Future<List<Budget>> getBudgetsForMonth(int month, int year) async {
    final rows = await _dao.getBudgetsForMonth(month, year);
    return rows.map(Budget.fromMap).toList();
  }

  Future<void> updateBudgetAmount(
      String name, int month, int year, double amount) async {
    await _dao.updateBudgetAmount(name, month, year, amount);
  }

  double spent(String budgetName, int month, int year,
      List<Transaction> transactions) {
    return transactions.where((t) {
      final parts = t.date.replaceAll('-', '/').split('/');
      if (parts.length < 3) return false;
      final m = int.tryParse(parts[1]);
      final y = int.tryParse(
          parts[2].length == 2 ? '20${parts[2]}' : parts[2]);
      return m == month &&
          y == year &&
          t.txnType == 'DEBIT' &&
          t.categoryParent == budgetName;
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  // Bills remainder flows into personal effective budget
  double effectivePersonalBudget(
      Budget personalBudget, Budget billsBudget, int month, int year,
      List<Transaction> transactions) {
    final billsSpent = spent('Bills', month, year, transactions);
    final billsRemainder = (billsBudget.effective - billsSpent).clamp(0.0, double.infinity);
    return personalBudget.effective + billsRemainder;
  }
}