import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/overview/overview_screen.dart';
import 'features/funds/funds_screen.dart';
import 'features/funds/fund_detail_screen.dart';
import 'features/funds/comparison_screen.dart';
import 'features/funds/risk_screen.dart';
import 'features/plans/plans_screen.dart';
import 'features/portfolio/portfolio_screen.dart';
import 'features/learn/learn_screen.dart';
import 'features/deposits/deposits_screen.dart';

GoRouter createRouter({String? initialLocation}) => GoRouter(
  initialLocation: initialLocation,
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('This page could not be found.'),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Back to overview'),
          ),
        ],
      ),
    ),
  ),
  routes: [
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(location: state.uri.path, child: child),
      routes: [
        GoRoute(path: '/', builder: (_, _) => const OverviewScreen()),
        GoRoute(path: '/funds', builder: (_, _) => const FundsScreen()),
        GoRoute(
          path: '/funds/:code',
          builder: (_, s) =>
              FundDetailScreen(schemeCode: s.pathParameters['code']!),
        ),
        GoRoute(
          path: '/compare',
          builder: (_, s) => ComparisonScreen(
            schemeCodes: (s.uri.queryParameters['codes'] ?? '')
                .split(',')
                .where((e) => e.isNotEmpty)
                .toList(),
          ),
        ),
        GoRoute(path: '/risk', builder: (_, _) => const RiskScreen()),
        GoRoute(
          path: '/portfolio',
          builder: (_, s) =>
              PortfolioScreen(investCode: s.uri.queryParameters['invest']),
        ),
        GoRoute(
          path: '/plans',
          builder: (_, s) =>
              PlansScreen(schemeCode: s.uri.queryParameters['scheme']),
        ),
        GoRoute(path: '/learn', builder: (_, _) => const LearnScreen()),
        GoRoute(
          path: '/learn/:id',
          builder: (_, s) => LearnScreen(articleId: s.pathParameters['id']),
        ),
        GoRoute(path: '/deposits', builder: (_, _) => const DepositsScreen()),
        GoRoute(
          path: '/auth',
          builder: (_, s) => AuthScreen(next: s.uri.queryParameters['next']),
        ),
      ],
    ),
  ],
);

class MutualManagementApp extends StatefulWidget {
  const MutualManagementApp({super.key, this.router});
  final GoRouter? router;
  @override
  State<MutualManagementApp> createState() => _MutualManagementAppState();
}

class _MutualManagementAppState extends State<MutualManagementApp> {
  late final _router = widget.router ?? createRouter();
  @override
  void dispose() {
    if (widget.router == null) _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'Mutual Management',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    routerConfig: _router,
  );
}

const _destinations = <(String, String, IconData)>[
  ('/', 'Overview', Icons.space_dashboard_outlined),
  ('/funds', 'Funds', Icons.search_rounded),
  ('/portfolio', 'Portfolio', Icons.pie_chart_outline),
  ('/plans', 'Plans', Icons.calendar_month_outlined),
  ('/learn', 'Learn', Icons.auto_stories_outlined),
  ('/deposits', 'Deposits', Icons.account_balance_outlined),
];

class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final compact =
        MediaQuery.sizeOf(context).width < 1050 ||
        MediaQuery.textScalerOf(context).scale(14) > 17;
    final verySmall = MediaQuery.sizeOf(context).width < 370;
    final largeText = MediaQuery.textScalerOf(context).scale(14) > 20;
    final iconAccount = largeText && MediaQuery.sizeOf(context).width < 640;
    Widget brand() => TextButton(
      onPressed: () => context.go('/'),
      child: Text(
        iconAccount
            ? 'Mutual'
            : verySmall
            ? 'Mutual\nManagement'
            : 'Mutual Management',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.1,
        ),
      ),
    );
    final account = user == null
        ? iconAccount
              ? IconButton(
                  tooltip: 'Sign in',
                  icon: const Icon(Icons.login),
                  onPressed: () => context.push(
                    '/auth?next=${Uri.encodeComponent(location)}',
                  ),
                )
              : FilledButton(
                  onPressed: () => context.push(
                    '/auth?next=${Uri.encodeComponent(location)}',
                  ),
                  child: const Text('Sign in'),
                )
        : IconButton(
            tooltip: 'Account and sign out',
            icon: const Icon(Icons.person_outline),
            onPressed: () async {
              final signOut = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Your account'),
                  content: Text(user.email ?? 'Signed in'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Close'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );
              if (signOut == true) {
                await ref.read(authRepositoryProvider).signOut();
              }
            },
          );
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: compact,
        backgroundColor: AppColors.canvas,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        toolbarHeight: verySmall ? 80 : 76,
        titleSpacing: compact ? 0 : 24,
        title: compact
            ? brand()
            : Row(
                children: [
                  brand(),
                  const Spacer(),
                  for (final destination in _destinations)
                    TextButton(
                      onPressed: () => context.go(destination.$1),
                      child: Text(
                        destination.$2,
                        style: TextStyle(
                          fontSize: 14,
                          color: location == destination.$1
                              ? AppColors.primary
                              : AppColors.ink,
                        ),
                      ),
                    ),
                ],
              ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: verySmall ? 8 : 24),
            child: account,
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      drawer: compact
          ? Drawer(
              child: SafeArea(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Mutual Management',
                        style: TextStyle(
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    for (final destination in _destinations)
                      ListTile(
                        leading: Icon(destination.$3),
                        title: Text(destination.$2),
                        selected: location == destination.$1,
                        minTileHeight: 56,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          context.go(destination.$1);
                        },
                      ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Learn with real data.\nPractice with simulated investments.',
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: SafeArea(top: false, child: child),
    );
  }
}
