enum PostingSide {
  debit('Debit', 'Debe'),
  credit('Credit', 'Haber');

  const PostingSide(this.qboName, this.label);

  /// Value sent to QuickBooks (`PostingType`).
  final String qboName;

  /// Spanish UI label.
  final String label;

  static PostingSide parse(String value) =>
      values.firstWhere((v) => v.qboName.toLowerCase() == value.toLowerCase() || v.name == value);
}

enum EntityType {
  customer('Customer', 'Cliente'),
  vendor('Vendor', 'Suplidor');

  const EntityType(this.qboName, this.label);

  final String qboName;
  final String label;

  static EntityType? tryParse(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final v in values) {
      if (v.qboName.toLowerCase() == value.toLowerCase() || v.name == value) return v;
    }
    return null;
  }
}

/// Maps a POS category to a QuickBooks account (and optional entity).
class AccountMapping {
  const AccountMapping({
    required this.category,
    required this.accountId,
    required this.accountName,
    required this.side,
    this.description,
    this.entityType,
    this.entityId,
    this.entityName,
  });

  final String category;
  final String accountId;
  final String accountName;
  final PostingSide side;
  final String? description;
  final EntityType? entityType;
  final String? entityId;
  final String? entityName;

  bool get requiresEntity => entityType != null;

  AccountMapping copyWith({
    String? accountId,
    String? accountName,
    PostingSide? side,
    String? Function()? description,
    EntityType? Function()? entityType,
    String? Function()? entityId,
    String? Function()? entityName,
  }) =>
      AccountMapping(
        category: category,
        accountId: accountId ?? this.accountId,
        accountName: accountName ?? this.accountName,
        side: side ?? this.side,
        description: description != null ? description() : this.description,
        entityType: entityType != null ? entityType() : this.entityType,
        entityId: entityId != null ? entityId() : this.entityId,
        entityName: entityName != null ? entityName() : this.entityName,
      );
}
