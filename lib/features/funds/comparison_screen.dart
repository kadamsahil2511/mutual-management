import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/calculations.dart';
import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'fund_models.dart';
import 'reference_data.dart';

class ComparisonScreen extends ConsumerWidget {
  const ComparisonScreen({super.key, required this.schemeCodes});
  final List<String> schemeCodes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unique = schemeCodes.toSet().toList();
    final refs = unique
        .map(
          (code) =>
              fundCatalog.where((item) => item.schemeCode == code).firstOrNull,
        )
        .toList();
    if (unique.length < 2 ||
        unique.length > 3 ||
        refs.any((item) => item == null)) {
      return PageFrame(
        title: 'Choose funds to compare',
        subtitle: 'Select two or three distinct schemes from the catalogue.',
        children: [
          EmptyState(
            title: 'Comparison needs 2–3 funds',
            message:
                'Return to the catalogue and select up to three known schemes.',
            action: FilledButton(
              onPressed: () => context.go('/funds'),
              child: const Text('Browse funds'),
            ),
          ),
        ],
      );
    }
    final known = refs.cast<FundReference>();
    final values = [
      for (final item in known) ref.watch(fundProvider(item.schemeCode)),
    ];
    final dated = known.map(_datedRows).toList();
    return PageFrame(
      title: 'Compare funds side by side.',
      subtitle: 'Review published scheme details and available NAV history. The comparison does not rank funds or recommend one.',
      children: [
        ResponsiveGrid(
          maxColumns: known.length,
          minWidth: 230,
          children: [
            for (final item in known)
              _FundColumn(reference: item, nav: values[known.indexOf(item)]),
          ],
        ),
        if (known.map((fund) => fund.expenseBasis).toSet().length > 1 ||
            known.any((fund) => fund.expenseBasis == null))
          const Padding(
            padding: EdgeInsets.only(top: 16),
            child: Text(
              'Expense ratio definitions differ or are unavailable; these figures may not be directly comparable.',
              style: TextStyle(color: AppColors.body, height: 1.5),
            ),
          ),
        const SizedBox(height: 32),
        const SectionTitle(
          'Dated benchmark comparison',
          subtitle: 'Dated fund and benchmark figures come from the scheme reference data. They are distinct from returns computed from the latest available NAV.',
        ),
        ResponsiveGrid(
          maxColumns: known.length,
          minWidth: 230,
          children: [
            for (var index = 0; index < known.length; index++)
              _DatedColumn(reference: known[index], rows: dated[index]),
          ],
        ),
        const SizedBox(height: 32),
        const SectionTitle(
          'Shared holdings',
          subtitle: 'Pairwise overlap is the sum of smaller published weights for matching identifiers. Coverage and holding dates show how much of each portfolio is disclosed.',
        ),
        _OverlapGrid(funds: known),
        const SizedBox(height: 24),
        const SectionTitle(
          'Reported sector allocation',
          subtitle: 'Each scheme is shown on its own. The unreported bucket preserves the portion not covered by disclosed holdings.',
        ),
        ResponsiveGrid(
          maxColumns: known.length,
          minWidth: 230,
          children: [for (final fund in known) _SectorColumn(reference: fund)],
        ),
        const SizedBox(height: 20),
        const Text(
          'Mutual fund investments are subject to market risks. Read all scheme related documents carefully. Historical returns do not assure future performance.',
          style: TextStyle(color: AppColors.body, fontSize: 13, height: 1.7),
        ),
      ],
    );
  }
}

