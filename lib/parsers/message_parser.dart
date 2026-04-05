import '../models/transaction.dart';

abstract class MessageParser {
  bool canParse(String body);
  Transaction? parse(String body);
}