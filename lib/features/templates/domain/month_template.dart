import 'dart:convert';

import '../../../core/db/database.dart';

/// An item in a template. Amounts, accounts and structure only: applied
/// items always start allotted with no payment date.
class TemplateItem {
  const TemplateItem({
    required this.name,
    required this.amountCents,
    this.accountId,
    this.kind = ItemKind.expense,
    this.dueDay,
    this.note,
    this.isCollection = false,
    this.children = const [],
  });

  factory TemplateItem.fromJson(Map<String, Object?> json) => TemplateItem(
    name: json['name'] as String,
    amountCents: json['amountCents'] as int,
    accountId: json['accountId'] as String?,
    kind: ItemKind.values.asNameMap()[json['kind']] ?? ItemKind.expense,
    dueDay: json['dueDay'] as int?,
    note: json['note'] as String?,
    isCollection: json['collection'] as bool? ?? false,
    children: [
      for (final c in (json['children'] as List? ?? const []))
        TemplateItem.fromJson((c as Map).cast()),
    ],
  );

  final String name;
  final int amountCents;
  final String? accountId;
  final ItemKind kind;
  final int? dueDay;
  final String? note;

  /// Holds sub-expenses (like Misc); [amountCents] is then its budget.
  final bool isCollection;
  final List<TemplateItem> children;

  /// What this item adds to the month: a collection counts its budget or
  /// its sub-expenses, whichever is larger.
  int get plannedCents {
    if (!isCollection && children.isEmpty) return amountCents;
    final used = children.fold(0, (s, c) => s + c.amountCents);
    return used > amountCents ? used : amountCents;
  }

  TemplateItem copyWith({
    String? name,
    int? amountCents,
    String? Function()? accountId,
    ItemKind? kind,
    int? Function()? dueDay,
    String? Function()? note,
    bool? isCollection,
    List<TemplateItem>? children,
  }) => TemplateItem(
    name: name ?? this.name,
    amountCents: amountCents ?? this.amountCents,
    accountId: accountId == null ? this.accountId : accountId(),
    kind: kind ?? this.kind,
    dueDay: dueDay == null ? this.dueDay : dueDay(),
    note: note == null ? this.note : note(),
    isCollection: isCollection ?? this.isCollection,
    children: children ?? this.children,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'amountCents': amountCents,
    if (accountId != null) 'accountId': accountId,
    'kind': kind.name,
    if (dueDay != null) 'dueDay': dueDay,
    if (note != null) 'note': note,
    if (isCollection) 'collection': true,
    if (children.isNotEmpty) 'children': [for (final c in children) c.toJson()],
  };
}

class TemplateIncome {
  const TemplateIncome({
    required this.name,
    required this.amountCents,
    this.accountId,
  });

  factory TemplateIncome.fromJson(Map<String, Object?> json) => TemplateIncome(
    name: json['name'] as String,
    amountCents: json['amountCents'] as int,
    accountId: json['accountId'] as String?,
  );

  final String name;
  final int amountCents;
  final String? accountId;

  Map<String, Object?> toJson() => {
    'name': name,
    'amountCents': amountCents,
    if (accountId != null) 'accountId': accountId,
  };
}

class MonthTemplate {
  const MonthTemplate({this.items = const [], this.incomes = const []});

  factory MonthTemplate.fromJson(Map<String, Object?> json) {
    final version = json['version'] as int? ?? 1;
    if (version > currentVersion) {
      throw FormatException('Template version $version is newer than this app');
    }
    return MonthTemplate(
      items: [
        for (final i in (json['items'] as List? ?? const []))
          switch (TemplateItem.fromJson((i as Map).cast())) {
            // Version 1 had groups: top-level items without an account.
            final t when version < 2 =>
              t.accountId == null || t.children.isNotEmpty
                  ? t.copyWith(isCollection: true)
                  : t,
            final t => t,
          },
      ],
      incomes: [
        for (final i in (json['incomes'] as List? ?? const []))
          TemplateIncome.fromJson((i as Map).cast()),
      ],
    );
  }

  factory MonthTemplate.decode(String payload) =>
      MonthTemplate.fromJson((jsonDecode(payload) as Map).cast());

  static const currentVersion = 2;

  final List<TemplateItem> items;
  final List<TemplateIncome> incomes;

  bool get isEmpty => items.isEmpty && incomes.isEmpty;

  int get incomeCents => incomes.fold(0, (s, i) => s + i.amountCents);

  int get expenseCents => items.fold(0, (s, i) => s + i.plannedCents);

  /// Top-level items plus sub-expenses.
  int get itemCount => items.fold(0, (sum, i) => sum + 1 + i.children.length);

  Map<String, Object?> toJson() => {
    'version': currentVersion,
    'items': [for (final i in items) i.toJson()],
    'incomes': [for (final i in incomes) i.toJson()],
  };

  String encode() => jsonEncode(toJson());
}

/// Captures a month's structure.
///
/// [includeSubExpenses] keeps the items inside collections (e.g. individual
/// Misc purchases). Usually those are one-offs, so it defaults to false and
/// the collection itself (with its budget) is kept.
MonthTemplate templateFromMonth({
  required List<BudgetItem> items,
  required List<Income> incomes,
  bool includeSubExpenses = false,
  bool includeIncomes = true,
}) {
  final live = items.where((i) => i.deletedAt == null).toList()
    ..sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      return byOrder != 0 ? byOrder : a.name.compareTo(b.name);
    });

  TemplateItem convert(BudgetItem i, List<TemplateItem> children) =>
      TemplateItem(
        name: i.name,
        amountCents: i.amountCents,
        accountId: i.accountId,
        kind: i.kind,
        dueDay: i.dueDay,
        note: i.note,
        isCollection: i.isCollection,
        children: children,
      );

  return MonthTemplate(
    items: [
      for (final top in live.where((i) => i.parentId == null))
        convert(top, [
          if (includeSubExpenses)
            for (final c in live.where((c) => c.parentId == top.id))
              convert(c, const []),
        ]),
    ],
    incomes: [
      if (includeIncomes)
        for (final i in incomes.where((i) => i.deletedAt == null))
          TemplateIncome(
            name: i.name,
            amountCents: i.amountCents,
            accountId: i.accountId,
          ),
    ],
  );
}
