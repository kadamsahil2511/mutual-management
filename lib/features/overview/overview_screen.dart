import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/calculations.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../funds/reference_data.dart';
import '../plans/user_models.dart';

class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributions = ref.watch(contributionsProvider);
    final goals = ref.watch(goalsProvider);
    final sips = ref.watch(sipsProvider);
    final width = MediaQuery.sizeOf(context).width;
    if (isMobileLayout(context)) {
      return _MobileDashboard(
        contributions: contributions,
        goals: goals,
        sips: sips,
        ref: ref,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = isMobileLayout(context);
        final tablet =
            !compact &&
            constraints.maxWidth >= 640 &&
            constraints.maxWidth < 1024;
        final padding = compact
            ? 16.0
            : tablet
            ? 24.0
            : 32.0;
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HeroBand(
                width: width,
                compact: compact,
                padding: padding,
                contributions: contributions,
                ref: ref,
              ),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      padding,
                      compact ? 48 : 80,
                      padding,
                      compact ? 56 : 96,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _GoalsSection(
                          state: goals,
                          contributions: contributions,
                        ),
                        SizedBox(height: compact ? 48 : 80),
                        _SipSection(state: sips, contributions: contributions),
                        SizedBox(height: compact ? 48 : 80),
                        const SectionTitle('A clear place to begin.'),
                        ResponsiveGrid(
                          maxColumns: 3,
                          minWidth: 240,
                          children: [
                            _ActionCard(
                              title: 'Explore funds',
                              body: 'Review published NAV, dated costs, source information, and available disclosures.',
                              label: 'Browse the catalogue',
                              route: '/funds',
                            ),
                            _ActionCard(
                              title: 'Create a goal',
                              body: 'Set a target and date, then explore a monthly plan with assumptions clearly shown.',
                              label: 'Plan a goal',
                              route: '/plans',
                            ),
                            _ActionCard(
                              title: 'Learn the basics',
                              body: 'Build context on risk, diversification, and how mutual funds work.',
                              label: 'Visit learning',
                              route: '/learn',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MobileDashboard extends StatelessWidget {
  const _MobileDashboard({
    required this.contributions,
    required this.goals,
    required this.sips,
    required this.ref,
  });
  final AsyncValue<List<Contribution>> contributions;
  final AsyncValue<List<Goal>> goals;
  final AsyncValue<List<Sip>> sips;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final items = contributions.value ?? const <Contribution>[];
    final codes = items.map((item) => item.schemeCode).toSet();
    final navs = {
      for (final code in codes) code: ref.watch(fundProvider(code)),
    };
    final complete =
        contributions.hasValue &&
        codes.every(
          (code) =>
              navs[code]!.hasValue && navs[code]!.value!.history.isNotEmpty,
        );
    final value = complete
        ? items.fold<double>(
            0,
            (sum, item) =>
                sum + item.units * navs[item.schemeCode]!.value!.latest.nav,
          )
        : 0.0;
    final invested =
        items.fold<int>(0, (sum, item) => sum + item.amountPaise) / 100;
    final gain = complete ? value - invested : null;
    final goalsList = goals.value ?? const <Goal>[];
    final sipsList =
        (sips.value ?? const <Sip>[]).where((sip) => sip.isActive).toList()
          ..sort(
            (a, b) => _nextSipDate(a, items).compareTo(_nextSipDate(b, items)),
          );
    final next = sipsList.isEmpty ? null : sipsList.first;
    final nextDate = next == null
        ? null
        : _nextSipDate(next, contributions.value ?? const []);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Good ${_timeGreeting()},',
            style: const TextStyle(color: AppColors.body, fontSize: 14),
          ),
          const SizedBox(height: 2),
          const Text(
            'Your money, in view.',
            style: TextStyle(
              fontSize: 27,
              height: 1.15,
              fontWeight: FontWeight.w400,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            color: AppColors.dark,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SmallLabel('SIMULATED PORTFOLIO', dark: true),
                const SizedBox(height: 6),
                Text(
                  contributions.isLoading
                      ? 'Loading…'
                      : contributions.hasError || !complete
                      ? 'Unavailable'
                      : money(value),
                  style: numberStyle(size: 28, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  items.isEmpty
                      ? 'No contributions recorded'
                      : complete
                      ? 'Based on latest published NAV'
                      : 'Latest NAV unavailable for a complete value',
                  style: const TextStyle(
                    color: AppColors.onDarkSoft,
                    fontSize: 13,
                  ),
                ),
                if (gain != null && items.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Change vs recorded contributions  ${gain >= 0 ? '+' : ''}${money(gain)}',
                    style: const TextStyle(
                      color: AppColors.onDarkSoft,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (items.isEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Practise with a contribution. No money is moved.',
                    style: TextStyle(color: AppColors.onDarkSoft, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _QuickAction(
                'Add simulation',
                Icons.add_rounded,
                '/portfolio/add',
              ),
              _QuickAction('New goal', Icons.flag_outlined, '/plans/goal/new'),
              _QuickAction('Find funds', Icons.search_rounded, '/funds'),
            ],
          ),
          const SizedBox(height: 18),
          if (goals.isLoading)
            const Text(
              'Loading goal progress…',
              style: TextStyle(color: AppColors.body),
            )
          else if (goals.hasError)
            TextButton(
              onPressed: () => ref.invalidate(goalsProvider),
              child: const Text('Retry goal progress'),
            )
          else if (goalsList.isEmpty)
            AppCard(
              color: AppColors.soft,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'No goals yet. Set a target for something that matters.',
                      style: TextStyle(color: AppColors.ink),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/plans/goal/new'),
                    child: const Text('Create'),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              'Goal progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            for (final goal in goalsList.take(2))
              _CompactGoal(goal: goal, contributions: items),
          ],
          const SizedBox(height: 8),
          if (sips.isLoading)
            const Text(
              'Loading upcoming plans…',
              style: TextStyle(color: AppColors.body),
            )
          else if (sips.hasError)
            TextButton(
              onPressed: () => ref.invalidate(sipsProvider),
              child: const Text('Retry upcoming plans'),
            )
          else if (next == null)
            AppCard(
              color: AppColors.soft,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'No upcoming SIPs. Create a schedule when you are ready.',
                      style: TextStyle(color: AppColors.ink),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push('/plans/sip/new'),
                    child: const Text('Plan'),
                  ),
                ],
              ),
            )
          else
            AppCard(
              color: AppColors.soft,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Next planned SIP',
                          style: TextStyle(color: AppColors.body, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          fundCatalog
                                  .where(
                                    (fund) =>
                                        fund.schemeCode == next.schemeCode,
                                  )
                                  .firstOrNull
                                  ?.name ??
                              'Scheme ${next.schemeCode}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${money(next.amountPaise / 100)} · ${dateLabel(nextDate!)}',
                          style: const TextStyle(
                            color: AppColors.body,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/plans?section=sips'),
                    child: const Text('Plans'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final String route;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () => context.push(route),
    icon: Icon(icon, size: 18),
    label: Text(label),
  );
}

class _CompactGoal extends StatelessWidget {
  const _CompactGoal({required this.goal, required this.contributions});
  final Goal goal;
  final List<Contribution> contributions;
  @override
  Widget build(BuildContext context) {
    final amount = contributions
        .where((item) => item.goalId == goal.id)
        .fold<int>(0, (sum, item) => sum + item.amountPaise);
    final progress = goal.targetPaise <= 0
        ? 0.0
        : (amount / goal.targetPaise).clamp(0, 1).toDouble();
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  goal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(color: AppColors.body),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, minHeight: 4),
          const SizedBox(height: 5),
          Text(
            '${money(amount / 100)} of ${money(goal.targetPaise / 100)} · ${dateLabel(goal.targetDate)}',
            style: const TextStyle(color: AppColors.body, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

DateTime _nextSipDate(Sip sip, List<Contribution> contributions) {
  var index = 0;
  var date = installmentDate(sip.startDate, index, sip.intervalMonths);
  final today = DateTime.now();
  while (date.isBefore(DateTime(today.year, today.month, today.day)) ||
      contributions.any((item) => item.id == installmentId(sip.id, date))) {
    date = installmentDate(sip.startDate, ++index, sip.intervalMonths);
    if (index > 1200) break;
  }
  return date;
}

String _timeGreeting() {
  final hour = DateTime.now().hour;
  return hour < 12
      ? 'morning'
      : hour < 17
      ? 'afternoon'
      : 'evening';
}

class _HeroBand extends StatelessWidget {
  const _HeroBand({
    required this.width,
    required this.compact,
    required this.padding,
    required this.contributions,
    required this.ref,
  });
  final double width;
  final bool compact;
  final double padding;
  final AsyncValue<List<Contribution>> contributions;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final desktop = width >= 1024 && !compact;
    final stackReserve = width < 1200 ? 148.0 : 76.0;
    final fontSize = compact
        ? 40.0
        : desktop
        ? 80.0
        : 64.0;
    final navCodes =
        contributions.value?.map((c) => c.schemeCode).toSet().toList() ??
        const <String>[];
    final navValues = {
      for (final code in navCodes) code: ref.watch(fundProvider(code)),
    };
    final valueReady =
        contributions.hasValue &&
        navCodes.every(
          (code) =>
              navValues[code]!.hasValue &&
              navValues[code]!.value!.history.isNotEmpty,
        );
    double portfolio = 0;
    if (valueReady) {
      final data = {for (final code in navCodes) code: navValues[code]!.value!};
      for (final c in contributions.value ?? const <Contribution>[]) {
        portfolio += c.units * data[c.schemeCode]!.latest.nav;
      }
    }
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SmallLabel('Mutual Management', dark: true),
        const SizedBox(height: 20),
        Text(
          'A calmer way\nto plan ahead.',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w400,
            height: 1.02,
            letterSpacing: compact ? -1 : -2,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Your goals and investments, grounded in published data and the choices you make.',
          style: TextStyle(
            color: AppColors.onDarkSoft,
            fontSize: 16,
            height: 1.6,
          ),
        ),
        if (desktop) ...[
          const SizedBox(height: 28),
          _HeroActions(
            onPlans: () => context.go('/plans'),
            onFunds: () => context.go('/funds'),
          ),
        ],
      ],
    );
    final portfolioCard = _PortfolioCard(
      state: contributions,
      valueReady: valueReady,
      portfolio: portfolio,
      ref: ref,
    );
    final nextStep = AppCard(
      color: AppColors.darkElevated,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SmallLabel('Your next step', dark: true),
          const SizedBox(height: 8),
          const Text(
            'Make a plan that starts with what matters to you.',
            style: TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/plans'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Plan a goal'),
          ),
        ],
      ),
    );

    final content = desktop
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 52, child: heading),
              const SizedBox(width: 40),
              Expanded(
                flex: 48,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(bottom: stackReserve),
                      child: portfolioCard,
                    ),
                    Positioned(
                      right: 24,
                      bottom: 0,
                      width: 276,
                      child: nextStep,
                    ),
                  ],
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              heading,
              const SizedBox(height: 28),
              AppCard(
                color: AppColors.darkElevated,
                padding: EdgeInsets.all(compact ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    portfolioCard,
                    const SizedBox(height: 16),
                    _HeroActions(
                      onPlans: () => context.go('/plans'),
                      onFunds: () => context.go('/funds'),
                    ),
                  ],
                ),
              ),
            ],
          );

    return Container(
      color: AppColors.dark,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              padding,
              compact
                  ? 36
                  : desktop
                  ? 64
                  : 56,
              padding,
              compact
                  ? 40
                  : desktop
                  ? 64
                  : 56,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _HeroActions extends StatelessWidget {
  const _HeroActions({required this.onPlans, required this.onFunds});
  final VoidCallback onPlans;
  final VoidCallback onFunds;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 12,
    runSpacing: 12,
    children: [
      FilledButton(onPressed: onPlans, child: const Text('Start with a goal')),
      OutlinedButton(
        onPressed: onFunds,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppColors.onDarkSoft),
        ),
        child: const Text('Explore funds'),
      ),
    ],
  );
}

class _PortfolioCard extends StatelessWidget {
  const _PortfolioCard({
    required this.state,
    required this.valueReady,
    required this.portfolio,
    required this.ref,
  });
  final AsyncValue<List<Contribution>> state;
  final bool valueReady;
  final double portfolio;
  final WidgetRef ref;
  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.darkElevated,
    padding: const EdgeInsets.all(20),
    child: state.when(
      loading: () =>
          const LoadingState(message: 'Loading recorded contributions…'),
      error: (error, stack) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SmallLabel('Portfolio value', dark: true),
          const SizedBox(height: 8),
          const Text(
            'Value unavailable',
            style: TextStyle(color: Colors.white, fontSize: 22),
          ),
          TextButton(
            onPressed: () => ref.invalidate(contributionsProvider),
            child: const Text('Retry'),
          ),
        ],
      ),
      data: (items) {
        if (items.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SmallLabel('Portfolio value', dark: true),
              const SizedBox(height: 8),
              Text(money(0), style: numberStyle(size: 28, color: Colors.white)),
              const SizedBox(height: 8),
              const Text(
                'No contributions recorded yet. This value will use your recorded units and latest published NAV.',
                style: TextStyle(color: AppColors.onDarkSoft, height: 1.5),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.go('/portfolio'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('View portfolio'),
              ),
            ],
          );
        }
        if (!valueReady) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SmallLabel('Portfolio value', dark: true),
              const SizedBox(height: 8),
              const Text(
                'Value unavailable',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 8),
              const Text(
                'A latest NAV is missing for one or more recorded schemes, so a complete value cannot be shown.',
                style: TextStyle(color: AppColors.onDarkSoft, height: 1.5),
              ),
              TextButton(
                onPressed: () {
                  for (final code
                      in items.map((item) => item.schemeCode).toSet()) {
                    _refreshFund(ref, code);
                  }
                },
                child: const Text('Retry NAV data'),
              ),
            ],
          );
        }
        final latestDates =
            items
                .map(
                  (item) => ref
                      .read(fundProvider(item.schemeCode))
                      .value!
                      .latest
                      .date,
                )
                .toSet()
                .toList()
              ..sort();
        final asOf = latestDates.length == 1
            ? dateLabel(latestDates.single)
            : 'Multiple NAV dates';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SmallLabel('Portfolio value', dark: true),
            const SizedBox(height: 8),
            Text(
              money(portfolio),
              style: numberStyle(size: 28, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Based on recorded units · NAV $asOf',
              style: const TextStyle(color: AppColors.onDarkSoft, height: 1.5),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/portfolio'),
              child: const Text('Open portfolio'),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _refreshFund(WidgetRef ref, String code) async {
  try {
    await ref.read(fundRepositoryProvider).fetchFund(code, forceRefresh: true);
  } catch (_) {
    // The invalidated provider displays the repository's normal error state.
  }
  ref.invalidate(fundProvider(code));
}

class _GoalsSection extends ConsumerWidget {
  const _GoalsSection({required this.state, required this.contributions});
  final AsyncValue<List<Goal>> state;
  final AsyncValue<List<Contribution>> contributions;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SectionTitle(
        'Progress toward your goals.',
        subtitle: 'Progress reflects contributions assigned to each goal. It does not include estimated investment growth.',
      ),
      state.when(
        loading: () => const LoadingState(message: 'Loading goals…'),
        error: (e, s) => ErrorState(
          message: 'Your goals could not be loaded.',
          onRetry: () => ref.invalidate(goalsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              title: 'No goals yet',
              message: 'Give your plan a purpose with a target and a date.',
              action: FilledButton(
                onPressed: () => context.go('/plans'),
                child: const Text('Create a goal'),
              ),
            );
          }
          if (contributions.hasError) {
            return const AppCard(
              child: Text(
                'Goal progress unavailable while contributions are loading.',
                style: TextStyle(color: AppColors.body),
              ),
            );
          }
          final records = contributions.value ?? const <Contribution>[];
          return ResponsiveGrid(
            maxColumns: 3,
            minWidth: 230,
            children: [
              for (final goal in items)
                _GoalCard(
                  goal: goal,
                  amount: records
                      .where((c) => c.goalId == goal.id)
                      .fold<int>(0, (sum, c) => sum + c.amountPaise),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.amount});
  final Goal goal;
  final int amount;
  @override
  Widget build(BuildContext context) {
    final progress = goal.targetPaise <= 0
        ? 0.0
        : (amount / goal.targetPaise).clamp(0, 1).toDouble();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            goal.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Text(
            '${money(amount / 100)} contributed of ${money(goal.targetPaise / 100)}',
            style: const TextStyle(color: AppColors.body, height: 1.5),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 12),
          Text(
            'Target date · ${dateLabel(goal.targetDate)} · ${(progress * 100).toStringAsFixed(0)}% of target contributed',
            style: const TextStyle(
              color: AppColors.body,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SipSection extends ConsumerWidget {
  const _SipSection({required this.state, required this.contributions});
  final AsyncValue<List<Sip>> state;
  final AsyncValue<List<Contribution>> contributions;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SectionTitle(
        'Your upcoming contributions.',
        subtitle: 'Schedule dates are shown as plans. No payment is collected or investment executed automatically.',
      ),
      state.when(
        loading: () => const LoadingState(message: 'Loading plans…'),
        error: (e, s) => ErrorState(
          message: 'Your planned contributions could not be loaded.',
          onRetry: () => ref.invalidate(sipsProvider),
        ),
        data: (sips) {
          final active = sips.where((sip) => sip.isActive).toList();
          if (active.isEmpty) {
            return EmptyState(
              title: 'No active plans',
              message: 'A monthly or quarterly plan can help you set a regular contribution intention.',
              action: FilledButton(
                onPressed: () => context.go('/plans'),
                child: const Text('Explore a plan'),
              ),
            );
          }
          if (contributions.hasError) {
            return const AppCard(
              child: Text(
                'Upcoming schedule unavailable while recorded contributions are loading.',
                style: TextStyle(color: AppColors.body),
              ),
            );
          }
          final recorded = contributions.value ?? const <Contribution>[];
          final today = DateTime.now();
          final upcoming = <({Sip sip, DateTime date})>[];
          for (final sip in active) {
            var index = 0;
            var date = installmentDate(
              sip.startDate,
              index,
              sip.intervalMonths,
            );
            while (date.isBefore(
                  DateTime(today.year, today.month, today.day),
                ) ||
                recorded.any(
                  (item) => item.id == installmentId(sip.id, date),
                )) {
              index++;
              date = installmentDate(sip.startDate, index, sip.intervalMonths);
              if (index > 1200) break;
            }
            upcoming.add((sip: sip, date: date));
          }
          upcoming.sort((a, b) => a.date.compareTo(b.date));
          return Column(
            children: [
              for (final entry in upcoming)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    color: AppColors.soft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fundCatalog
                                        .where(
                                          (f) =>
                                              f.schemeCode ==
                                              entry.sip.schemeCode,
                                        )
                                        .firstOrNull
                                        ?.name ??
                                    'Scheme ${entry.sip.schemeCode}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Planned date · ${dateLabel(entry.date)}',
                                style: const TextStyle(color: AppColors.body),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          money(entry.sip.amountPaise / 100),
                          style: numberStyle(size: 16),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.body,
    required this.label,
    required this.route,
  });
  final String title, body, label, route;
  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.soft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.w400,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(body, style: const TextStyle(color: AppColors.body, height: 1.6)),
        const SizedBox(height: 16),
        TextButton(onPressed: () => context.go(route), child: Text(label)),
      ],
    ),
  );
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
