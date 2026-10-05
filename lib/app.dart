import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers.dart';
import 'core/theme.dart';
import 'core/widgets.dart';
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
import 'features/more/more_screen.dart';

GoRouter createRouter({String? initialLocation}) {
  GoRouter.optionURLReflectsImperativeAPIs = true;
  return GoRouter(
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
          GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
          GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
          GoRoute(path: '/about', builder: (_, _) => const AboutScreen()),
          GoRoute(
            path: '/calculators',
            builder: (_, _) => const CalculatorsScreen(),
          ),
          GoRoute(
            path: '/auth/reset',
            builder: (_, _) => const PasswordResetScreen(),
          ),
          GoRoute(
            path: '/plans/goal/new',
            builder: (_, _) => const GoalEditorScreen(),
          ),
          GoRoute(
            path: '/plans/goal/:id',
            builder: (_, s) => GoalEditorScreen(goalId: s.pathParameters['id']),
          ),
          GoRoute(
            path: '/plans/sip/new',
            builder: (_, s) =>
                SipEditorScreen(schemeCode: s.uri.queryParameters['scheme']),
          ),
          GoRoute(
            path: '/portfolio/add',
            builder: (_, s) => ContributionEditorScreen(
              schemeCode: s.uri.queryParameters['scheme'],
            ),
          ),
          GoRoute(
            path: '/portfolio/activity',
            builder: (_, _) => const ActivityScreen(),
          ),
          GoRoute(
            path: '/portfolio/activity/:id',
            builder: (_, s) => ContributionDetailScreen(
              contributionId: s.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/portfolio',
            builder: (_, s) =>
                PortfolioScreen(investCode: s.uri.queryParameters['invest']),
          ),
          GoRoute(
            path: '/plans',
            builder: (_, s) => PlansScreen(
              key: ValueKey(s.uri.queryParameters['section']),
              schemeCode: s.uri.queryParameters['scheme'],
              showSips: s.uri.queryParameters['section'] == 'sips',
            ),
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
}

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
    if (isMobileLayout(context)) {
      return _MobileShell(location: location, child: child);
    }
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

const _mobileDestinations = <(String, String, IconData, IconData)>[
  ('/', 'Home', Icons.home_outlined, Icons.home_rounded),
  ('/funds', 'Funds', Icons.search_rounded, Icons.search_rounded),
  ('/portfolio', 'Portfolio', Icons.pie_chart_outline, Icons.pie_chart),
  ('/plans', 'Plans', Icons.calendar_month_outlined, Icons.calendar_month),
  ('/more', 'More', Icons.grid_view_outlined, Icons.grid_view_rounded),
];

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.location, required this.child});
  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rootIndex = _mobileDestinations.indexWhere(
      (item) => item.$1 == location,
    );
    final isRoot = rootIndex >= 0;
    final title = switch (location) {
      '/' => 'Mutual Management',
      '/funds' => 'Discover',
      '/portfolio' => 'Portfolio',
      '/plans' => 'Plans',
      '/more' => 'More',
      '/account' => 'Account',
      '/auth' => 'Welcome',
      '/auth/reset' => 'Reset password',
      '/calculators' => 'Calculators',
      '/learn' => 'Learn',
      '/deposits' => 'Fixed deposits',
      '/portfolio/add' => 'Add simulation',
      '/portfolio/activity' => 'Activity',
      '/plans/goal/new' => 'New goal',
      '/plans/sip/new' => 'New SIP',
      '/compare' => 'Compare funds',
      '/risk' => 'Risk comfort',
      '/about' => 'About',
      _ =>
        location.startsWith('/funds/')
            ? 'Fund details'
            : location.startsWith('/learn/')
            ? 'Learn'
            : location.startsWith('/portfolio/activity/')
            ? 'Contribution'
            : 'Edit goal',
    };
    final fallback = location.startsWith('/plans/')
        ? '/plans'
        : location.startsWith('/portfolio/activity/')
        ? '/portfolio/activity'
        : location.startsWith('/portfolio/')
        ? '/portfolio'
        : location.startsWith('/funds/') ||
              location == '/compare' ||
              location == '/risk'
        ? '/funds'
        : location.startsWith('/learn/')
        ? '/learn'
        : location == '/auth/reset'
        ? '/auth'
        : '/more';
    return Scaffold(
      backgroundColor: AppColors.soft,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: isRoot
            ? null
            : BackButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(fallback);
                  }
                },
              ),
        title: Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        titleSpacing: isRoot ? 20 : 0,
        toolbarHeight: 60,
        backgroundColor: AppColors.soft,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        actions: isRoot
            ? [
                IconButton(
                  tooltip: 'Your account',
                  onPressed: () => context.push('/account'),
                  icon: const Icon(Icons.account_circle_outlined),
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: SafeArea(top: false, child: child),
      bottomNavigationBar:
          isRoot && MediaQuery.viewInsetsOf(context).bottom == 0
          ? DecoratedBox(
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.hairline)),
              ),
              child: NavigationBar(
                selectedIndex: rootIndex,
                onDestinationSelected: (index) {
                  if (index != rootIndex) {
                    context.go(_mobileDestinations[index].$1);
                  }
                },
                height: 72,
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                indicatorColor: AppColors.primary.withValues(alpha: .1),
                elevation: 0,
                labelTextStyle: const WidgetStatePropertyAll(
                  TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                destinations: [
                  for (final item in _mobileDestinations)
                    NavigationDestination(
                      key: ValueKey('nav-${item.$1}'),
                      icon: Icon(item.$3, color: AppColors.body),
                      selectedIcon: Icon(item.$4, color: AppColors.primary),
                      label: item.$2,
                      tooltip: item.$2,
                    ),
                ],
              ),
            )
          : null,
    );
  }
}
