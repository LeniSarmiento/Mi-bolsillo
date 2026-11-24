// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finance_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [label];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<Category> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {label};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final String label;
  const Category({required this.label});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['label'] = Variable<String>(label);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(label: Value(label));
  }

  factory Category.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(label: serializer.fromJson<String>(json['label']));
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{'label': serializer.toJson<String>(label)};
  }

  Category copyWith({String? label}) => Category(label: label ?? this.label);
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(label: data.label.present ? data.label.value : this.label);
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => label.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category && other.label == this.label);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<String> label;
  final Value<int> rowid;
  const CategoriesCompanion({
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CategoriesCompanion.insert({
    required String label,
    this.rowid = const Value.absent(),
  }) : label = Value(label);
  static Insertable<Category> custom({
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CategoriesCompanion copyWith({Value<String>? label, Value<int>? rowid}) {
    return CategoriesCompanion(
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MovementsTable extends Movements
    with TableInfo<$MovementsTable, Movement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (amount > 0)',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (label)',
    ),
  );
  static const VerificationMeta _occurredMeta = const VerificationMeta(
    'occurred',
  );
  @override
  late final GeneratedColumn<DateTime> occurred = GeneratedColumn<DateTime>(
    'occurred',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodMeta = const VerificationMeta('method');
  @override
  late final GeneratedColumn<String> method = GeneratedColumn<String>(
    'method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('confirmed'),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
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
    requiredDuringInsert: false,
    defaultValue: const Constant('none'),
  );
  static const VerificationMeta _nextDueMeta = const VerificationMeta(
    'nextDue',
  );
  @override
  late final GeneratedColumn<DateTime> nextDue = GeneratedColumn<DateTime>(
    'next_due',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentMeta = const VerificationMeta('parent');
  @override
  late final GeneratedColumn<String> parent = GeneratedColumn<String>(
    'parent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scheduledMeta = const VerificationMeta(
    'scheduled',
  );
  @override
  late final GeneratedColumn<DateTime> scheduled = GeneratedColumn<DateTime>(
    'scheduled',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedMeta = const VerificationMeta(
    'updated',
  );
  @override
  late final GeneratedColumn<DateTime> updated = GeneratedColumn<DateTime>(
    'updated',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    amount,
    description,
    category,
    occurred,
    method,
    source,
    status,
    note,
    frequency,
    nextDue,
    parent,
    scheduled,
    created,
    updated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Movement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('occurred')) {
      context.handle(
        _occurredMeta,
        occurred.isAcceptableOrUnknown(data['occurred']!, _occurredMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredMeta);
    }
    if (data.containsKey('method')) {
      context.handle(
        _methodMeta,
        method.isAcceptableOrUnknown(data['method']!, _methodMeta),
      );
    } else if (isInserting) {
      context.missing(_methodMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('next_due')) {
      context.handle(
        _nextDueMeta,
        nextDue.isAcceptableOrUnknown(data['next_due']!, _nextDueMeta),
      );
    }
    if (data.containsKey('parent')) {
      context.handle(
        _parentMeta,
        parent.isAcceptableOrUnknown(data['parent']!, _parentMeta),
      );
    }
    if (data.containsKey('scheduled')) {
      context.handle(
        _scheduledMeta,
        scheduled.isAcceptableOrUnknown(data['scheduled']!, _scheduledMeta),
      );
    }
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    if (data.containsKey('updated')) {
      context.handle(
        _updatedMeta,
        updated.isAcceptableOrUnknown(data['updated']!, _updatedMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {parent, scheduled},
  ];
  @override
  Movement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Movement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      occurred: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}occurred'],
      )!,
      method: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}method'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      nextDue: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_due'],
      ),
      parent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent'],
      ),
      scheduled: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled'],
      ),
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created'],
      )!,
      updated: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated'],
      )!,
    );
  }

  @override
  $MovementsTable createAlias(String alias) {
    return $MovementsTable(attachedDatabase, alias);
  }
}

