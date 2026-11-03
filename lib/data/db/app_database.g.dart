// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $OAuthConnectionsTable extends OAuthConnections
    with TableInfo<$OAuthConnectionsTable, OAuthConnectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OAuthConnectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _editionMeta = const VerificationMeta(
    'edition',
  );
  @override
  late final GeneratedColumn<String> edition = GeneratedColumn<String>(
    'edition',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('QuickBooksOnline'),
  );
  static const VerificationMeta _environmentMeta = const VerificationMeta(
    'environment',
  );
  @override
  late final GeneratedColumn<String> environment = GeneratedColumn<String>(
    'environment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('sandbox'),
  );
  static const VerificationMeta _realmIdMeta = const VerificationMeta(
    'realmId',
  );
  @override
  late final GeneratedColumn<String> realmId = GeneratedColumn<String>(
    'realm_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _companyNameMeta = const VerificationMeta(
    'companyName',
  );
  @override
  late final GeneratedColumn<String> companyName = GeneratedColumn<String>(
    'company_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accessTokenExpiresAtMeta =
      const VerificationMeta('accessTokenExpiresAt');
  @override
  late final GeneratedColumn<DateTime> accessTokenExpiresAt =
      GeneratedColumn<DateTime>(
        'access_token_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _refreshTokenExpiresAtMeta =
      const VerificationMeta('refreshTokenExpiresAt');
  @override
  late final GeneratedColumn<DateTime> refreshTokenExpiresAt =
      GeneratedColumn<DateTime>(
        'refresh_token_expires_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _connectedAtMeta = const VerificationMeta(
    'connectedAt',
  );
  @override
  late final GeneratedColumn<DateTime> connectedAt = GeneratedColumn<DateTime>(
    'connected_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastRefreshAtMeta = const VerificationMeta(
    'lastRefreshAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastRefreshAt =
      GeneratedColumn<DateTime>(
        'last_refresh_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    edition,
    environment,
    realmId,
    companyName,
    accessTokenExpiresAt,
    refreshTokenExpiresAt,
    connectedAt,
    lastRefreshAt,
    lastSyncAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'o_auth_connections';
  @override
  VerificationContext validateIntegrity(
    Insertable<OAuthConnectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('edition')) {
      context.handle(
        _editionMeta,
        edition.isAcceptableOrUnknown(data['edition']!, _editionMeta),
      );
    }
    if (data.containsKey('environment')) {
      context.handle(
        _environmentMeta,
        environment.isAcceptableOrUnknown(
          data['environment']!,
          _environmentMeta,
        ),
      );
    }
    if (data.containsKey('realm_id')) {
      context.handle(
        _realmIdMeta,
        realmId.isAcceptableOrUnknown(data['realm_id']!, _realmIdMeta),
      );
    } else if (isInserting) {
      context.missing(_realmIdMeta);
    }
    if (data.containsKey('company_name')) {
      context.handle(
        _companyNameMeta,
        companyName.isAcceptableOrUnknown(
          data['company_name']!,
          _companyNameMeta,
        ),
      );
    }
    if (data.containsKey('access_token_expires_at')) {
      context.handle(
        _accessTokenExpiresAtMeta,
        accessTokenExpiresAt.isAcceptableOrUnknown(
          data['access_token_expires_at']!,
          _accessTokenExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('refresh_token_expires_at')) {
      context.handle(
        _refreshTokenExpiresAtMeta,
        refreshTokenExpiresAt.isAcceptableOrUnknown(
          data['refresh_token_expires_at']!,
          _refreshTokenExpiresAtMeta,
        ),
      );
    }
    if (data.containsKey('connected_at')) {
      context.handle(
        _connectedAtMeta,
        connectedAt.isAcceptableOrUnknown(
          data['connected_at']!,
          _connectedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_connectedAtMeta);
    }
    if (data.containsKey('last_refresh_at')) {
      context.handle(
        _lastRefreshAtMeta,
        lastRefreshAt.isAcceptableOrUnknown(
          data['last_refresh_at']!,
          _lastRefreshAtMeta,
        ),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OAuthConnectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OAuthConnectionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      edition: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edition'],
      )!,
      environment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}environment'],
      )!,
      realmId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}realm_id'],
      )!,
      companyName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}company_name'],
      ),
      accessTokenExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}access_token_expires_at'],
      ),
      refreshTokenExpiresAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}refresh_token_expires_at'],
      ),
      connectedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}connected_at'],
      )!,
      lastRefreshAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_refresh_at'],
      ),
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
    );
  }

  @override
  $OAuthConnectionsTable createAlias(String alias) {
    return $OAuthConnectionsTable(attachedDatabase, alias);
  }
}

