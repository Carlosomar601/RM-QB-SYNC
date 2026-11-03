import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/dates.dart';
import '../../core/journal_entry.dart';
import '../../core/money.dart';

abstract final class JournalEntryQboMapper {
  /// QuickBooks `JournalEntry` create payload.
  static Map<String, Object?> toQbo(JournalEntryDraft draft) => {
        'TxnDate': Dates.iso(draft.txnDate),
        'PrivateNote': draft.description,
        'Line': [
          for (var i = 0; i < draft.lines.length; i++) _line(i, draft.lines[i]),
        ],
      };

  static Map<String, Object?> _line(int index, JournalEntryLine l) {
    final detail = <String, Object?>{
      'PostingType': l.side.qboName,
      'AccountRef': {'value': l.accountId, 'name': l.accountName},
    };
    if (l.entityType != null && (l.entityId ?? '').isNotEmpty) {
      detail['Entity'] = {
        'Type': l.entityType!.qboName,
        'EntityRef': {'value': l.entityId, 'name': l.entityName ?? ''},
      };
    }
    return {
      'Id': '$index',
      'Description': l.description,
      'Amount': Money.round2(l.amount),
      'DetailType': 'JournalEntryLineDetail',
      'JournalEntryLineDetail': detail,
    };
  }

  /// Idempotency key: same range + same lines (+ optional salt) → same id,
  /// so network retries can never create a second entry. A forced duplicate
  /// ("Sincronizar de todas formas") passes a salt to obtain a new key.
  static String requestId(DateTime from, DateTime to, JournalEntryDraft draft, {String salt = ''}) {
    final canonical = jsonEncode({
      'from': Dates.iso(from),
      'to': Dates.iso(to),
      'body': toQbo(draft),
      'salt': salt,
    });
    return sha256.convert(utf8.encode(canonical)).toString().substring(0, 36);
  }
}
