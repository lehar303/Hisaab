import '../models/transaction.dart';
import 'database_helper.dart';
import 'package:sqflite/sqflite.dart' hide Transaction;

class TransactionDao {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<void> insertTransaction(Transaction txn) async {
    final db = await _helper.db;
    await db.insert(
      'transactions',
      {
        'txn_type': txn.txnType,
        'amount': txn.amount,
        'party': txn.party,
        'date': txn.date,
        'raw_sms': txn.rawSms,
        'category_id': txn.categoryId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> getTransactionsByMonth(int month, int year) async {
  final db = await _helper.db;
  final all = await db.rawQuery('''
    SELECT t.*, c.name as category_name, c.parent as category_parent
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
  ''');

  // Filter in Dart since date formats are inconsistent
  return all.where((row) {
    final date = row['date'] as String;
    final parts = date.replaceAll('-', '/').split('/');
    if (parts.length < 3) return false;
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2].length == 2 ? '20${parts[2]}' : parts[2]);
    return m == month && y == year;
  }).toList();
}

  Future<void> updateCategory(int transactionId, int categoryId) async {
    final db = await _helper.db;
    await db.update(
      'transactions',
      {'category_id': categoryId},
      where: 'id = ?',
      whereArgs: [transactionId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
  final db = await _helper.db;
  return db.rawQuery('''
    SELECT t.*, c.name as category_name, c.parent as category_parent
    FROM transactions t
    LEFT JOIN categories c ON t.category_id = c.id
    ORDER BY t.date DESC
  ''');
}
}