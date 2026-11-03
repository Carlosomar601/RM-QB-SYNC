import 'package:flutter_test/flutter_test.dart';
import 'package:rmqbsync/core/sync_rules.dart';

void main() {
  DateTime d(int day) => DateTime(2026, 5, day);
  SyncRangeRecord r(int a, int b, SyncStatus s) => SyncRangeRecord(from: d(a), to: d(b), status: s);

  test('overlap is inclusive on both ends', () {
    expect(DuplicateRule.overlaps(d(1), d(5), d(5), d(9)), isTrue);
    expect(DuplicateRule.overlaps(d(6), d(9), d(1), d(5)), isFalse);
    expect(DuplicateRule.overlaps(d(1), d(31), d(10), d(10)), isTrue);
  });

  test('only Success rows block', () {
    final history = [r(1, 5, SyncStatus.failed), r(1, 5, SyncStatus.skipped)];
    expect(DuplicateRule.findOverlappingSuccess(history, d(3), d(3)), isNull);
  });

  test('finds overlapping success', () {
    final history = [r(1, 5, SyncStatus.failed), r(4, 10, SyncStatus.success)];
    final hit = DuplicateRule.findOverlappingSuccess(history, d(10), d(12));
    expect(hit, isNotNull);
    expect(DuplicateRule.skippedMessage(hit!), contains('04/05/2026 al 10/05/2026'));
  });

  test('adjacent range does not block', () {
    final history = [r(1, 5, SyncStatus.success)];
    expect(DuplicateRule.findOverlappingSuccess(history, d(6), d(7)), isNull);
  });
}
