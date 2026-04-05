import '../models/transaction.dart';
import 'message_parser.dart';

class HdfcDebitParser implements MessageParser {
  @override
  bool canParse(String body) => body.contains('Sent');

  @override
  Transaction? parse(String body) {
    final amount = RegExp(r'Rs\.(\d+\.\d+)').firstMatch(body)?.group(1);
    final party = RegExp(r'To (.+)').firstMatch(body)?.group(1)?.trim();
    final date = RegExp(r'On (\d+/\d+/\d+|\d+-\d+-\d+)').firstMatch(body)?.group(1);

    if (amount != null && party != null) {
      return Transaction(
        txnType: 'DEBIT',
        amount: double.parse(amount),
        party: party,
        date: date ?? 'Unknown',
        rawSms: body,
      );
    }
    return null;
  }
}