class _SectorColumn extends StatelessWidget {
  const _SectorColumn({required this.reference});
  final FundReference reference;
  @override
  Widget build(BuildContext context) {
    final allocation = sectorAllocation({reference: 1});
    return AppCard(
      color: AppColors.soft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reference.name,
            style: const TextStyle(fontWeight: FontWeight.w600, height: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            'Coverage ${reference.holdingsCoverage.toStringAsFixed(1)}% · ${reference.holdingsDate == null ? 'date unavailable' : dateLabel(reference.holdingsDate!)}',
            style: const TextStyle(
              color: AppColors.body,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          if (allocation.isEmpty)
            const Text(
              'Sector allocation unavailable.',
              style: TextStyle(color: AppColors.body),
            )
          else
            for (final entry in allocation.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text('${entry.value.toStringAsFixed(2)}%'),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _FundColumn extends ConsumerWidget {
  const _FundColumn({required this.reference, required this.nav});
  final FundReference reference;
  final AsyncValue<FundData> nav;
  @override
  Widget build(BuildContext context, WidgetRef ref) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reference.name,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w500,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${reference.amc} · ${reference.category}',
          style: const TextStyle(color: AppColors.body),
        ),
        const Divider(height: 32),
        Metric(
          label: 'Expense ratio · ${dateLabel(reference.asOfDate)}',
          value: reference.expenseRatioPct == null
              ? 'Unavailable'
              : '${reference.expenseRatioPct!.toStringAsFixed(2)}%',
          note: reference.expenseBasis ?? 'Basis unavailable',
        ),
        const SizedBox(height: 20),
        Metric(
          label: 'AUM · ${dateLabel(reference.asOfDate)}',
          value: reference.aumCrore == null
              ? 'Unavailable'
              : '₹${reference.aumCrore!.toStringAsFixed(2)} crore',
        ),
        const SizedBox(height: 20),
        nav.when(
          loading: () => const LoadingState(message: 'Loading NAV…'),
          error: (e, s) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'NAV unavailable',
                style: TextStyle(color: AppColors.body),
              ),
              TextButton(
                onPressed: () => _refreshFund(ref, reference.schemeCode),
                child: const Text('Retry'),
              ),
            ],
          ),
          data: (data) => data.history.isEmpty
              ? const Text(
                  'NAV unavailable',
                  style: TextStyle(color: AppColors.body),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Metric(
                      label:
                          'Latest published NAV · ${dateLabel(data.latest.date)}',
                      value: money(data.latest.nav, decimals: 4),
                    ),
                    const SizedBox(height: 20),
                    for (final year in [1, 3, 5])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Metric(
                          label: year == 1
                              ? '1-year NAV return'
                              : '$year-year NAV CAGR',
                          value: percentLabel(data.returnYears(year)),
                        ),
                      ),
                    Text(
                      '${data.isCached ? 'Cached' : 'Retrieved'} · ${dateLabel(data.fetchedAt)}${data.warning == null ? '' : ' · ${data.warning}'}',
                      style: const TextStyle(
                        color: AppColors.body,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
        ),
      ],
    ),
  );
}

Future<void> _refreshFund(WidgetRef ref, String code) async {
  try {
    await ref.read(fundRepositoryProvider).fetchFund(code, forceRefresh: true);
  } catch (_) {
    // The invalidated provider presents the repository's normal error state.
  }
  ref.invalidate(fundProvider(code));
}

Map<int, ({double? fund, double? benchmark})> _datedRows(
  FundReference reference,
) {
  final years = {
    ...reference.datedFundReturns.keys,
    ...reference.datedBenchmarkReturns.keys,
  };
  return {
    for (final year in years)
      year: (
        fund: reference.datedFundReturns[year],
        benchmark: reference.datedBenchmarkReturns[year],
      ),
  };
}

class _DatedColumn extends StatelessWidget {
  const _DatedColumn({required this.reference, required this.rows});
  final FundReference reference;
  final Map<int, ({double? fund, double? benchmark})> rows;
  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.soft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reference.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Reference date · ${dateLabel(reference.asOfDate)}',
          style: const TextStyle(color: AppColors.body, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const Text(
            'Dated fund and benchmark returns unavailable.',
            style: TextStyle(color: AppColors.body),
          )
        else
          for (final year in rows.keys.toList()..sort())
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                '${year == 1 ? '1-year absolute return' : '$year-year CAGR'} · Fund ${percentLabel(rows[year]!.fund)} · ${reference.benchmarkName ?? 'Benchmark'} ${percentLabel(rows[year]!.benchmark)}',
                style: const TextStyle(height: 1.5),
              ),
            ),
        if (reference.benchmarkName != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Benchmark · ${reference.benchmarkName}',
              style: const TextStyle(color: AppColors.body, fontSize: 12),
            ),
          ),
      ],
    ),
  );
}

class _OverlapGrid extends StatelessWidget {
  const _OverlapGrid({required this.funds});
  final List<FundReference> funds;
  @override
  Widget build(BuildContext context) => ResponsiveGrid(
    maxColumns: 3,
    minWidth: 230,
    children: [
      for (var i = 0; i < funds.length; i++)
        for (var j = i + 1; j < funds.length; j++)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${funds[i].name} · ${funds[j].name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                if (funds[i].holdings.isEmpty || funds[j].holdings.isEmpty)
                  const Text(
                    'Overlap unavailable because holdings are not reported for both funds.',
                    style: TextStyle(color: AppColors.body, height: 1.5),
                  )
                else
                  Text(
                    '${overlapPercent(funds[i].holdings, funds[j].holdings).toStringAsFixed(2)}% reported overlap',
                    style: numberStyle(size: 18),
                  ),
                const SizedBox(height: 12),
                Text(
                  '${funds[i].name}: ${funds[i].holdingsCoverage.toStringAsFixed(1)}% coverage · ${funds[i].holdingsDate == null ? 'date unavailable' : dateLabel(funds[i].holdingsDate!)}',
                  style: const TextStyle(
                    color: AppColors.body,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                Text(
                  '${funds[j].name}: ${funds[j].holdingsCoverage.toStringAsFixed(1)}% coverage · ${funds[j].holdingsDate == null ? 'date unavailable' : dateLabel(funds[j].holdingsDate!)}',
                  style: const TextStyle(
                    color: AppColors.body,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                if ((funds[i].holdings.isNotEmpty &&
                        !funds[i].holdingsComplete) ||
                    (funds[j].holdings.isNotEmpty &&
                        !funds[j].holdingsComplete))
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Partial disclosure: reported overlap may not cover all assets.',
                      style: TextStyle(
                        color: AppColors.body,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
    ],
  );
}