class Movement extends DataClass implements Insertable<Movement> {
  final String id;
  final String kind;
  final int amount;
  final String description;
  final String category;
  final DateTime occurred;
  final String method;
  final String source;
  final String status;
  final String note;
  final String frequency;
  final DateTime? nextDue;
  final String? parent;
  final DateTime? scheduled;
  final DateTime created;
  final DateTime updated;
  const Movement({
    required this.id,
    required this.kind,
    required this.amount,
    required this.description,
    required this.category,
    required this.occurred,
    required this.method,
    required this.source,
    required this.status,
    required this.note,
    required this.frequency,
    this.nextDue,
    this.parent,
    this.scheduled,
    required this.created,
    required this.updated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['amount'] = Variable<int>(amount);
    map['description'] = Variable<String>(description);
    map['category'] = Variable<String>(category);
    map['occurred'] = Variable<DateTime>(occurred);
    map['method'] = Variable<String>(method);
    map['source'] = Variable<String>(source);
    map['status'] = Variable<String>(status);
    map['note'] = Variable<String>(note);
    map['frequency'] = Variable<String>(frequency);
    if (!nullToAbsent || nextDue != null) {
      map['next_due'] = Variable<DateTime>(nextDue);
    }
    if (!nullToAbsent || parent != null) {
      map['parent'] = Variable<String>(parent);
    }
    if (!nullToAbsent || scheduled != null) {
      map['scheduled'] = Variable<DateTime>(scheduled);
    }
    map['created'] = Variable<DateTime>(created);
    map['updated'] = Variable<DateTime>(updated);
    return map;
  }

  MovementsCompanion toCompanion(bool nullToAbsent) {
    return MovementsCompanion(
      id: Value(id),
      kind: Value(kind),
      amount: Value(amount),
      description: Value(description),
      category: Value(category),
      occurred: Value(occurred),
      method: Value(method),
      source: Value(source),
      status: Value(status),
      note: Value(note),
      frequency: Value(frequency),
      nextDue: nextDue == null && nullToAbsent
          ? const Value.absent()
          : Value(nextDue),
      parent: parent == null && nullToAbsent
          ? const Value.absent()
          : Value(parent),
      scheduled: scheduled == null && nullToAbsent
          ? const Value.absent()
          : Value(scheduled),
      created: Value(created),
      updated: Value(updated),
    );
  }

  factory Movement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Movement(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      amount: serializer.fromJson<int>(json['amount']),
      description: serializer.fromJson<String>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      occurred: serializer.fromJson<DateTime>(json['occurred']),
      method: serializer.fromJson<String>(json['method']),
      source: serializer.fromJson<String>(json['source']),
      status: serializer.fromJson<String>(json['status']),
      note: serializer.fromJson<String>(json['note']),
      frequency: serializer.fromJson<String>(json['frequency']),
      nextDue: serializer.fromJson<DateTime?>(json['nextDue']),
      parent: serializer.fromJson<String?>(json['parent']),
      scheduled: serializer.fromJson<DateTime?>(json['scheduled']),
      created: serializer.fromJson<DateTime>(json['created']),
      updated: serializer.fromJson<DateTime>(json['updated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'amount': serializer.toJson<int>(amount),
      'description': serializer.toJson<String>(description),
      'category': serializer.toJson<String>(category),
      'occurred': serializer.toJson<DateTime>(occurred),
      'method': serializer.toJson<String>(method),
      'source': serializer.toJson<String>(source),
      'status': serializer.toJson<String>(status),
      'note': serializer.toJson<String>(note),
      'frequency': serializer.toJson<String>(frequency),
      'nextDue': serializer.toJson<DateTime?>(nextDue),
      'parent': serializer.toJson<String?>(parent),
      'scheduled': serializer.toJson<DateTime?>(scheduled),
      'created': serializer.toJson<DateTime>(created),
      'updated': serializer.toJson<DateTime>(updated),
    };
  }

  Movement copyWith({
    String? id,
    String? kind,
    int? amount,
    String? description,
    String? category,
    DateTime? occurred,
    String? method,
    String? source,
    String? status,
    String? note,
    String? frequency,
    Value<DateTime?> nextDue = const Value.absent(),
    Value<String?> parent = const Value.absent(),
    Value<DateTime?> scheduled = const Value.absent(),
    DateTime? created,
    DateTime? updated,
  }) => Movement(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    amount: amount ?? this.amount,
    description: description ?? this.description,
    category: category ?? this.category,
    occurred: occurred ?? this.occurred,
    method: method ?? this.method,
    source: source ?? this.source,
    status: status ?? this.status,
    note: note ?? this.note,
    frequency: frequency ?? this.frequency,
    nextDue: nextDue.present ? nextDue.value : this.nextDue,
    parent: parent.present ? parent.value : this.parent,
    scheduled: scheduled.present ? scheduled.value : this.scheduled,
    created: created ?? this.created,
    updated: updated ?? this.updated,
  );
  Movement copyWithCompanion(MovementsCompanion data) {
    return Movement(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      amount: data.amount.present ? data.amount.value : this.amount,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      occurred: data.occurred.present ? data.occurred.value : this.occurred,
      method: data.method.present ? data.method.value : this.method,
      source: data.source.present ? data.source.value : this.source,
      status: data.status.present ? data.status.value : this.status,
      note: data.note.present ? data.note.value : this.note,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      nextDue: data.nextDue.present ? data.nextDue.value : this.nextDue,
      parent: data.parent.present ? data.parent.value : this.parent,
      scheduled: data.scheduled.present ? data.scheduled.value : this.scheduled,
      created: data.created.present ? data.created.value : this.created,
      updated: data.updated.present ? data.updated.value : this.updated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Movement(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('occurred: $occurred, ')
          ..write('method: $method, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('frequency: $frequency, ')
          ..write('nextDue: $nextDue, ')
          ..write('parent: $parent, ')
          ..write('scheduled: $scheduled, ')
          ..write('created: $created, ')
          ..write('updated: $updated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    amount,
    description,
    category,
    occurred,
    method,
    source,
    status,
    note,
    frequency,
    nextDue,
    parent,
    scheduled,
    created,
    updated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Movement &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.amount == this.amount &&
          other.description == this.description &&
          other.category == this.category &&
          other.occurred == this.occurred &&
          other.method == this.method &&
          other.source == this.source &&
          other.status == this.status &&
          other.note == this.note &&
          other.frequency == this.frequency &&
          other.nextDue == this.nextDue &&
          other.parent == this.parent &&
          other.scheduled == this.scheduled &&
          other.created == this.created &&
          other.updated == this.updated);
}

class MovementsCompanion extends UpdateCompanion<Movement> {
  final Value<String> id;
  final Value<String> kind;
  final Value<int> amount;
  final Value<String> description;
  final Value<String> category;
  final Value<DateTime> occurred;
  final Value<String> method;
  final Value<String> source;
  final Value<String> status;
  final Value<String> note;
  final Value<String> frequency;
  final Value<DateTime?> nextDue;
  final Value<String?> parent;
  final Value<DateTime?> scheduled;
  final Value<DateTime> created;
  final Value<DateTime> updated;
  final Value<int> rowid;
  const MovementsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.amount = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.occurred = const Value.absent(),
    this.method = const Value.absent(),
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.frequency = const Value.absent(),
    this.nextDue = const Value.absent(),
    this.parent = const Value.absent(),
    this.scheduled = const Value.absent(),
    this.created = const Value.absent(),
    this.updated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MovementsCompanion.insert({
    required String id,
    required String kind,
    required int amount,
    required String description,
    required String category,
    required DateTime occurred,
    required String method,
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.note = const Value.absent(),
    this.frequency = const Value.absent(),
    this.nextDue = const Value.absent(),
    this.parent = const Value.absent(),
    this.scheduled = const Value.absent(),
    required DateTime created,
    required DateTime updated,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       amount = Value(amount),
       description = Value(description),
       category = Value(category),
       occurred = Value(occurred),
       method = Value(method),
       created = Value(created),
       updated = Value(updated);
  static Insertable<Movement> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<int>? amount,
    Expression<String>? description,
    Expression<String>? category,
    Expression<DateTime>? occurred,
    Expression<String>? method,
    Expression<String>? source,
    Expression<String>? status,
    Expression<String>? note,
    Expression<String>? frequency,
    Expression<DateTime>? nextDue,
    Expression<String>? parent,
    Expression<DateTime>? scheduled,
    Expression<DateTime>? created,
    Expression<DateTime>? updated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (occurred != null) 'occurred': occurred,
      if (method != null) 'method': method,
      if (source != null) 'source': source,
      if (status != null) 'status': status,
      if (note != null) 'note': note,
      if (frequency != null) 'frequency': frequency,
      if (nextDue != null) 'next_due': nextDue,
      if (parent != null) 'parent': parent,
      if (scheduled != null) 'scheduled': scheduled,
      if (created != null) 'created': created,
      if (updated != null) 'updated': updated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MovementsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<int>? amount,
    Value<String>? description,
    Value<String>? category,
    Value<DateTime>? occurred,
    Value<String>? method,
    Value<String>? source,
    Value<String>? status,
    Value<String>? note,
    Value<String>? frequency,
    Value<DateTime?>? nextDue,
    Value<String?>? parent,
    Value<DateTime?>? scheduled,
    Value<DateTime>? created,
    Value<DateTime>? updated,
    Value<int>? rowid,
  }) {
    return MovementsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      category: category ?? this.category,
      occurred: occurred ?? this.occurred,
      method: method ?? this.method,
      source: source ?? this.source,
      status: status ?? this.status,
      note: note ?? this.note,
      frequency: frequency ?? this.frequency,
      nextDue: nextDue ?? this.nextDue,
      parent: parent ?? this.parent,
      scheduled: scheduled ?? this.scheduled,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (occurred.present) {
      map['occurred'] = Variable<DateTime>(occurred.value);
    }
    if (method.present) {
      map['method'] = Variable<String>(method.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (nextDue.present) {
      map['next_due'] = Variable<DateTime>(nextDue.value);
    }
    if (parent.present) {
      map['parent'] = Variable<String>(parent.value);
    }
    if (scheduled.present) {
      map['scheduled'] = Variable<DateTime>(scheduled.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (updated.present) {
      map['updated'] = Variable<DateTime>(updated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovementsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('amount: $amount, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('occurred: $occurred, ')
          ..write('method: $method, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('note: $note, ')
          ..write('frequency: $frequency, ')
          ..write('nextDue: $nextDue, ')
          ..write('parent: $parent, ')
          ..write('scheduled: $scheduled, ')
          ..write('created: $created, ')
          ..write('updated: $updated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SpendingLimitsTable extends SpendingLimits
    with TableInfo<$SpendingLimitsTable, SpendingLimit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpendingLimitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (label)',
    ),
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (amount > 0)',
  );
  static const VerificationMeta _periodMeta = const VerificationMeta('period');
  @override
  late final GeneratedColumn<String> period = GeneratedColumn<String>(
    'period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _warnMeta = const VerificationMeta('warn');
  @override
  late final GeneratedColumn<bool> warn = GeneratedColumn<bool>(
    'warn',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("warn" IN (0, 1))',
    ),
  );
  static const VerificationMeta _exhaustedMeta = const VerificationMeta(
    'exhausted',
  );
  @override
  late final GeneratedColumn<bool> exhausted = GeneratedColumn<bool>(
    'exhausted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("exhausted" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    category,
    amount,
    period,
    warn,
    exhausted,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'spending_limits';
  @override
  VerificationContext validateIntegrity(
    Insertable<SpendingLimit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('period')) {
      context.handle(
        _periodMeta,
        period.isAcceptableOrUnknown(data['period']!, _periodMeta),
      );
    } else if (isInserting) {
      context.missing(_periodMeta);
    }
    if (data.containsKey('warn')) {
      context.handle(
        _warnMeta,
        warn.isAcceptableOrUnknown(data['warn']!, _warnMeta),
      );
    } else if (isInserting) {
      context.missing(_warnMeta);
    }
    if (data.containsKey('exhausted')) {
      context.handle(
        _exhaustedMeta,
        exhausted.isAcceptableOrUnknown(data['exhausted']!, _exhaustedMeta),
      );
    } else if (isInserting) {
      context.missing(_exhaustedMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SpendingLimit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpendingLimit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      period: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}period'],
      )!,
      warn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}warn'],
      )!,
      exhausted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}exhausted'],
      )!,
    );
  }

  @override
  $SpendingLimitsTable createAlias(String alias) {
    return $SpendingLimitsTable(attachedDatabase, alias);
  }
}

class SpendingLimit extends DataClass implements Insertable<SpendingLimit> {
  final String id;
  final String category;
  final int amount;
  final String period;
  final bool warn;
  final bool exhausted;
  const SpendingLimit({
    required this.id,
    required this.category,
    required this.amount,
    required this.period,
    required this.warn,
    required this.exhausted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['category'] = Variable<String>(category);
    map['amount'] = Variable<int>(amount);
    map['period'] = Variable<String>(period);
    map['warn'] = Variable<bool>(warn);
    map['exhausted'] = Variable<bool>(exhausted);
    return map;
  }

  SpendingLimitsCompanion toCompanion(bool nullToAbsent) {
    return SpendingLimitsCompanion(
      id: Value(id),
      category: Value(category),
      amount: Value(amount),
      period: Value(period),
      warn: Value(warn),
      exhausted: Value(exhausted),
    );
  }

  factory SpendingLimit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpendingLimit(
      id: serializer.fromJson<String>(json['id']),
      category: serializer.fromJson<String>(json['category']),
      amount: serializer.fromJson<int>(json['amount']),
      period: serializer.fromJson<String>(json['period']),
      warn: serializer.fromJson<bool>(json['warn']),
      exhausted: serializer.fromJson<bool>(json['exhausted']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'category': serializer.toJson<String>(category),
      'amount': serializer.toJson<int>(amount),
      'period': serializer.toJson<String>(period),
      'warn': serializer.toJson<bool>(warn),
      'exhausted': serializer.toJson<bool>(exhausted),
    };
  }

  SpendingLimit copyWith({
    String? id,
    String? category,
    int? amount,
    String? period,
    bool? warn,
    bool? exhausted,
  }) => SpendingLimit(
    id: id ?? this.id,
    category: category ?? this.category,
    amount: amount ?? this.amount,
    period: period ?? this.period,
    warn: warn ?? this.warn,
    exhausted: exhausted ?? this.exhausted,
  );
  SpendingLimit copyWithCompanion(SpendingLimitsCompanion data) {
    return SpendingLimit(
      id: data.id.present ? data.id.value : this.id,
      category: data.category.present ? data.category.value : this.category,
      amount: data.amount.present ? data.amount.value : this.amount,
      period: data.period.present ? data.period.value : this.period,
      warn: data.warn.present ? data.warn.value : this.warn,
      exhausted: data.exhausted.present ? data.exhausted.value : this.exhausted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpendingLimit(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('period: $period, ')
          ..write('warn: $warn, ')
          ..write('exhausted: $exhausted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, category, amount, period, warn, exhausted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpendingLimit &&
          other.id == this.id &&
          other.category == this.category &&
          other.amount == this.amount &&
          other.period == this.period &&
          other.warn == this.warn &&
          other.exhausted == this.exhausted);
}

class SpendingLimitsCompanion extends UpdateCompanion<SpendingLimit> {
  final Value<String> id;
  final Value<String> category;
  final Value<int> amount;
  final Value<String> period;
  final Value<bool> warn;
  final Value<bool> exhausted;
  final Value<int> rowid;
  const SpendingLimitsCompanion({
    this.id = const Value.absent(),
    this.category = const Value.absent(),
    this.amount = const Value.absent(),
    this.period = const Value.absent(),
    this.warn = const Value.absent(),
    this.exhausted = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SpendingLimitsCompanion.insert({
    required String id,
    required String category,
    required int amount,
    required String period,
    required bool warn,
    required bool exhausted,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       category = Value(category),
       amount = Value(amount),
       period = Value(period),
       warn = Value(warn),
       exhausted = Value(exhausted);
  static Insertable<SpendingLimit> custom({
    Expression<String>? id,
    Expression<String>? category,
    Expression<int>? amount,
    Expression<String>? period,
    Expression<bool>? warn,
    Expression<bool>? exhausted,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (category != null) 'category': category,
      if (amount != null) 'amount': amount,
      if (period != null) 'period': period,
      if (warn != null) 'warn': warn,
      if (exhausted != null) 'exhausted': exhausted,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SpendingLimitsCompanion copyWith({
    Value<String>? id,
    Value<String>? category,
    Value<int>? amount,
    Value<String>? period,
    Value<bool>? warn,
    Value<bool>? exhausted,
    Value<int>? rowid,
  }) {
    return SpendingLimitsCompanion(
      id: id ?? this.id,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      warn: warn ?? this.warn,
      exhausted: exhausted ?? this.exhausted,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (period.present) {
      map['period'] = Variable<String>(period.value);
    }
    if (warn.present) {
      map['warn'] = Variable<bool>(warn.value);
    }
    if (exhausted.present) {
      map['exhausted'] = Variable<bool>(exhausted.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpendingLimitsCompanion(')
          ..write('id: $id, ')
          ..write('category: $category, ')
          ..write('amount: $amount, ')
          ..write('period: $period, ')
          ..write('warn: $warn, ')
          ..write('exhausted: $exhausted, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PreferencesTable extends Preferences
    with TableInfo<$PreferencesTable, Preference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
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
  List<GeneratedColumn> get $columns => [id, payload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<Preference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
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
  Preference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Preference(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
    );
  }

  @override
  $PreferencesTable createAlias(String alias) {
    return $PreferencesTable(attachedDatabase, alias);
  }
}

class Preference extends DataClass implements Insertable<Preference> {
  final int id;
  final String payload;
  const Preference({required this.id, required this.payload});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['payload'] = Variable<String>(payload);
    return map;
  }

  PreferencesCompanion toCompanion(bool nullToAbsent) {
    return PreferencesCompanion(id: Value(id), payload: Value(payload));
  }

  factory Preference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Preference(
      id: serializer.fromJson<int>(json['id']),
      payload: serializer.fromJson<String>(json['payload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'payload': serializer.toJson<String>(payload),
    };
  }

  Preference copyWith({int? id, String? payload}) =>
      Preference(id: id ?? this.id, payload: payload ?? this.payload);
  Preference copyWithCompanion(PreferencesCompanion data) {
    return Preference(
      id: data.id.present ? data.id.value : this.id,
      payload: data.payload.present ? data.payload.value : this.payload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Preference(')
          ..write('id: $id, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, payload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Preference &&
          other.id == this.id &&
          other.payload == this.payload);
}

class PreferencesCompanion extends UpdateCompanion<Preference> {
  final Value<int> id;
  final Value<String> payload;
  const PreferencesCompanion({
    this.id = const Value.absent(),
    this.payload = const Value.absent(),
  });
  PreferencesCompanion.insert({
    this.id = const Value.absent(),
    required String payload,
  }) : payload = Value(payload);
  static Insertable<Preference> custom({
    Expression<int>? id,
    Expression<String>? payload,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (payload != null) 'payload': payload,
    });
  }

  PreferencesCompanion copyWith({Value<int>? id, Value<String>? payload}) {
    return PreferencesCompanion(
      id: id ?? this.id,
      payload: payload ?? this.payload,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PreferencesCompanion(')
          ..write('id: $id, ')
          ..write('payload: $payload')
          ..write(')'))
        .toString();
  }
}

class $DetectionReceiptsTable extends DetectionReceipts
    with TableInfo<$DetectionReceiptsTable, DetectionReceipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DetectionReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fingerprintMeta = const VerificationMeta(
    'fingerprint',
  );
  @override
  late final GeneratedColumn<String> fingerprint = GeneratedColumn<String>(
    'fingerprint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceAppMeta = const VerificationMeta(
    'sourceApp',
  );
  @override
  late final GeneratedColumn<String> sourceApp = GeneratedColumn<String>(
    'source_app',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [fingerprint, sourceApp];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'detection_receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<DetectionReceipt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('fingerprint')) {
      context.handle(
        _fingerprintMeta,
        fingerprint.isAcceptableOrUnknown(
          data['fingerprint']!,
          _fingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fingerprintMeta);
    }
    if (data.containsKey('source_app')) {
      context.handle(
        _sourceAppMeta,
        sourceApp.isAcceptableOrUnknown(data['source_app']!, _sourceAppMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceAppMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fingerprint};
  @override
  DetectionReceipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DetectionReceipt(
      fingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}fingerprint'],
      )!,
      sourceApp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_app'],
      )!,
    );
  }

  @override
  $DetectionReceiptsTable createAlias(String alias) {
    return $DetectionReceiptsTable(attachedDatabase, alias);
  }
}

class DetectionReceipt extends DataClass
    implements Insertable<DetectionReceipt> {
  final String fingerprint;
  final String sourceApp;
  const DetectionReceipt({required this.fingerprint, required this.sourceApp});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['fingerprint'] = Variable<String>(fingerprint);
    map['source_app'] = Variable<String>(sourceApp);
    return map;
  }

  DetectionReceiptsCompanion toCompanion(bool nullToAbsent) {
    return DetectionReceiptsCompanion(
      fingerprint: Value(fingerprint),
      sourceApp: Value(sourceApp),
    );
  }

  factory DetectionReceipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DetectionReceipt(
      fingerprint: serializer.fromJson<String>(json['fingerprint']),
      sourceApp: serializer.fromJson<String>(json['sourceApp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fingerprint': serializer.toJson<String>(fingerprint),
      'sourceApp': serializer.toJson<String>(sourceApp),
    };
  }

  DetectionReceipt copyWith({String? fingerprint, String? sourceApp}) =>
      DetectionReceipt(
        fingerprint: fingerprint ?? this.fingerprint,
        sourceApp: sourceApp ?? this.sourceApp,
      );
  DetectionReceipt copyWithCompanion(DetectionReceiptsCompanion data) {
    return DetectionReceipt(
      fingerprint: data.fingerprint.present
          ? data.fingerprint.value
          : this.fingerprint,
      sourceApp: data.sourceApp.present ? data.sourceApp.value : this.sourceApp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DetectionReceipt(')
          ..write('fingerprint: $fingerprint, ')
          ..write('sourceApp: $sourceApp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(fingerprint, sourceApp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DetectionReceipt &&
          other.fingerprint == this.fingerprint &&
          other.sourceApp == this.sourceApp);
}

class DetectionReceiptsCompanion extends UpdateCompanion<DetectionReceipt> {
  final Value<String> fingerprint;
  final Value<String> sourceApp;
  final Value<int> rowid;
  const DetectionReceiptsCompanion({
    this.fingerprint = const Value.absent(),
    this.sourceApp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DetectionReceiptsCompanion.insert({
    required String fingerprint,
    required String sourceApp,
    this.rowid = const Value.absent(),
  }) : fingerprint = Value(fingerprint),
       sourceApp = Value(sourceApp);
  static Insertable<DetectionReceipt> custom({
    Expression<String>? fingerprint,
    Expression<String>? sourceApp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fingerprint != null) 'fingerprint': fingerprint,
      if (sourceApp != null) 'source_app': sourceApp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DetectionReceiptsCompanion copyWith({
    Value<String>? fingerprint,
    Value<String>? sourceApp,
    Value<int>? rowid,
  }) {
    return DetectionReceiptsCompanion(
      fingerprint: fingerprint ?? this.fingerprint,
      sourceApp: sourceApp ?? this.sourceApp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fingerprint.present) {
      map['fingerprint'] = Variable<String>(fingerprint.value);
    }
    if (sourceApp.present) {
      map['source_app'] = Variable<String>(sourceApp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DetectionReceiptsCompanion(')
          ..write('fingerprint: $fingerprint, ')
          ..write('sourceApp: $sourceApp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BudgetAlertReceiptsTable extends BudgetAlertReceipts
    with TableInfo<$BudgetAlertReceiptsTable, BudgetAlertReceipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetAlertReceiptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdMeta = const VerificationMeta(
    'created',
  );
  @override
  late final GeneratedColumn<DateTime> created = GeneratedColumn<DateTime>(
    'created',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, created];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budget_alert_receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<BudgetAlertReceipt> instance, {
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
    if (data.containsKey('created')) {
      context.handle(
        _createdMeta,
        created.isAcceptableOrUnknown(data['created']!, _createdMeta),
      );
    } else if (isInserting) {
      context.missing(_createdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  BudgetAlertReceipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BudgetAlertReceipt(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      created: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created'],
      )!,
    );
  }

  @override
  $BudgetAlertReceiptsTable createAlias(String alias) {
    return $BudgetAlertReceiptsTable(attachedDatabase, alias);
  }
}

class BudgetAlertReceipt extends DataClass
    implements Insertable<BudgetAlertReceipt> {
  final String key;
  final DateTime created;
  const BudgetAlertReceipt({required this.key, required this.created});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['created'] = Variable<DateTime>(created);
    return map;
  }

  BudgetAlertReceiptsCompanion toCompanion(bool nullToAbsent) {
    return BudgetAlertReceiptsCompanion(
      key: Value(key),
      created: Value(created),
    );
  }

  factory BudgetAlertReceipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BudgetAlertReceipt(
      key: serializer.fromJson<String>(json['key']),
      created: serializer.fromJson<DateTime>(json['created']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'created': serializer.toJson<DateTime>(created),
    };
  }

  BudgetAlertReceipt copyWith({String? key, DateTime? created}) =>
      BudgetAlertReceipt(
        key: key ?? this.key,
        created: created ?? this.created,
      );
  BudgetAlertReceipt copyWithCompanion(BudgetAlertReceiptsCompanion data) {
    return BudgetAlertReceipt(
      key: data.key.present ? data.key.value : this.key,
      created: data.created.present ? data.created.value : this.created,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BudgetAlertReceipt(')
          ..write('key: $key, ')
          ..write('created: $created')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, created);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BudgetAlertReceipt &&
          other.key == this.key &&
          other.created == this.created);
}

class BudgetAlertReceiptsCompanion extends UpdateCompanion<BudgetAlertReceipt> {
  final Value<String> key;
  final Value<DateTime> created;
  final Value<int> rowid;
  const BudgetAlertReceiptsCompanion({
    this.key = const Value.absent(),
    this.created = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BudgetAlertReceiptsCompanion.insert({
    required String key,
    required DateTime created,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       created = Value(created);
  static Insertable<BudgetAlertReceipt> custom({
    Expression<String>? key,
    Expression<DateTime>? created,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (created != null) 'created': created,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BudgetAlertReceiptsCompanion copyWith({
    Value<String>? key,
    Value<DateTime>? created,
    Value<int>? rowid,
  }) {
    return BudgetAlertReceiptsCompanion(
      key: key ?? this.key,
      created: created ?? this.created,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (created.present) {
      map['created'] = Variable<DateTime>(created.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetAlertReceiptsCompanion(')
          ..write('key: $key, ')
          ..write('created: $created, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$FinanceDatabase extends GeneratedDatabase {
  _$FinanceDatabase(QueryExecutor e) : super(e);
  $FinanceDatabaseManager get managers => $FinanceDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $MovementsTable movements = $MovementsTable(this);
  late final $SpendingLimitsTable spendingLimits = $SpendingLimitsTable(this);
  late final $PreferencesTable preferences = $PreferencesTable(this);
  late final $DetectionReceiptsTable detectionReceipts =
      $DetectionReceiptsTable(this);
  late final $BudgetAlertReceiptsTable budgetAlertReceipts =
      $BudgetAlertReceiptsTable(this);
  late final Index movementPeriod = Index(
    'movement_period',
    'CREATE INDEX movement_period ON movements (kind, status, occurred)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    categories,
    movements,
    spendingLimits,
    preferences,
    detectionReceipts,
    budgetAlertReceipts,
    movementPeriod,
  ];
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  required String label,
  Value<int> rowid,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<String> label,
  Value<int> rowid,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$FinanceDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MovementsTable, List<Movement>>
  _movementsRefsTable(_$FinanceDatabase db) => MultiTypedResultKey.fromTable(
    db.movements,
    aliasName: 'categories__label__movements__category',
  );

  $$MovementsTableProcessedTableManager get movementsRefs {
    final manager = $$MovementsTableTableManager(
      $_db,
      $_db.movements,
    ).filter((f) => f.category.label.sqlEquals($_itemColumn<String>('label')!));

    final cache = $_typedResult.readTableOrNull(_movementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SpendingLimitsTable, List<SpendingLimit>>
  _spendingLimitsRefsTable(_$FinanceDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.spendingLimits,
        aliasName: 'categories__label__spending_limits__category',
      );

  $$SpendingLimitsTableProcessedTableManager get spendingLimitsRefs {
    final manager = $$SpendingLimitsTableTableManager(
      $_db,
      $_db.spendingLimits,
    ).filter((f) => f.category.label.sqlEquals($_itemColumn<String>('label')!));

    final cache = $_typedResult.readTableOrNull(_spendingLimitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$FinanceDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> movementsRefs(
    Expression<bool> Function($$MovementsTableFilterComposer f) f,
  ) {
    final $$MovementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.label,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.category,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableFilterComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> spendingLimitsRefs(
    Expression<bool> Function($$SpendingLimitsTableFilterComposer f) f,
  ) {
    final $$SpendingLimitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.label,
      referencedTable: $db.spendingLimits,
      getReferencedColumn: (t) => t.category,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpendingLimitsTableFilterComposer(
            $db: $db,
            $table: $db.spendingLimits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$FinanceDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$FinanceDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  Expression<T> movementsRefs<T extends Object>(
    Expression<T> Function($$MovementsTableAnnotationComposer a) f,
  ) {
    final $$MovementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.label,
      referencedTable: $db.movements,
      getReferencedColumn: (t) => t.category,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovementsTableAnnotationComposer(
            $db: $db,
            $table: $db.movements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> spendingLimitsRefs<T extends Object>(
    Expression<T> Function($$SpendingLimitsTableAnnotationComposer a) f,
  ) {
    final $$SpendingLimitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.label,
      referencedTable: $db.spendingLimits,
      getReferencedColumn: (t) => t.category,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SpendingLimitsTableAnnotationComposer(
            $db: $db,
            $table: $db.spendingLimits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CategoriesTableTableManager
    extends
        RootTableManager<
          _$FinanceDatabase,
          $CategoriesTable,
          Category,
          $$CategoriesTableFilterComposer,
          $$CategoriesTableOrderingComposer,
          $$CategoriesTableAnnotationComposer,
          $$CategoriesTableCreateCompanionBuilder,
          $$CategoriesTableUpdateCompanionBuilder,
          (Category, $$CategoriesTableReferences),
          Category,
          PrefetchHooks Function({bool movementsRefs, bool spendingLimitsRefs})
        > {
  $$CategoriesTableTableManager(_$FinanceDatabase db, $CategoriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> label = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => CategoriesCompanion(label: label, rowid: rowid),
          createCompanionCallback: ({
            required String label,
            Value<int> rowid = const Value.absent(),
          }) => CategoriesCompanion.insert(label: label, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CategoriesTable, Category>(table),
                  $$CategoriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({movementsRefs = false, spendingLimitsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (movementsRefs) db.movements,
                    if (spendingLimitsRefs) db.spendingLimits,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (movementsRefs)
                        await $_getPrefetchedDataByColumns<
                          Category,
                          $CategoriesTable,
                          Movement,
                          $MovementsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._movementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).movementsRefs,
                          currentColumn: 'label',
                          referencedColumn: 'category',
                          typedResults: items,
                        ),
                      if (spendingLimitsRefs)
                        await $_getPrefetchedDataByColumns<
                          Category,
                          $CategoriesTable,
                          SpendingLimit,
                          $SpendingLimitsTable
                        >(
                          currentTable: table,
                          referencedTable: $$CategoriesTableReferences
                              ._spendingLimitsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CategoriesTableReferences(
                                db,
                                table,
                                p0,
                              ).spendingLimitsRefs,
                          currentColumn: 'label',
                          referencedColumn: 'category',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CategoriesTableProcessedTableManager =
    ProcessedTableManager<
      _$FinanceDatabase,
      $CategoriesTable,
      Category,
      $$CategoriesTableFilterComposer,
      $$CategoriesTableOrderingComposer,
      $$CategoriesTableAnnotationComposer,
      $$CategoriesTableCreateCompanionBuilder,
      $$CategoriesTableUpdateCompanionBuilder,
      (Category, $$CategoriesTableReferences),
      Category,
      PrefetchHooks Function({bool movementsRefs, bool spendingLimitsRefs})
    >;
typedef $$MovementsTableCreateCompanionBuilder = MovementsCompanion Function({
  required String id,
  required String kind,
  required int amount,
  required String description,
  required String category,
  required DateTime occurred,
  required String method,
  Value<String> source,
  Value<String> status,
  Value<String> note,
  Value<String> frequency,
  Value<DateTime?> nextDue,
  Value<String?> parent,
  Value<DateTime?> scheduled,
  required DateTime created,
  required DateTime updated,
  Value<int> rowid,
});
typedef $$MovementsTableUpdateCompanionBuilder = MovementsCompanion Function({
  Value<String> id,
  Value<String> kind,
  Value<int> amount,
  Value<String> description,
  Value<String> category,
  Value<DateTime> occurred,
  Value<String> method,
  Value<String> source,
  Value<String> status,
  Value<String> note,
  Value<String> frequency,
  Value<DateTime?> nextDue,
  Value<String?> parent,
  Value<DateTime?> scheduled,
  Value<DateTime> created,
  Value<DateTime> updated,
  Value<int> rowid,
});

final class $$MovementsTableReferences
    extends BaseReferences<_$FinanceDatabase, $MovementsTable, Movement> {
  $$MovementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryTable(_$FinanceDatabase db) =>
      db.categories.createAlias('movements__category__categories__label');

  $$CategoriesTableProcessedTableManager get category {
    final $_column = $_itemColumn<String>('category')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.label.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MovementsTableFilterComposer
    extends Composer<_$FinanceDatabase, $MovementsTable> {
  $$MovementsTableFilterComposer({
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

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get occurred => $composableBuilder(
    column: $table.occurred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextDue => $composableBuilder(
    column: $table.nextDue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parent => $composableBuilder(
    column: $table.parent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduled => $composableBuilder(
    column: $table.scheduled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get category {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.label,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovementsTableOrderingComposer
    extends Composer<_$FinanceDatabase, $MovementsTable> {
  $$MovementsTableOrderingComposer({
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

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get occurred => $composableBuilder(
    column: $table.occurred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get method => $composableBuilder(
    column: $table.method,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextDue => $composableBuilder(
    column: $table.nextDue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parent => $composableBuilder(
    column: $table.parent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduled => $composableBuilder(
    column: $table.scheduled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updated => $composableBuilder(
    column: $table.updated,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get category {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.label,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovementsTableAnnotationComposer
    extends Composer<_$FinanceDatabase, $MovementsTable> {
  $$MovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get occurred =>
      $composableBuilder(column: $table.occurred, builder: (column) => column);

  GeneratedColumn<String> get method =>
      $composableBuilder(column: $table.method, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<DateTime> get nextDue =>
      $composableBuilder(column: $table.nextDue, builder: (column) => column);

  GeneratedColumn<String> get parent =>
      $composableBuilder(column: $table.parent, builder: (column) => column);

  GeneratedColumn<DateTime> get scheduled =>
      $composableBuilder(column: $table.scheduled, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);

  GeneratedColumn<DateTime> get updated =>
      $composableBuilder(column: $table.updated, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get category {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.label,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MovementsTableTableManager
    extends
        RootTableManager<
          _$FinanceDatabase,
          $MovementsTable,
          Movement,
          $$MovementsTableFilterComposer,
          $$MovementsTableOrderingComposer,
          $$MovementsTableAnnotationComposer,
          $$MovementsTableCreateCompanionBuilder,
          $$MovementsTableUpdateCompanionBuilder,
          (Movement, $$MovementsTableReferences),
          Movement,
          PrefetchHooks Function({bool category})
        > {
  $$MovementsTableTableManager(_$FinanceDatabase db, $MovementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<DateTime> occurred = const Value.absent(),
                Value<String> method = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<DateTime?> nextDue = const Value.absent(),
                Value<String?> parent = const Value.absent(),
                Value<DateTime?> scheduled = const Value.absent(),
                Value<DateTime> created = const Value.absent(),
                Value<DateTime> updated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovementsCompanion(
                id: id,
                kind: kind,
                amount: amount,
                description: description,
                category: category,
                occurred: occurred,
                method: method,
                source: source,
                status: status,
                note: note,
                frequency: frequency,
                nextDue: nextDue,
                parent: parent,
                scheduled: scheduled,
                created: created,
                updated: updated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required int amount,
                required String description,
                required String category,
                required DateTime occurred,
                required String method,
                Value<String> source = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<DateTime?> nextDue = const Value.absent(),
                Value<String?> parent = const Value.absent(),
                Value<DateTime?> scheduled = const Value.absent(),
                required DateTime created,
                required DateTime updated,
                Value<int> rowid = const Value.absent(),
              }) => MovementsCompanion.insert(
                id: id,
                kind: kind,
                amount: amount,
                description: description,
                category: category,
                occurred: occurred,
                method: method,
                source: source,
                status: status,
                note: note,
                frequency: frequency,
                nextDue: nextDue,
                parent: parent,
                scheduled: scheduled,
                created: created,
                updated: updated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MovementsTable, Movement>(table),
                  $$MovementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({category = false}) {
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
                    if (category) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.category,
                        referencedTable: $$MovementsTableReferences
                            ._categoryTable(db),
                        referencedColumn: $$MovementsTableReferences
                            ._categoryTable(db)
                            .label,
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

typedef $$MovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$FinanceDatabase,
      $MovementsTable,
      Movement,
      $$MovementsTableFilterComposer,
      $$MovementsTableOrderingComposer,
      $$MovementsTableAnnotationComposer,
      $$MovementsTableCreateCompanionBuilder,
      $$MovementsTableUpdateCompanionBuilder,
      (Movement, $$MovementsTableReferences),
      Movement,
      PrefetchHooks Function({bool category})
    >;
typedef $$SpendingLimitsTableCreateCompanionBuilder =
    SpendingLimitsCompanion Function({
      required String id,
      required String category,
      required int amount,
      required String period,
      required bool warn,
      required bool exhausted,
      Value<int> rowid,
    });
typedef $$SpendingLimitsTableUpdateCompanionBuilder =
    SpendingLimitsCompanion Function({
      Value<String> id,
      Value<String> category,
      Value<int> amount,
      Value<String> period,
      Value<bool> warn,
      Value<bool> exhausted,
      Value<int> rowid,
    });

final class $$SpendingLimitsTableReferences
    extends
        BaseReferences<_$FinanceDatabase, $SpendingLimitsTable, SpendingLimit> {
  $$SpendingLimitsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $CategoriesTable _categoryTable(_$FinanceDatabase db) =>
      db.categories.createAlias('spending_limits__category__categories__label');

  $$CategoriesTableProcessedTableManager get category {
    final $_column = $_itemColumn<String>('category')!;

    final manager = $$CategoriesTableTableManager(
      $_db,
      $_db.categories,
    ).filter((f) => f.label.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SpendingLimitsTableFilterComposer
    extends Composer<_$FinanceDatabase, $SpendingLimitsTable> {
  $$SpendingLimitsTableFilterComposer({
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

  ColumnFilters<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get warn => $composableBuilder(
    column: $table.warn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get exhausted => $composableBuilder(
    column: $table.exhausted,
    builder: (column) => ColumnFilters(column),
  );

  $$CategoriesTableFilterComposer get category {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.label,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableFilterComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SpendingLimitsTableOrderingComposer
    extends Composer<_$FinanceDatabase, $SpendingLimitsTable> {
  $$SpendingLimitsTableOrderingComposer({
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

  ColumnOrderings<int> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get period => $composableBuilder(
    column: $table.period,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get warn => $composableBuilder(
    column: $table.warn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get exhausted => $composableBuilder(
    column: $table.exhausted,
    builder: (column) => ColumnOrderings(column),
  );

  $$CategoriesTableOrderingComposer get category {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.label,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableOrderingComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SpendingLimitsTableAnnotationComposer
    extends Composer<_$FinanceDatabase, $SpendingLimitsTable> {
  $$SpendingLimitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get period =>
      $composableBuilder(column: $table.period, builder: (column) => column);

  GeneratedColumn<bool> get warn =>
      $composableBuilder(column: $table.warn, builder: (column) => column);

  GeneratedColumn<bool> get exhausted =>
      $composableBuilder(column: $table.exhausted, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get category {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.category,
      referencedTable: $db.categories,
      getReferencedColumn: (t) => t.label,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CategoriesTableAnnotationComposer(
            $db: $db,
            $table: $db.categories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SpendingLimitsTableTableManager
    extends
        RootTableManager<
          _$FinanceDatabase,
          $SpendingLimitsTable,
          SpendingLimit,
          $$SpendingLimitsTableFilterComposer,
          $$SpendingLimitsTableOrderingComposer,
          $$SpendingLimitsTableAnnotationComposer,
          $$SpendingLimitsTableCreateCompanionBuilder,
          $$SpendingLimitsTableUpdateCompanionBuilder,
          (SpendingLimit, $$SpendingLimitsTableReferences),
          SpendingLimit,
          PrefetchHooks Function({bool category})
        > {
  $$SpendingLimitsTableTableManager(
    _$FinanceDatabase db,
    $SpendingLimitsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpendingLimitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpendingLimitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpendingLimitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> amount = const Value.absent(),
                Value<String> period = const Value.absent(),
                Value<bool> warn = const Value.absent(),
                Value<bool> exhausted = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SpendingLimitsCompanion(
                id: id,
                category: category,
                amount: amount,
                period: period,
                warn: warn,
                exhausted: exhausted,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String category,
                required int amount,
                required String period,
                required bool warn,
                required bool exhausted,
                Value<int> rowid = const Value.absent(),
              }) => SpendingLimitsCompanion.insert(
                id: id,
                category: category,
                amount: amount,
                period: period,
                warn: warn,
                exhausted: exhausted,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SpendingLimitsTable, SpendingLimit>(table),
                  $$SpendingLimitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({category = false}) {
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
                    if (category) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.category,
                        referencedTable: $$SpendingLimitsTableReferences
                            ._categoryTable(db),
                        referencedColumn: $$SpendingLimitsTableReferences
                            ._categoryTable(db)
                            .label,
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

typedef $$SpendingLimitsTableProcessedTableManager =
    ProcessedTableManager<
      _$FinanceDatabase,
      $SpendingLimitsTable,
      SpendingLimit,
      $$SpendingLimitsTableFilterComposer,
      $$SpendingLimitsTableOrderingComposer,
      $$SpendingLimitsTableAnnotationComposer,
      $$SpendingLimitsTableCreateCompanionBuilder,
      $$SpendingLimitsTableUpdateCompanionBuilder,
      (SpendingLimit, $$SpendingLimitsTableReferences),
      SpendingLimit,
      PrefetchHooks Function({bool category})
    >;
typedef $$PreferencesTableCreateCompanionBuilder =
    PreferencesCompanion Function({Value<int> id, required String payload});
typedef $$PreferencesTableUpdateCompanionBuilder =
    PreferencesCompanion Function({Value<int> id, Value<String> payload});

class $$PreferencesTableFilterComposer
    extends Composer<_$FinanceDatabase, $PreferencesTable> {
  $$PreferencesTableFilterComposer({
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

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PreferencesTableOrderingComposer
    extends Composer<_$FinanceDatabase, $PreferencesTable> {
  $$PreferencesTableOrderingComposer({
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

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PreferencesTableAnnotationComposer
    extends Composer<_$FinanceDatabase, $PreferencesTable> {
  $$PreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);
}

class $$PreferencesTableTableManager
    extends
        RootTableManager<
          _$FinanceDatabase,
          $PreferencesTable,
          Preference,
          $$PreferencesTableFilterComposer,
          $$PreferencesTableOrderingComposer,
          $$PreferencesTableAnnotationComposer,
          $$PreferencesTableCreateCompanionBuilder,
          $$PreferencesTableUpdateCompanionBuilder,
          (
            Preference,
            BaseReferences<_$FinanceDatabase, $PreferencesTable, Preference>,
          ),
          Preference,
          PrefetchHooks Function()
        > {
  $$PreferencesTableTableManager(_$FinanceDatabase db, $PreferencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PreferencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PreferencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> payload = const Value.absent(),
          }) => PreferencesCompanion(id: id, payload: payload),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String payload,
          }) => PreferencesCompanion.insert(id: id, payload: payload),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PreferencesTable, Preference>(table),
                  BaseReferences<
                    _$FinanceDatabase,
                    $PreferencesTable,
                    Preference
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$FinanceDatabase,
      $PreferencesTable,
      Preference,
      $$PreferencesTableFilterComposer,
      $$PreferencesTableOrderingComposer,
      $$PreferencesTableAnnotationComposer,
      $$PreferencesTableCreateCompanionBuilder,
      $$PreferencesTableUpdateCompanionBuilder,
      (
        Preference,
        BaseReferences<_$FinanceDatabase, $PreferencesTable, Preference>,
      ),
      Preference,
      PrefetchHooks Function()
    >;
typedef $$DetectionReceiptsTableCreateCompanionBuilder =
    DetectionReceiptsCompanion Function({
      required String fingerprint,
      required String sourceApp,
      Value<int> rowid,
    });
typedef $$DetectionReceiptsTableUpdateCompanionBuilder =
    DetectionReceiptsCompanion Function({
      Value<String> fingerprint,
      Value<String> sourceApp,
      Value<int> rowid,
    });

class $$DetectionReceiptsTableFilterComposer
    extends Composer<_$FinanceDatabase, $DetectionReceiptsTable> {
  $$DetectionReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceApp => $composableBuilder(
    column: $table.sourceApp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DetectionReceiptsTableOrderingComposer
    extends Composer<_$FinanceDatabase, $DetectionReceiptsTable> {
  $$DetectionReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceApp => $composableBuilder(
    column: $table.sourceApp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DetectionReceiptsTableAnnotationComposer
    extends Composer<_$FinanceDatabase, $DetectionReceiptsTable> {
  $$DetectionReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fingerprint => $composableBuilder(
    column: $table.fingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceApp =>
      $composableBuilder(column: $table.sourceApp, builder: (column) => column);
}

class $$DetectionReceiptsTableTableManager
    extends
        RootTableManager<
          _$FinanceDatabase,
          $DetectionReceiptsTable,
          DetectionReceipt,
          $$DetectionReceiptsTableFilterComposer,
          $$DetectionReceiptsTableOrderingComposer,
          $$DetectionReceiptsTableAnnotationComposer,
          $$DetectionReceiptsTableCreateCompanionBuilder,
          $$DetectionReceiptsTableUpdateCompanionBuilder,
          (
            DetectionReceipt,
            BaseReferences<
              _$FinanceDatabase,
              $DetectionReceiptsTable,
              DetectionReceipt
            >,
          ),
          DetectionReceipt,
          PrefetchHooks Function()
        > {
  $$DetectionReceiptsTableTableManager(
    _$FinanceDatabase db,
    $DetectionReceiptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DetectionReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DetectionReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DetectionReceiptsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> fingerprint = const Value.absent(),
                Value<String> sourceApp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DetectionReceiptsCompanion(
                fingerprint: fingerprint,
                sourceApp: sourceApp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fingerprint,
                required String sourceApp,
                Value<int> rowid = const Value.absent(),
              }) => DetectionReceiptsCompanion.insert(
                fingerprint: fingerprint,
                sourceApp: sourceApp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$DetectionReceiptsTable, DetectionReceipt>(table),
                  BaseReferences<
                    _$FinanceDatabase,
                    $DetectionReceiptsTable,
                    DetectionReceipt
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DetectionReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$FinanceDatabase,
      $DetectionReceiptsTable,
      DetectionReceipt,
      $$DetectionReceiptsTableFilterComposer,
      $$DetectionReceiptsTableOrderingComposer,
      $$DetectionReceiptsTableAnnotationComposer,
      $$DetectionReceiptsTableCreateCompanionBuilder,
      $$DetectionReceiptsTableUpdateCompanionBuilder,
      (
        DetectionReceipt,
        BaseReferences<
          _$FinanceDatabase,
          $DetectionReceiptsTable,
          DetectionReceipt
        >,
      ),
      DetectionReceipt,
      PrefetchHooks Function()
    >;
typedef $$BudgetAlertReceiptsTableCreateCompanionBuilder =
    BudgetAlertReceiptsCompanion Function({
      required String key,
      required DateTime created,
      Value<int> rowid,
    });
typedef $$BudgetAlertReceiptsTableUpdateCompanionBuilder =
    BudgetAlertReceiptsCompanion Function({
      Value<String> key,
      Value<DateTime> created,
      Value<int> rowid,
    });

class $$BudgetAlertReceiptsTableFilterComposer
    extends Composer<_$FinanceDatabase, $BudgetAlertReceiptsTable> {
  $$BudgetAlertReceiptsTableFilterComposer({
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

  ColumnFilters<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BudgetAlertReceiptsTableOrderingComposer
    extends Composer<_$FinanceDatabase, $BudgetAlertReceiptsTable> {
  $$BudgetAlertReceiptsTableOrderingComposer({
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

  ColumnOrderings<DateTime> get created => $composableBuilder(
    column: $table.created,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BudgetAlertReceiptsTableAnnotationComposer
    extends Composer<_$FinanceDatabase, $BudgetAlertReceiptsTable> {
  $$BudgetAlertReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<DateTime> get created =>
      $composableBuilder(column: $table.created, builder: (column) => column);
}

class $$BudgetAlertReceiptsTableTableManager
    extends
        RootTableManager<
          _$FinanceDatabase,
          $BudgetAlertReceiptsTable,
          BudgetAlertReceipt,
          $$BudgetAlertReceiptsTableFilterComposer,
          $$BudgetAlertReceiptsTableOrderingComposer,
          $$BudgetAlertReceiptsTableAnnotationComposer,
          $$BudgetAlertReceiptsTableCreateCompanionBuilder,
          $$BudgetAlertReceiptsTableUpdateCompanionBuilder,
          (
            BudgetAlertReceipt,
            BaseReferences<
              _$FinanceDatabase,
              $BudgetAlertReceiptsTable,
              BudgetAlertReceipt
            >,
          ),
          BudgetAlertReceipt,
          PrefetchHooks Function()
        > {
  $$BudgetAlertReceiptsTableTableManager(
    _$FinanceDatabase db,
    $BudgetAlertReceiptsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetAlertReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetAlertReceiptsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BudgetAlertReceiptsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<DateTime> created = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BudgetAlertReceiptsCompanion(
                key: key,
                created: created,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required DateTime created,
                Value<int> rowid = const Value.absent(),
              }) => BudgetAlertReceiptsCompanion.insert(
                key: key,
                created: created,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetAlertReceiptsTable, BudgetAlertReceipt>(
                    table,
                  ),
                  BaseReferences<
                    _$FinanceDatabase,
                    $BudgetAlertReceiptsTable,
                    BudgetAlertReceipt
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BudgetAlertReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$FinanceDatabase,
      $BudgetAlertReceiptsTable,
      BudgetAlertReceipt,
      $$BudgetAlertReceiptsTableFilterComposer,
      $$BudgetAlertReceiptsTableOrderingComposer,
      $$BudgetAlertReceiptsTableAnnotationComposer,
      $$BudgetAlertReceiptsTableCreateCompanionBuilder,
      $$BudgetAlertReceiptsTableUpdateCompanionBuilder,
      (
        BudgetAlertReceipt,
        BaseReferences<
          _$FinanceDatabase,
          $BudgetAlertReceiptsTable,
          BudgetAlertReceipt
        >,
      ),
      BudgetAlertReceipt,
      PrefetchHooks Function()
    >;

class $FinanceDatabaseManager {
  final _$FinanceDatabase _db;
  $FinanceDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$MovementsTableTableManager get movements =>
      $$MovementsTableTableManager(_db, _db.movements);
  $$SpendingLimitsTableTableManager get spendingLimits =>
      $$SpendingLimitsTableTableManager(_db, _db.spendingLimits);
  $$PreferencesTableTableManager get preferences =>
      $$PreferencesTableTableManager(_db, _db.preferences);
  $$DetectionReceiptsTableTableManager get detectionReceipts =>
      $$DetectionReceiptsTableTableManager(_db, _db.detectionReceipts);
  $$BudgetAlertReceiptsTableTableManager get budgetAlertReceipts =>
      $$BudgetAlertReceiptsTableTableManager(_db, _db.budgetAlertReceipts);
}
