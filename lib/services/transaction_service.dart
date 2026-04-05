import '../db/transaction_dao.dart';
import '../models/transaction.dart';
import '../parsers/parser_registry.dart';
import 'sms_service.dart';

class TransactionService {
  final SmsService _smsService;
  final ParserRegistry _registry;
  final TransactionDao _dao;

  TransactionService({
    required SmsService smsService,
    required ParserRegistry registry,
    required TransactionDao dao,
  })  : _smsService = smsService,
        _registry = registry,
        _dao = dao;

  Future<bool> requestPermission() => _smsService.requestPermission();

  Future<void> syncFromSms() async {
    final messages = await _smsService.fetchFilteredMessages();
    for (final body in messages) {
      final txn = _registry.parse(body);
      if (txn != null) await _dao.insertTransaction(txn);
    }
  }

  Future<List<Transaction>> getAllTransactions() async {
    final rows = await _dao.getAllTransactions();
    return rows.map(Transaction.fromMap).toList();
  }

  Future<void> categorize(int transactionId, int categoryId) async {
    await _dao.updateCategory(transactionId, categoryId);
  }
}