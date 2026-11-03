import 'account_mapping.dart';
import 'exceptions.dart';
import 'money.dart';
import 'pos_sales_summary.dart';
import 'dates.dart';

class JournalEntryLine {
  const JournalEntryLine({
    required this.category,
    required this.accountId,
    required this.accountName,
    required this.side,
    required this.amount,
    required this.description,
    this.entityType,
    this.entityId,
    this.entityName,
  });

  final String category;
  final String accountId;
  final String accountName;
  final PostingSide side;
  final double amount;
  final String description;
  final EntityType? entityType;
  final String? entityId;
  final String? entityName;

  bool get isMissingRequiredEntity =>
      entityType != null && (entityId == null || entityId!.trim().isEmpty);

  double get debit => side == PostingSide.debit ? amount : 0;
  double get credit => side == PostingSide.credit ? amount : 0;
}

class JournalEntryDraft {
  JournalEntryDraft({
    required DateTime txnDate,
    required this.description,
    required List<JournalEntryLine> lines,
  })  : txnDate = Dates.dateOnly(txnDate),
        lines = List.unmodifiable(lines);

  static const double balanceTolerance = 0.005;

  final DateTime txnDate;
  final String description;
  final List<JournalEntryLine> lines;

  double get totalDebit => Money.sum(lines.map((l) => l.debit));
  double get totalCredit => Money.sum(lines.map((l) => l.credit));
  double get difference => Money.round2(totalDebit - totalCredit);

  bool get hasLines => lines.isNotEmpty;
  bool get isBalanced => difference.abs() <= balanceTolerance;

  List<JournalEntryLine> get linesMissingRequiredEntity =>
      lines.where((l) => l.isMissingRequiredEntity).toList();

  bool get hasMissingEntities => linesMissingRequiredEntity.isNotEmpty;

  bool get canSubmit => hasLines && isBalanced && !hasMissingEntities;

  /// `Ventas del dd/MM/yyyy al dd/MM/yyyy`
  static String defaultDescription(DateTime from, DateTime to) =>
      'Ventas del ${Dates.dmy(from)} al ${Dates.dmy(to)}';
}

/// Builds a journal entry draft from a POS summary and account mappings.
/// Balance is NOT enforced here; callers check [JournalEntryDraft.canSubmit].
class JournalEntryBuilder {
  const JournalEntryBuilder();

  JournalEntryDraft build(
    PosSalesSummary summary,
    Map<String, AccountMapping> mappingsByCategory,
    String description,
  ) {
    final lines = <JournalEntryLine>[];
    for (final c in summary.categories) {
      if (Money.toCents(c.amount) == 0) continue;
      final mapping = mappingsByCategory[c.category];
      if (mapping == null) throw AccountMappingNotFoundException(c.category);
      lines.add(JournalEntryLine(
        category: c.category,
        accountId: mapping.accountId,
        accountName: mapping.accountName,
        side: mapping.side,
        amount: Money.round2(c.amount.abs()),
        description: (mapping.description?.trim().isNotEmpty ?? false)
            ? mapping.description!
            : c.category,
        entityType: mapping.entityType,
        entityId: mapping.entityId,
        entityName: mapping.entityName,
      ));
    }
    return JournalEntryDraft(
      txnDate: summary.toDate,
      description: description,
      lines: lines,
    );
  }
}
