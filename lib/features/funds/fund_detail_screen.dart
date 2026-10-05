import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'fund_models.dart';
import 'reference_data.dart';

class FundDetailScreen extends ConsumerWidget {
  const FundDetailScreen({super.key, required this.schemeCode});
  final String schemeCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reference = fundCatalog
        .where((item) => item.schemeCode == schemeCode)
        .firstOrNull;
    if (reference == null) {
      return PageFrame(
        title: 'Fund unavailable',
        subtitle: 'This scheme code is not in the published catalogue.',
        children: [
          FilledButton(
            onPressed: () => context.go('/funds'),
            child: const Text('Browse funds'),
          ),
        ],
      );
    }
    final nav = ref.watch(fundProvider(schemeCode));
    return PageFrame(
      title: reference.name,
      subtitle:
          '${reference.amc} · ${reference.category} · Scheme code ${reference.schemeCode}',
      action: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton(
            onPressed: () => context.go('/plans?scheme=$schemeCode'),
            child: const Text('Plan a SIP'),
          ),
          OutlinedButton(
            onPressed: () => context.go('/portfolio?invest=$schemeCode'),
            child: const Text('Record a contribution'),
          ),
        ],
      ),
      children: [
        nav.when(
          loading: () =>
              const LoadingState(message: 'Getting published NAV history…'),
          error: (error, stack) => ErrorState(
            message: 'Published NAV history could not be loaded. Reference details remain available below.',
            onRetry: () => _refreshFund(ref, schemeCode),
          ),
          data: (data) => data.history.isEmpty
              ? _NavUnavailable(onRetry: () => _refreshFund(ref, schemeCode))
              : _NavSummary(data: data),
        ),
        const SizedBox(height: 32),
        const SectionTitle(
          'Fund reference',
          subtitle: 'Scheme information is shown with its source date. Unpublished fields remain unavailable.',
        ),
        ResponsiveGrid(
          maxColumns: 3,
          minWidth: 210,
          children: [
            Metric(label: 'AMC', value: reference.amc),
            Metric(label: 'Category', value: reference.category),
            Metric(
              label: 'Reference date',
              value: dateLabel(reference.asOfDate),
            ),
            Metric(
              label: 'Expense ratio',
              value: reference.expenseRatioPct == null
                  ? 'Unavailable'
                  : '${reference.expenseRatioPct!.toStringAsFixed(2)}%',
              note:
                  '${reference.expenseBasis ?? 'Basis unavailable'} · ${dateLabel(reference.asOfDate)} · ${_categoryAverage(reference)}',
            ),
            Metric(
              label: 'Assets under management',
              value: reference.aumCrore == null
                  ? 'Unavailable'
                  : '₹${reference.aumCrore!.toStringAsFixed(2)} crore',
            ),
            Metric(
              label: reference.minSipPaise == null
                  ? 'Minimum SIP'
                  : 'Minimum monthly SIP',
              value: reference.minSipPaise == null
                  ? 'Unavailable'
                  : money(reference.minSipPaise! / 100),
              note: reference.minSipPaise == null
                  ? null
                  : 'Minimum monthly instalment · ${dateLabel(reference.minimumAsOfDate ?? reference.asOfDate)}',
            ),
            Metric(
              label: 'Minimum lump sum',
              value: reference.minLumpSumPaise == null
                  ? 'Unavailable'
                  : money(reference.minLumpSumPaise! / 100),
              note: reference.minLumpSumPaise == null
                  ? null
                  : 'Source date · ${dateLabel(reference.minimumAsOfDate ?? reference.asOfDate)}',
            ),
            Metric(
              label: 'Fund manager',
              value: reference.manager ?? 'Unavailable',
              note: reference.managerExperience,
            ),
            Metric(
              label: 'Other funds managed',
              value: reference.managerOtherFunds.isEmpty
                  ? 'Unavailable'
                  : reference.managerOtherFunds.join(', '),
            ),
          ],
        ),
        if (reference.minSipPaise != null || reference.minLumpSumPaise != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: SourceLink(
              label:
                  'Minimum investment source · ${dateLabel(reference.minimumAsOfDate ?? reference.asOfDate)}',
              url: reference.minimumSourceUrl ?? reference.sourceUrl,
            ),
          ),
        const SizedBox(height: 32),
        SectionTitle(
          'Returns and benchmark',
          subtitle: reference.benchmarkName == null
              ? 'NAV-derived returns use available published observations. A dated benchmark series is unavailable.'
              : 'NAV-derived returns use the latest available observation. Dated benchmark figures use the reference date shown below.',
        ),
        _DatedReturns(reference: reference),
        const SizedBox(height: 32),
        const SectionTitle(
          'Portfolio disclosure',
          subtitle: 'Holdings are not inferred from NAV history. Missing disclosure is kept visible.',
        ),
        _Holdings(reference: reference),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.only(top: 20),
          child: Text(
            'Mutual fund investments are subject to market risks. Read all scheme related documents carefully. Returns are historical and do not assure future performance.',
            style: TextStyle(color: AppColors.body, fontSize: 13, height: 1.7),
          ),
        ),
      ],
    );
  }
}

