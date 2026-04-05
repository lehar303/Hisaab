import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsService {
  final List<String> _allowedSenders;
  final List<String> _requiredKeywords;
  final List<String> _blockedKeywords;

  SmsService({
    required List<String> allowedSenders,
    required List<String> requiredKeywords,
    required List<String> blockedKeywords,
  })  : _allowedSenders = allowedSenders,
        _requiredKeywords = requiredKeywords,
        _blockedKeywords = blockedKeywords;

  Future<bool> requestPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  Future<List<String>> fetchFilteredMessages() async {
    final query = SmsQuery();
    final messages = await query.querySms(kinds: [SmsQueryKind.inbox]);

    final filtered = <String>[];
    for (final msg in messages) {
      final address = msg.address ?? '';
      final body = msg.body ?? '';

      final senderMatch = _allowedSenders
          .any((s) => address.toUpperCase().contains(s.toUpperCase()));
      if (!senderMatch) continue;

      final keywordMatch = _requiredKeywords.any((k) => body.contains(k));
      if (!keywordMatch) continue;

      final blocked = _blockedKeywords.any((k) => body.contains(k));
      if (blocked) continue;

      filtered.add(body);
    }

    return filtered;
  }
}