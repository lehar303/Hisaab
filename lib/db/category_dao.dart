import 'database_helper.dart';

class CategoryDao {
  final DatabaseHelper _helper = DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await _helper.db;
    return db.query('categories');
  }
}