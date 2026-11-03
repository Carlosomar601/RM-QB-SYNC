import '../core/account_mapping.dart';
import '../core/journal_entry.dart';
import '../core/money.dart';
import '../core/pos_sales_summary.dart';
import '../data/db/repositories.dart';
import '../data/pos/pos_client.dart';

class PreviewResult {
  const PreviewResult({
    required this.summary,
    required this.mappings,
    required this.missingCategories,
    this.draft,
  });

  final PosSalesSummary summary;
  final Map<String, AccountMapping> mappings;

  /// Categories with a non-zero amount but no account mapping.
  final List<String> missingCategories;

  /// Null when mappings are missing.
  final JournalEntryDraft? draft;

  bool get canSubmit => draft?.canSubmit ?? false;
}

class PreviewService {
  PreviewService({required this.pos, required this.mappings, this.builder = const JournalEntryBuilder()});

  final PosClient pos;
  final MappingRepository mappings;
  final JournalEntryBuilder builder;

  Future<PreviewResult> build(DateTime from, DateTime to) async {
    final summary = await pos.getSalesSummary(from, to);
    return buildFromSummary(summary);
  }

  Future<PreviewResult> buildFromSummary(PosSalesSummary summary) async {
    final m = await mappings.byCategory();
    final missing = [
      for (final c in summary.categories)
        if (Money.toCents(c.amount) != 0 && !m.containsKey(c.category)) c.category,
    ];
    final draft = missing.isEmpty
        ? builder.build(summary, m, JournalEntryDraft.defaultDescription(summary.fromDate, summary.toDate))
        : null;
    return PreviewResult(summary: summary, mappings: m, missingCategories: missing, draft: draft);
  }
}
