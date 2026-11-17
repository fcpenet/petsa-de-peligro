// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $InstitutionsTable extends Institutions
    with TableInfo<$InstitutionsTable, Institution> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InstitutionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
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
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    name,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'institutions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Institution> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Institution map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Institution(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $InstitutionsTable createAlias(String alias) {
    return $InstitutionsTable(attachedDatabase, alias);
  }
}

class Institution extends DataClass implements Insertable<Institution> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String name;
  final int sortOrder;
  const Institution({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  InstitutionsCompanion toCompanion(bool nullToAbsent) {
    return InstitutionsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      sortOrder: Value(sortOrder),
    );
  }

  factory Institution.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Institution(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Institution copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    int? sortOrder,
  }) => Institution(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Institution copyWithCompanion(InstitutionsCompanion data) {
    return Institution(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Institution(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, deletedAt, name, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Institution &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.sortOrder == this.sortOrder);
}

class InstitutionsCompanion extends UpdateCompanion<Institution> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const InstitutionsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InstitutionsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String name,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<Institution> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InstitutionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return InstitutionsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InstitutionsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AccountsTable extends Accounts with TableInfo<$AccountsTable, Account> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
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
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _institutionIdMeta = const VerificationMeta(
    'institutionId',
  );
  @override
  late final GeneratedColumn<String> institutionId = GeneratedColumn<String>(
    'institution_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES institutions (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<AccountType, String> type =
      GeneratedColumn<String>(
        'type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<AccountType>($AccountsTable.$convertertype);
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    institutionId,
    name,
    type,
    sortOrder,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Account> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('institution_id')) {
      context.handle(
        _institutionIdMeta,
        institutionId.isAcceptableOrUnknown(
          data['institution_id']!,
          _institutionIdMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Account map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Account(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      institutionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}institution_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: $AccountsTable.$convertertype.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}type'],
        )!,
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<AccountType, String, String> $convertertype =
      const EnumNameConverter<AccountType>(AccountType.values);
}

class Account extends DataClass implements Insertable<Account> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String? institutionId;
  final String name;
  final AccountType type;
  final int sortOrder;
  final bool archived;
  const Account({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    this.institutionId,
    required this.name,
    required this.type,
    required this.sortOrder,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || institutionId != null) {
      map['institution_id'] = Variable<String>(institutionId);
    }
    map['name'] = Variable<String>(name);
    {
      map['type'] = Variable<String>($AccountsTable.$convertertype.toSql(type));
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      institutionId: institutionId == null && nullToAbsent
          ? const Value.absent()
          : Value(institutionId),
      name: Value(name),
      type: Value(type),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
    );
  }

  factory Account.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Account(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      institutionId: serializer.fromJson<String?>(json['institutionId']),
      name: serializer.fromJson<String>(json['name']),
      type: $AccountsTable.$convertertype.fromJson(
        serializer.fromJson<String>(json['type']),
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'institutionId': serializer.toJson<String?>(institutionId),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(
        $AccountsTable.$convertertype.toJson(type),
      ),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  Account copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> institutionId = const Value.absent(),
    String? name,
    AccountType? type,
    int? sortOrder,
    bool? archived,
  }) => Account(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    institutionId: institutionId.present
        ? institutionId.value
        : this.institutionId,
    name: name ?? this.name,
    type: type ?? this.type,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
  );
  Account copyWithCompanion(AccountsCompanion data) {
    return Account(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      institutionId: data.institutionId.present
          ? data.institutionId.value
          : this.institutionId,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Account(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('institutionId: $institutionId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    institutionId,
    name,
    type,
    sortOrder,
    archived,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Account &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.institutionId == this.institutionId &&
          other.name == this.name &&
          other.type == this.type &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived);
}

class AccountsCompanion extends UpdateCompanion<Account> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> institutionId;
  final Value<String> name;
  final Value<AccountType> type;
  final Value<int> sortOrder;
  final Value<bool> archived;
  final Value<int> rowid;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.institutionId = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.institutionId = const Value.absent(),
    required String name,
    required AccountType type,
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       type = Value(type);
  static Insertable<Account> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? institutionId,
    Expression<String>? name,
    Expression<String>? type,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (institutionId != null) 'institution_id': institutionId,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? institutionId,
    Value<String>? name,
    Value<AccountType>? type,
    Value<int>? sortOrder,
    Value<bool>? archived,
    Value<int>? rowid,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      institutionId: institutionId ?? this.institutionId,
      name: name ?? this.name,
      type: type ?? this.type,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (institutionId.present) {
      map['institution_id'] = Variable<String>(institutionId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(
        $AccountsTable.$convertertype.toSql(type.value),
      );
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('institutionId: $institutionId, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MonthsTable extends Months with TableInfo<$MonthsTable, Month> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
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
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMonthMeta = const VerificationMeta(
    'yearMonth',
  );
  @override
  late final GeneratedColumn<String> yearMonth = GeneratedColumn<String>(
    'year_month',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 7,
      maxTextLength: 7,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, updatedAt, deletedAt, yearMonth];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'months';
  @override
  VerificationContext validateIntegrity(
    Insertable<Month> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('year_month')) {
      context.handle(
        _yearMonthMeta,
        yearMonth.isAcceptableOrUnknown(data['year_month']!, _yearMonthMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMonthMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Month map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Month(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      yearMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year_month'],
      )!,
    );
  }

  @override
  $MonthsTable createAlias(String alias) {
    return $MonthsTable(attachedDatabase, alias);
  }
}

class Month extends DataClass implements Insertable<Month> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String yearMonth;
  const Month({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.yearMonth,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['year_month'] = Variable<String>(yearMonth);
    return map;
  }

  MonthsCompanion toCompanion(bool nullToAbsent) {
    return MonthsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      yearMonth: Value(yearMonth),
    );
  }

  factory Month.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Month(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      yearMonth: serializer.fromJson<String>(json['yearMonth']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'yearMonth': serializer.toJson<String>(yearMonth),
    };
  }

  Month copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? yearMonth,
  }) => Month(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    yearMonth: yearMonth ?? this.yearMonth,
  );
  Month copyWithCompanion(MonthsCompanion data) {
    return Month(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      yearMonth: data.yearMonth.present ? data.yearMonth.value : this.yearMonth,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Month(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('yearMonth: $yearMonth')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, deletedAt, yearMonth);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Month &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.yearMonth == this.yearMonth);
}

class MonthsCompanion extends UpdateCompanion<Month> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> yearMonth;
  final Value<int> rowid;
  const MonthsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.yearMonth = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MonthsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String yearMonth,
    this.rowid = const Value.absent(),
  }) : yearMonth = Value(yearMonth);
  static Insertable<Month> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? yearMonth,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (yearMonth != null) 'year_month': yearMonth,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MonthsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? yearMonth,
    Value<int>? rowid,
  }) {
    return MonthsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      yearMonth: yearMonth ?? this.yearMonth,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (yearMonth.present) {
      map['year_month'] = Variable<String>(yearMonth.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IncomesTable extends Incomes with TableInfo<$IncomesTable, Income> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncomesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
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
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthIdMeta = const VerificationMeta(
    'monthId',
  );
  @override
  late final GeneratedColumn<String> monthId = GeneratedColumn<String>(
    'month_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES months (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    monthId,
    name,
    amountCents,
    accountId,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'incomes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Income> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('month_id')) {
      context.handle(
        _monthIdMeta,
        monthId.isAcceptableOrUnknown(data['month_id']!, _monthIdMeta),
      );
    } else if (isInserting) {
      context.missing(_monthIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Income map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Income(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      monthId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $IncomesTable createAlias(String alias) {
    return $IncomesTable(attachedDatabase, alias);
  }
}

class Income extends DataClass implements Insertable<Income> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String monthId;
  final String name;
  final int amountCents;
  final String? accountId;
  final int sortOrder;
  const Income({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.monthId,
    required this.name,
    required this.amountCents,
    this.accountId,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['month_id'] = Variable<String>(monthId);
    map['name'] = Variable<String>(name);
    map['amount_cents'] = Variable<int>(amountCents);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  IncomesCompanion toCompanion(bool nullToAbsent) {
    return IncomesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      monthId: Value(monthId),
      name: Value(name),
      amountCents: Value(amountCents),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      sortOrder: Value(sortOrder),
    );
  }

  factory Income.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Income(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      monthId: serializer.fromJson<String>(json['monthId']),
      name: serializer.fromJson<String>(json['name']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'monthId': serializer.toJson<String>(monthId),
      'name': serializer.toJson<String>(name),
      'amountCents': serializer.toJson<int>(amountCents),
      'accountId': serializer.toJson<String?>(accountId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  Income copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? monthId,
    String? name,
    int? amountCents,
    Value<String?> accountId = const Value.absent(),
    int? sortOrder,
  }) => Income(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    monthId: monthId ?? this.monthId,
    name: name ?? this.name,
    amountCents: amountCents ?? this.amountCents,
    accountId: accountId.present ? accountId.value : this.accountId,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  Income copyWithCompanion(IncomesCompanion data) {
    return Income(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      name: data.name.present ? data.name.value : this.name,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Income(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('monthId: $monthId, ')
          ..write('name: $name, ')
          ..write('amountCents: $amountCents, ')
          ..write('accountId: $accountId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    monthId,
    name,
    amountCents,
    accountId,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Income &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.monthId == this.monthId &&
          other.name == this.name &&
          other.amountCents == this.amountCents &&
          other.accountId == this.accountId &&
          other.sortOrder == this.sortOrder);
}

class IncomesCompanion extends UpdateCompanion<Income> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> monthId;
  final Value<String> name;
  final Value<int> amountCents;
  final Value<String?> accountId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const IncomesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.monthId = const Value.absent(),
    this.name = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.accountId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IncomesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String monthId,
    required String name,
    required int amountCents,
    this.accountId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : monthId = Value(monthId),
       name = Value(name),
       amountCents = Value(amountCents);
  static Insertable<Income> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? monthId,
    Expression<String>? name,
    Expression<int>? amountCents,
    Expression<String>? accountId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (monthId != null) 'month_id': monthId,
      if (name != null) 'name': name,
      if (amountCents != null) 'amount_cents': amountCents,
      if (accountId != null) 'account_id': accountId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IncomesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? monthId,
    Value<String>? name,
    Value<int>? amountCents,
    Value<String?>? accountId,
    Value<int>? sortOrder,
    Value<int>? rowid,
  }) {
    return IncomesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      monthId: monthId ?? this.monthId,
      name: name ?? this.name,
      amountCents: amountCents ?? this.amountCents,
      accountId: accountId ?? this.accountId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (monthId.present) {
      map['month_id'] = Variable<String>(monthId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncomesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('monthId: $monthId, ')
          ..write('name: $name, ')
          ..write('amountCents: $amountCents, ')
          ..write('accountId: $accountId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $IncomeTopUpsTable extends IncomeTopUps
    with TableInfo<$IncomeTopUpsTable, TopUp> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncomeTopUpsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
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
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _incomeIdMeta = const VerificationMeta(
    'incomeId',
  );
  @override
  late final GeneratedColumn<String> incomeId = GeneratedColumn<String>(
    'income_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES incomes (id)',
    ),
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _receivedAtMeta = const VerificationMeta(
    'receivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> receivedAt = GeneratedColumn<DateTime>(
    'received_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    incomeId,
    amountCents,
    receivedAt,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'income_top_ups';
  @override
  VerificationContext validateIntegrity(
    Insertable<TopUp> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('income_id')) {
      context.handle(
        _incomeIdMeta,
        incomeId.isAcceptableOrUnknown(data['income_id']!, _incomeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_incomeIdMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('received_at')) {
      context.handle(
        _receivedAtMeta,
        receivedAt.isAcceptableOrUnknown(data['received_at']!, _receivedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_receivedAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TopUp map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TopUp(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      incomeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}income_id'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      receivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}received_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $IncomeTopUpsTable createAlias(String alias) {
    return $IncomeTopUpsTable(attachedDatabase, alias);
  }
}

class TopUp extends DataClass implements Insertable<TopUp> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String incomeId;
  final int amountCents;
  final DateTime receivedAt;
  final String? note;
  const TopUp({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.incomeId,
    required this.amountCents,
    required this.receivedAt,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['income_id'] = Variable<String>(incomeId);
    map['amount_cents'] = Variable<int>(amountCents);
    map['received_at'] = Variable<DateTime>(receivedAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  IncomeTopUpsCompanion toCompanion(bool nullToAbsent) {
    return IncomeTopUpsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      incomeId: Value(incomeId),
      amountCents: Value(amountCents),
      receivedAt: Value(receivedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory TopUp.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TopUp(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      incomeId: serializer.fromJson<String>(json['incomeId']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      receivedAt: serializer.fromJson<DateTime>(json['receivedAt']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'incomeId': serializer.toJson<String>(incomeId),
      'amountCents': serializer.toJson<int>(amountCents),
      'receivedAt': serializer.toJson<DateTime>(receivedAt),
      'note': serializer.toJson<String?>(note),
    };
  }

  TopUp copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? incomeId,
    int? amountCents,
    DateTime? receivedAt,
    Value<String?> note = const Value.absent(),
  }) => TopUp(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    incomeId: incomeId ?? this.incomeId,
    amountCents: amountCents ?? this.amountCents,
    receivedAt: receivedAt ?? this.receivedAt,
    note: note.present ? note.value : this.note,
  );
  TopUp copyWithCompanion(IncomeTopUpsCompanion data) {
    return TopUp(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      incomeId: data.incomeId.present ? data.incomeId.value : this.incomeId,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      receivedAt: data.receivedAt.present
          ? data.receivedAt.value
          : this.receivedAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TopUp(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('incomeId: $incomeId, ')
          ..write('amountCents: $amountCents, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    incomeId,
    amountCents,
    receivedAt,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TopUp &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.incomeId == this.incomeId &&
          other.amountCents == this.amountCents &&
          other.receivedAt == this.receivedAt &&
          other.note == this.note);
}

class IncomeTopUpsCompanion extends UpdateCompanion<TopUp> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> incomeId;
  final Value<int> amountCents;
  final Value<DateTime> receivedAt;
  final Value<String?> note;
  final Value<int> rowid;
  const IncomeTopUpsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.incomeId = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.receivedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  IncomeTopUpsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String incomeId,
    required int amountCents,
    required DateTime receivedAt,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : incomeId = Value(incomeId),
       amountCents = Value(amountCents),
       receivedAt = Value(receivedAt);
  static Insertable<TopUp> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? incomeId,
    Expression<int>? amountCents,
    Expression<DateTime>? receivedAt,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (incomeId != null) 'income_id': incomeId,
      if (amountCents != null) 'amount_cents': amountCents,
      if (receivedAt != null) 'received_at': receivedAt,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  IncomeTopUpsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? incomeId,
    Value<int>? amountCents,
    Value<DateTime>? receivedAt,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return IncomeTopUpsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      incomeId: incomeId ?? this.incomeId,
      amountCents: amountCents ?? this.amountCents,
      receivedAt: receivedAt ?? this.receivedAt,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (incomeId.present) {
      map['income_id'] = Variable<String>(incomeId.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (receivedAt.present) {
      map['received_at'] = Variable<DateTime>(receivedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncomeTopUpsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('incomeId: $incomeId, ')
          ..write('amountCents: $amountCents, ')
          ..write('receivedAt: $receivedAt, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ItemsTable extends Items with TableInfo<$ItemsTable, BudgetItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
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
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthIdMeta = const VerificationMeta(
    'monthId',
  );
  @override
  late final GeneratedColumn<String> monthId = GeneratedColumn<String>(
    'month_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES months (id)',
    ),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES items (id)',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ItemKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(ItemKind.expense.name),
      ).withConverter<ItemKind>($ItemsTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<ItemStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: Constant(ItemStatus.planned.name),
      ).withConverter<ItemStatus>($ItemsTable.$converterstatus);
  static const VerificationMeta _paidAtMeta = const VerificationMeta('paidAt');
  @override
  late final GeneratedColumn<DateTime> paidAt = GeneratedColumn<DateTime>(
    'paid_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _paidFromAccountIdMeta = const VerificationMeta(
    'paidFromAccountId',
  );
  @override
  late final GeneratedColumn<String> paidFromAccountId =
      GeneratedColumn<String>(
        'paid_from_account_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES accounts (id)',
        ),
      );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isCollectionMeta = const VerificationMeta(
    'isCollection',
  );
  @override
  late final GeneratedColumn<bool> isCollection = GeneratedColumn<bool>(
    'is_collection',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_collection" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    monthId,
    parentId,
    accountId,
    name,
    amountCents,
    kind,
    status,
    paidAt,
    paidFromAccountId,
    dueDay,
    note,
    sortOrder,
    isCollection,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'items';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('month_id')) {
      context.handle(
        _monthIdMeta,
        monthId.isAcceptableOrUnknown(data['month_id']!, _monthIdMeta),
      );
    } else if (isInserting) {
      context.missing(_monthIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('paid_at')) {
      context.handle(
        _paidAtMeta,
        paidAt.isAcceptableOrUnknown(data['paid_at']!, _paidAtMeta),
      );
    }
    if (data.containsKey('paid_from_account_id')) {
      context.handle(
        _paidFromAccountIdMeta,
        paidFromAccountId.isAcceptableOrUnknown(
          data['paid_from_account_id']!,
          _paidFromAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_collection')) {
      context.handle(
        _isCollectionMeta,
        isCollection.isAcceptableOrUnknown(
          data['is_collection']!,
          _isCollectionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BudgetItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      monthId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      kind: $ItemsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      status: $ItemsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      paidAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paid_at'],
      ),
      paidFromAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}paid_from_account_id'],
      ),
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isCollection: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_collection'],
      )!,
    );
  }

  @override
  $ItemsTable createAlias(String alias) {
    return $ItemsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ItemKind, String, String> $converterkind =
      const EnumNameConverter<ItemKind>(ItemKind.values);
  static JsonTypeConverter2<ItemStatus, String, String> $converterstatus =
      const EnumNameConverter<ItemStatus>(ItemStatus.values);
}

class BudgetItem extends DataClass implements Insertable<BudgetItem> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String monthId;
  final String? parentId;
  final String? accountId;
  final String name;
  final int amountCents;
  final ItemKind kind;
  final ItemStatus status;
  final DateTime? paidAt;

  /// Set when the item was paid from another account than planned (e.g.
  /// planned on the RCBC Card, paid from UB). Null means the planned one.
  final String? paidFromAccountId;
  final int? dueDay;
  final String? note;
  final int sortOrder;
  final bool isCollection;
  const BudgetItem({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.monthId,
    this.parentId,
    this.accountId,
    required this.name,
    required this.amountCents,
    required this.kind,
    required this.status,
    this.paidAt,
    this.paidFromAccountId,
    this.dueDay,
    this.note,
    required this.sortOrder,
    required this.isCollection,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['month_id'] = Variable<String>(monthId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['name'] = Variable<String>(name);
    map['amount_cents'] = Variable<int>(amountCents);
    {
      map['kind'] = Variable<String>($ItemsTable.$converterkind.toSql(kind));
    }
    {
      map['status'] = Variable<String>(
        $ItemsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || paidAt != null) {
      map['paid_at'] = Variable<DateTime>(paidAt);
    }
    if (!nullToAbsent || paidFromAccountId != null) {
      map['paid_from_account_id'] = Variable<String>(paidFromAccountId);
    }
    if (!nullToAbsent || dueDay != null) {
      map['due_day'] = Variable<int>(dueDay);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_collection'] = Variable<bool>(isCollection);
    return map;
  }

  ItemsCompanion toCompanion(bool nullToAbsent) {
    return ItemsCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      monthId: Value(monthId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      name: Value(name),
      amountCents: Value(amountCents),
      kind: Value(kind),
      status: Value(status),
      paidAt: paidAt == null && nullToAbsent
          ? const Value.absent()
          : Value(paidAt),
      paidFromAccountId: paidFromAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(paidFromAccountId),
      dueDay: dueDay == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDay),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      sortOrder: Value(sortOrder),
      isCollection: Value(isCollection),
    );
  }

  factory BudgetItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetItem(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      monthId: serializer.fromJson<String>(json['monthId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      name: serializer.fromJson<String>(json['name']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      kind: $ItemsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      status: $ItemsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      paidAt: serializer.fromJson<DateTime?>(json['paidAt']),
      paidFromAccountId: serializer.fromJson<String?>(
        json['paidFromAccountId'],
      ),
      dueDay: serializer.fromJson<int?>(json['dueDay']),
      note: serializer.fromJson<String?>(json['note']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isCollection: serializer.fromJson<bool>(json['isCollection']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'monthId': serializer.toJson<String>(monthId),
      'parentId': serializer.toJson<String?>(parentId),
      'accountId': serializer.toJson<String?>(accountId),
      'name': serializer.toJson<String>(name),
      'amountCents': serializer.toJson<int>(amountCents),
      'kind': serializer.toJson<String>(
        $ItemsTable.$converterkind.toJson(kind),
      ),
      'status': serializer.toJson<String>(
        $ItemsTable.$converterstatus.toJson(status),
      ),
      'paidAt': serializer.toJson<DateTime?>(paidAt),
      'paidFromAccountId': serializer.toJson<String?>(paidFromAccountId),
      'dueDay': serializer.toJson<int?>(dueDay),
      'note': serializer.toJson<String?>(note),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isCollection': serializer.toJson<bool>(isCollection),
    };
  }

  BudgetItem copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? monthId,
    Value<String?> parentId = const Value.absent(),
    Value<String?> accountId = const Value.absent(),
    String? name,
    int? amountCents,
    ItemKind? kind,
    ItemStatus? status,
    Value<DateTime?> paidAt = const Value.absent(),
    Value<String?> paidFromAccountId = const Value.absent(),
    Value<int?> dueDay = const Value.absent(),
    Value<String?> note = const Value.absent(),
    int? sortOrder,
    bool? isCollection,
  }) => BudgetItem(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    monthId: monthId ?? this.monthId,
    parentId: parentId.present ? parentId.value : this.parentId,
    accountId: accountId.present ? accountId.value : this.accountId,
    name: name ?? this.name,
    amountCents: amountCents ?? this.amountCents,
    kind: kind ?? this.kind,
    status: status ?? this.status,
    paidAt: paidAt.present ? paidAt.value : this.paidAt,
    paidFromAccountId: paidFromAccountId.present
        ? paidFromAccountId.value
        : this.paidFromAccountId,
    dueDay: dueDay.present ? dueDay.value : this.dueDay,
    note: note.present ? note.value : this.note,
    sortOrder: sortOrder ?? this.sortOrder,
    isCollection: isCollection ?? this.isCollection,
  );
  BudgetItem copyWithCompanion(ItemsCompanion data) {
    return BudgetItem(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      name: data.name.present ? data.name.value : this.name,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      kind: data.kind.present ? data.kind.value : this.kind,
      status: data.status.present ? data.status.value : this.status,
      paidAt: data.paidAt.present ? data.paidAt.value : this.paidAt,
      paidFromAccountId: data.paidFromAccountId.present
          ? data.paidFromAccountId.value
          : this.paidFromAccountId,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      note: data.note.present ? data.note.value : this.note,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isCollection: data.isCollection.present
          ? data.isCollection.value
          : this.isCollection,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetItem(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('monthId: $monthId, ')
          ..write('parentId: $parentId, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('amountCents: $amountCents, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('paidAt: $paidAt, ')
          ..write('paidFromAccountId: $paidFromAccountId, ')
          ..write('dueDay: $dueDay, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isCollection: $isCollection')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    monthId,
    parentId,
    accountId,
    name,
    amountCents,
    kind,
    status,
    paidAt,
    paidFromAccountId,
    dueDay,
    note,
    sortOrder,
    isCollection,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetItem &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.monthId == this.monthId &&
          other.parentId == this.parentId &&
          other.accountId == this.accountId &&
          other.name == this.name &&
          other.amountCents == this.amountCents &&
          other.kind == this.kind &&
          other.status == this.status &&
          other.paidAt == this.paidAt &&
          other.paidFromAccountId == this.paidFromAccountId &&
          other.dueDay == this.dueDay &&
          other.note == this.note &&
          other.sortOrder == this.sortOrder &&
          other.isCollection == this.isCollection);
}

class ItemsCompanion extends UpdateCompanion<BudgetItem> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> monthId;
  final Value<String?> parentId;
  final Value<String?> accountId;
  final Value<String> name;
  final Value<int> amountCents;
  final Value<ItemKind> kind;
  final Value<ItemStatus> status;
  final Value<DateTime?> paidAt;
  final Value<String?> paidFromAccountId;
  final Value<int?> dueDay;
  final Value<String?> note;
  final Value<int> sortOrder;
  final Value<bool> isCollection;
  final Value<int> rowid;
  const ItemsCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.monthId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.name = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.kind = const Value.absent(),
    this.status = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.paidFromAccountId = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.note = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isCollection = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ItemsCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String monthId,
    this.parentId = const Value.absent(),
    this.accountId = const Value.absent(),
    required String name,
    required int amountCents,
    this.kind = const Value.absent(),
    this.status = const Value.absent(),
    this.paidAt = const Value.absent(),
    this.paidFromAccountId = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.note = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isCollection = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : monthId = Value(monthId),
       name = Value(name),
       amountCents = Value(amountCents);
  static Insertable<BudgetItem> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? monthId,
    Expression<String>? parentId,
    Expression<String>? accountId,
    Expression<String>? name,
    Expression<int>? amountCents,
    Expression<String>? kind,
    Expression<String>? status,
    Expression<DateTime>? paidAt,
    Expression<String>? paidFromAccountId,
    Expression<int>? dueDay,
    Expression<String>? note,
    Expression<int>? sortOrder,
    Expression<bool>? isCollection,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (monthId != null) 'month_id': monthId,
      if (parentId != null) 'parent_id': parentId,
      if (accountId != null) 'account_id': accountId,
      if (name != null) 'name': name,
      if (amountCents != null) 'amount_cents': amountCents,
      if (kind != null) 'kind': kind,
      if (status != null) 'status': status,
      if (paidAt != null) 'paid_at': paidAt,
      if (paidFromAccountId != null) 'paid_from_account_id': paidFromAccountId,
      if (dueDay != null) 'due_day': dueDay,
      if (note != null) 'note': note,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isCollection != null) 'is_collection': isCollection,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ItemsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? monthId,
    Value<String?>? parentId,
    Value<String?>? accountId,
    Value<String>? name,
    Value<int>? amountCents,
    Value<ItemKind>? kind,
    Value<ItemStatus>? status,
    Value<DateTime?>? paidAt,
    Value<String?>? paidFromAccountId,
    Value<int?>? dueDay,
    Value<String?>? note,
    Value<int>? sortOrder,
    Value<bool>? isCollection,
    Value<int>? rowid,
  }) {
    return ItemsCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      monthId: monthId ?? this.monthId,
      parentId: parentId ?? this.parentId,
      accountId: accountId ?? this.accountId,
      name: name ?? this.name,
      amountCents: amountCents ?? this.amountCents,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      paidAt: paidAt ?? this.paidAt,
      paidFromAccountId: paidFromAccountId ?? this.paidFromAccountId,
      dueDay: dueDay ?? this.dueDay,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
      isCollection: isCollection ?? this.isCollection,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (monthId.present) {
      map['month_id'] = Variable<String>(monthId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $ItemsTable.$converterkind.toSql(kind.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ItemsTable.$converterstatus.toSql(status.value),
      );
    }
    if (paidAt.present) {
      map['paid_at'] = Variable<DateTime>(paidAt.value);
    }
    if (paidFromAccountId.present) {
      map['paid_from_account_id'] = Variable<String>(paidFromAccountId.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isCollection.present) {
      map['is_collection'] = Variable<bool>(isCollection.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ItemsCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('monthId: $monthId, ')
          ..write('parentId: $parentId, ')
          ..write('accountId: $accountId, ')
          ..write('name: $name, ')
          ..write('amountCents: $amountCents, ')
          ..write('kind: $kind, ')
          ..write('status: $status, ')
          ..write('paidAt: $paidAt, ')
          ..write('paidFromAccountId: $paidFromAccountId, ')
          ..write('dueDay: $dueDay, ')
          ..write('note: $note, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isCollection: $isCollection, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TransfersTable extends Transfers
    with TableInfo<$TransfersTable, Transfer> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransfersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
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
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _monthIdMeta = const VerificationMeta(
    'monthId',
  );
  @override
  late final GeneratedColumn<String> monthId = GeneratedColumn<String>(
    'month_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES months (id)',
    ),
  );
  static const VerificationMeta _fromAccountIdMeta = const VerificationMeta(
    'fromAccountId',
  );
  @override
  late final GeneratedColumn<String> fromAccountId = GeneratedColumn<String>(
    'from_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<String> toAccountId = GeneratedColumn<String>(
    'to_account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _transferredAtMeta = const VerificationMeta(
    'transferredAt',
  );
  @override
  late final GeneratedColumn<DateTime> transferredAt =
      GeneratedColumn<DateTime>(
        'transferred_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    monthId,
    fromAccountId,
    toAccountId,
    amountCents,
    transferredAt,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transfers';
  @override
  VerificationContext validateIntegrity(
    Insertable<Transfer> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('month_id')) {
      context.handle(
        _monthIdMeta,
        monthId.isAcceptableOrUnknown(data['month_id']!, _monthIdMeta),
      );
    } else if (isInserting) {
      context.missing(_monthIdMeta);
    }
    if (data.containsKey('from_account_id')) {
      context.handle(
        _fromAccountIdMeta,
        fromAccountId.isAcceptableOrUnknown(
          data['from_account_id']!,
          _fromAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromAccountIdMeta);
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_toAccountIdMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('transferred_at')) {
      context.handle(
        _transferredAtMeta,
        transferredAt.isAcceptableOrUnknown(
          data['transferred_at']!,
          _transferredAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_transferredAtMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Transfer map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Transfer(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      monthId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}month_id'],
      )!,
      fromAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_account_id'],
      )!,
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_account_id'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      transferredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}transferred_at'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $TransfersTable createAlias(String alias) {
    return $TransfersTable(attachedDatabase, alias);
  }
}

class Transfer extends DataClass implements Insertable<Transfer> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String monthId;
  final String fromAccountId;
  final String toAccountId;
  final int amountCents;
  final DateTime transferredAt;
  final String? note;
  const Transfer({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.monthId,
    required this.fromAccountId,
    required this.toAccountId,
    required this.amountCents,
    required this.transferredAt,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['month_id'] = Variable<String>(monthId);
    map['from_account_id'] = Variable<String>(fromAccountId);
    map['to_account_id'] = Variable<String>(toAccountId);
    map['amount_cents'] = Variable<int>(amountCents);
    map['transferred_at'] = Variable<DateTime>(transferredAt);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  TransfersCompanion toCompanion(bool nullToAbsent) {
    return TransfersCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      monthId: Value(monthId),
      fromAccountId: Value(fromAccountId),
      toAccountId: Value(toAccountId),
      amountCents: Value(amountCents),
      transferredAt: Value(transferredAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Transfer.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Transfer(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      monthId: serializer.fromJson<String>(json['monthId']),
      fromAccountId: serializer.fromJson<String>(json['fromAccountId']),
      toAccountId: serializer.fromJson<String>(json['toAccountId']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      transferredAt: serializer.fromJson<DateTime>(json['transferredAt']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'monthId': serializer.toJson<String>(monthId),
      'fromAccountId': serializer.toJson<String>(fromAccountId),
      'toAccountId': serializer.toJson<String>(toAccountId),
      'amountCents': serializer.toJson<int>(amountCents),
      'transferredAt': serializer.toJson<DateTime>(transferredAt),
      'note': serializer.toJson<String?>(note),
    };
  }

  Transfer copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? monthId,
    String? fromAccountId,
    String? toAccountId,
    int? amountCents,
    DateTime? transferredAt,
    Value<String?> note = const Value.absent(),
  }) => Transfer(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    monthId: monthId ?? this.monthId,
    fromAccountId: fromAccountId ?? this.fromAccountId,
    toAccountId: toAccountId ?? this.toAccountId,
    amountCents: amountCents ?? this.amountCents,
    transferredAt: transferredAt ?? this.transferredAt,
    note: note.present ? note.value : this.note,
  );
  Transfer copyWithCompanion(TransfersCompanion data) {
    return Transfer(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      fromAccountId: data.fromAccountId.present
          ? data.fromAccountId.value
          : this.fromAccountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      transferredAt: data.transferredAt.present
          ? data.transferredAt.value
          : this.transferredAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Transfer(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('monthId: $monthId, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('amountCents: $amountCents, ')
          ..write('transferredAt: $transferredAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    updatedAt,
    deletedAt,
    monthId,
    fromAccountId,
    toAccountId,
    amountCents,
    transferredAt,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Transfer &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.monthId == this.monthId &&
          other.fromAccountId == this.fromAccountId &&
          other.toAccountId == this.toAccountId &&
          other.amountCents == this.amountCents &&
          other.transferredAt == this.transferredAt &&
          other.note == this.note);
}

class TransfersCompanion extends UpdateCompanion<Transfer> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> monthId;
  final Value<String> fromAccountId;
  final Value<String> toAccountId;
  final Value<int> amountCents;
  final Value<DateTime> transferredAt;
  final Value<String?> note;
  final Value<int> rowid;
  const TransfersCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.monthId = const Value.absent(),
    this.fromAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.transferredAt = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TransfersCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String monthId,
    required String fromAccountId,
    required String toAccountId,
    required int amountCents,
    required DateTime transferredAt,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : monthId = Value(monthId),
       fromAccountId = Value(fromAccountId),
       toAccountId = Value(toAccountId),
       amountCents = Value(amountCents),
       transferredAt = Value(transferredAt);
  static Insertable<Transfer> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? monthId,
    Expression<String>? fromAccountId,
    Expression<String>? toAccountId,
    Expression<int>? amountCents,
    Expression<DateTime>? transferredAt,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (monthId != null) 'month_id': monthId,
      if (fromAccountId != null) 'from_account_id': fromAccountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (amountCents != null) 'amount_cents': amountCents,
      if (transferredAt != null) 'transferred_at': transferredAt,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TransfersCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? monthId,
    Value<String>? fromAccountId,
    Value<String>? toAccountId,
    Value<int>? amountCents,
    Value<DateTime>? transferredAt,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return TransfersCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      monthId: monthId ?? this.monthId,
      fromAccountId: fromAccountId ?? this.fromAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      amountCents: amountCents ?? this.amountCents,
      transferredAt: transferredAt ?? this.transferredAt,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (monthId.present) {
      map['month_id'] = Variable<String>(monthId.value);
    }
    if (fromAccountId.present) {
      map['from_account_id'] = Variable<String>(fromAccountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<String>(toAccountId.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (transferredAt.present) {
      map['transferred_at'] = Variable<DateTime>(transferredAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransfersCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('monthId: $monthId, ')
          ..write('fromAccountId: $fromAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('amountCents: $amountCents, ')
          ..write('transferredAt: $transferredAt, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplatesTable extends Templates
    with TableInfo<$TemplatesTable, TemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: newId,
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
    requiredDuringInsert: false,
    clientDefault: DateTime.now,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    updatedAt,
    deletedAt,
    name,
    payload,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class TemplateRow extends DataClass implements Insertable<TemplateRow> {
  final String id;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final String name;
  final String payload;
  const TemplateRow({
    required this.id,
    required this.updatedAt,
    this.deletedAt,
    required this.name,
    required this.payload,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['name'] = Variable<String>(name);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      name: Value(name),
      payload: Value(payload),
    );
  }

  factory TemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateRow(
      id: serializer.fromJson<String>(json['id']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      name: serializer.fromJson<String>(json['name']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'name': serializer.toJson<String>(name),
      'payload': serializer.toJson<String>(payload),
    };
  }

  TemplateRow copyWith({
    String? id,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? name,
    String? payload,
  }) => TemplateRow(
    id: id ?? this.id,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    name: name ?? this.name,
    payload: payload ?? this.payload,
  );
  TemplateRow copyWithCompanion(TemplatesCompanion data) {
    return TemplateRow(
      id: data.id.present ? data.id.value : this.id,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      name: data.name.present ? data.name.value : this.name,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateRow(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, updatedAt, deletedAt, name, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateRow &&
          other.id == this.id &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.name == this.name &&
          other.payload == this.payload);
}

class TemplatesCompanion extends UpdateCompanion<TemplateRow> {
  final Value<String> id;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<String> name;
  final Value<String> payload;
  final Value<int> rowid;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.payload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplatesCompanion.insert({
    this.id = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    required String name,
    required String payload,
    this.rowid = const Value.absent(),
  }) : name = Value(name),
       payload = Value(payload);
  static Insertable<TemplateRow> custom({
    Expression<String>? id,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? name,
    Expression<String>? payload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (name != null) 'name': name,
      if (payload != null) 'payload': payload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplatesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<String>? name,
    Value<String>? payload,
    Value<int>? rowid,
  }) {
    return TemplatesCompanion(
      id: id ?? this.id,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      name: name ?? this.name,
      payload: payload ?? this.payload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('name: $name, ')
          ..write('payload: $payload, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $InstitutionsTable institutions = $InstitutionsTable(this);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $MonthsTable months = $MonthsTable(this);
  late final $IncomesTable incomes = $IncomesTable(this);
  late final $IncomeTopUpsTable incomeTopUps = $IncomeTopUpsTable(this);
  late final $ItemsTable items = $ItemsTable(this);
  late final $TransfersTable transfers = $TransfersTable(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    institutions,
    accounts,
    months,
    incomes,
    incomeTopUps,
    items,
    transfers,
    templates,
  ];
}

typedef $$InstitutionsTableCreateCompanionBuilder =
    InstitutionsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String name,
      Value<int> sortOrder,
      Value<int> rowid,
    });
typedef $$InstitutionsTableUpdateCompanionBuilder =
    InstitutionsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> name,
      Value<int> sortOrder,
      Value<int> rowid,
    });

final class $$InstitutionsTableReferences
    extends BaseReferences<_$AppDatabase, $InstitutionsTable, Institution> {
  $$InstitutionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AccountsTable, List<Account>> _accountsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.accounts,
    aliasName: 'institutions__id__accounts__institution_id',
  );

  $$AccountsTableProcessedTableManager get accountsRefs {
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.institutionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_accountsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InstitutionsTableFilterComposer
    extends Composer<_$AppDatabase, $InstitutionsTable> {
  $$InstitutionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> accountsRefs(
    Expression<bool> Function($$AccountsTableFilterComposer f) f,
  ) {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.institutionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InstitutionsTableOrderingComposer
    extends Composer<_$AppDatabase, $InstitutionsTable> {
  $$InstitutionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$InstitutionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InstitutionsTable> {
  $$InstitutionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  Expression<T> accountsRefs<T extends Object>(
    Expression<T> Function($$AccountsTableAnnotationComposer a) f,
  ) {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.institutionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InstitutionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InstitutionsTable,
          Institution,
          $$InstitutionsTableFilterComposer,
          $$InstitutionsTableOrderingComposer,
          $$InstitutionsTableAnnotationComposer,
          $$InstitutionsTableCreateCompanionBuilder,
          $$InstitutionsTableUpdateCompanionBuilder,
          (Institution, $$InstitutionsTableReferences),
          Institution,
          PrefetchHooks Function({bool accountsRefs})
        > {
  $$InstitutionsTableTableManager(_$AppDatabase db, $InstitutionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InstitutionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InstitutionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InstitutionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstitutionsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InstitutionsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InstitutionsTable, Institution>(table),
                  $$InstitutionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({accountsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (accountsRefs) db.accounts],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (accountsRefs)
                    await $_getPrefetchedDataByColumns<
                      Institution,
                      $InstitutionsTable,
                      Account,
                      $AccountsTable
                    >(
                      currentTable: table,
                      referencedTable: $$InstitutionsTableReferences
                          ._accountsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$InstitutionsTableReferences(
                            db,
                            table,
                            p0,
                          ).accountsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'institution_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$InstitutionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InstitutionsTable,
      Institution,
      $$InstitutionsTableFilterComposer,
      $$InstitutionsTableOrderingComposer,
      $$InstitutionsTableAnnotationComposer,
      $$InstitutionsTableCreateCompanionBuilder,
      $$InstitutionsTableUpdateCompanionBuilder,
      (Institution, $$InstitutionsTableReferences),
      Institution,
      PrefetchHooks Function({bool accountsRefs})
    >;
typedef $$AccountsTableCreateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> institutionId,
  required String name,
  required AccountType type,
  Value<int> sortOrder,
  Value<bool> archived,
  Value<int> rowid,
});
typedef $$AccountsTableUpdateCompanionBuilder = AccountsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String?> institutionId,
  Value<String> name,
  Value<AccountType> type,
  Value<int> sortOrder,
  Value<bool> archived,
  Value<int> rowid,
});

final class $$AccountsTableReferences
    extends BaseReferences<_$AppDatabase, $AccountsTable, Account> {
  $$AccountsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InstitutionsTable _institutionIdTable(_$AppDatabase db) =>
      db.institutions.createAlias('accounts__institution_id__institutions__id');

  $$InstitutionsTableProcessedTableManager? get institutionId {
    final $_column = $_itemColumn<String>('institution_id');
    if ($_column == null) return null;
    final manager = $$InstitutionsTableTableManager(
      $_db,
      $_db.institutions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_institutionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$IncomesTable, List<Income>> _incomesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.incomes,
    aliasName: 'accounts__id__incomes__account_id',
  );

  $$IncomesTableProcessedTableManager get incomesRefs {
    final manager = $$IncomesTableTableManager(
      $_db,
      $_db.incomes,
    ).filter((f) => f.accountId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_incomesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AccountsTableFilterComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<AccountType, AccountType, String> get type =>
      $composableBuilder(
        column: $table.type,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  $$InstitutionsTableFilterComposer get institutionId {
    final $$InstitutionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.institutionId,
      referencedTable: $db.institutions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstitutionsTableFilterComposer(
            $db: $db,
            $table: $db.institutions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> incomesRefs(
    Expression<bool> Function($$IncomesTableFilterComposer f) f,
  ) {
    final $$IncomesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incomes,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomesTableFilterComposer(
            $db: $db,
            $table: $db.incomes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableOrderingComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  $$InstitutionsTableOrderingComposer get institutionId {
    final $$InstitutionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.institutionId,
      referencedTable: $db.institutions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstitutionsTableOrderingComposer(
            $db: $db,
            $table: $db.institutions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AccountsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AccountsTable> {
  $$AccountsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<AccountType, String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  $$InstitutionsTableAnnotationComposer get institutionId {
    final $$InstitutionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.institutionId,
      referencedTable: $db.institutions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InstitutionsTableAnnotationComposer(
            $db: $db,
            $table: $db.institutions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> incomesRefs<T extends Object>(
    Expression<T> Function($$IncomesTableAnnotationComposer a) f,
  ) {
    final $$IncomesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incomes,
      getReferencedColumn: (t) => t.accountId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomesTableAnnotationComposer(
            $db: $db,
            $table: $db.incomes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AccountsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AccountsTable,
          Account,
          $$AccountsTableFilterComposer,
          $$AccountsTableOrderingComposer,
          $$AccountsTableAnnotationComposer,
          $$AccountsTableCreateCompanionBuilder,
          $$AccountsTableUpdateCompanionBuilder,
          (Account, $$AccountsTableReferences),
          Account,
          PrefetchHooks Function({bool institutionId, bool incomesRefs})
        > {
  $$AccountsTableTableManager(_$AppDatabase db, $AccountsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AccountsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AccountsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AccountsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> institutionId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<AccountType> type = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                institutionId: institutionId,
                name: name,
                type: type,
                sortOrder: sortOrder,
                archived: archived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> institutionId = const Value.absent(),
                required String name,
                required AccountType type,
                Value<int> sortOrder = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AccountsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                institutionId: institutionId,
                name: name,
                type: type,
                sortOrder: sortOrder,
                archived: archived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AccountsTable, Account>(table),
                  $$AccountsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({institutionId = false, incomesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (incomesRefs) db.incomes],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (institutionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.institutionId,
                            referencedTable: $$AccountsTableReferences
                                ._institutionIdTable(db),
                            referencedColumn: $$AccountsTableReferences
                                ._institutionIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (incomesRefs)
                        await $_getPrefetchedDataByColumns<
                          Account,
                          $AccountsTable,
                          Income,
                          $IncomesTable
                        >(
                          currentTable: table,
                          referencedTable: $$AccountsTableReferences
                              ._incomesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$AccountsTableReferences(
                                db,
                                table,
                                p0,
                              ).incomesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'account_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$AccountsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AccountsTable,
      Account,
      $$AccountsTableFilterComposer,
      $$AccountsTableOrderingComposer,
      $$AccountsTableAnnotationComposer,
      $$AccountsTableCreateCompanionBuilder,
      $$AccountsTableUpdateCompanionBuilder,
      (Account, $$AccountsTableReferences),
      Account,
      PrefetchHooks Function({bool institutionId, bool incomesRefs})
    >;
typedef $$MonthsTableCreateCompanionBuilder = MonthsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String yearMonth,
  Value<int> rowid,
});
typedef $$MonthsTableUpdateCompanionBuilder = MonthsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> yearMonth,
  Value<int> rowid,
});

final class $$MonthsTableReferences
    extends BaseReferences<_$AppDatabase, $MonthsTable, Month> {
  $$MonthsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IncomesTable, List<Income>> _incomesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.incomes,
    aliasName: 'months__id__incomes__month_id',
  );

  $$IncomesTableProcessedTableManager get incomesRefs {
    final manager = $$IncomesTableTableManager(
      $_db,
      $_db.incomes,
    ).filter((f) => f.monthId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_incomesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ItemsTable, List<BudgetItem>> _itemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.items,
    aliasName: 'months__id__items__month_id',
  );

  $$ItemsTableProcessedTableManager get itemsRefs {
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.monthId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_itemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TransfersTable, List<Transfer>>
  _transfersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.transfers,
    aliasName: 'months__id__transfers__month_id',
  );

  $$TransfersTableProcessedTableManager get transfersRefs {
    final manager = $$TransfersTableTableManager(
      $_db,
      $_db.transfers,
    ).filter((f) => f.monthId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_transfersRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MonthsTableFilterComposer
    extends Composer<_$AppDatabase, $MonthsTable> {
  $$MonthsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get yearMonth => $composableBuilder(
    column: $table.yearMonth,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> incomesRefs(
    Expression<bool> Function($$IncomesTableFilterComposer f) f,
  ) {
    final $$IncomesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incomes,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomesTableFilterComposer(
            $db: $db,
            $table: $db.incomes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> itemsRefs(
    Expression<bool> Function($$ItemsTableFilterComposer f) f,
  ) {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> transfersRefs(
    Expression<bool> Function($$TransfersTableFilterComposer f) f,
  ) {
    final $$TransfersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transfers,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransfersTableFilterComposer(
            $db: $db,
            $table: $db.transfers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MonthsTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthsTable> {
  $$MonthsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get yearMonth => $composableBuilder(
    column: $table.yearMonth,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MonthsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthsTable> {
  $$MonthsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get yearMonth =>
      $composableBuilder(column: $table.yearMonth, builder: (column) => column);

  Expression<T> incomesRefs<T extends Object>(
    Expression<T> Function($$IncomesTableAnnotationComposer a) f,
  ) {
    final $$IncomesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incomes,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomesTableAnnotationComposer(
            $db: $db,
            $table: $db.incomes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> itemsRefs<T extends Object>(
    Expression<T> Function($$ItemsTableAnnotationComposer a) f,
  ) {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> transfersRefs<T extends Object>(
    Expression<T> Function($$TransfersTableAnnotationComposer a) f,
  ) {
    final $$TransfersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.transfers,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TransfersTableAnnotationComposer(
            $db: $db,
            $table: $db.transfers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MonthsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MonthsTable,
          Month,
          $$MonthsTableFilterComposer,
          $$MonthsTableOrderingComposer,
          $$MonthsTableAnnotationComposer,
          $$MonthsTableCreateCompanionBuilder,
          $$MonthsTableUpdateCompanionBuilder,
          (Month, $$MonthsTableReferences),
          Month,
          PrefetchHooks Function({
            bool incomesRefs,
            bool itemsRefs,
            bool transfersRefs,
          })
        > {
  $$MonthsTableTableManager(_$AppDatabase db, $MonthsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> yearMonth = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MonthsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                yearMonth: yearMonth,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String yearMonth,
                Value<int> rowid = const Value.absent(),
              }) => MonthsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                yearMonth: yearMonth,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MonthsTable, Month>(table),
                  $$MonthsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                incomesRefs = false,
                itemsRefs = false,
                transfersRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (incomesRefs) db.incomes,
                    if (itemsRefs) db.items,
                    if (transfersRefs) db.transfers,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (incomesRefs)
                        await $_getPrefetchedDataByColumns<
                          Month,
                          $MonthsTable,
                          Income,
                          $IncomesTable
                        >(
                          currentTable: table,
                          referencedTable: $$MonthsTableReferences
                              ._incomesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MonthsTableReferences(
                                db,
                                table,
                                p0,
                              ).incomesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'month_id',
                          typedResults: items,
                        ),
                      if (itemsRefs)
                        await $_getPrefetchedDataByColumns<
                          Month,
                          $MonthsTable,
                          BudgetItem,
                          $ItemsTable
                        >(
                          currentTable: table,
                          referencedTable: $$MonthsTableReferences
                              ._itemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MonthsTableReferences(db, table, p0).itemsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'month_id',
                          typedResults: items,
                        ),
                      if (transfersRefs)
                        await $_getPrefetchedDataByColumns<
                          Month,
                          $MonthsTable,
                          Transfer,
                          $TransfersTable
                        >(
                          currentTable: table,
                          referencedTable: $$MonthsTableReferences
                              ._transfersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MonthsTableReferences(
                                db,
                                table,
                                p0,
                              ).transfersRefs,
                          currentColumn: 'id',
                          referencedColumn: 'month_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MonthsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MonthsTable,
      Month,
      $$MonthsTableFilterComposer,
      $$MonthsTableOrderingComposer,
      $$MonthsTableAnnotationComposer,
      $$MonthsTableCreateCompanionBuilder,
      $$MonthsTableUpdateCompanionBuilder,
      (Month, $$MonthsTableReferences),
      Month,
      PrefetchHooks Function({
        bool incomesRefs,
        bool itemsRefs,
        bool transfersRefs,
      })
    >;
typedef $$IncomesTableCreateCompanionBuilder = IncomesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String monthId,
  required String name,
  required int amountCents,
  Value<String?> accountId,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$IncomesTableUpdateCompanionBuilder = IncomesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> monthId,
  Value<String> name,
  Value<int> amountCents,
  Value<String?> accountId,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$IncomesTableReferences
    extends BaseReferences<_$AppDatabase, $IncomesTable, Income> {
  $$IncomesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MonthsTable _monthIdTable(_$AppDatabase db) =>
      db.months.createAlias('incomes__month_id__months__id');

  $$MonthsTableProcessedTableManager get monthId {
    final $_column = $_itemColumn<String>('month_id')!;

    final manager = $$MonthsTableTableManager(
      $_db,
      $_db.months,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_monthIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('incomes__account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<String>('account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$IncomeTopUpsTable, List<TopUp>>
  _incomeTopUpsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.incomeTopUps,
    aliasName: 'incomes__id__income_top_ups__income_id',
  );

  $$IncomeTopUpsTableProcessedTableManager get incomeTopUpsRefs {
    final manager = $$IncomeTopUpsTableTableManager(
      $_db,
      $_db.incomeTopUps,
    ).filter((f) => f.incomeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_incomeTopUpsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$IncomesTableFilterComposer
    extends Composer<_$AppDatabase, $IncomesTable> {
  $$IncomesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  $$MonthsTableFilterComposer get monthId {
    final $$MonthsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.months,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthsTableFilterComposer(
            $db: $db,
            $table: $db.months,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> incomeTopUpsRefs(
    Expression<bool> Function($$IncomeTopUpsTableFilterComposer f) f,
  ) {
    final $$IncomeTopUpsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incomeTopUps,
      getReferencedColumn: (t) => t.incomeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeTopUpsTableFilterComposer(
            $db: $db,
            $table: $db.incomeTopUps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IncomesTableOrderingComposer
    extends Composer<_$AppDatabase, $IncomesTable> {
  $$IncomesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  $$MonthsTableOrderingComposer get monthId {
    final $$MonthsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.months,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthsTableOrderingComposer(
            $db: $db,
            $table: $db.months,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncomesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncomesTable> {
  $$IncomesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$MonthsTableAnnotationComposer get monthId {
    final $$MonthsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.months,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthsTableAnnotationComposer(
            $db: $db,
            $table: $db.months,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> incomeTopUpsRefs<T extends Object>(
    Expression<T> Function($$IncomeTopUpsTableAnnotationComposer a) f,
  ) {
    final $$IncomeTopUpsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incomeTopUps,
      getReferencedColumn: (t) => t.incomeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomeTopUpsTableAnnotationComposer(
            $db: $db,
            $table: $db.incomeTopUps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$IncomesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncomesTable,
          Income,
          $$IncomesTableFilterComposer,
          $$IncomesTableOrderingComposer,
          $$IncomesTableAnnotationComposer,
          $$IncomesTableCreateCompanionBuilder,
          $$IncomesTableUpdateCompanionBuilder,
          (Income, $$IncomesTableReferences),
          Income,
          PrefetchHooks Function({
            bool monthId,
            bool accountId,
            bool incomeTopUpsRefs,
          })
        > {
  $$IncomesTableTableManager(_$AppDatabase db, $IncomesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncomesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncomesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncomesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> monthId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncomesCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                monthId: monthId,
                name: name,
                amountCents: amountCents,
                accountId: accountId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String monthId,
                required String name,
                required int amountCents,
                Value<String?> accountId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncomesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                monthId: monthId,
                name: name,
                amountCents: amountCents,
                accountId: accountId,
                sortOrder: sortOrder,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IncomesTable, Income>(table),
                  $$IncomesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({monthId = false, accountId = false, incomeTopUpsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (incomeTopUpsRefs) db.incomeTopUps,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (monthId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.monthId,
                            referencedTable: $$IncomesTableReferences
                                ._monthIdTable(db),
                            referencedColumn: $$IncomesTableReferences
                                ._monthIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (accountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.accountId,
                            referencedTable: $$IncomesTableReferences
                                ._accountIdTable(db),
                            referencedColumn: $$IncomesTableReferences
                                ._accountIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (incomeTopUpsRefs)
                        await $_getPrefetchedDataByColumns<
                          Income,
                          $IncomesTable,
                          TopUp,
                          $IncomeTopUpsTable
                        >(
                          currentTable: table,
                          referencedTable: $$IncomesTableReferences
                              ._incomeTopUpsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$IncomesTableReferences(
                                db,
                                table,
                                p0,
                              ).incomeTopUpsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'income_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$IncomesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncomesTable,
      Income,
      $$IncomesTableFilterComposer,
      $$IncomesTableOrderingComposer,
      $$IncomesTableAnnotationComposer,
      $$IncomesTableCreateCompanionBuilder,
      $$IncomesTableUpdateCompanionBuilder,
      (Income, $$IncomesTableReferences),
      Income,
      PrefetchHooks Function({
        bool monthId,
        bool accountId,
        bool incomeTopUpsRefs,
      })
    >;
typedef $$IncomeTopUpsTableCreateCompanionBuilder =
    IncomeTopUpsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      required String incomeId,
      required int amountCents,
      required DateTime receivedAt,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$IncomeTopUpsTableUpdateCompanionBuilder =
    IncomeTopUpsCompanion Function({
      Value<String> id,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<String> incomeId,
      Value<int> amountCents,
      Value<DateTime> receivedAt,
      Value<String?> note,
      Value<int> rowid,
    });

final class $$IncomeTopUpsTableReferences
    extends BaseReferences<_$AppDatabase, $IncomeTopUpsTable, TopUp> {
  $$IncomeTopUpsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $IncomesTable _incomeIdTable(_$AppDatabase db) =>
      db.incomes.createAlias('income_top_ups__income_id__incomes__id');

  $$IncomesTableProcessedTableManager get incomeId {
    final $_column = $_itemColumn<String>('income_id')!;

    final manager = $$IncomesTableTableManager(
      $_db,
      $_db.incomes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_incomeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IncomeTopUpsTableFilterComposer
    extends Composer<_$AppDatabase, $IncomeTopUpsTable> {
  $$IncomeTopUpsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$IncomesTableFilterComposer get incomeId {
    final $$IncomesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.incomeId,
      referencedTable: $db.incomes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomesTableFilterComposer(
            $db: $db,
            $table: $db.incomes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncomeTopUpsTableOrderingComposer
    extends Composer<_$AppDatabase, $IncomeTopUpsTable> {
  $$IncomeTopUpsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$IncomesTableOrderingComposer get incomeId {
    final $$IncomesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.incomeId,
      referencedTable: $db.incomes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomesTableOrderingComposer(
            $db: $db,
            $table: $db.incomes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncomeTopUpsTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncomeTopUpsTable> {
  $$IncomeTopUpsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get receivedAt => $composableBuilder(
    column: $table.receivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$IncomesTableAnnotationComposer get incomeId {
    final $$IncomesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.incomeId,
      referencedTable: $db.incomes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomesTableAnnotationComposer(
            $db: $db,
            $table: $db.incomes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncomeTopUpsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncomeTopUpsTable,
          TopUp,
          $$IncomeTopUpsTableFilterComposer,
          $$IncomeTopUpsTableOrderingComposer,
          $$IncomeTopUpsTableAnnotationComposer,
          $$IncomeTopUpsTableCreateCompanionBuilder,
          $$IncomeTopUpsTableUpdateCompanionBuilder,
          (TopUp, $$IncomeTopUpsTableReferences),
          TopUp,
          PrefetchHooks Function({bool incomeId})
        > {
  $$IncomeTopUpsTableTableManager(_$AppDatabase db, $IncomeTopUpsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncomeTopUpsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncomeTopUpsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncomeTopUpsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> incomeId = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<DateTime> receivedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncomeTopUpsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                incomeId: incomeId,
                amountCents: amountCents,
                receivedAt: receivedAt,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String incomeId,
                required int amountCents,
                required DateTime receivedAt,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => IncomeTopUpsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                incomeId: incomeId,
                amountCents: amountCents,
                receivedAt: receivedAt,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IncomeTopUpsTable, TopUp>(table),
                  $$IncomeTopUpsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({incomeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (incomeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.incomeId,
                        referencedTable: $$IncomeTopUpsTableReferences
                            ._incomeIdTable(db),
                        referencedColumn: $$IncomeTopUpsTableReferences
                            ._incomeIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IncomeTopUpsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncomeTopUpsTable,
      TopUp,
      $$IncomeTopUpsTableFilterComposer,
      $$IncomeTopUpsTableOrderingComposer,
      $$IncomeTopUpsTableAnnotationComposer,
      $$IncomeTopUpsTableCreateCompanionBuilder,
      $$IncomeTopUpsTableUpdateCompanionBuilder,
      (TopUp, $$IncomeTopUpsTableReferences),
      TopUp,
      PrefetchHooks Function({bool incomeId})
    >;
typedef $$ItemsTableCreateCompanionBuilder = ItemsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String monthId,
  Value<String?> parentId,
  Value<String?> accountId,
  required String name,
  required int amountCents,
  Value<ItemKind> kind,
  Value<ItemStatus> status,
  Value<DateTime?> paidAt,
  Value<String?> paidFromAccountId,
  Value<int?> dueDay,
  Value<String?> note,
  Value<int> sortOrder,
  Value<bool> isCollection,
  Value<int> rowid,
});
typedef $$ItemsTableUpdateCompanionBuilder = ItemsCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> monthId,
  Value<String?> parentId,
  Value<String?> accountId,
  Value<String> name,
  Value<int> amountCents,
  Value<ItemKind> kind,
  Value<ItemStatus> status,
  Value<DateTime?> paidAt,
  Value<String?> paidFromAccountId,
  Value<int?> dueDay,
  Value<String?> note,
  Value<int> sortOrder,
  Value<bool> isCollection,
  Value<int> rowid,
});

final class $$ItemsTableReferences
    extends BaseReferences<_$AppDatabase, $ItemsTable, BudgetItem> {
  $$ItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MonthsTable _monthIdTable(_$AppDatabase db) =>
      db.months.createAlias('items__month_id__months__id');

  $$MonthsTableProcessedTableManager get monthId {
    final $_column = $_itemColumn<String>('month_id')!;

    final manager = $$MonthsTableTableManager(
      $_db,
      $_db.months,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_monthIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ItemsTable _parentIdTable(_$AppDatabase db) =>
      db.items.createAlias('items__parent_id__items__id');

  $$ItemsTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$ItemsTableTableManager(
      $_db,
      $_db.items,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _accountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('items__account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get accountId {
    final $_column = $_itemColumn<String>('account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_accountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _paidFromAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('items__paid_from_account_id__accounts__id');

  $$AccountsTableProcessedTableManager? get paidFromAccountId {
    final $_column = $_itemColumn<String>('paid_from_account_id');
    if ($_column == null) return null;
    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_paidFromAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ItemsTableFilterComposer extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ItemKind, ItemKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<ItemStatus, ItemStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCollection => $composableBuilder(
    column: $table.isCollection,
    builder: (column) => ColumnFilters(column),
  );

  $$MonthsTableFilterComposer get monthId {
    final $$MonthsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.months,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthsTableFilterComposer(
            $db: $db,
            $table: $db.months,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableFilterComposer get parentId {
    final $$ItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableFilterComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get accountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get paidFromAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.paidFromAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get paidAt => $composableBuilder(
    column: $table.paidAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dueDay => $composableBuilder(
    column: $table.dueDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCollection => $composableBuilder(
    column: $table.isCollection,
    builder: (column) => ColumnOrderings(column),
  );

  $$MonthsTableOrderingComposer get monthId {
    final $$MonthsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.months,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthsTableOrderingComposer(
            $db: $db,
            $table: $db.months,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableOrderingComposer get parentId {
    final $$ItemsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableOrderingComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get accountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get paidFromAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.paidFromAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ItemsTable> {
  $$ItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<ItemKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ItemStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get paidAt =>
      $composableBuilder(column: $table.paidAt, builder: (column) => column);

  GeneratedColumn<int> get dueDay =>
      $composableBuilder(column: $table.dueDay, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isCollection => $composableBuilder(
    column: $table.isCollection,
    builder: (column) => column,
  );

  $$MonthsTableAnnotationComposer get monthId {
    final $$MonthsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.months,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthsTableAnnotationComposer(
            $db: $db,
            $table: $db.months,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ItemsTableAnnotationComposer get parentId {
    final $$ItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.items,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.items,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get accountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.accountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get paidFromAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.paidFromAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ItemsTable,
          BudgetItem,
          $$ItemsTableFilterComposer,
          $$ItemsTableOrderingComposer,
          $$ItemsTableAnnotationComposer,
          $$ItemsTableCreateCompanionBuilder,
          $$ItemsTableUpdateCompanionBuilder,
          (BudgetItem, $$ItemsTableReferences),
          BudgetItem,
          PrefetchHooks Function({
            bool monthId,
            bool parentId,
            bool accountId,
            bool paidFromAccountId,
          })
        > {
  $$ItemsTableTableManager(_$AppDatabase db, $ItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> monthId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<ItemKind> kind = const Value.absent(),
                Value<ItemStatus> status = const Value.absent(),
                Value<DateTime?> paidAt = const Value.absent(),
                Value<String?> paidFromAccountId = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isCollection = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                monthId: monthId,
                parentId: parentId,
                accountId: accountId,
                name: name,
                amountCents: amountCents,
                kind: kind,
                status: status,
                paidAt: paidAt,
                paidFromAccountId: paidFromAccountId,
                dueDay: dueDay,
                note: note,
                sortOrder: sortOrder,
                isCollection: isCollection,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String monthId,
                Value<String?> parentId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                required String name,
                required int amountCents,
                Value<ItemKind> kind = const Value.absent(),
                Value<ItemStatus> status = const Value.absent(),
                Value<DateTime?> paidAt = const Value.absent(),
                Value<String?> paidFromAccountId = const Value.absent(),
                Value<int?> dueDay = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isCollection = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ItemsCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                monthId: monthId,
                parentId: parentId,
                accountId: accountId,
                name: name,
                amountCents: amountCents,
                kind: kind,
                status: status,
                paidAt: paidAt,
                paidFromAccountId: paidFromAccountId,
                dueDay: dueDay,
                note: note,
                sortOrder: sortOrder,
                isCollection: isCollection,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ItemsTable, BudgetItem>(table),
                  $$ItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                monthId = false,
                parentId = false,
                accountId = false,
                paidFromAccountId = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (monthId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.monthId,
                            referencedTable: $$ItemsTableReferences
                                ._monthIdTable(db),
                            referencedColumn: $$ItemsTableReferences
                                ._monthIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (parentId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.parentId,
                            referencedTable: $$ItemsTableReferences
                                ._parentIdTable(db),
                            referencedColumn: $$ItemsTableReferences
                                ._parentIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (accountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.accountId,
                            referencedTable: $$ItemsTableReferences
                                ._accountIdTable(db),
                            referencedColumn: $$ItemsTableReferences
                                ._accountIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (paidFromAccountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.paidFromAccountId,
                            referencedTable: $$ItemsTableReferences
                                ._paidFromAccountIdTable(db),
                            referencedColumn: $$ItemsTableReferences
                                ._paidFromAccountIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$ItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ItemsTable,
      BudgetItem,
      $$ItemsTableFilterComposer,
      $$ItemsTableOrderingComposer,
      $$ItemsTableAnnotationComposer,
      $$ItemsTableCreateCompanionBuilder,
      $$ItemsTableUpdateCompanionBuilder,
      (BudgetItem, $$ItemsTableReferences),
      BudgetItem,
      PrefetchHooks Function({
        bool monthId,
        bool parentId,
        bool accountId,
        bool paidFromAccountId,
      })
    >;
typedef $$TransfersTableCreateCompanionBuilder = TransfersCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String monthId,
  required String fromAccountId,
  required String toAccountId,
  required int amountCents,
  required DateTime transferredAt,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$TransfersTableUpdateCompanionBuilder = TransfersCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> monthId,
  Value<String> fromAccountId,
  Value<String> toAccountId,
  Value<int> amountCents,
  Value<DateTime> transferredAt,
  Value<String?> note,
  Value<int> rowid,
});

final class $$TransfersTableReferences
    extends BaseReferences<_$AppDatabase, $TransfersTable, Transfer> {
  $$TransfersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MonthsTable _monthIdTable(_$AppDatabase db) =>
      db.months.createAlias('transfers__month_id__months__id');

  $$MonthsTableProcessedTableManager get monthId {
    final $_column = $_itemColumn<String>('month_id')!;

    final manager = $$MonthsTableTableManager(
      $_db,
      $_db.months,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_monthIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _fromAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transfers__from_account_id__accounts__id');

  $$AccountsTableProcessedTableManager get fromAccountId {
    final $_column = $_itemColumn<String>('from_account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $AccountsTable _toAccountIdTable(_$AppDatabase db) =>
      db.accounts.createAlias('transfers__to_account_id__accounts__id');

  $$AccountsTableProcessedTableManager get toAccountId {
    final $_column = $_itemColumn<String>('to_account_id')!;

    final manager = $$AccountsTableTableManager(
      $_db,
      $_db.accounts,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toAccountIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TransfersTableFilterComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get transferredAt => $composableBuilder(
    column: $table.transferredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$MonthsTableFilterComposer get monthId {
    final $$MonthsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.months,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthsTableFilterComposer(
            $db: $db,
            $table: $db.months,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get fromAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableFilterComposer get toAccountId {
    final $$AccountsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableFilterComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransfersTableOrderingComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get transferredAt => $composableBuilder(
    column: $table.transferredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$MonthsTableOrderingComposer get monthId {
    final $$MonthsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.months,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthsTableOrderingComposer(
            $db: $db,
            $table: $db.months,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get fromAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableOrderingComposer get toAccountId {
    final $$AccountsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableOrderingComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransfersTableAnnotationComposer
    extends Composer<_$AppDatabase, $TransfersTable> {
  $$TransfersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get transferredAt => $composableBuilder(
    column: $table.transferredAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$MonthsTableAnnotationComposer get monthId {
    final $$MonthsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.months,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthsTableAnnotationComposer(
            $db: $db,
            $table: $db.months,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get fromAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$AccountsTableAnnotationComposer get toAccountId {
    final $$AccountsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toAccountId,
      referencedTable: $db.accounts,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AccountsTableAnnotationComposer(
            $db: $db,
            $table: $db.accounts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TransfersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TransfersTable,
          Transfer,
          $$TransfersTableFilterComposer,
          $$TransfersTableOrderingComposer,
          $$TransfersTableAnnotationComposer,
          $$TransfersTableCreateCompanionBuilder,
          $$TransfersTableUpdateCompanionBuilder,
          (Transfer, $$TransfersTableReferences),
          Transfer,
          PrefetchHooks Function({
            bool monthId,
            bool fromAccountId,
            bool toAccountId,
          })
        > {
  $$TransfersTableTableManager(_$AppDatabase db, $TransfersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TransfersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TransfersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TransfersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> monthId = const Value.absent(),
                Value<String> fromAccountId = const Value.absent(),
                Value<String> toAccountId = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<DateTime> transferredAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransfersCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                monthId: monthId,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                amountCents: amountCents,
                transferredAt: transferredAt,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String monthId,
                required String fromAccountId,
                required String toAccountId,
                required int amountCents,
                required DateTime transferredAt,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TransfersCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                monthId: monthId,
                fromAccountId: fromAccountId,
                toAccountId: toAccountId,
                amountCents: amountCents,
                transferredAt: transferredAt,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TransfersTable, Transfer>(table),
                  $$TransfersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({monthId = false, fromAccountId = false, toAccountId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (monthId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.monthId,
                            referencedTable: $$TransfersTableReferences
                                ._monthIdTable(db),
                            referencedColumn: $$TransfersTableReferences
                                ._monthIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (fromAccountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.fromAccountId,
                            referencedTable: $$TransfersTableReferences
                                ._fromAccountIdTable(db),
                            referencedColumn: $$TransfersTableReferences
                                ._fromAccountIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (toAccountId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.toAccountId,
                            referencedTable: $$TransfersTableReferences
                                ._toAccountIdTable(db),
                            referencedColumn: $$TransfersTableReferences
                                ._toAccountIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$TransfersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TransfersTable,
      Transfer,
      $$TransfersTableFilterComposer,
      $$TransfersTableOrderingComposer,
      $$TransfersTableAnnotationComposer,
      $$TransfersTableCreateCompanionBuilder,
      $$TransfersTableUpdateCompanionBuilder,
      (Transfer, $$TransfersTableReferences),
      Transfer,
      PrefetchHooks Function({
        bool monthId,
        bool fromAccountId,
        bool toAccountId,
      })
    >;
typedef $$TemplatesTableCreateCompanionBuilder = TemplatesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  required String name,
  required String payload,
  Value<int> rowid,
});
typedef $$TemplatesTableUpdateCompanionBuilder = TemplatesCompanion Function({
  Value<String> id,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<String> name,
  Value<String> payload,
  Value<int> rowid,
});

class $$TemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplatesTable> {
  $$TemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$TemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplatesTable,
          TemplateRow,
          $$TemplatesTableFilterComposer,
          $$TemplatesTableOrderingComposer,
          $$TemplatesTableAnnotationComposer,
          $$TemplatesTableCreateCompanionBuilder,
          $$TemplatesTableUpdateCompanionBuilder,
          (
            TemplateRow,
            BaseReferences<_$AppDatabase, $TemplatesTable, TemplateRow>,
          ),
          TemplateRow,
          PrefetchHooks Function()
        > {
  $$TemplatesTableTableManager(_$AppDatabase db, $TemplatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                payload: payload,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                required String name,
                required String payload,
                Value<int> rowid = const Value.absent(),
              }) => TemplatesCompanion.insert(
                id: id,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                name: name,
                payload: payload,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TemplatesTable, TemplateRow>(table),
                  BaseReferences<_$AppDatabase, $TemplatesTable, TemplateRow>(
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

typedef $$TemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplatesTable,
      TemplateRow,
      $$TemplatesTableFilterComposer,
      $$TemplatesTableOrderingComposer,
      $$TemplatesTableAnnotationComposer,
      $$TemplatesTableCreateCompanionBuilder,
      $$TemplatesTableUpdateCompanionBuilder,
      (
        TemplateRow,
        BaseReferences<_$AppDatabase, $TemplatesTable, TemplateRow>,
      ),
      TemplateRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$InstitutionsTableTableManager get institutions =>
      $$InstitutionsTableTableManager(_db, _db.institutions);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db, _db.accounts);
  $$MonthsTableTableManager get months =>
      $$MonthsTableTableManager(_db, _db.months);
  $$IncomesTableTableManager get incomes =>
      $$IncomesTableTableManager(_db, _db.incomes);
  $$IncomeTopUpsTableTableManager get incomeTopUps =>
      $$IncomeTopUpsTableTableManager(_db, _db.incomeTopUps);
  $$ItemsTableTableManager get items =>
      $$ItemsTableTableManager(_db, _db.items);
  $$TransfersTableTableManager get transfers =>
      $$TransfersTableTableManager(_db, _db.transfers);
  $$TemplatesTableTableManager get templates =>
      $$TemplatesTableTableManager(_db, _db.templates);
}