class OAuthConnectionRow extends DataClass
    implements Insertable<OAuthConnectionRow> {
  final int id;
  final String edition;
  final String environment;
  final String realmId;
  final String? companyName;
  final DateTime? accessTokenExpiresAt;
  final DateTime? refreshTokenExpiresAt;
  final DateTime connectedAt;
  final DateTime? lastRefreshAt;
  final DateTime? lastSyncAt;
  const OAuthConnectionRow({
    required this.id,
    required this.edition,
    required this.environment,
    required this.realmId,
    this.companyName,
    this.accessTokenExpiresAt,
    this.refreshTokenExpiresAt,
    required this.connectedAt,
    this.lastRefreshAt,
    this.lastSyncAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['edition'] = Variable<String>(edition);
    map['environment'] = Variable<String>(environment);
    map['realm_id'] = Variable<String>(realmId);
    if (!nullToAbsent || companyName != null) {
      map['company_name'] = Variable<String>(companyName);
    }
    if (!nullToAbsent || accessTokenExpiresAt != null) {
      map['access_token_expires_at'] = Variable<DateTime>(accessTokenExpiresAt);
    }
    if (!nullToAbsent || refreshTokenExpiresAt != null) {
      map['refresh_token_expires_at'] = Variable<DateTime>(
        refreshTokenExpiresAt,
      );
    }
    map['connected_at'] = Variable<DateTime>(connectedAt);
    if (!nullToAbsent || lastRefreshAt != null) {
      map['last_refresh_at'] = Variable<DateTime>(lastRefreshAt);
    }
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    return map;
  }

  OAuthConnectionsCompanion toCompanion(bool nullToAbsent) {
    return OAuthConnectionsCompanion(
      id: Value(id),
      edition: Value(edition),
      environment: Value(environment),
      realmId: Value(realmId),
      companyName: companyName == null && nullToAbsent
          ? const Value.absent()
          : Value(companyName),
      accessTokenExpiresAt: accessTokenExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(accessTokenExpiresAt),
      refreshTokenExpiresAt: refreshTokenExpiresAt == null && nullToAbsent
          ? const Value.absent()
          : Value(refreshTokenExpiresAt),
      connectedAt: Value(connectedAt),
      lastRefreshAt: lastRefreshAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRefreshAt),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory OAuthConnectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OAuthConnectionRow(
      id: serializer.fromJson<int>(json['id']),
      edition: serializer.fromJson<String>(json['edition']),
      environment: serializer.fromJson<String>(json['environment']),
      realmId: serializer.fromJson<String>(json['realmId']),
      companyName: serializer.fromJson<String?>(json['companyName']),
      accessTokenExpiresAt: serializer.fromJson<DateTime?>(
        json['accessTokenExpiresAt'],
      ),
      refreshTokenExpiresAt: serializer.fromJson<DateTime?>(
        json['refreshTokenExpiresAt'],
      ),
      connectedAt: serializer.fromJson<DateTime>(json['connectedAt']),
      lastRefreshAt: serializer.fromJson<DateTime?>(json['lastRefreshAt']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'edition': serializer.toJson<String>(edition),
      'environment': serializer.toJson<String>(environment),
      'realmId': serializer.toJson<String>(realmId),
      'companyName': serializer.toJson<String?>(companyName),
      'accessTokenExpiresAt': serializer.toJson<DateTime?>(
        accessTokenExpiresAt,
      ),
      'refreshTokenExpiresAt': serializer.toJson<DateTime?>(
        refreshTokenExpiresAt,
      ),
      'connectedAt': serializer.toJson<DateTime>(connectedAt),
      'lastRefreshAt': serializer.toJson<DateTime?>(lastRefreshAt),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
    };
  }

  OAuthConnectionRow copyWith({
    int? id,
    String? edition,
    String? environment,
    String? realmId,
    Value<String?> companyName = const Value.absent(),
    Value<DateTime?> accessTokenExpiresAt = const Value.absent(),
    Value<DateTime?> refreshTokenExpiresAt = const Value.absent(),
    DateTime? connectedAt,
    Value<DateTime?> lastRefreshAt = const Value.absent(),
    Value<DateTime?> lastSyncAt = const Value.absent(),
  }) => OAuthConnectionRow(
    id: id ?? this.id,
    edition: edition ?? this.edition,
    environment: environment ?? this.environment,
    realmId: realmId ?? this.realmId,
    companyName: companyName.present ? companyName.value : this.companyName,
    accessTokenExpiresAt: accessTokenExpiresAt.present
        ? accessTokenExpiresAt.value
        : this.accessTokenExpiresAt,
    refreshTokenExpiresAt: refreshTokenExpiresAt.present
        ? refreshTokenExpiresAt.value
        : this.refreshTokenExpiresAt,
    connectedAt: connectedAt ?? this.connectedAt,
    lastRefreshAt: lastRefreshAt.present
        ? lastRefreshAt.value
        : this.lastRefreshAt,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
  );
  OAuthConnectionRow copyWithCompanion(OAuthConnectionsCompanion data) {
    return OAuthConnectionRow(
      id: data.id.present ? data.id.value : this.id,
      edition: data.edition.present ? data.edition.value : this.edition,
      environment: data.environment.present
          ? data.environment.value
          : this.environment,
      realmId: data.realmId.present ? data.realmId.value : this.realmId,
      companyName: data.companyName.present
          ? data.companyName.value
          : this.companyName,
      accessTokenExpiresAt: data.accessTokenExpiresAt.present
          ? data.accessTokenExpiresAt.value
          : this.accessTokenExpiresAt,
      refreshTokenExpiresAt: data.refreshTokenExpiresAt.present
          ? data.refreshTokenExpiresAt.value
          : this.refreshTokenExpiresAt,
      connectedAt: data.connectedAt.present
          ? data.connectedAt.value
          : this.connectedAt,
      lastRefreshAt: data.lastRefreshAt.present
          ? data.lastRefreshAt.value
          : this.lastRefreshAt,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OAuthConnectionRow(')
          ..write('id: $id, ')
          ..write('edition: $edition, ')
          ..write('environment: $environment, ')
          ..write('realmId: $realmId, ')
          ..write('companyName: $companyName, ')
          ..write('accessTokenExpiresAt: $accessTokenExpiresAt, ')
          ..write('refreshTokenExpiresAt: $refreshTokenExpiresAt, ')
          ..write('connectedAt: $connectedAt, ')
          ..write('lastRefreshAt: $lastRefreshAt, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    edition,
    environment,
    realmId,
    companyName,
    accessTokenExpiresAt,
    refreshTokenExpiresAt,
    connectedAt,
    lastRefreshAt,
    lastSyncAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OAuthConnectionRow &&
          other.id == this.id &&
          other.edition == this.edition &&
          other.environment == this.environment &&
          other.realmId == this.realmId &&
          other.companyName == this.companyName &&
          other.accessTokenExpiresAt == this.accessTokenExpiresAt &&
          other.refreshTokenExpiresAt == this.refreshTokenExpiresAt &&
          other.connectedAt == this.connectedAt &&
          other.lastRefreshAt == this.lastRefreshAt &&
          other.lastSyncAt == this.lastSyncAt);
}

class OAuthConnectionsCompanion extends UpdateCompanion<OAuthConnectionRow> {
  final Value<int> id;
  final Value<String> edition;
  final Value<String> environment;
  final Value<String> realmId;
  final Value<String?> companyName;
  final Value<DateTime?> accessTokenExpiresAt;
  final Value<DateTime?> refreshTokenExpiresAt;
  final Value<DateTime> connectedAt;
  final Value<DateTime?> lastRefreshAt;
  final Value<DateTime?> lastSyncAt;
  const OAuthConnectionsCompanion({
    this.id = const Value.absent(),
    this.edition = const Value.absent(),
    this.environment = const Value.absent(),
    this.realmId = const Value.absent(),
    this.companyName = const Value.absent(),
    this.accessTokenExpiresAt = const Value.absent(),
    this.refreshTokenExpiresAt = const Value.absent(),
    this.connectedAt = const Value.absent(),
    this.lastRefreshAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
  });
  OAuthConnectionsCompanion.insert({
    this.id = const Value.absent(),
    this.edition = const Value.absent(),
    this.environment = const Value.absent(),
    required String realmId,
    this.companyName = const Value.absent(),
    this.accessTokenExpiresAt = const Value.absent(),
    this.refreshTokenExpiresAt = const Value.absent(),
    required DateTime connectedAt,
    this.lastRefreshAt = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
  }) : realmId = Value(realmId),
       connectedAt = Value(connectedAt);
  static Insertable<OAuthConnectionRow> custom({
    Expression<int>? id,
    Expression<String>? edition,
    Expression<String>? environment,
    Expression<String>? realmId,
    Expression<String>? companyName,
    Expression<DateTime>? accessTokenExpiresAt,
    Expression<DateTime>? refreshTokenExpiresAt,
    Expression<DateTime>? connectedAt,
    Expression<DateTime>? lastRefreshAt,
    Expression<DateTime>? lastSyncAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (edition != null) 'edition': edition,
      if (environment != null) 'environment': environment,
      if (realmId != null) 'realm_id': realmId,
      if (companyName != null) 'company_name': companyName,
      if (accessTokenExpiresAt != null)
        'access_token_expires_at': accessTokenExpiresAt,
      if (refreshTokenExpiresAt != null)
        'refresh_token_expires_at': refreshTokenExpiresAt,
      if (connectedAt != null) 'connected_at': connectedAt,
      if (lastRefreshAt != null) 'last_refresh_at': lastRefreshAt,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
    });
  }

  OAuthConnectionsCompanion copyWith({
    Value<int>? id,
    Value<String>? edition,
    Value<String>? environment,
    Value<String>? realmId,
    Value<String?>? companyName,
    Value<DateTime?>? accessTokenExpiresAt,
    Value<DateTime?>? refreshTokenExpiresAt,
    Value<DateTime>? connectedAt,
    Value<DateTime?>? lastRefreshAt,
    Value<DateTime?>? lastSyncAt,
  }) {
    return OAuthConnectionsCompanion(
      id: id ?? this.id,
      edition: edition ?? this.edition,
      environment: environment ?? this.environment,
      realmId: realmId ?? this.realmId,
      companyName: companyName ?? this.companyName,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      refreshTokenExpiresAt:
          refreshTokenExpiresAt ?? this.refreshTokenExpiresAt,
      connectedAt: connectedAt ?? this.connectedAt,
      lastRefreshAt: lastRefreshAt ?? this.lastRefreshAt,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (edition.present) {
      map['edition'] = Variable<String>(edition.value);
    }
    if (environment.present) {
      map['environment'] = Variable<String>(environment.value);
    }
    if (realmId.present) {
      map['realm_id'] = Variable<String>(realmId.value);
    }
    if (companyName.present) {
      map['company_name'] = Variable<String>(companyName.value);
    }
    if (accessTokenExpiresAt.present) {
      map['access_token_expires_at'] = Variable<DateTime>(
        accessTokenExpiresAt.value,
      );
    }
    if (refreshTokenExpiresAt.present) {
      map['refresh_token_expires_at'] = Variable<DateTime>(
        refreshTokenExpiresAt.value,
      );
    }
    if (connectedAt.present) {
      map['connected_at'] = Variable<DateTime>(connectedAt.value);
    }
    if (lastRefreshAt.present) {
      map['last_refresh_at'] = Variable<DateTime>(lastRefreshAt.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OAuthConnectionsCompanion(')
          ..write('id: $id, ')
          ..write('edition: $edition, ')
          ..write('environment: $environment, ')
          ..write('realmId: $realmId, ')
          ..write('companyName: $companyName, ')
          ..write('accessTokenExpiresAt: $accessTokenExpiresAt, ')
          ..write('refreshTokenExpiresAt: $refreshTokenExpiresAt, ')
          ..write('connectedAt: $connectedAt, ')
          ..write('lastRefreshAt: $lastRefreshAt, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }
}

class $AccountMappingsTable extends AccountMappings
    with TableInfo<$AccountMappingsTable, AccountMappingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountMappingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountNameMeta = const VerificationMeta(
    'accountName',
  );
  @override
  late final GeneratedColumn<String> accountName = GeneratedColumn<String>(
    'account_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sideMeta = const VerificationMeta('side');
  @override
  late final GeneratedColumn<String> side = GeneratedColumn<String>(
    'side',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityDisplayNameMeta = const VerificationMeta(
    'entityDisplayName',
  );
  @override
  late final GeneratedColumn<String> entityDisplayName =
      GeneratedColumn<String>(
        'entity_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    accountId,
    accountName,
    side,
    description,
    entityType,
    entityId,
    entityDisplayName,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_mappings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountMappingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('account_name')) {
      context.handle(
        _accountNameMeta,
        accountName.isAcceptableOrUnknown(
          data['account_name']!,
          _accountNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accountNameMeta);
    }
    if (data.containsKey('side')) {
      context.handle(
        _sideMeta,
        side.isAcceptableOrUnknown(data['side']!, _sideMeta),
      );
    } else if (isInserting) {
      context.missing(_sideMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    }
    if (data.containsKey('entity_name')) {
      context.handle(
        _entityDisplayNameMeta,
        entityDisplayName.isAcceptableOrUnknown(
          data['entity_name']!,
          _entityDisplayNameMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountMappingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountMappingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      accountName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_name'],
      )!,
      side: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}side'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      ),
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      ),
      entityDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_name'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AccountMappingsTable createAlias(String alias) {
    return $AccountMappingsTable(attachedDatabase, alias);
  }
}

class AccountMappingRow extends DataClass
    implements Insertable<AccountMappingRow> {
  final int id;
  final String category;
  final String accountId;
  final String accountName;
  final String side;
  final String? description;
  final String? entityType;
  final String? entityId;
  final String? entityDisplayName;
  final DateTime updatedAt;
  const AccountMappingRow({
    required this.id,
    required this.category,
    required this.accountId,
    required this.accountName,
    required this.side,
    this.description,
    this.entityType,
    this.entityId,
    this.entityDisplayName,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category'] = Variable<String>(category);
    map['account_id'] = Variable<String>(accountId);
    map['account_name'] = Variable<String>(accountName);
    map['side'] = Variable<String>(side);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || entityType != null) {
      map['entity_type'] = Variable<String>(entityType);
    }
    if (!nullToAbsent || entityId != null) {
      map['entity_id'] = Variable<String>(entityId);
    }
    if (!nullToAbsent || entityDisplayName != null) {
      map['entity_name'] = Variable<String>(entityDisplayName);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AccountMappingsCompanion toCompanion(bool nullToAbsent) {
    return AccountMappingsCompanion(
      id: Value(id),
      category: Value(category),
      accountId: Value(accountId),
      accountName: Value(accountName),
      side: Value(side),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      entityType: entityType == null && nullToAbsent
          ? const Value.absent()
          : Value(entityType),
      entityId: entityId == null && nullToAbsent
          ? const Value.absent()
          : Value(entityId),
      entityDisplayName: entityDisplayName == null && nullToAbsent
          ? const Value.absent()
          : Value(entityDisplayName),
      updatedAt: Value(updatedAt),
    );
  }

  factory AccountMappingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountMappingRow(
      id: serializer.fromJson<int>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      accountId: serializer.fromJson<String>(json['accountId']),
      accountName: serializer.fromJson<String>(json['accountName']),
      side: serializer.fromJson<String>(json['side']),
      description: serializer.fromJson<String?>(json['description']),
      entityType: serializer.fromJson<String?>(json['entityType']),
      entityId: serializer.fromJson<String?>(json['entityId']),
      entityDisplayName: serializer.fromJson<String?>(
        json['entityDisplayName'],
      ),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'category': serializer.toJson<String>(category),
      'accountId': serializer.toJson<String>(accountId),
      'accountName': serializer.toJson<String>(accountName),
      'side': serializer.toJson<String>(side),
      'description': serializer.toJson<String?>(description),
      'entityType': serializer.toJson<String?>(entityType),
      'entityId': serializer.toJson<String?>(entityId),
      'entityDisplayName': serializer.toJson<String?>(entityDisplayName),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AccountMappingRow copyWith({
    int? id,
    String? category,
    String? accountId,
    String? accountName,
    String? side,
    Value<String?> description = const Value.absent(),
    Value<String?> entityType = const Value.absent(),
    Value<String?> entityId = const Value.absent(),
    Value<String?> entityDisplayName = const Value.absent(),
    DateTime? updatedAt,
  }) => AccountMappingRow(
    id: id ?? this.id,
    category: category ?? this.category,
    accountId: accountId ?? this.accountId,
    accountName: accountName ?? this.accountName,
    side: side ?? this.side,
    description: description.present ? description.value : this.description,
    entityType: entityType.present ? entityType.value : this.entityType,
    entityId: entityId.present ? entityId.value : this.entityId,
    entityDisplayName: entityDisplayName.present
        ? entityDisplayName.value
        : this.entityDisplayName,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AccountMappingRow copyWithCompanion(AccountMappingsCompanion data) {
    return AccountMappingRow(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      accountName: data.accountName.present
          ? data.accountName.value
          : this.accountName,
      side: data.side.present ? data.side.value : this.side,
      description: data.description.present
          ? data.description.value
          : this.description,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      entityDisplayName: data.entityDisplayName.present
          ? data.entityDisplayName.value
          : this.entityDisplayName,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountMappingRow(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('accountId: $accountId, ')
          ..write('accountName: $accountName, ')
          ..write('side: $side, ')
          ..write('description: $description, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('entityDisplayName: $entityDisplayName, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    category,
    accountId,
    accountName,
    side,
    description,
    entityType,
    entityId,
    entityDisplayName,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountMappingRow &&
          other.id == this.id &&
          other.category == this.category &&
          other.accountId == this.accountId &&
          other.accountName == this.accountName &&
          other.side == this.side &&
          other.description == this.description &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.entityDisplayName == this.entityDisplayName &&
          other.updatedAt == this.updatedAt);
}

class AccountMappingsCompanion extends UpdateCompanion<AccountMappingRow> {
  final Value<int> id;
  final Value<String> category;
  final Value<String> accountId;
  final Value<String> accountName;
  final Value<String> side;
  final Value<String?> description;
  final Value<String?> entityType;
  final Value<String?> entityId;
  final Value<String?> entityDisplayName;
  final Value<DateTime> updatedAt;
  const AccountMappingsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.accountId = const Value.absent(),
    this.accountName = const Value.absent(),
    this.side = const Value.absent(),
    this.description = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.entityDisplayName = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  AccountMappingsCompanion.insert({
    this.id = const Value.absent(),
    required String category,
    required String accountId,
    required String accountName,
    required String side,
    this.description = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.entityDisplayName = const Value.absent(),
    required DateTime updatedAt,
  }) : category = Value(category),
       accountId = Value(accountId),
       accountName = Value(accountName),
       side = Value(side),
       updatedAt = Value(updatedAt);
  static Insertable<AccountMappingRow> custom({
    Expression<int>? id,
    Expression<String>? category,
    Expression<String>? accountId,
    Expression<String>? accountName,
    Expression<String>? side,
    Expression<String>? description,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? entityDisplayName,
    Expression<DateTime>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (accountId != null) 'account_id': accountId,
      if (accountName != null) 'account_name': accountName,
      if (side != null) 'side': side,
      if (description != null) 'description': description,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (entityDisplayName != null) 'entity_name': entityDisplayName,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  AccountMappingsCompanion copyWith({
    Value<int>? id,
    Value<String>? category,
    Value<String>? accountId,
    Value<String>? accountName,
    Value<String>? side,
    Value<String?>? description,
    Value<String?>? entityType,
    Value<String?>? entityId,
    Value<String?>? entityDisplayName,
    Value<DateTime>? updatedAt,
  }) {
    return AccountMappingsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      accountId: accountId ?? this.accountId,
      accountName: accountName ?? this.accountName,
      side: side ?? this.side,
      description: description ?? this.description,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      entityDisplayName: entityDisplayName ?? this.entityDisplayName,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (accountName.present) {
      map['account_name'] = Variable<String>(accountName.value);
    }
    if (side.present) {
      map['side'] = Variable<String>(side.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (entityDisplayName.present) {
      map['entity_name'] = Variable<String>(entityDisplayName.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountMappingsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('accountId: $accountId, ')
          ..write('accountName: $accountName, ')
          ..write('side: $side, ')
          ..write('description: $description, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('entityDisplayName: $entityDisplayName, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncSchedulesTable extends SyncSchedules
    with TableInfo<$SyncSchedulesTable, SyncScheduleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncSchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeOfDayMeta = const VerificationMeta(
    'timeOfDay',
  );
  @override
  late final GeneratedColumn<String> timeOfDay = GeneratedColumn<String>(
    'time_of_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayOfWeekMeta = const VerificationMeta(
    'dayOfWeek',
  );
  @override
  late final GeneratedColumn<int> dayOfWeek = GeneratedColumn<int>(
    'day_of_week',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayOfMonthMeta = const VerificationMeta(
    'dayOfMonth',
  );
  @override
  late final GeneratedColumn<int> dayOfMonth = GeneratedColumn<int>(
    'day_of_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastRunAtMeta = const VerificationMeta(
    'lastRunAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastRunAt = GeneratedColumn<DateTime>(
    'last_run_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextRunAtMeta = const VerificationMeta(
    'nextRunAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRunAt = GeneratedColumn<DateTime>(
    'next_run_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    enabled,
    frequency,
    timeOfDay,
    dayOfWeek,
    dayOfMonth,
    lastRunAt,
    nextRunAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncScheduleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('time_of_day')) {
      context.handle(
        _timeOfDayMeta,
        timeOfDay.isAcceptableOrUnknown(data['time_of_day']!, _timeOfDayMeta),
      );
    } else if (isInserting) {
      context.missing(_timeOfDayMeta);
    }
    if (data.containsKey('day_of_week')) {
      context.handle(
        _dayOfWeekMeta,
        dayOfWeek.isAcceptableOrUnknown(data['day_of_week']!, _dayOfWeekMeta),
      );
    }
    if (data.containsKey('day_of_month')) {
      context.handle(
        _dayOfMonthMeta,
        dayOfMonth.isAcceptableOrUnknown(
          data['day_of_month']!,
          _dayOfMonthMeta,
        ),
      );
    }
    if (data.containsKey('last_run_at')) {
      context.handle(
        _lastRunAtMeta,
        lastRunAt.isAcceptableOrUnknown(data['last_run_at']!, _lastRunAtMeta),
      );
    }
    if (data.containsKey('next_run_at')) {
      context.handle(
        _nextRunAtMeta,
        nextRunAt.isAcceptableOrUnknown(data['next_run_at']!, _nextRunAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncScheduleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncScheduleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      timeOfDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_of_day'],
      )!,
      dayOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_week'],
      ),
      dayOfMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_of_month'],
      ),
      lastRunAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_run_at'],
      ),
      nextRunAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_run_at'],
      ),
    );
  }

  @override
  $SyncSchedulesTable createAlias(String alias) {
    return $SyncSchedulesTable(attachedDatabase, alias);
  }
}

class SyncScheduleRow extends DataClass implements Insertable<SyncScheduleRow> {
  final int id;
  final bool enabled;
  final String frequency;
  final String timeOfDay;
  final int? dayOfWeek;
  final int? dayOfMonth;
  final DateTime? lastRunAt;
  final DateTime? nextRunAt;
  const SyncScheduleRow({
    required this.id,
    required this.enabled,
    required this.frequency,
    required this.timeOfDay,
    this.dayOfWeek,
    this.dayOfMonth,
    this.lastRunAt,
    this.nextRunAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['enabled'] = Variable<bool>(enabled);
    map['frequency'] = Variable<String>(frequency);
    map['time_of_day'] = Variable<String>(timeOfDay);
    if (!nullToAbsent || dayOfWeek != null) {
      map['day_of_week'] = Variable<int>(dayOfWeek);
    }
    if (!nullToAbsent || dayOfMonth != null) {
      map['day_of_month'] = Variable<int>(dayOfMonth);
    }
    if (!nullToAbsent || lastRunAt != null) {
      map['last_run_at'] = Variable<DateTime>(lastRunAt);
    }
    if (!nullToAbsent || nextRunAt != null) {
      map['next_run_at'] = Variable<DateTime>(nextRunAt);
    }
    return map;
  }

  SyncSchedulesCompanion toCompanion(bool nullToAbsent) {
    return SyncSchedulesCompanion(
      id: Value(id),
      enabled: Value(enabled),
      frequency: Value(frequency),
      timeOfDay: Value(timeOfDay),
      dayOfWeek: dayOfWeek == null && nullToAbsent
          ? const Value.absent()
          : Value(dayOfWeek),
      dayOfMonth: dayOfMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(dayOfMonth),
      lastRunAt: lastRunAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastRunAt),
      nextRunAt: nextRunAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRunAt),
    );
  }

  factory SyncScheduleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncScheduleRow(
      id: serializer.fromJson<int>(json['id']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      frequency: serializer.fromJson<String>(json['frequency']),
      timeOfDay: serializer.fromJson<String>(json['timeOfDay']),
      dayOfWeek: serializer.fromJson<int?>(json['dayOfWeek']),
      dayOfMonth: serializer.fromJson<int?>(json['dayOfMonth']),
      lastRunAt: serializer.fromJson<DateTime?>(json['lastRunAt']),
      nextRunAt: serializer.fromJson<DateTime?>(json['nextRunAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'enabled': serializer.toJson<bool>(enabled),
      'frequency': serializer.toJson<String>(frequency),
      'timeOfDay': serializer.toJson<String>(timeOfDay),
      'dayOfWeek': serializer.toJson<int?>(dayOfWeek),
      'dayOfMonth': serializer.toJson<int?>(dayOfMonth),
      'lastRunAt': serializer.toJson<DateTime?>(lastRunAt),
      'nextRunAt': serializer.toJson<DateTime?>(nextRunAt),
    };
  }

  SyncScheduleRow copyWith({
    int? id,
    bool? enabled,
    String? frequency,
    String? timeOfDay,
    Value<int?> dayOfWeek = const Value.absent(),
    Value<int?> dayOfMonth = const Value.absent(),
    Value<DateTime?> lastRunAt = const Value.absent(),
    Value<DateTime?> nextRunAt = const Value.absent(),
  }) => SyncScheduleRow(
    id: id ?? this.id,
    enabled: enabled ?? this.enabled,
    frequency: frequency ?? this.frequency,
    timeOfDay: timeOfDay ?? this.timeOfDay,
    dayOfWeek: dayOfWeek.present ? dayOfWeek.value : this.dayOfWeek,
    dayOfMonth: dayOfMonth.present ? dayOfMonth.value : this.dayOfMonth,
    lastRunAt: lastRunAt.present ? lastRunAt.value : this.lastRunAt,
    nextRunAt: nextRunAt.present ? nextRunAt.value : this.nextRunAt,
  );
  SyncScheduleRow copyWithCompanion(SyncSchedulesCompanion data) {
    return SyncScheduleRow(
      id: data.id.present ? data.id.value : this.id,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      timeOfDay: data.timeOfDay.present ? data.timeOfDay.value : this.timeOfDay,
      dayOfWeek: data.dayOfWeek.present ? data.dayOfWeek.value : this.dayOfWeek,
      dayOfMonth: data.dayOfMonth.present
          ? data.dayOfMonth.value
          : this.dayOfMonth,
      lastRunAt: data.lastRunAt.present ? data.lastRunAt.value : this.lastRunAt,
      nextRunAt: data.nextRunAt.present ? data.nextRunAt.value : this.nextRunAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncScheduleRow(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('frequency: $frequency, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('lastRunAt: $lastRunAt, ')
          ..write('nextRunAt: $nextRunAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    enabled,
    frequency,
    timeOfDay,
    dayOfWeek,
    dayOfMonth,
    lastRunAt,
    nextRunAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncScheduleRow &&
          other.id == this.id &&
          other.enabled == this.enabled &&
          other.frequency == this.frequency &&
          other.timeOfDay == this.timeOfDay &&
          other.dayOfWeek == this.dayOfWeek &&
          other.dayOfMonth == this.dayOfMonth &&
          other.lastRunAt == this.lastRunAt &&
          other.nextRunAt == this.nextRunAt);
}

class SyncSchedulesCompanion extends UpdateCompanion<SyncScheduleRow> {
  final Value<int> id;
  final Value<bool> enabled;
  final Value<String> frequency;
  final Value<String> timeOfDay;
  final Value<int?> dayOfWeek;
  final Value<int?> dayOfMonth;
  final Value<DateTime?> lastRunAt;
  final Value<DateTime?> nextRunAt;
  const SyncSchedulesCompanion({
    this.id = const Value.absent(),
    this.enabled = const Value.absent(),
    this.frequency = const Value.absent(),
    this.timeOfDay = const Value.absent(),
    this.dayOfWeek = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.lastRunAt = const Value.absent(),
    this.nextRunAt = const Value.absent(),
  });
  SyncSchedulesCompanion.insert({
    this.id = const Value.absent(),
    this.enabled = const Value.absent(),
    required String frequency,
    required String timeOfDay,
    this.dayOfWeek = const Value.absent(),
    this.dayOfMonth = const Value.absent(),
    this.lastRunAt = const Value.absent(),
    this.nextRunAt = const Value.absent(),
  }) : frequency = Value(frequency),
       timeOfDay = Value(timeOfDay);
  static Insertable<SyncScheduleRow> custom({
    Expression<int>? id,
    Expression<bool>? enabled,
    Expression<String>? frequency,
    Expression<String>? timeOfDay,
    Expression<int>? dayOfWeek,
    Expression<int>? dayOfMonth,
    Expression<DateTime>? lastRunAt,
    Expression<DateTime>? nextRunAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (enabled != null) 'enabled': enabled,
      if (frequency != null) 'frequency': frequency,
      if (timeOfDay != null) 'time_of_day': timeOfDay,
      if (dayOfWeek != null) 'day_of_week': dayOfWeek,
      if (dayOfMonth != null) 'day_of_month': dayOfMonth,
      if (lastRunAt != null) 'last_run_at': lastRunAt,
      if (nextRunAt != null) 'next_run_at': nextRunAt,
    });
  }

  SyncSchedulesCompanion copyWith({
    Value<int>? id,
    Value<bool>? enabled,
    Value<String>? frequency,
    Value<String>? timeOfDay,
    Value<int?>? dayOfWeek,
    Value<int?>? dayOfMonth,
    Value<DateTime?>? lastRunAt,
    Value<DateTime?>? nextRunAt,
  }) {
    return SyncSchedulesCompanion(
      id: id ?? this.id,
      enabled: enabled ?? this.enabled,
      frequency: frequency ?? this.frequency,
      timeOfDay: timeOfDay ?? this.timeOfDay,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      lastRunAt: lastRunAt ?? this.lastRunAt,
      nextRunAt: nextRunAt ?? this.nextRunAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (timeOfDay.present) {
      map['time_of_day'] = Variable<String>(timeOfDay.value);
    }
    if (dayOfWeek.present) {
      map['day_of_week'] = Variable<int>(dayOfWeek.value);
    }
    if (dayOfMonth.present) {
      map['day_of_month'] = Variable<int>(dayOfMonth.value);
    }
    if (lastRunAt.present) {
      map['last_run_at'] = Variable<DateTime>(lastRunAt.value);
    }
    if (nextRunAt.present) {
      map['next_run_at'] = Variable<DateTime>(nextRunAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncSchedulesCompanion(')
          ..write('id: $id, ')
          ..write('enabled: $enabled, ')
          ..write('frequency: $frequency, ')
          ..write('timeOfDay: $timeOfDay, ')
          ..write('dayOfWeek: $dayOfWeek, ')
          ..write('dayOfMonth: $dayOfMonth, ')
          ..write('lastRunAt: $lastRunAt, ')
          ..write('nextRunAt: $nextRunAt')
          ..write(')'))
        .toString();
  }
}

class $SyncHistoryTable extends SyncHistory
    with TableInfo<$SyncHistoryTable, SyncHistoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _ranAtMeta = const VerificationMeta('ranAt');
  @override
  late final GeneratedColumn<DateTime> ranAt = GeneratedColumn<DateTime>(
    'ran_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _triggerMeta = const VerificationMeta(
    'trigger',
  );
  @override
  late final GeneratedColumn<String> trigger = GeneratedColumn<String>(
    'trigger',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _performedByMeta = const VerificationMeta(
    'performedBy',
  );
  @override
  late final GeneratedColumn<String> performedBy = GeneratedColumn<String>(
    'performed_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fromDateMeta = const VerificationMeta(
    'fromDate',
  );
  @override
  late final GeneratedColumn<DateTime> fromDate = GeneratedColumn<DateTime>(
    'from_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _toDateMeta = const VerificationMeta('toDate');
  @override
  late final GeneratedColumn<DateTime> toDate = GeneratedColumn<DateTime>(
    'to_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalDebitMeta = const VerificationMeta(
    'totalDebit',
  );
  @override
  late final GeneratedColumn<double> totalDebit = GeneratedColumn<double>(
    'total_debit',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalCreditMeta = const VerificationMeta(
    'totalCredit',
  );
  @override
  late final GeneratedColumn<double> totalCredit = GeneratedColumn<double>(
    'total_credit',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _qboJournalEntryIdMeta = const VerificationMeta(
    'qboJournalEntryId',
  );
  @override
  late final GeneratedColumn<String> qboJournalEntryId =
      GeneratedColumn<String>(
        'qbo_journal_entry_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _requestJsonMeta = const VerificationMeta(
    'requestJson',
  );
  @override
  late final GeneratedColumn<String> requestJson = GeneratedColumn<String>(
    'request_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _responseJsonMeta = const VerificationMeta(
    'responseJson',
  );
  @override
  late final GeneratedColumn<String> responseJson = GeneratedColumn<String>(
    'response_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    ranAt,
    trigger,
    performedBy,
    fromDate,
    toDate,
    status,
    totalDebit,
    totalCredit,
    qboJournalEntryId,
    requestJson,
    responseJson,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncHistoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('ran_at')) {
      context.handle(
        _ranAtMeta,
        ranAt.isAcceptableOrUnknown(data['ran_at']!, _ranAtMeta),
      );
    } else if (isInserting) {
      context.missing(_ranAtMeta);
    }
    if (data.containsKey('trigger')) {
      context.handle(
        _triggerMeta,
        trigger.isAcceptableOrUnknown(data['trigger']!, _triggerMeta),
      );
    } else if (isInserting) {
      context.missing(_triggerMeta);
    }
    if (data.containsKey('performed_by')) {
      context.handle(
        _performedByMeta,
        performedBy.isAcceptableOrUnknown(
          data['performed_by']!,
          _performedByMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_performedByMeta);
    }
    if (data.containsKey('from_date')) {
      context.handle(
        _fromDateMeta,
        fromDate.isAcceptableOrUnknown(data['from_date']!, _fromDateMeta),
      );
    } else if (isInserting) {
      context.missing(_fromDateMeta);
    }
    if (data.containsKey('to_date')) {
      context.handle(
        _toDateMeta,
        toDate.isAcceptableOrUnknown(data['to_date']!, _toDateMeta),
      );
    } else if (isInserting) {
      context.missing(_toDateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('total_debit')) {
      context.handle(
        _totalDebitMeta,
        totalDebit.isAcceptableOrUnknown(data['total_debit']!, _totalDebitMeta),
      );
    }
    if (data.containsKey('total_credit')) {
      context.handle(
        _totalCreditMeta,
        totalCredit.isAcceptableOrUnknown(
          data['total_credit']!,
          _totalCreditMeta,
        ),
      );
    }
    if (data.containsKey('qbo_journal_entry_id')) {
      context.handle(
        _qboJournalEntryIdMeta,
        qboJournalEntryId.isAcceptableOrUnknown(
          data['qbo_journal_entry_id']!,
          _qboJournalEntryIdMeta,
        ),
      );
    }
    if (data.containsKey('request_json')) {
      context.handle(
        _requestJsonMeta,
        requestJson.isAcceptableOrUnknown(
          data['request_json']!,
          _requestJsonMeta,
        ),
      );
    }
    if (data.containsKey('response_json')) {
      context.handle(
        _responseJsonMeta,
        responseJson.isAcceptableOrUnknown(
          data['response_json']!,
          _responseJsonMeta,
        ),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncHistoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncHistoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      ranAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ran_at'],
      )!,
      trigger: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trigger'],
      )!,
      performedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}performed_by'],
      )!,
      fromDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}from_date'],
      )!,
      toDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}to_date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      totalDebit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_debit'],
      ),
      totalCredit: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_credit'],
      ),
      qboJournalEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}qbo_journal_entry_id'],
      ),
      requestJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}request_json'],
      ),
      responseJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_json'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $SyncHistoryTable createAlias(String alias) {
    return $SyncHistoryTable(attachedDatabase, alias);
  }
}

class SyncHistoryRow extends DataClass implements Insertable<SyncHistoryRow> {
  final int id;
  final DateTime ranAt;
  final String trigger;
  final String performedBy;
  final DateTime fromDate;
  final DateTime toDate;
  final String status;
  final double? totalDebit;
  final double? totalCredit;
  final String? qboJournalEntryId;
  final String? requestJson;
  final String? responseJson;
  final String? errorMessage;
  const SyncHistoryRow({
    required this.id,
    required this.ranAt,
    required this.trigger,
    required this.performedBy,
    required this.fromDate,
    required this.toDate,
    required this.status,
    this.totalDebit,
    this.totalCredit,
    this.qboJournalEntryId,
    this.requestJson,
    this.responseJson,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['ran_at'] = Variable<DateTime>(ranAt);
    map['trigger'] = Variable<String>(trigger);
    map['performed_by'] = Variable<String>(performedBy);
    map['from_date'] = Variable<DateTime>(fromDate);
    map['to_date'] = Variable<DateTime>(toDate);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || totalDebit != null) {
      map['total_debit'] = Variable<double>(totalDebit);
    }
    if (!nullToAbsent || totalCredit != null) {
      map['total_credit'] = Variable<double>(totalCredit);
    }
    if (!nullToAbsent || qboJournalEntryId != null) {
      map['qbo_journal_entry_id'] = Variable<String>(qboJournalEntryId);
    }
    if (!nullToAbsent || requestJson != null) {
      map['request_json'] = Variable<String>(requestJson);
    }
    if (!nullToAbsent || responseJson != null) {
      map['response_json'] = Variable<String>(responseJson);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  SyncHistoryCompanion toCompanion(bool nullToAbsent) {
    return SyncHistoryCompanion(
      id: Value(id),
      ranAt: Value(ranAt),
      trigger: Value(trigger),
      performedBy: Value(performedBy),
      fromDate: Value(fromDate),
      toDate: Value(toDate),
      status: Value(status),
      totalDebit: totalDebit == null && nullToAbsent
          ? const Value.absent()
          : Value(totalDebit),
      totalCredit: totalCredit == null && nullToAbsent
          ? const Value.absent()
          : Value(totalCredit),
      qboJournalEntryId: qboJournalEntryId == null && nullToAbsent
          ? const Value.absent()
          : Value(qboJournalEntryId),
      requestJson: requestJson == null && nullToAbsent
          ? const Value.absent()
          : Value(requestJson),
      responseJson: responseJson == null && nullToAbsent
          ? const Value.absent()
          : Value(responseJson),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory SyncHistoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncHistoryRow(
      id: serializer.fromJson<int>(json['id']),
      ranAt: serializer.fromJson<DateTime>(json['ranAt']),
      trigger: serializer.fromJson<String>(json['trigger']),
      performedBy: serializer.fromJson<String>(json['performedBy']),
      fromDate: serializer.fromJson<DateTime>(json['fromDate']),
      toDate: serializer.fromJson<DateTime>(json['toDate']),
      status: serializer.fromJson<String>(json['status']),
      totalDebit: serializer.fromJson<double?>(json['totalDebit']),
      totalCredit: serializer.fromJson<double?>(json['totalCredit']),
      qboJournalEntryId: serializer.fromJson<String?>(
        json['qboJournalEntryId'],
      ),
      requestJson: serializer.fromJson<String?>(json['requestJson']),
      responseJson: serializer.fromJson<String?>(json['responseJson']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'ranAt': serializer.toJson<DateTime>(ranAt),
      'trigger': serializer.toJson<String>(trigger),
      'performedBy': serializer.toJson<String>(performedBy),
      'fromDate': serializer.toJson<DateTime>(fromDate),
      'toDate': serializer.toJson<DateTime>(toDate),
      'status': serializer.toJson<String>(status),
      'totalDebit': serializer.toJson<double?>(totalDebit),
      'totalCredit': serializer.toJson<double?>(totalCredit),
      'qboJournalEntryId': serializer.toJson<String?>(qboJournalEntryId),
      'requestJson': serializer.toJson<String?>(requestJson),
      'responseJson': serializer.toJson<String?>(responseJson),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  SyncHistoryRow copyWith({
    int? id,
    DateTime? ranAt,
    String? trigger,
    String? performedBy,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    Value<double?> totalDebit = const Value.absent(),
    Value<double?> totalCredit = const Value.absent(),
    Value<String?> qboJournalEntryId = const Value.absent(),
    Value<String?> requestJson = const Value.absent(),
    Value<String?> responseJson = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
  }) => SyncHistoryRow(
    id: id ?? this.id,
    ranAt: ranAt ?? this.ranAt,
    trigger: trigger ?? this.trigger,
    performedBy: performedBy ?? this.performedBy,
    fromDate: fromDate ?? this.fromDate,
    toDate: toDate ?? this.toDate,
    status: status ?? this.status,
    totalDebit: totalDebit.present ? totalDebit.value : this.totalDebit,
    totalCredit: totalCredit.present ? totalCredit.value : this.totalCredit,
    qboJournalEntryId: qboJournalEntryId.present
        ? qboJournalEntryId.value
        : this.qboJournalEntryId,
    requestJson: requestJson.present ? requestJson.value : this.requestJson,
    responseJson: responseJson.present ? responseJson.value : this.responseJson,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  SyncHistoryRow copyWithCompanion(SyncHistoryCompanion data) {
    return SyncHistoryRow(
      id: data.id.present ? data.id.value : this.id,
      ranAt: data.ranAt.present ? data.ranAt.value : this.ranAt,
      trigger: data.trigger.present ? data.trigger.value : this.trigger,
      performedBy: data.performedBy.present
          ? data.performedBy.value
          : this.performedBy,
      fromDate: data.fromDate.present ? data.fromDate.value : this.fromDate,
      toDate: data.toDate.present ? data.toDate.value : this.toDate,
      status: data.status.present ? data.status.value : this.status,
      totalDebit: data.totalDebit.present
          ? data.totalDebit.value
          : this.totalDebit,
      totalCredit: data.totalCredit.present
          ? data.totalCredit.value
          : this.totalCredit,
      qboJournalEntryId: data.qboJournalEntryId.present
          ? data.qboJournalEntryId.value
          : this.qboJournalEntryId,
      requestJson: data.requestJson.present
          ? data.requestJson.value
          : this.requestJson,
      responseJson: data.responseJson.present
          ? data.responseJson.value
          : this.responseJson,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncHistoryRow(')
          ..write('id: $id, ')
          ..write('ranAt: $ranAt, ')
          ..write('trigger: $trigger, ')
          ..write('performedBy: $performedBy, ')
          ..write('fromDate: $fromDate, ')
          ..write('toDate: $toDate, ')
          ..write('status: $status, ')
          ..write('totalDebit: $totalDebit, ')
          ..write('totalCredit: $totalCredit, ')
          ..write('qboJournalEntryId: $qboJournalEntryId, ')
          ..write('requestJson: $requestJson, ')
          ..write('responseJson: $responseJson, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    ranAt,
    trigger,
    performedBy,
    fromDate,
    toDate,
    status,
    totalDebit,
    totalCredit,
    qboJournalEntryId,
    requestJson,
    responseJson,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncHistoryRow &&
          other.id == this.id &&
          other.ranAt == this.ranAt &&
          other.trigger == this.trigger &&
          other.performedBy == this.performedBy &&
          other.fromDate == this.fromDate &&
          other.toDate == this.toDate &&
          other.status == this.status &&
          other.totalDebit == this.totalDebit &&
          other.totalCredit == this.totalCredit &&
          other.qboJournalEntryId == this.qboJournalEntryId &&
          other.requestJson == this.requestJson &&
          other.responseJson == this.responseJson &&
          other.errorMessage == this.errorMessage);
}

class SyncHistoryCompanion extends UpdateCompanion<SyncHistoryRow> {
  final Value<int> id;
  final Value<DateTime> ranAt;
  final Value<String> trigger;
  final Value<String> performedBy;
  final Value<DateTime> fromDate;
  final Value<DateTime> toDate;
  final Value<String> status;
  final Value<double?> totalDebit;
  final Value<double?> totalCredit;
  final Value<String?> qboJournalEntryId;
  final Value<String?> requestJson;
  final Value<String?> responseJson;
  final Value<String?> errorMessage;
  const SyncHistoryCompanion({
    this.id = const Value.absent(),
    this.ranAt = const Value.absent(),
    this.trigger = const Value.absent(),
    this.performedBy = const Value.absent(),
    this.fromDate = const Value.absent(),
    this.toDate = const Value.absent(),
    this.status = const Value.absent(),
    this.totalDebit = const Value.absent(),
    this.totalCredit = const Value.absent(),
    this.qboJournalEntryId = const Value.absent(),
    this.requestJson = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.errorMessage = const Value.absent(),
  });
  SyncHistoryCompanion.insert({
    this.id = const Value.absent(),
    required DateTime ranAt,
    required String trigger,
    required String performedBy,
    required DateTime fromDate,
    required DateTime toDate,
    required String status,
    this.totalDebit = const Value.absent(),
    this.totalCredit = const Value.absent(),
    this.qboJournalEntryId = const Value.absent(),
    this.requestJson = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.errorMessage = const Value.absent(),
  }) : ranAt = Value(ranAt),
       trigger = Value(trigger),
       performedBy = Value(performedBy),
       fromDate = Value(fromDate),
       toDate = Value(toDate),
       status = Value(status);
  static Insertable<SyncHistoryRow> custom({
    Expression<int>? id,
    Expression<DateTime>? ranAt,
    Expression<String>? trigger,
    Expression<String>? performedBy,
    Expression<DateTime>? fromDate,
    Expression<DateTime>? toDate,
    Expression<String>? status,
    Expression<double>? totalDebit,
    Expression<double>? totalCredit,
    Expression<String>? qboJournalEntryId,
    Expression<String>? requestJson,
    Expression<String>? responseJson,
    Expression<String>? errorMessage,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (ranAt != null) 'ran_at': ranAt,
      if (trigger != null) 'trigger': trigger,
      if (performedBy != null) 'performed_by': performedBy,
      if (fromDate != null) 'from_date': fromDate,
      if (toDate != null) 'to_date': toDate,
      if (status != null) 'status': status,
      if (totalDebit != null) 'total_debit': totalDebit,
      if (totalCredit != null) 'total_credit': totalCredit,
      if (qboJournalEntryId != null) 'qbo_journal_entry_id': qboJournalEntryId,
      if (requestJson != null) 'request_json': requestJson,
      if (responseJson != null) 'response_json': responseJson,
      if (errorMessage != null) 'error_message': errorMessage,
    });
  }

  SyncHistoryCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? ranAt,
    Value<String>? trigger,
    Value<String>? performedBy,
    Value<DateTime>? fromDate,
    Value<DateTime>? toDate,
    Value<String>? status,
    Value<double?>? totalDebit,
    Value<double?>? totalCredit,
    Value<String?>? qboJournalEntryId,
    Value<String?>? requestJson,
    Value<String?>? responseJson,
    Value<String?>? errorMessage,
  }) {
    return SyncHistoryCompanion(
      id: id ?? this.id,
      ranAt: ranAt ?? this.ranAt,
      trigger: trigger ?? this.trigger,
      performedBy: performedBy ?? this.performedBy,
      fromDate: fromDate ?? this.fromDate,
      toDate: toDate ?? this.toDate,
      status: status ?? this.status,
      totalDebit: totalDebit ?? this.totalDebit,
      totalCredit: totalCredit ?? this.totalCredit,
      qboJournalEntryId: qboJournalEntryId ?? this.qboJournalEntryId,
      requestJson: requestJson ?? this.requestJson,
      responseJson: responseJson ?? this.responseJson,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (ranAt.present) {
      map['ran_at'] = Variable<DateTime>(ranAt.value);
    }
    if (trigger.present) {
      map['trigger'] = Variable<String>(trigger.value);
    }
    if (performedBy.present) {
      map['performed_by'] = Variable<String>(performedBy.value);
    }
    if (fromDate.present) {
      map['from_date'] = Variable<DateTime>(fromDate.value);
    }
    if (toDate.present) {
      map['to_date'] = Variable<DateTime>(toDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalDebit.present) {
      map['total_debit'] = Variable<double>(totalDebit.value);
    }
    if (totalCredit.present) {
      map['total_credit'] = Variable<double>(totalCredit.value);
    }
    if (qboJournalEntryId.present) {
      map['qbo_journal_entry_id'] = Variable<String>(qboJournalEntryId.value);
    }
    if (requestJson.present) {
      map['request_json'] = Variable<String>(requestJson.value);
    }
    if (responseJson.present) {
      map['response_json'] = Variable<String>(responseJson.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncHistoryCompanion(')
          ..write('id: $id, ')
          ..write('ranAt: $ranAt, ')
          ..write('trigger: $trigger, ')
          ..write('performedBy: $performedBy, ')
          ..write('fromDate: $fromDate, ')
          ..write('toDate: $toDate, ')
          ..write('status: $status, ')
          ..write('totalDebit: $totalDebit, ')
          ..write('totalCredit: $totalCredit, ')
          ..write('qboJournalEntryId: $qboJournalEntryId, ')
          ..write('requestJson: $requestJson, ')
          ..write('responseJson: $responseJson, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, UserRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _passwordHashMeta = const VerificationMeta(
    'passwordHash',
  );
  @override
  late final GeneratedColumn<String> passwordHash = GeneratedColumn<String>(
    'password_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAdminMeta = const VerificationMeta(
    'isAdmin',
  );
  @override
  late final GeneratedColumn<bool> isAdmin = GeneratedColumn<bool>(
    'is_admin',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_admin" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _mustChangePasswordMeta =
      const VerificationMeta('mustChangePassword');
  @override
  late final GeneratedColumn<bool> mustChangePassword = GeneratedColumn<bool>(
    'must_change_password',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("must_change_password" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _failedAttemptsMeta = const VerificationMeta(
    'failedAttempts',
  );
  @override
  late final GeneratedColumn<int> failedAttempts = GeneratedColumn<int>(
    'failed_attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lockedUntilMeta = const VerificationMeta(
    'lockedUntil',
  );
  @override
  late final GeneratedColumn<DateTime> lockedUntil = GeneratedColumn<DateTime>(
    'locked_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastLoginAtMeta = const VerificationMeta(
    'lastLoginAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastLoginAt = GeneratedColumn<DateTime>(
    'last_login_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    username,
    passwordHash,
    displayName,
    isAdmin,
    isActive,
    mustChangePassword,
    failedAttempts,
    lockedUntil,
    createdAt,
    lastLoginAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('is_admin')) {
      context.handle(
        _isAdminMeta,
        isAdmin.isAcceptableOrUnknown(data['is_admin']!, _isAdminMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('must_change_password')) {
      context.handle(
        _mustChangePasswordMeta,
        mustChangePassword.isAcceptableOrUnknown(
          data['must_change_password']!,
          _mustChangePasswordMeta,
        ),
      );
    }
    if (data.containsKey('failed_attempts')) {
      context.handle(
        _failedAttemptsMeta,
        failedAttempts.isAcceptableOrUnknown(
          data['failed_attempts']!,
          _failedAttemptsMeta,
        ),
      );
    }
    if (data.containsKey('locked_until')) {
      context.handle(
        _lockedUntilMeta,
        lockedUntil.isAcceptableOrUnknown(
          data['locked_until']!,
          _lockedUntilMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('last_login_at')) {
      context.handle(
        _lastLoginAtMeta,
        lastLoginAt.isAcceptableOrUnknown(
          data['last_login_at']!,
          _lastLoginAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      isAdmin: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_admin'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      mustChangePassword: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}must_change_password'],
      )!,
      failedAttempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}failed_attempts'],
      )!,
      lockedUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}locked_until'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      lastLoginAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_login_at'],
      ),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class UserRow extends DataClass implements Insertable<UserRow> {
  final int id;
  final String username;
  final String passwordHash;
  final String displayName;
  final bool isAdmin;
  final bool isActive;
  final bool mustChangePassword;
  final int failedAttempts;
  final DateTime? lockedUntil;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  const UserRow({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.displayName,
    required this.isAdmin,
    required this.isActive,
    required this.mustChangePassword,
    required this.failedAttempts,
    this.lockedUntil,
    required this.createdAt,
    this.lastLoginAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['username'] = Variable<String>(username);
    map['password_hash'] = Variable<String>(passwordHash);
    map['display_name'] = Variable<String>(displayName);
    map['is_admin'] = Variable<bool>(isAdmin);
    map['is_active'] = Variable<bool>(isActive);
    map['must_change_password'] = Variable<bool>(mustChangePassword);
    map['failed_attempts'] = Variable<int>(failedAttempts);
    if (!nullToAbsent || lockedUntil != null) {
      map['locked_until'] = Variable<DateTime>(lockedUntil);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || lastLoginAt != null) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      username: Value(username),
      passwordHash: Value(passwordHash),
      displayName: Value(displayName),
      isAdmin: Value(isAdmin),
      isActive: Value(isActive),
      mustChangePassword: Value(mustChangePassword),
      failedAttempts: Value(failedAttempts),
      lockedUntil: lockedUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedUntil),
      createdAt: Value(createdAt),
      lastLoginAt: lastLoginAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastLoginAt),
    );
  }

  factory UserRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserRow(
      id: serializer.fromJson<int>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      passwordHash: serializer.fromJson<String>(json['passwordHash']),
      displayName: serializer.fromJson<String>(json['displayName']),
      isAdmin: serializer.fromJson<bool>(json['isAdmin']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      mustChangePassword: serializer.fromJson<bool>(json['mustChangePassword']),
      failedAttempts: serializer.fromJson<int>(json['failedAttempts']),
      lockedUntil: serializer.fromJson<DateTime?>(json['lockedUntil']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      lastLoginAt: serializer.fromJson<DateTime?>(json['lastLoginAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'username': serializer.toJson<String>(username),
      'passwordHash': serializer.toJson<String>(passwordHash),
      'displayName': serializer.toJson<String>(displayName),
      'isAdmin': serializer.toJson<bool>(isAdmin),
      'isActive': serializer.toJson<bool>(isActive),
      'mustChangePassword': serializer.toJson<bool>(mustChangePassword),
      'failedAttempts': serializer.toJson<int>(failedAttempts),
      'lockedUntil': serializer.toJson<DateTime?>(lockedUntil),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'lastLoginAt': serializer.toJson<DateTime?>(lastLoginAt),
    };
  }

  UserRow copyWith({
    int? id,
    String? username,
    String? passwordHash,
    String? displayName,
    bool? isAdmin,
    bool? isActive,
    bool? mustChangePassword,
    int? failedAttempts,
    Value<DateTime?> lockedUntil = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> lastLoginAt = const Value.absent(),
  }) => UserRow(
    id: id ?? this.id,
    username: username ?? this.username,
    passwordHash: passwordHash ?? this.passwordHash,
    displayName: displayName ?? this.displayName,
    isAdmin: isAdmin ?? this.isAdmin,
    isActive: isActive ?? this.isActive,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    failedAttempts: failedAttempts ?? this.failedAttempts,
    lockedUntil: lockedUntil.present ? lockedUntil.value : this.lockedUntil,
    createdAt: createdAt ?? this.createdAt,
    lastLoginAt: lastLoginAt.present ? lastLoginAt.value : this.lastLoginAt,
  );
  UserRow copyWithCompanion(UsersCompanion data) {
    return UserRow(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      passwordHash: data.passwordHash.present
          ? data.passwordHash.value
          : this.passwordHash,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      isAdmin: data.isAdmin.present ? data.isAdmin.value : this.isAdmin,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      mustChangePassword: data.mustChangePassword.present
          ? data.mustChangePassword.value
          : this.mustChangePassword,
      failedAttempts: data.failedAttempts.present
          ? data.failedAttempts.value
          : this.failedAttempts,
      lockedUntil: data.lockedUntil.present
          ? data.lockedUntil.value
          : this.lockedUntil,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      lastLoginAt: data.lastLoginAt.present
          ? data.lastLoginAt.value
          : this.lastLoginAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserRow(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('displayName: $displayName, ')
          ..write('isAdmin: $isAdmin, ')
          ..write('isActive: $isActive, ')
          ..write('mustChangePassword: $mustChangePassword, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLoginAt: $lastLoginAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    username,
    passwordHash,
    displayName,
    isAdmin,
    isActive,
    mustChangePassword,
    failedAttempts,
    lockedUntil,
    createdAt,
    lastLoginAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserRow &&
          other.id == this.id &&
          other.username == this.username &&
          other.passwordHash == this.passwordHash &&
          other.displayName == this.displayName &&
          other.isAdmin == this.isAdmin &&
          other.isActive == this.isActive &&
          other.mustChangePassword == this.mustChangePassword &&
          other.failedAttempts == this.failedAttempts &&
          other.lockedUntil == this.lockedUntil &&
          other.createdAt == this.createdAt &&
          other.lastLoginAt == this.lastLoginAt);
}

class UsersCompanion extends UpdateCompanion<UserRow> {
  final Value<int> id;
  final Value<String> username;
  final Value<String> passwordHash;
  final Value<String> displayName;
  final Value<bool> isAdmin;
  final Value<bool> isActive;
  final Value<bool> mustChangePassword;
  final Value<int> failedAttempts;
  final Value<DateTime?> lockedUntil;
  final Value<DateTime> createdAt;
  final Value<DateTime?> lastLoginAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.passwordHash = const Value.absent(),
    this.displayName = const Value.absent(),
    this.isAdmin = const Value.absent(),
    this.isActive = const Value.absent(),
    this.mustChangePassword = const Value.absent(),
    this.failedAttempts = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.lastLoginAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String username,
    required String passwordHash,
    required String displayName,
    this.isAdmin = const Value.absent(),
    this.isActive = const Value.absent(),
    this.mustChangePassword = const Value.absent(),
    this.failedAttempts = const Value.absent(),
    this.lockedUntil = const Value.absent(),
    required DateTime createdAt,
    this.lastLoginAt = const Value.absent(),
  }) : username = Value(username),
       passwordHash = Value(passwordHash),
       displayName = Value(displayName),
       createdAt = Value(createdAt);
  static Insertable<UserRow> custom({
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? passwordHash,
    Expression<String>? displayName,
    Expression<bool>? isAdmin,
    Expression<bool>? isActive,
    Expression<bool>? mustChangePassword,
    Expression<int>? failedAttempts,
    Expression<DateTime>? lockedUntil,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? lastLoginAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (displayName != null) 'display_name': displayName,
      if (isAdmin != null) 'is_admin': isAdmin,
      if (isActive != null) 'is_active': isActive,
      if (mustChangePassword != null)
        'must_change_password': mustChangePassword,
      if (failedAttempts != null) 'failed_attempts': failedAttempts,
      if (lockedUntil != null) 'locked_until': lockedUntil,
      if (createdAt != null) 'created_at': createdAt,
      if (lastLoginAt != null) 'last_login_at': lastLoginAt,
    });
  }

  UsersCompanion copyWith({
    Value<int>? id,
    Value<String>? username,
    Value<String>? passwordHash,
    Value<String>? displayName,
    Value<bool>? isAdmin,
    Value<bool>? isActive,
    Value<bool>? mustChangePassword,
    Value<int>? failedAttempts,
    Value<DateTime?>? lockedUntil,
    Value<DateTime>? createdAt,
    Value<DateTime?>? lastLoginAt,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      displayName: displayName ?? this.displayName,
      isAdmin: isAdmin ?? this.isAdmin,
      isActive: isActive ?? this.isActive,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockedUntil: lockedUntil ?? this.lockedUntil,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = Variable<String>(passwordHash.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (isAdmin.present) {
      map['is_admin'] = Variable<bool>(isAdmin.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (mustChangePassword.present) {
      map['must_change_password'] = Variable<bool>(mustChangePassword.value);
    }
    if (failedAttempts.present) {
      map['failed_attempts'] = Variable<int>(failedAttempts.value);
    }
    if (lockedUntil.present) {
      map['locked_until'] = Variable<DateTime>(lockedUntil.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (lastLoginAt.present) {
      map['last_login_at'] = Variable<DateTime>(lastLoginAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('displayName: $displayName, ')
          ..write('isAdmin: $isAdmin, ')
          ..write('isActive: $isActive, ')
          ..write('mustChangePassword: $mustChangePassword, ')
          ..write('failedAttempts: $failedAttempts, ')
          ..write('lockedUntil: $lockedUntil, ')
          ..write('createdAt: $createdAt, ')
          ..write('lastLoginAt: $lastLoginAt')
          ..write(')'))
        .toString();
  }
}

class $AuditLogTable extends AuditLog
    with TableInfo<$AuditLogTable, AuditLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuditLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _detailsMeta = const VerificationMeta(
    'details',
  );
  @override
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    timestamp,
    username,
    action,
    details,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'audit_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuditLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('details')) {
      context.handle(
        _detailsMeta,
        details.isAcceptableOrUnknown(data['details']!, _detailsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuditLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuditLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      details: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details'],
      ),
    );
  }

  @override
  $AuditLogTable createAlias(String alias) {
    return $AuditLogTable(attachedDatabase, alias);
  }
}

class AuditLogRow extends DataClass implements Insertable<AuditLogRow> {
  final int id;
  final DateTime timestamp;
  final String username;
  final String action;
  final String? details;
  const AuditLogRow({
    required this.id,
    required this.timestamp,
    required this.username,
    required this.action,
    this.details,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['username'] = Variable<String>(username);
    map['action'] = Variable<String>(action);
    if (!nullToAbsent || details != null) {
      map['details'] = Variable<String>(details);
    }
    return map;
  }

  AuditLogCompanion toCompanion(bool nullToAbsent) {
    return AuditLogCompanion(
      id: Value(id),
      timestamp: Value(timestamp),
      username: Value(username),
      action: Value(action),
      details: details == null && nullToAbsent
          ? const Value.absent()
          : Value(details),
    );
  }

  factory AuditLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuditLogRow(
      id: serializer.fromJson<int>(json['id']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      username: serializer.fromJson<String>(json['username']),
      action: serializer.fromJson<String>(json['action']),
      details: serializer.fromJson<String?>(json['details']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'username': serializer.toJson<String>(username),
      'action': serializer.toJson<String>(action),
      'details': serializer.toJson<String?>(details),
    };
  }

  AuditLogRow copyWith({
    int? id,
    DateTime? timestamp,
    String? username,
    String? action,
    Value<String?> details = const Value.absent(),
  }) => AuditLogRow(
    id: id ?? this.id,
    timestamp: timestamp ?? this.timestamp,
    username: username ?? this.username,
    action: action ?? this.action,
    details: details.present ? details.value : this.details,
  );
  AuditLogRow copyWithCompanion(AuditLogCompanion data) {
    return AuditLogRow(
      id: data.id.present ? data.id.value : this.id,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      username: data.username.present ? data.username.value : this.username,
      action: data.action.present ? data.action.value : this.action,
      details: data.details.present ? data.details.value : this.details,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogRow(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('username: $username, ')
          ..write('action: $action, ')
          ..write('details: $details')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, timestamp, username, action, details);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuditLogRow &&
          other.id == this.id &&
          other.timestamp == this.timestamp &&
          other.username == this.username &&
          other.action == this.action &&
          other.details == this.details);
}

class AuditLogCompanion extends UpdateCompanion<AuditLogRow> {
  final Value<int> id;
  final Value<DateTime> timestamp;
  final Value<String> username;
  final Value<String> action;
  final Value<String?> details;
  const AuditLogCompanion({
    this.id = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.username = const Value.absent(),
    this.action = const Value.absent(),
    this.details = const Value.absent(),
  });
  AuditLogCompanion.insert({
    this.id = const Value.absent(),
    required DateTime timestamp,
    required String username,
    required String action,
    this.details = const Value.absent(),
  }) : timestamp = Value(timestamp),
       username = Value(username),
       action = Value(action);
  static Insertable<AuditLogRow> custom({
    Expression<int>? id,
    Expression<DateTime>? timestamp,
    Expression<String>? username,
    Expression<String>? action,
    Expression<String>? details,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (timestamp != null) 'timestamp': timestamp,
      if (username != null) 'username': username,
      if (action != null) 'action': action,
      if (details != null) 'details': details,
    });
  }

  AuditLogCompanion copyWith({
    Value<int>? id,
    Value<DateTime>? timestamp,
    Value<String>? username,
    Value<String>? action,
    Value<String?>? details,
  }) {
    return AuditLogCompanion(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      username: username ?? this.username,
      action: action ?? this.action,
      details: details ?? this.details,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuditLogCompanion(')
          ..write('id: $id, ')
          ..write('timestamp: $timestamp, ')
          ..write('username: $username, ')
          ..write('action: $action, ')
          ..write('details: $details')
          ..write(')'))
        .toString();
  }
}

class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String value;
  const AppSettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSettingRow copyWith({String? key, String? value}) =>
      AppSettingRow(key: key ?? this.key, value: value ?? this.value);
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $OAuthConnectionsTable oAuthConnections = $OAuthConnectionsTable(
    this,
  );
  late final $AccountMappingsTable accountMappings = $AccountMappingsTable(
    this,
  );
  late final $SyncSchedulesTable syncSchedules = $SyncSchedulesTable(this);
  late final $SyncHistoryTable syncHistory = $SyncHistoryTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final $AuditLogTable auditLog = $AuditLogTable(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    oAuthConnections,
    accountMappings,
    syncSchedules,
    syncHistory,
    users,
    auditLog,
    appSettings,
  ];
}

typedef $$OAuthConnectionsTableCreateCompanionBuilder =
    OAuthConnectionsCompanion Function({
      Value<int> id,
      Value<String> edition,
      Value<String> environment,
      required String realmId,
      Value<String?> companyName,
      Value<DateTime?> accessTokenExpiresAt,
      Value<DateTime?> refreshTokenExpiresAt,
      required DateTime connectedAt,
      Value<DateTime?> lastRefreshAt,
      Value<DateTime?> lastSyncAt,
    });
typedef $$OAuthConnectionsTableUpdateCompanionBuilder =
    OAuthConnectionsCompanion Function({
      Value<int> id,
      Value<String> edition,
      Value<String> environment,
      Value<String> realmId,
      Value<String?> companyName,
      Value<DateTime?> accessTokenExpiresAt,
      Value<DateTime?> refreshTokenExpiresAt,
      Value<DateTime> connectedAt,
      Value<DateTime?> lastRefreshAt,
      Value<DateTime?> lastSyncAt,
    });

class $$OAuthConnectionsTableFilterComposer
    extends Composer<_$AppDatabase, $OAuthConnectionsTable> {
  $$OAuthConnectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get edition => $composableBuilder(
    column: $table.edition,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get environment => $composableBuilder(
    column: $table.environment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get realmId => $composableBuilder(
    column: $table.realmId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get accessTokenExpiresAt => $composableBuilder(
    column: $table.accessTokenExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get refreshTokenExpiresAt => $composableBuilder(
    column: $table.refreshTokenExpiresAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get connectedAt => $composableBuilder(
    column: $table.connectedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastRefreshAt => $composableBuilder(
    column: $table.lastRefreshAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$OAuthConnectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $OAuthConnectionsTable> {
  $$OAuthConnectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get edition => $composableBuilder(
    column: $table.edition,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get environment => $composableBuilder(
    column: $table.environment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get realmId => $composableBuilder(
    column: $table.realmId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get accessTokenExpiresAt => $composableBuilder(
    column: $table.accessTokenExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get refreshTokenExpiresAt => $composableBuilder(
    column: $table.refreshTokenExpiresAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get connectedAt => $composableBuilder(
    column: $table.connectedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRefreshAt => $composableBuilder(
    column: $table.lastRefreshAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$OAuthConnectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $OAuthConnectionsTable> {
  $$OAuthConnectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get edition =>
      $composableBuilder(column: $table.edition, builder: (column) => column);

  GeneratedColumn<String> get environment => $composableBuilder(
    column: $table.environment,
    builder: (column) => column,
  );

  GeneratedColumn<String> get realmId =>
      $composableBuilder(column: $table.realmId, builder: (column) => column);

  GeneratedColumn<String> get companyName => $composableBuilder(
    column: $table.companyName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get accessTokenExpiresAt => $composableBuilder(
    column: $table.accessTokenExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get refreshTokenExpiresAt => $composableBuilder(
    column: $table.refreshTokenExpiresAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get connectedAt => $composableBuilder(
    column: $table.connectedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastRefreshAt => $composableBuilder(
    column: $table.lastRefreshAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );
}

class $$OAuthConnectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OAuthConnectionsTable,
          OAuthConnectionRow,
          $$OAuthConnectionsTableFilterComposer,
          $$OAuthConnectionsTableOrderingComposer,
          $$OAuthConnectionsTableAnnotationComposer,
          $$OAuthConnectionsTableCreateCompanionBuilder,
          $$OAuthConnectionsTableUpdateCompanionBuilder,
          (
            OAuthConnectionRow,
            BaseReferences<
              _$AppDatabase,
              $OAuthConnectionsTable,
              OAuthConnectionRow
            >,
          ),
          OAuthConnectionRow,
          PrefetchHooks Function()
        > {
  $$OAuthConnectionsTableTableManager(
    _$AppDatabase db,
    $OAuthConnectionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$OAuthConnectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$OAuthConnectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$OAuthConnectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> edition = const Value.absent(),
                Value<String> environment = const Value.absent(),
                Value<String> realmId = const Value.absent(),
                Value<String?> companyName = const Value.absent(),
                Value<DateTime?> accessTokenExpiresAt = const Value.absent(),
                Value<DateTime?> refreshTokenExpiresAt = const Value.absent(),
                Value<DateTime> connectedAt = const Value.absent(),
                Value<DateTime?> lastRefreshAt = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
              }) => OAuthConnectionsCompanion(
                id: id,
                edition: edition,
                environment: environment,
                realmId: realmId,
                companyName: companyName,
                accessTokenExpiresAt: accessTokenExpiresAt,
                refreshTokenExpiresAt: refreshTokenExpiresAt,
                connectedAt: connectedAt,
                lastRefreshAt: lastRefreshAt,
                lastSyncAt: lastSyncAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> edition = const Value.absent(),
                Value<String> environment = const Value.absent(),
                required String realmId,
                Value<String?> companyName = const Value.absent(),
                Value<DateTime?> accessTokenExpiresAt = const Value.absent(),
                Value<DateTime?> refreshTokenExpiresAt = const Value.absent(),
                required DateTime connectedAt,
                Value<DateTime?> lastRefreshAt = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
              }) => OAuthConnectionsCompanion.insert(
                id: id,
                edition: edition,
                environment: environment,
                realmId: realmId,
                companyName: companyName,
                accessTokenExpiresAt: accessTokenExpiresAt,
                refreshTokenExpiresAt: refreshTokenExpiresAt,
                connectedAt: connectedAt,
                lastRefreshAt: lastRefreshAt,
                lastSyncAt: lastSyncAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$OAuthConnectionsTable, OAuthConnectionRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $OAuthConnectionsTable,
                    OAuthConnectionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$OAuthConnectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OAuthConnectionsTable,
      OAuthConnectionRow,
      $$OAuthConnectionsTableFilterComposer,
      $$OAuthConnectionsTableOrderingComposer,
      $$OAuthConnectionsTableAnnotationComposer,
      $$OAuthConnectionsTableCreateCompanionBuilder,
      $$OAuthConnectionsTableUpdateCompanionBuilder,
      (
        OAuthConnectionRow,
        BaseReferences<
          _$AppDatabase,
          $OAuthConnectionsTable,
          OAuthConnectionRow
        >,
      ),
      OAuthConnectionRow,
      PrefetchHooks Function()
    >;
typedef $$AccountMappingsTableCreateCompanionBuilder =
    AccountMappingsCompanion Function({
      Value<int> id,
      required String category,
      required String accountId,
      required String accountName,
      required String side,
      Value<String?> description,
      Value<String?> entityType,
      Value<String?> entityId,
      Value<String?> entityDisplayName,
      required DateTime updatedAt,
    });
typedef $$AccountMappingsTableUpdateCompanionBuilder =
    AccountMappingsCompanion Function({
      Value<int> id,
      Value<String> category,
      Value<String> accountId,
      Value<String> accountName,
      Value<String> side,
      Value<String?> description,
      Value<String?> entityType,
      Value<String?> entityId,
      Value<String?> entityDisplayName,
      Value<DateTime> updatedAt,
    });

class $$AccountMappingsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountMappingsTable> {
  $$AccountMappingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get side => $composableBuilder(
    column: $table.side,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityDisplayName => $composableBuilder(
    column: $table.entityDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AccountMappingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountMappingsTable> {
  $$AccountMappingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get side => $composableBuilder(
    column: $table.side,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityDisplayName => $composableBuilder(
    column: $table.entityDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AccountMappingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountMappingsTable> {
  $$AccountMappingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get accountName => $composableBuilder(
    column: $table.accountName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get side =>
      $composableBuilder(column: $table.side, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get entityDisplayName => $composableBuilder(
    column: $table.entityDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AccountMappingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountMappingsTable,
          AccountMappingRow,
          $$AccountMappingsTableFilterComposer,
          $$AccountMappingsTableOrderingComposer,
          $$AccountMappingsTableAnnotationComposer,
          $$AccountMappingsTableCreateCompanionBuilder,
          $$AccountMappingsTableUpdateCompanionBuilder,
          (
            AccountMappingRow,
            BaseReferences<
              _$AppDatabase,
              $AccountMappingsTable,
              AccountMappingRow
            >,
          ),
          AccountMappingRow,
          PrefetchHooks Function()
        > {
  $$AccountMappingsTableTableManager(
    _$AppDatabase db,
    $AccountMappingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountMappingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountMappingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountMappingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> accountName = const Value.absent(),
                Value<String> side = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> entityType = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<String?> entityDisplayName = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
              }) => AccountMappingsCompanion(
                id: id,
                category: category,
                accountId: accountId,
                accountName: accountName,
                side: side,
                description: description,
                entityType: entityType,
                entityId: entityId,
                entityDisplayName: entityDisplayName,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String category,
                required String accountId,
                required String accountName,
                required String side,
                Value<String?> description = const Value.absent(),
                Value<String?> entityType = const Value.absent(),
                Value<String?> entityId = const Value.absent(),
                Value<String?> entityDisplayName = const Value.absent(),
                required DateTime updatedAt,
              }) => AccountMappingsCompanion.insert(
                id: id,
                category: category,
                accountId: accountId,
                accountName: accountName,
                side: side,
                description: description,
                entityType: entityType,
                entityId: entityId,
                entityDisplayName: entityDisplayName,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountMappingsTable, AccountMappingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AccountMappingsTable,
                    AccountMappingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AccountMappingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountMappingsTable,
      AccountMappingRow,
      $$AccountMappingsTableFilterComposer,
      $$AccountMappingsTableOrderingComposer,
      $$AccountMappingsTableAnnotationComposer,
      $$AccountMappingsTableCreateCompanionBuilder,
      $$AccountMappingsTableUpdateCompanionBuilder,
      (
        AccountMappingRow,
        BaseReferences<_$AppDatabase, $AccountMappingsTable, AccountMappingRow>,
      ),
      AccountMappingRow,
      PrefetchHooks Function()
    >;
typedef $$SyncSchedulesTableCreateCompanionBuilder =
    SyncSchedulesCompanion Function({
      Value<int> id,
      Value<bool> enabled,
      required String frequency,
      required String timeOfDay,
      Value<int?> dayOfWeek,
      Value<int?> dayOfMonth,
      Value<DateTime?> lastRunAt,
      Value<DateTime?> nextRunAt,
    });
typedef $$SyncSchedulesTableUpdateCompanionBuilder =
    SyncSchedulesCompanion Function({
      Value<int> id,
      Value<bool> enabled,
      Value<String> frequency,
      Value<String> timeOfDay,
      Value<int?> dayOfWeek,
      Value<int?> dayOfMonth,
      Value<DateTime?> lastRunAt,
      Value<DateTime?> nextRunAt,
    });

class $$SyncSchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncSchedulesTable> {
  $$SyncSchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeOfDay => $composableBuilder(
    column: $table.timeOfDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastRunAt => $composableBuilder(
    column: $table.lastRunAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRunAt => $composableBuilder(
    column: $table.nextRunAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncSchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncSchedulesTable> {
  $$SyncSchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeOfDay => $composableBuilder(
    column: $table.timeOfDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfWeek => $composableBuilder(
    column: $table.dayOfWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastRunAt => $composableBuilder(
    column: $table.lastRunAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRunAt => $composableBuilder(
    column: $table.nextRunAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncSchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncSchedulesTable> {
  $$SyncSchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<String> get timeOfDay =>
      $composableBuilder(column: $table.timeOfDay, builder: (column) => column);

  GeneratedColumn<int> get dayOfWeek =>
      $composableBuilder(column: $table.dayOfWeek, builder: (column) => column);

  GeneratedColumn<int> get dayOfMonth => $composableBuilder(
    column: $table.dayOfMonth,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastRunAt =>
      $composableBuilder(column: $table.lastRunAt, builder: (column) => column);

  GeneratedColumn<DateTime> get nextRunAt =>
      $composableBuilder(column: $table.nextRunAt, builder: (column) => column);
}

class $$SyncSchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncSchedulesTable,
          SyncScheduleRow,
          $$SyncSchedulesTableFilterComposer,
          $$SyncSchedulesTableOrderingComposer,
          $$SyncSchedulesTableAnnotationComposer,
          $$SyncSchedulesTableCreateCompanionBuilder,
          $$SyncSchedulesTableUpdateCompanionBuilder,
          (
            SyncScheduleRow,
            BaseReferences<_$AppDatabase, $SyncSchedulesTable, SyncScheduleRow>,
          ),
          SyncScheduleRow,
          PrefetchHooks Function()
        > {
  $$SyncSchedulesTableTableManager(_$AppDatabase db, $SyncSchedulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncSchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncSchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncSchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<String> timeOfDay = const Value.absent(),
                Value<int?> dayOfWeek = const Value.absent(),
                Value<int?> dayOfMonth = const Value.absent(),
                Value<DateTime?> lastRunAt = const Value.absent(),
                Value<DateTime?> nextRunAt = const Value.absent(),
              }) => SyncSchedulesCompanion(
                id: id,
                enabled: enabled,
                frequency: frequency,
                timeOfDay: timeOfDay,
                dayOfWeek: dayOfWeek,
                dayOfMonth: dayOfMonth,
                lastRunAt: lastRunAt,
                nextRunAt: nextRunAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                required String frequency,
                required String timeOfDay,
                Value<int?> dayOfWeek = const Value.absent(),
                Value<int?> dayOfMonth = const Value.absent(),
                Value<DateTime?> lastRunAt = const Value.absent(),
                Value<DateTime?> nextRunAt = const Value.absent(),
              }) => SyncSchedulesCompanion.insert(
                id: id,
                enabled: enabled,
                frequency: frequency,
                timeOfDay: timeOfDay,
                dayOfWeek: dayOfWeek,
                dayOfMonth: dayOfMonth,
                lastRunAt: lastRunAt,
                nextRunAt: nextRunAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncSchedulesTable, SyncScheduleRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncSchedulesTable,
                    SyncScheduleRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncSchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncSchedulesTable,
      SyncScheduleRow,
      $$SyncSchedulesTableFilterComposer,
      $$SyncSchedulesTableOrderingComposer,
      $$SyncSchedulesTableAnnotationComposer,
      $$SyncSchedulesTableCreateCompanionBuilder,
      $$SyncSchedulesTableUpdateCompanionBuilder,
      (
        SyncScheduleRow,
        BaseReferences<_$AppDatabase, $SyncSchedulesTable, SyncScheduleRow>,
      ),
      SyncScheduleRow,
      PrefetchHooks Function()
    >;
typedef $$SyncHistoryTableCreateCompanionBuilder =
    SyncHistoryCompanion Function({
      Value<int> id,
      required DateTime ranAt,
      required String trigger,
      required String performedBy,
      required DateTime fromDate,
      required DateTime toDate,
      required String status,
      Value<double?> totalDebit,
      Value<double?> totalCredit,
      Value<String?> qboJournalEntryId,
      Value<String?> requestJson,
      Value<String?> responseJson,
      Value<String?> errorMessage,
    });
typedef $$SyncHistoryTableUpdateCompanionBuilder =
    SyncHistoryCompanion Function({
      Value<int> id,
      Value<DateTime> ranAt,
      Value<String> trigger,
      Value<String> performedBy,
      Value<DateTime> fromDate,
      Value<DateTime> toDate,
      Value<String> status,
      Value<double?> totalDebit,
      Value<double?> totalCredit,
      Value<String?> qboJournalEntryId,
      Value<String?> requestJson,
      Value<String?> responseJson,
      Value<String?> errorMessage,
    });

class $$SyncHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $SyncHistoryTable> {
  $$SyncHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get ranAt => $composableBuilder(
    column: $table.ranAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get performedBy => $composableBuilder(
    column: $table.performedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get fromDate => $composableBuilder(
    column: $table.fromDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get toDate => $composableBuilder(
    column: $table.toDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalDebit => $composableBuilder(
    column: $table.totalDebit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get totalCredit => $composableBuilder(
    column: $table.totalCredit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qboJournalEntryId => $composableBuilder(
    column: $table.qboJournalEntryId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get requestJson => $composableBuilder(
    column: $table.requestJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncHistoryTable> {
  $$SyncHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get ranAt => $composableBuilder(
    column: $table.ranAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trigger => $composableBuilder(
    column: $table.trigger,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get performedBy => $composableBuilder(
    column: $table.performedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get fromDate => $composableBuilder(
    column: $table.fromDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get toDate => $composableBuilder(
    column: $table.toDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalDebit => $composableBuilder(
    column: $table.totalDebit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalCredit => $composableBuilder(
    column: $table.totalCredit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qboJournalEntryId => $composableBuilder(
    column: $table.qboJournalEntryId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get requestJson => $composableBuilder(
    column: $table.requestJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncHistoryTable> {
  $$SyncHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get ranAt =>
      $composableBuilder(column: $table.ranAt, builder: (column) => column);

  GeneratedColumn<String> get trigger =>
      $composableBuilder(column: $table.trigger, builder: (column) => column);

  GeneratedColumn<String> get performedBy => $composableBuilder(
    column: $table.performedBy,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get fromDate =>
      $composableBuilder(column: $table.fromDate, builder: (column) => column);

  GeneratedColumn<DateTime> get toDate =>
      $composableBuilder(column: $table.toDate, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get totalDebit => $composableBuilder(
    column: $table.totalDebit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get totalCredit => $composableBuilder(
    column: $table.totalCredit,
    builder: (column) => column,
  );

  GeneratedColumn<String> get qboJournalEntryId => $composableBuilder(
    column: $table.qboJournalEntryId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get requestJson => $composableBuilder(
    column: $table.requestJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$SyncHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncHistoryTable,
          SyncHistoryRow,
          $$SyncHistoryTableFilterComposer,
          $$SyncHistoryTableOrderingComposer,
          $$SyncHistoryTableAnnotationComposer,
          $$SyncHistoryTableCreateCompanionBuilder,
          $$SyncHistoryTableUpdateCompanionBuilder,
          (
            SyncHistoryRow,
            BaseReferences<_$AppDatabase, $SyncHistoryTable, SyncHistoryRow>,
          ),
          SyncHistoryRow,
          PrefetchHooks Function()
        > {
  $$SyncHistoryTableTableManager(_$AppDatabase db, $SyncHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> ranAt = const Value.absent(),
                Value<String> trigger = const Value.absent(),
                Value<String> performedBy = const Value.absent(),
                Value<DateTime> fromDate = const Value.absent(),
                Value<DateTime> toDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double?> totalDebit = const Value.absent(),
                Value<double?> totalCredit = const Value.absent(),
                Value<String?> qboJournalEntryId = const Value.absent(),
                Value<String?> requestJson = const Value.absent(),
                Value<String?> responseJson = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
              }) => SyncHistoryCompanion(
                id: id,
                ranAt: ranAt,
                trigger: trigger,
                performedBy: performedBy,
                fromDate: fromDate,
                toDate: toDate,
                status: status,
                totalDebit: totalDebit,
                totalCredit: totalCredit,
                qboJournalEntryId: qboJournalEntryId,
                requestJson: requestJson,
                responseJson: responseJson,
                errorMessage: errorMessage,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime ranAt,
                required String trigger,
                required String performedBy,
                required DateTime fromDate,
                required DateTime toDate,
                required String status,
                Value<double?> totalDebit = const Value.absent(),
                Value<double?> totalCredit = const Value.absent(),
                Value<String?> qboJournalEntryId = const Value.absent(),
                Value<String?> requestJson = const Value.absent(),
                Value<String?> responseJson = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
              }) => SyncHistoryCompanion.insert(
                id: id,
                ranAt: ranAt,
                trigger: trigger,
                performedBy: performedBy,
                fromDate: fromDate,
                toDate: toDate,
                status: status,
                totalDebit: totalDebit,
                totalCredit: totalCredit,
                qboJournalEntryId: qboJournalEntryId,
                requestJson: requestJson,
                responseJson: responseJson,
                errorMessage: errorMessage,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncHistoryTable, SyncHistoryRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncHistoryTable,
                    SyncHistoryRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncHistoryTable,
      SyncHistoryRow,
      $$SyncHistoryTableFilterComposer,
      $$SyncHistoryTableOrderingComposer,
      $$SyncHistoryTableAnnotationComposer,
      $$SyncHistoryTableCreateCompanionBuilder,
      $$SyncHistoryTableUpdateCompanionBuilder,
      (
        SyncHistoryRow,
        BaseReferences<_$AppDatabase, $SyncHistoryTable, SyncHistoryRow>,
      ),
      SyncHistoryRow,
      PrefetchHooks Function()
    >;
typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  required String username,
  required String passwordHash,
  required String displayName,
  Value<bool> isAdmin,
  Value<bool> isActive,
  Value<bool> mustChangePassword,
  Value<int> failedAttempts,
  Value<DateTime?> lockedUntil,
  required DateTime createdAt,
  Value<DateTime?> lastLoginAt,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  Value<String> username,
  Value<String> passwordHash,
  Value<String> displayName,
  Value<bool> isAdmin,
  Value<bool> isActive,
  Value<bool> mustChangePassword,
  Value<int> failedAttempts,
  Value<DateTime?> lockedUntil,
  Value<DateTime> createdAt,
  Value<DateTime?> lastLoginAt,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAdmin => $composableBuilder(
    column: $table.isAdmin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get mustChangePassword => $composableBuilder(
    column: $table.mustChangePassword,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAdmin => $composableBuilder(
    column: $table.isAdmin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get mustChangePassword => $composableBuilder(
    column: $table.mustChangePassword,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isAdmin =>
      $composableBuilder(column: $table.isAdmin, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get mustChangePassword => $composableBuilder(
    column: $table.mustChangePassword,
    builder: (column) => column,
  );

  GeneratedColumn<int> get failedAttempts => $composableBuilder(
    column: $table.failedAttempts,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lockedUntil => $composableBuilder(
    column: $table.lockedUntil,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastLoginAt => $composableBuilder(
    column: $table.lastLoginAt,
    builder: (column) => column,
  );
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $UsersTable,
          UserRow,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (UserRow, BaseReferences<_$AppDatabase, $UsersTable, UserRow>),
          UserRow,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> passwordHash = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<bool> isAdmin = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> mustChangePassword = const Value.absent(),
                Value<int> failedAttempts = const Value.absent(),
                Value<DateTime?> lockedUntil = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> lastLoginAt = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                username: username,
                passwordHash: passwordHash,
                displayName: displayName,
                isAdmin: isAdmin,
                isActive: isActive,
                mustChangePassword: mustChangePassword,
                failedAttempts: failedAttempts,
                lockedUntil: lockedUntil,
                createdAt: createdAt,
                lastLoginAt: lastLoginAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String username,
                required String passwordHash,
                required String displayName,
                Value<bool> isAdmin = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> mustChangePassword = const Value.absent(),
                Value<int> failedAttempts = const Value.absent(),
                Value<DateTime?> lockedUntil = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> lastLoginAt = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                username: username,
                passwordHash: passwordHash,
                displayName: displayName,
                isAdmin: isAdmin,
                isActive: isActive,
                mustChangePassword: mustChangePassword,
                failedAttempts: failedAttempts,
                lockedUntil: lockedUntil,
                createdAt: createdAt,
                lastLoginAt: lastLoginAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$UsersTable, UserRow>(table),
                  BaseReferences<_$AppDatabase, $UsersTable, UserRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $UsersTable,
      UserRow,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (UserRow, BaseReferences<_$AppDatabase, $UsersTable, UserRow>),
      UserRow,
      PrefetchHooks Function()
    >;
typedef $$AuditLogTableCreateCompanionBuilder = AuditLogCompanion Function({
  Value<int> id,
  required DateTime timestamp,
  required String username,
  required String action,
  Value<String?> details,
});
typedef $$AuditLogTableUpdateCompanionBuilder = AuditLogCompanion Function({
  Value<int> id,
  Value<DateTime> timestamp,
  Value<String> username,
  Value<String> action,
  Value<String?> details,
});

class $$AuditLogTableFilterComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuditLogTableOrderingComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuditLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuditLogTable> {
  $$AuditLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);
}

class $$AuditLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuditLogTable,
          AuditLogRow,
          $$AuditLogTableFilterComposer,
          $$AuditLogTableOrderingComposer,
          $$AuditLogTableAnnotationComposer,
          $$AuditLogTableCreateCompanionBuilder,
          $$AuditLogTableUpdateCompanionBuilder,
          (
            AuditLogRow,
            BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogRow>,
          ),
          AuditLogRow,
          PrefetchHooks Function()
        > {
  $$AuditLogTableTableManager(_$AppDatabase db, $AuditLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuditLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuditLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuditLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String?> details = const Value.absent(),
              }) => AuditLogCompanion(
                id: id,
                timestamp: timestamp,
                username: username,
                action: action,
                details: details,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required DateTime timestamp,
                required String username,
                required String action,
                Value<String?> details = const Value.absent(),
              }) => AuditLogCompanion.insert(
                id: id,
                timestamp: timestamp,
                username: username,
                action: action,
                details: details,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AuditLogTable, AuditLogRow>(table),
                  BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuditLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuditLogTable,
      AuditLogRow,
      $$AuditLogTableFilterComposer,
      $$AuditLogTableOrderingComposer,
      $$AuditLogTableAnnotationComposer,
      $$AuditLogTableCreateCompanionBuilder,
      $$AuditLogTableUpdateCompanionBuilder,
      (AuditLogRow, BaseReferences<_$AppDatabase, $AuditLogTable, AuditLogRow>),
      AuditLogRow,
      PrefetchHooks Function()
    >;
typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSettingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppSettingsTable,
                    AppSettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$OAuthConnectionsTableTableManager get oAuthConnections =>
      $$OAuthConnectionsTableTableManager(_db, _db.oAuthConnections);
  $$AccountMappingsTableTableManager get accountMappings =>
      $$AccountMappingsTableTableManager(_db, _db.accountMappings);
  $$SyncSchedulesTableTableManager get syncSchedules =>
      $$SyncSchedulesTableTableManager(_db, _db.syncSchedules);
  $$SyncHistoryTableTableManager get syncHistory =>
      $$SyncHistoryTableTableManager(_db, _db.syncHistory);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$AuditLogTableTableManager get auditLog =>
      $$AuditLogTableTableManager(_db, _db.auditLog);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
}
