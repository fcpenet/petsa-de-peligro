import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petsa/core/db/database.dart';
import 'package:petsa/features/accounts/data/account_repository.dart';
import 'package:petsa/features/budget/data/budget_repository.dart';
import 'package:petsa/features/templates/data/template_repository.dart';
import 'package:petsa/features/templates/domain/month_template.dart';

import '../../helpers/fake_turso.dart';
import '../../helpers/november.dart';
import '../../helpers/test_db.dart';

import 'package:petsa/core/db/turso/turso_database.dart';

void main() {
  late AppDatabase db;
  late NovemberIds ids;
  late TemplateRepository templates;
  late BudgetRepository budget;
  late String december;

  setUp(() async {
    db = createTestDatabase();
    ids = await seedNovember(db);
    templates = TemplateRepository(db);
    budget = BudgetRepository(db);
    december = (await budget.ensureMonth('2026-12')).id;
  });

  tearDown(() => db.close());

  test('saves a month as a template', () async {
    final id = await templates.saveFromMonth(
      monthId: ids.monthId,
      name: ' Monthly ',
    );
    final saved = (await templates.templates()).single;
    expect(saved.id, id);
    expect(saved.name, 'Monthly');
    final t = MonthTemplate.decode(saved.payload);
    expect(t.items.map((i) => i.name), contains('Misc'));
    expect(t.items.firstWhere((i) => i.name == 'Misc').children, isEmpty);
    expect(t.incomes.single.name, 'Salary');
  });

  test('saving with the same name replaces the template', () async {
    final first = await templates.saveFromMonth(
      monthId: ids.monthId,
      name: 'Monthly',
    );
    await budget.deleteItem(ids.items['QR']!);
    final second = await templates.saveFromMonth(
      monthId: ids.monthId,
      name: 'monthly',
    );
    expect(second, first);
    final t = MonthTemplate.decode(
      (await templates.templates()).single.payload,
    );
    expect(t.items.map((i) => i.name), isNot(contains('QR')));
  });

  test('refuses to save an empty month or a blank name', () async {
    expect(
      () => templates.saveFromMonth(monthId: december, name: 'Empty'),
      throwsA(isA<BudgetException>()),
    );
    expect(
      () => templates.saveFromMonth(monthId: ids.monthId, name: '  '),
      throwsA(isA<BudgetException>()),
    );
  });

  group('save from the editor', () {
    const template = MonthTemplate(
      items: [TemplateItem(name: 'Rent', amountCents: 2500000)],
      incomes: [TemplateIncome(name: 'Salary', amountCents: 9000000)],
    );

    test('creates, loads and updates a template', () async {
      final id = await templates.save(name: ' Lean ', template: template);
      var row = (await templates.template(id))!;
      expect(row.name, 'Lean');
      expect(MonthTemplate.decode(row.payload).items.single.name, 'Rent');

      final again = await templates.save(
        id: id,
        name: 'Lean month',
        template: const MonthTemplate(
          items: [TemplateItem(name: 'Food', amountCents: 1)],
        ),
      );
      expect(again, id);
      row = (await templates.template(id))!;
      expect(row.name, 'Lean month');
      expect(MonthTemplate.decode(row.payload).incomes, isEmpty);
      expect(await templates.templates(), hasLength(1));
    });

    test('a name used by another template is an error', () async {
      await templates.save(name: 'Lean', template: template);
      final other = await templates.save(name: 'Big', template: template);
      expect(
        () => templates.save(name: 'lean', template: template),
        throwsA(isA<BudgetException>()),
      );
      expect(
        () => templates.save(id: other, name: 'LEAN', template: template),
        throwsA(isA<BudgetException>()),
      );
      // Keeping your own name (in another case) is fine.
      await templates.save(id: other, name: 'BIG', template: template);
    });

    test('needs a name and some content', () async {
      expect(
        () => templates.save(name: ' ', template: template),
        throwsA(isA<BudgetException>()),
      );
      expect(
        () => templates.save(name: 'Empty', template: const MonthTemplate()),
        throwsA(isA<BudgetException>()),
      );
    });

    test('updating a deleted template fails', () async {
      final id = await templates.save(name: 'Lean', template: template);
      await templates.delete(id);
      expect(await templates.template(id), isNull);
      expect(
        () => templates.save(id: id, name: 'Lean', template: template),
        throwsA(isA<BudgetException>()),
      );
    });

    test('a template made from scratch fills a month', () async {
      final id = await templates.save(
        name: 'Scratch',
        template: MonthTemplate(
          items: [
            TemplateItem(
              name: 'Rent',
              amountCents: php(25000),
              accountId: ids.accounts['BPI'],
              dueDay: 5,
            ),
            TemplateItem(
              name: 'Misc',
              amountCents: php(2000),
              children: [
                TemplateItem(
                  name: 'Coffee',
                  amountCents: php(300),
                  accountId: ids.accounts['Cash'],
                ),
              ],
            ),
          ],
        ),
      );
      expect(
        await templates.applyTemplate(templateId: id, monthId: december),
        3,
      );
      final dec = await budget.itemsFor(december);
      final misc = dec.singleWhere((i) => i.name == 'Misc');
      expect(dec.singleWhere((i) => i.name == 'Coffee').parentId, misc.id);
      expect(dec.singleWhere((i) => i.name == 'Rent').dueDay, 5);
    });
  });

  test('applying fills an empty month with fresh, unpaid items', () async {
    final id = await templates.saveFromMonth(
      monthId: ids.monthId,
      name: 'Monthly',
      includeSubExpenses: true,
    );
    final created = await templates.applyTemplate(
      templateId: id,
      monthId: december,
    );

    final nov = await budget.itemsFor(ids.monthId);
    final dec = await budget.itemsFor(december);
    expect(created, nov.length);
    expect(dec.length, nov.length);
    expect(dec.every((i) => i.status == ItemStatus.allotted), isTrue);
    expect(dec.every((i) => i.paidAt == null), isTrue);
    // New rows, not moved ones.
    expect(
      dec.map((i) => i.id).toSet().intersection(nov.map((i) => i.id).toSet()),
      isEmpty,
    );

    final misc = dec.singleWhere((i) => i.name == 'Misc');
    final children = dec.where((i) => i.parentId == misc.id);
    expect(children.map((c) => c.name), ['dental pliers', 'sleeve']);
    expect(children.first.accountId, ids.accounts['JCB']);
    expect(
      dec.singleWhere((i) => i.name == 'Electric').accountId,
      ids.accounts['RCBC Card'],
    );
    expect(
      (await budget.incomesFor(december)).single.amountCents,
      php(242122.23),
    );

    // November is untouched.
    expect((await budget.item(ids.items['Basic']!)).status, ItemStatus.paid);
  });

  test('applying keeps the original order', () async {
    final id = await templates.saveFromMonth(
      monthId: ids.monthId,
      name: 'Monthly',
    );
    await templates.applyTemplate(templateId: id, monthId: december);
    final nov = (await budget.itemsFor(ids.monthId))
        .where((i) => i.parentId == null)
        .map((i) => i.name);
    final dec = (await budget.itemsFor(december)).map((i) => i.name);
    expect(dec, nov);
  });

  test('only empty months can be filled', () async {
    final id = await templates.saveFromMonth(
      monthId: ids.monthId,
      name: 'Monthly',
    );
    await budget.addIncome(monthId: december, name: 'Bonus', amountCents: 1);
    expect(
      () => templates.applyTemplate(templateId: id, monthId: december),
      throwsA(isA<BudgetException>()),
    );
  });

  test('archived accounts are dropped from applied items', () async {
    final id = await templates.saveFromMonth(
      monthId: ids.monthId,
      name: 'Monthly',
    );
    await AccountRepository(db)
        .setArchived(ids.accounts['UB']!, archived: true);
    await templates.applyTemplate(templateId: id, monthId: december);
    final pru = (await budget.itemsFor(december))
        .singleWhere((i) => i.name == 'Pru');
    expect(pru.accountId, isNull);
  });

  test('deleted templates disappear and cannot be applied', () async {
    final id = await templates.saveFromMonth(
      monthId: ids.monthId,
      name: 'Monthly',
    );
    await templates.delete(id);
    expect(await templates.templates(), isEmpty);
    expect(
      () => templates.applyTemplate(templateId: id, monthId: december),
      throwsA(isA<BudgetException>()),
    );
  });

  test(
    'copyMonth copies the previous month without saving a template',
    () async {
      final created = await templates.copyMonth(
        fromYearMonth: '2026-11',
        toMonthId: december,
      );
      expect(created, greaterThan(0));
      expect(await templates.templates(), isEmpty);
      final dec = await budget.itemsFor(december);
      expect(dec.where((i) => i.parentId != null), isEmpty);
      expect(dec.map((i) => i.name), contains('Electric'));
    },
  );

  test(
    'copyMonth returns 0 when the source month is missing or empty',
    () async {
      expect(
        await templates.copyMonth(
          fromYearMonth: '2020-01',
          toMonthId: december,
        ),
        0,
      );
      final jan = (await budget.ensureMonth('2027-01')).id;
      expect(
        await templates.copyMonth(fromYearMonth: '2026-12', toMonthId: jan),
        0,
      );
    },
  );

  test('applying over Turso is one read plus one batch', () async {
    final server = FakeTursoServer();
    addTearDown(server.dispose);
    final remote = AppDatabase(
      TursoDatabase(
        url: 'libsql://x.turso.io',
        authToken: 'test-token',
        httpClient: server.client,
      ),
    );
    addTearDown(remote.close);
    final remoteIds = await seedNovember(remote);
    final repo = TemplateRepository(remote);
    final id = await repo.saveFromMonth(
      monthId: remoteIds.monthId,
      name: 'Monthly',
      includeSubExpenses: true,
    );
    final dec = (await BudgetRepository(remote).ensureMonth('2026-12')).id;

    server.requests.clear();
    await repo.applyTemplate(templateId: id, monthId: dec);
    // template lookup, (counts ‖ accounts), BEGIN+batch, COMMIT
    expect(server.requestCount, 5);
  });

  test('upgrades a version 1 database to the current schema', () async {
    final legacy = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(
            'CREATE TABLE months (id TEXT NOT NULL PRIMARY KEY, '
            'updated_at INTEGER NOT NULL, deleted_at INTEGER, '
            'year_month TEXT NOT NULL UNIQUE)',
          );
          raw.execute("INSERT INTO months VALUES ('m1', 0, NULL, '2026-10')");
          raw.execute(
            'CREATE TABLE items (id TEXT NOT NULL PRIMARY KEY, '
            'updated_at INTEGER NOT NULL, deleted_at INTEGER, '
            'month_id TEXT NOT NULL, parent_id TEXT, account_id TEXT, '
            'name TEXT NOT NULL, amount_cents INTEGER NOT NULL, '
            "kind TEXT NOT NULL DEFAULT 'expense', "
            "status TEXT NOT NULL DEFAULT 'allotted', paid_at INTEGER, "
            'due_day INTEGER, note TEXT, '
            'sort_order INTEGER NOT NULL DEFAULT 0)',
          );
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    addTearDown(legacy.close);
    expect(await TemplateRepository(legacy).templates(), isEmpty);
    expect((await BudgetRepository(legacy).findMonth('2026-10'))?.id, 'm1');
    final version = await legacy
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.data.values.single, 4);
  });
}
