import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../core/db/connection.dart';
import '../core/ui/adaptive.dart';
import '../features/accounts/ui/accounts_page.dart';
import '../features/budget/data/budget_repository.dart';
import '../features/budget/ui/budget_page.dart';
import '../features/sheet/ui/overview_page.dart';
import '../features/summary/domain/account_summary.dart' show DayRange;
import '../features/summary/ui/summary_page.dart';
import '../features/templates/ui/template_editor_page.dart';
import '../features/templates/ui/templates_page.dart';
import 'side_nav.dart';

GoRouter buildRouter({DateTime Function() clock = DateTime.now}) {
  String currentMonth() => BudgetRepository.yearMonthOf(clock());

  String? validMonth(GoRouterState state, String section) {
    final month = state.pathParameters['month']!;
    return BudgetRepository.isValidYearMonth(month)
        ? null
        : '/$section/${currentMonth()}';
  }

  return GoRouter(
    initialLocation: '/budget/${currentMonth()}',
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/budget/${currentMonth()}'),
      ShellRoute(
        builder: (context, state, child) => AppShell(
          location: state.uri.path,
          account: state.uri.queryParameters['account'],
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/budget/:month',
            redirect: (_, state) => validMonth(state, 'budget'),
            builder: (_, state) => BudgetPage(
              yearMonth: state.pathParameters['month']!,
              accountId: state.uri.queryParameters['account'],
            ),
          ),
          // Before '/summary/:month' so 'range' isn't taken for a month.
          GoRoute(
            path: '/summary/range',
            redirect: (_, state) => _parseRange(state) == null
                ? '/summary/${currentMonth()}'
                : null,
            builder: (_, state) =>
                SummaryPage.range(range: _parseRange(state)!),
          ),
          GoRoute(
            path: '/summary/:month',
            redirect: (_, state) => validMonth(state, 'summary'),
            builder: (_, state) =>
                SummaryPage(yearMonth: state.pathParameters['month']!),
          ),
          GoRoute(
            path: '/overview/:month',
            redirect: (_, state) => validMonth(state, 'overview'),
            builder: (_, state) =>
                OverviewPage(yearMonth: state.pathParameters['month']!),
          ),
          GoRoute(
            path: '/templates',
            builder: (_, _) => const TemplatesPage(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, _) => const TemplateEditorPage(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    TemplateEditorPage(templateId: state.pathParameters['id']),
              ),
            ],
          ),
          GoRoute(path: '/accounts', builder: (_, _) => const AccountsPage()),
        ],
      ),
      // Old links: '/2026-11' → the budget page for that month.
      GoRoute(
        path: '/:month',
        redirect: (_, state) {
          final month = state.pathParameters['month']!;
          return BudgetRepository.isValidYearMonth(month)
              ? '/budget/$month'
              : '/budget/${currentMonth()}';
        },
      ),
    ],
  );
}

/// `?from=YYYY-MM-DD&to=YYYY-MM-DD` → an inclusive day range, or null when
/// missing, malformed or backwards.
DayRange? _parseRange(GoRouterState state) {
  DateTime? day(String key) {
    final text = state.uri.queryParameters[key];
    if (text == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) {
      return null;
    }
    final d = DateTime.tryParse(text);
    return d == null ? null : DateTime(d.year, d.month, d.day);
  }

  final from = day('from');
  final to = day('to');
  if (from == null || to == null || to.isBefore(from)) return null;
  return (from: from, to: to);
}

/// Bottom navigation on phones; on wider screens a side menu that lists the
/// month's accounts under Budget.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.location,
    this.account,
    required this.child,
  });

  final String location;

  /// The Budget page's selected account, from `?account=`.
  final String? account;
  final Widget child;

  static const List<NavDestination> _destinations = [
    (icon: Icons.receipt_long, label: 'Budget', path: 'budget'),
    (icon: Icons.insights_outlined, label: 'Summary', path: 'summary'),
    (icon: Icons.table_chart_outlined, label: 'Overview', path: 'overview'),
    (icon: Icons.copy_all, label: 'Templates', path: 'templates'),
    (icon: Icons.account_balance_outlined, label: 'Accounts', path: 'accounts'),
  ];

  int get _index {
    final i = _destinations.indexWhere(
      (d) => location.startsWith('/${d.path}'),
    );
    return i < 0 ? 0 : i;
  }

  /// Keeps the month when switching between Budget, Summary and Overview.
  /// (Nested template routes like /templates/new aren't months, which the
  /// year-month check below rejects.)
  String _monthFromLocation() {
    final segments = Uri.parse(location).pathSegments;
    if (segments.length == 2 &&
        BudgetRepository.isValidYearMonth(segments[1])) {
      return segments[1];
    }
    return BudgetRepository.yearMonthOf(DateTime.now());
  }

  void _go(BuildContext context, int index) {
    final d = _destinations[index];
    context.go(switch (d.path) {
      'accounts' || 'templates' => '/${d.path}',
      _ => '/${d.path}/${_monthFromLocation()}',
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isNarrow(context)) {
      return Scaffold(
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => _go(context, i),
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                key: Key('nav-${d.path}'),
                icon: Icon(d.icon),
                label: d.label,
              ),
          ],
        ),
      );
    }
    final onBudget = location.startsWith('/budget/');
    return Scaffold(
      body: Row(
        children: [
          SideNav(
            destinations: _destinations,
            selectedIndex: _index,
            onSelect: (i) => _go(context, i),
            budgetMonth: onBudget ? _monthFromLocation() : null,
            selectedAccount: onBudget ? account : null,
            onAccount: (id) =>
                context.go(budgetLocation(_monthFromLocation(), id)),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}

final appTheme = ThemeData(
  colorSchemeSeed: const Color(0xFF1A73E8),
  brightness: Brightness.light,
);

final appDarkTheme = ThemeData(
  colorSchemeSeed: const Color(0xFF1A73E8),
  brightness: Brightness.dark,
);

class PetsaApp extends StatefulWidget {
  const PetsaApp({super.key, this.router});

  /// Injected in tests.
  final GoRouter? router;

  @override
  State<PetsaApp> createState() => _PetsaAppState();
}

class _PetsaAppState extends State<PetsaApp> {
  late final GoRouter _router = widget.router ?? buildRouter();

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && !hasTursoConfig) {
      return MaterialApp(
        theme: appTheme,
        home: const Scaffold(
          body: Center(
            child: Text(
              'Missing Turso settings. Run with '
              '--dart-define-from-file=.env.local',
            ),
          ),
        ),
      );
    }
    return MaterialApp.router(
      title: 'Petsa',
      theme: appTheme,
      darkTheme: appDarkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: _router,
    );
  }
}
