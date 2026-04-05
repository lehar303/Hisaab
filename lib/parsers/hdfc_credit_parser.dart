import '../models/transaction.dart';
import 'message_parser.dart';

class HdfcCreditParser implements MessageParser {
  @override
  bool canParse(String body) => body.contains('credited');

  @override
  Transaction? parse(String body) {
    final amount = RegExp(r'Rs\.?\s*(\d+\.\d+)').firstMatch(body)?.group(1);
    final party = RegExp(r'by a/c linked to VPA (.+?) \(').firstMatch(body)?.group(1)?.trim();
    final date = RegExp(r'on (\d+-\d+-\d+|\d+/\d+/\d+)').firstMatch(body)?.group(1);

    if (amount != null) {
      return Transaction(
        txnType: 'CREDIT',
        amount: double.parse(amount),
        party: party ?? 'Unknown',
        date: date ?? 'Unknown',
        rawSms: body,
      );
    }
    return null;
  }
}