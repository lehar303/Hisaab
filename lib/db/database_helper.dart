import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  DatabaseHelper._internal();

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final path = join(await getDatabasesPath(), 'expense_tracker.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        txn_type TEXT NOT NULL,
        amount REAL NOT NULL,
        party TEXT NOT NULL,
        date TEXT NOT NULL,
        raw_sms TEXT NOT NULL  UNIQUE,
        category_id INTEGER,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        carryover REAL NOT NULL DEFAULT 0
      )
    ''');

    // Seed default categories
    await _seedCategories(db);

    // Seed default budgets for current month
    await _seedBudgets(db);
  }

  Future<void> _seedCategories(Database db) async {
    final categories = [
      {'name': 'Bills', 'parent': 'Bills'},
      {'name': 'Unforeseen', 'parent': 'Personal'},
      {'name': 'Entertainment', 'parent': 'Personal'},
      {'name': 'Medical', 'parent': 'Personal'},
      {'name': 'Gym', 'parent': 'Personal'},
      {'name': 'Skill', 'parent': 'Personal'},
      {'name': 'Investment', 'parent': 'Investment'},
    ];
    for (final cat in categories) {
      await db.insert('categories', cat);
    }
  }

  Future<void> _seedBudgets(Database db) async {
    final now = DateTime.now();
    final budgets = [
      {'name': 'Bills', 'amount': 2000.0, 'month': now.month, 'year': now.year, 'carryover': 0.0},
      {'name': 'Personal', 'amount': 2000.0, 'month': now.month, 'year': now.year, 'carryover': 0.0},
      {'name': 'Investment', 'amount': 6000.0, 'month': now.month, 'year': now.year, 'carryover': 0.0},
    ];
    for (final budget in budgets) {
      await db.insert('budgets', budget);
    }
  }
}