Future<void> _refreshFund(WidgetRef ref, String code) async {
  try {
    await ref.read(fundRepositoryProvider).fetchFund(code, forceRefresh: true);
  } catch (_) {
    // The invalidated provider presents the repository's normal error state.
  }
  ref.invalidate(fundProvider(code));
}

String _categoryAverage(FundReference reference) {
  final funds = fundCatalog
      .where((item) => item.category == reference.category)
      .toList();
  if (funds.length != 2 || funds.any((item) => item.expenseRatioPct == null)) {
    return 'Selected-category average · ${funds.length} funds · Unavailable';
  }
  final bases = funds.map((item) => item.expenseBasis).toSet();
  if (bases.length != 1 || bases.single == null) {
    return 'Selected-category average · 2 funds · Unavailable: expense bases differ';
  }
  final values = funds.map((item) => item.expenseRatioPct!).toList();
  final average = values.reduce((a, b) => a + b) / values.length;
  return 'Selected-category average · ${values.length} funds · ${average.toStringAsFixed(2)}%';
}

class _NavUnavailable extends StatelessWidget {
  const _NavUnavailable({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.soft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Published NAV history is unavailable.',
          style: TextStyle(color: AppColors.body),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry NAV'),
        ),
      ],
    ),
  );
}

class _NavSummary extends StatelessWidget {
  const _NavSummary({required this.data});
  final FundData data;
  @override
  Widget build(BuildContext context) {
    final latest = data.latest;
    return AppCard(
      color: AppColors.dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SmallLabel('Published NAV', dark: true),
          const SizedBox(height: 8),
          Text(
            money(latest.nav, decimals: 4),
            style: numberStyle(size: 32, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            'Valuation date · ${dateLabel(latest.date)}',
            style: const TextStyle(color: AppColors.onDarkSoft),
          ),
          const SizedBox(height: 24),
          ResponsiveGrid(
            maxColumns: 3,
            minWidth: 170,
            children: [
              for (final years in [1, 3, 5])
                Metric(
                  label: years == 1
                      ? '1-year NAV return'
                      : '$years-year NAV CAGR',
                  value: percentLabel(data.returnYears(years)),
                  note: 'Calculated from NAV history',
                  color: data.returnYears(years) == null
                      ? AppColors.onDarkSoft
                      : (data.returnYears(years)! >= 0
                            ? AppColors.up
                            : AppColors.down),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${data.isCached ? 'Cached NAV' : 'NAV retrieved'} · ${dateLabel(data.fetchedAt)}${data.warning == null ? '' : ' · ${data.warning}'}',
            style: const TextStyle(
              color: AppColors.onDarkSoft,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DatedReturns extends StatelessWidget {
  const _DatedReturns({required this.reference});
  final FundReference reference;
  @override
  Widget build(BuildContext context) {
    final years = {
      ...reference.datedFundReturns.keys,
      ...reference.datedBenchmarkReturns.keys,
    }.toList()..sort();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reference date · ${dateLabel(reference.asOfDate)}',
            style: const TextStyle(color: AppColors.body),
          ),
          if (reference.benchmarkName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Benchmark · ${reference.benchmarkName}',
              style: const TextStyle(color: AppColors.body),
            ),
          ],
          const SizedBox(height: 16),
          if (years.isEmpty)
            const Text(
              'Dated fund and benchmark returns are unavailable.',
              style: TextStyle(color: AppColors.body),
            )
          else
            for (final year in years)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    Text(
                      year == 1 ? '1-year absolute return' : '$year-year CAGR',
                    ),
                    Text(
                      'Fund ${percentLabel(reference.datedFundReturns[year])}',
                    ),
                    Text(
                      '${reference.benchmarkName ?? 'Benchmark'} ${percentLabel(reference.datedBenchmarkReturns[year])}',
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _Holdings extends StatelessWidget {
  const _Holdings({required this.reference});
  final FundReference reference;
  @override
  Widget build(BuildContext context) {
    if (reference.holdings.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppCard(
            color: AppColors.soft,
            child: Text(
              'Holdings and sector allocation are unavailable in the current reference data.',
              style: TextStyle(color: AppColors.body),
            ),
          ),
          SourceLink(
            label:
                'Open portfolio factsheet · ${dateLabel(reference.holdingsDate ?? reference.asOfDate)}',
            url: reference.sourceUrl,
          ),
        ],
      );
    }
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reported coverage · ${reference.holdingsCoverage.toStringAsFixed(1)}%',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            'Holdings date · ${reference.holdingsDate == null ? 'Unavailable' : dateLabel(reference.holdingsDate!)} · ${reference.holdingsComplete ? 'Complete disclosure' : 'Partial disclosure'}',
            style: const TextStyle(color: AppColors.body, height: 1.6),
          ),
          const SizedBox(height: 16),
          for (final holding in reference.holdings)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Text(holding.name)),
                  Text('${holding.weight.toStringAsFixed(2)}%'),
                ],
              ),
            ),
          SourceLink(
            label:
                'Open portfolio factsheet · ${dateLabel(reference.holdingsDate ?? reference.asOfDate)}',
            url: reference.sourceUrl,
          ),
        ],
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
