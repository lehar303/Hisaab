import '../models/transaction.dart';
import 'message_parser.dart';

class ParserRegistry {
  final List<MessageParser> _parsers = [];

  void register(MessageParser parser) {
    _parsers.add(parser);
  }

  Transaction? parse(String body) {
    for (final parser in _parsers) {
      if (parser.canParse(body)) {
        return parser.parse(body);
      }
    }
    return null;
  }
}