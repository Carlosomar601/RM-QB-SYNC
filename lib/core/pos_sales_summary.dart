import 'money.dart';

/// One aggregated amount for a POS category.
class PosCategoryAmount {
  const PosCategoryAmount(this.group, this.category, this.amount);

  final String group;
  final String category;
  final double amount;

  @override
  bool operator ==(Object other) =>
      other is PosCategoryAmount &&
      other.group == group &&
      other.category == category &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(group, category, amount);

  @override
  String toString() => 'PosCategoryAmount($group, $category, $amount)';
}

/// Sales and payment totals for a date range.
class PosSalesSummary {
  PosSalesSummary({
    required DateTime fromDate,
    required DateTime toDate,
    required List<PosCategoryAmount> categories,
    this.totalDiscounts = 0,
  })  : fromDate = DateTime(fromDate.year, fromDate.month, fromDate.day),
        toDate = DateTime(toDate.year, toDate.month, toDate.day),
        categories = List.unmodifiable(categories) {
    if (this.toDate.isBefore(this.fromDate)) {
      throw ArgumentError('La fecha final no puede ser anterior a la fecha inicial.');
    }
  }

  final DateTime fromDate;
  final DateTime toDate;
  final List<PosCategoryAmount> categories;

  /// Informational only: discounts are NOT part of the journal entry.
  final double totalDiscounts;

  /// Sum of a group's amounts (case-insensitive group name).
  double totalByGroup(String group) {
    final g = group.toLowerCase();
    return Money.sum(
      categories.where((c) => c.group.toLowerCase() == g).map((c) => c.amount),
    );
  }
}
