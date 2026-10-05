import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import 'fund_models.dart';
import 'reference_data.dart';

class FundsScreen extends ConsumerStatefulWidget {
  const FundsScreen({super.key});

  @override
  ConsumerState<FundsScreen> createState() => _FundsScreenState();
}

class _FundsScreenState extends ConsumerState<FundsScreen> {
  final _search = TextEditingController();
  String _category = 'All funds';
  final Set<String> _selected = {};

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = isMobileLayout(context);
    final categories = [
      'All funds',
      ...fundCatalog.map((fund) => fund.category).toSet(),
    ];
    final query = _search.text.trim().toLowerCase();
    final filters = categories
        .map(
          (category) => ChoiceChip(
            label: Text(category),
            selected: _category == category,
            onSelected: (_) => setState(() => _category = category),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
        )
        .toList();
    final visible = fundCatalog
        .where(
          (fund) =>
              (_category == 'All funds' || fund.category == _category) &&
              '${fund.name} ${fund.amc} ${fund.category} ${fund.schemeCode}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    return PageFrame(
      title: compact ? 'Explore funds' : 'Find your next perspective.',
      subtitle: compact ? 'Published data, clearly dated.' : 'Explore six mutual fund schemes across three categories. Understand the details, compare the costs, and build a plan at your own pace.',
      action: compact
          ? null
          : TextButton.icon(
              onPressed: () => context.push('/risk'),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Explore your risk comfort'),
            ),
      children: [
        TextField(
          key: const ValueKey('fund-search'),
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search a fund, category, or scheme code',
            labelText: 'Search funds',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () => setState(_search.clear),
                    icon: const Icon(Icons.close_rounded),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        if (compact)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final filter in filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: filter,
                  ),
              ],
            ),
          )
        else
          Wrap(spacing: 8, runSpacing: 8, children: filters),
        SizedBox(height: compact ? 16 : 32),
        if (_selected.isNotEmpty) ...[
          AppCard(
            color: AppColors.soft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selected.length} of 3 funds selected',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select two or three funds for a side-by-side view.',
                  style: TextStyle(color: AppColors.body),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton(
                      onPressed: _selected.length < 2
                          ? null
                          : () => context.push(
                              '/compare?codes=${_selected.join(',')}',
                            ),
                      child: Text('Compare selected (${_selected.length})'),
                    ),
                    TextButton(
                      onPressed: () => setState(_selected.clear),
                      child: const Text('Clear selection'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (visible.isEmpty)
          EmptyState(
            title: 'No funds match your search.',
            message: 'Try a different name or clear your filters to see all six schemes.',
            action: OutlinedButton(
              onPressed: () => setState(() {
                _search.clear();
                _category = 'All funds';
              }),
              child: const Text('Reset filters'),
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              '${visible.length} schemes · Published NAV, with valuation dates',
              style: const TextStyle(color: AppColors.body, fontSize: 13),
            ),
          ),
          for (final fund in visible) ...[
            FundSummaryCard(
              reference: fund,
              selected: _selected.contains(fund.schemeCode),
              canSelect:
                  _selected.length < 3 || _selected.contains(fund.schemeCode),
              onSelected: () => setState(() {
                if (_selected.contains(fund.schemeCode)) {
                  _selected.remove(fund.schemeCode);
                } else if (_selected.length < 3) {
                  _selected.add(fund.schemeCode);
                }
              }),
            ),
            const SizedBox(height: 16),
          ],
        ],
        const SizedBox(height: 40),
        const Text(
          'This is a focused educational catalogue, not a ranking or a recommendation. Mutual fund investments are subject to market risks. Past performance does not guarantee future returns.',
          style: TextStyle(color: AppColors.body, fontSize: 13, height: 1.7),
        ),
      ],
    );
  }
}

class FundSummaryCard extends ConsumerWidget {
  const FundSummaryCard({
    super.key,
    required this.reference,
    required this.selected,
    required this.canSelect,
    required this.onSelected,
  });
  final FundReference reference;
  final bool selected;
  final bool canSelect;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fund = ref.watch(fundProvider(reference.schemeCode));
    final compact = isMobileLayout(context);
    return AppCard(
      padding: EdgeInsets.all(compact ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FundGlyph(reference: reference, size: compact ? 38 : 48),
              SizedBox(width: compact ? 10 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reference.name,
                      style: TextStyle(
                        fontSize: compact ? 16 : 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${reference.category} · ${reference.amc}',
                      style: const TextStyle(
                        color: AppColors.body,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 12 : 24),
          fund.when(
            loading: () =>
                const LoadingState(message: 'Getting published NAV…'),
            error: (error, stack) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'NAV is unavailable right now.',
                  style: TextStyle(color: AppColors.body),
                ),
                TextButton.icon(
                  onPressed: () => _refreshFund(ref, reference.schemeCode),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry NAV'),
                ),
              ],
            ),
            data: (data) => data.history.isEmpty
                ? const Text(
                    'NAV history is unavailable.',
                    style: TextStyle(color: AppColors.body),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (compact)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Metric(
                                label: 'Latest NAV',
                                value: money(data.latest.nav, decimals: 4),
                                note: dateLabel(data.latest.date),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Metric(
                                label: '1-year return',
                                value: percentLabel(data.returnYears(1)),
                                color: _returnColor(data.returnYears(1)),
                              ),
                            ),
                          ],
                        )
                      else
                        ResponsiveGrid(
                          maxColumns: 3,
                          minWidth: 190,
                          spacing: 20,
                          children: [
                            Metric(
                              label: 'Published NAV',
                              value: money(data.latest.nav, decimals: 4),
                              note: dateLabel(data.latest.date),
                            ),
                            Metric(
                              label: '1-year NAV return',
                              value: percentLabel(data.returnYears(1)),
                              color: _returnColor(data.returnYears(1)),
                              note: 'Calculated from NAV',
                            ),
                            Metric(
                              label: 'Expense ratio',
                              value: reference.expenseRatioPct == null
                                  ? 'Unavailable'
                                  : '${reference.expenseRatioPct!.toStringAsFixed(2)}%',
                              note:
                                  'Reference: ${dateLabel(reference.asOfDate)}',
                            ),
                          ],
                        ),
                      if (compact) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Expense ratio · ${reference.expenseRatioPct == null ? 'Unavailable' : '${reference.expenseRatioPct!.toStringAsFixed(2)}%'} · ${dateLabel(reference.asOfDate)}',
                          style: const TextStyle(
                            color: AppColors.body,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      SizedBox(height: compact ? 8 : 16),
                      Text(
                        '${data.isCached ? 'Cached NAV' : 'NAV retrieved'} · ${dateLabel(data.fetchedAt)}${data.warning == null ? '' : ' · ${data.warning}'}',
                        style: const TextStyle(
                          color: AppColors.body,
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(height: compact ? 8 : 24),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => context.push('/funds/${reference.schemeCode}'),
                child: const Text('Explore fund'),
              ),
              TextButton.icon(
                key: ValueKey('compare-${reference.schemeCode}'),
                onPressed: canSelect ? onSelected : null,
                icon: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.add_circle_outline_rounded,
                  size: 20,
                ),
                label: Text(selected ? 'Selected for comparison' : 'Compare'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Future<void> _refreshFund(WidgetRef ref, String code) async {
  try {
    await ref.read(fundRepositoryProvider).fetchFund(code, forceRefresh: true);
  } catch (_) {
    // The invalidated provider below presents the normal error state.
  }
  ref.invalidate(fundProvider(code));
}

Color? _returnColor(double? value) => value == null
    ? null
    : value >= 0
    ? AppColors.up
    : AppColors.down;

class FundGlyph extends StatelessWidget {
  const FundGlyph({super.key, required this.reference, this.size = 48});
  final FundReference reference;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.strong,
        shape: BoxShape.circle,
      ),
      child: Text(
        reference.amc.isEmpty ? 'F' : reference.amc.substring(0, 1),
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
      ),
    ),
  );
}
