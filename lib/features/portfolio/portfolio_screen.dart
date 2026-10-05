import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/calculations.dart';
import '../../core/input.dart';
import '../../core/providers.dart';
import '../../core/record_widgets.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../funds/reference_data.dart';
import '../plans/user_models.dart';
import 'portfolio_math.dart';

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key, this.investCode});
  final String? investCode;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(contributionsProvider);
    final contributions = records.value ?? [];
    final codes = contributions.map((c) => c.schemeCode).toSet();
    final funds = {
      for (final code in codes) code: ref.watch(fundProvider(code)),
    };
    final holdings = deriveHoldings(contributions, {
      for (final e in funds.entries)
        if (e.value.value != null) e.key: e.value.value!.latest.nav,
    });
    final complete = holdings.every((h) => h.value != null);
    final invested = holdings.fold<int>(0, (sum, h) => sum + h.investedPaise);
    final value = holdings.fold<double>(0, (sum, h) => sum + (h.value ?? 0));
    final refs = [
      for (final h in holdings)
        fundCatalog.firstWhere((f) => f.schemeCode == h.schemeCode),
    ];
    final sectors = complete
        ? sectorAllocation({
            for (final h in holdings)
              fundCatalog.firstWhere((f) => f.schemeCode == h.schemeCode):
                  h.value!,
          })
        : <String, double>{};
    return PageFrame(
      title: 'See the whole picture.',
      subtitle: 'Every holding comes from contributions you explicitly record. Values follow the latest published NAV.',
      children: [
        const SimulationNote(),
        RecordStatus(
          value: records,
          onRetry: () => ref.invalidate(contributionsProvider),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (holdings.isEmpty)
                EmptyState(
                  title: 'A clean slate.',
                  message: 'Your simulated portfolio is empty. Record a contribution below, or create a SIP in Plans.',
                  action: OutlinedButton(
                    onPressed: () => context.go('/funds'),
                    child: const Text('Explore funds'),
                  ),
                ),
              if (holdings.isNotEmpty) ...[
                ResponsiveGrid(
                  children: [
                    AppCard(
                      child: Metric(
                        label: 'Simulated portfolio value',
                        value: complete ? money(value) : 'Unavailable',
                        large: true,
                      ),
                    ),
                    AppCard(
                      child: Metric(
                        label: 'Amount contributed',
                        value: money(invested / 100),
                        large: true,
                      ),
                    ),
                    AppCard(
                      child: Metric(
                        label: 'Unrealized gain / loss',
                        value: complete
                            ? money(value - invested / 100)
                            : 'Unavailable',
                        note: 'No withdrawals or sales',
                        large: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                for (final h in holdings)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fundCatalog
                                .firstWhere((f) => f.schemeCode == h.schemeCode)
                                .name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          ResponsiveGrid(
                            minWidth: 200,
                            children: [
                              Metric(
                                label: 'Units',
                                value: h.units.toStringAsFixed(6),
                              ),
                              Metric(
                                label: 'Contributed',
                                value: money(h.investedPaise / 100),
                              ),
                              Metric(
                                label: 'Current value',
                                value: h.value == null
                                    ? 'Unavailable'
                                    : money(h.value!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          funds[h.schemeCode]!.when(
                            data: (d) => Text(
                              'NAV ${dateLabel(d.latest.date)}${d.isCached ? ' · Cached' : ''}${d.warning == null ? '' : ' · ${d.warning}'}',
                            ),
                            loading: () => const Text('Loading published NAV…'),
                            error: (_, _) => TextButton(
                              onPressed: () =>
                                  ref.invalidate(fundProvider(h.schemeCode)),
                              child: const Text('NAV unavailable · Retry'),
                            ),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.go('/funds/${h.schemeCode}'),
                            child: const Text('Fund details'),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                const SectionTitle(
                  'Portfolio X-ray',
                  subtitle: 'Sector weights use the current value of each fund. The underlying holdings are dated disclosures.',
                ),
                if (!complete)
                  const Text(
                    'Allocation is unavailable until all current fund values load.',
                  ),
                if (complete)
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final sector in sectors.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${sector.key} · ${sector.value.toStringAsFixed(2)}%',
                                  style: numberStyle(size: 14),
                                ),
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: (sector.value / 100).clamp(0, 1),
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ],
                            ),
                          ),
                        for (final f in refs)
                          Text(
                            '${f.name}: ${f.holdingsCoverage.toStringAsFixed(2)}% holdings coverage${f.holdingsDate == null ? ' · date unavailable' : ' · ${dateLabel(f.holdingsDate!)}'}',
                          ),
                        const Text(
                          'Unreported assets stay visible. Allocation may have changed since the disclosure.',
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                const SectionTitle(
                  'Fund overlap',
                  subtitle: 'The smaller weight of each matching security is added. Partial coverage gives a lower bound, not a complete estimate.',
                ),
                if (refs.length < 2)
                  const Text(
                    'Add a second fund to compare overlapping holdings.',
                  ),
                for (var i = 0; i < refs.length; i++)
                  for (var j = i + 1; j < refs.length; j++)
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${refs[i].name} / ${refs[j].name}'),
                          const SizedBox(height: 12),
                          Text(
                            refs[i].holdings.isEmpty || refs[j].holdings.isEmpty
                                ? 'Overlap unavailable'
                                : '${overlapPercent(refs[i].holdings, refs[j].holdings).toStringAsFixed(2)}% disclosed overlap',
                            style: numberStyle(),
                          ),
                          Text(
                            'Coverage ${refs[i].holdingsCoverage.toStringAsFixed(1)}% / ${refs[j].holdingsCoverage.toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                    ),
                const SizedBox(height: 32),
                const SectionTitle('Contribution history'),
                for (final c in contributions.reversed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fundCatalog
                                .firstWhere((f) => f.schemeCode == c.schemeCode)
                                .name,
                          ),
                          MoneyText(c.amountPaise / 100),
                          Text(
                            '${c.sipId == null ? 'One-off simulation' : 'SIP simulation'} · ${dateLabel(c.effectiveDate)}',
                          ),
                          Text(
                            '${c.units.toStringAsFixed(6)} units at ₹${c.nav.toStringAsFixed(4)} · NAV ${dateLabel(c.navDate)}',
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
        ContributionForm(key: ValueKey(investCode), schemeCode: investCode),
      ],
    );
  }
}

class ContributionForm extends ConsumerStatefulWidget {
  const ContributionForm({super.key, this.schemeCode});
  final String? schemeCode;
  @override
  ConsumerState<ContributionForm> createState() => _ContributionFormState();
}

class _ContributionFormState extends ConsumerState<ContributionForm> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  late String _scheme =
      fundCatalog.any((f) => f.schemeCode == widget.schemeCode)
      ? widget.schemeCode!
      : fundCatalog.first.schemeCode;
  String? _goal;
  String _submissionId = newRecordId();
  bool _busy = false;
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    if (!await requireAccount(context, ref) || !mounted) return;
    setState(() => _busy = true);
    try {
      final data = await ref
          .read(fundRepositoryProvider)
          .fetchFund(_scheme, forceRefresh: true);
      final price = data.latest;
      final now = DateTime.now();
      final date = DateTime(now.year, now.month, now.day);
      if (date.difference(price.date).inDays > 7 || price.date.isAfter(date)) {
        throw StateError(
          'A recent published NAV is unavailable. Try again after the data updates.',
        );
      }
      final amount = parsePaise(_amount.text)!;
      final units = amount / 100 / price.nav;
      if (!mounted) return;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          scrollable: true,
          title: const Text('Confirm simulated contribution'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.reference.name),
              const SizedBox(height: 16),
              MoneyText(amount / 100),
              Text(
                'NAV ₹${price.nav.toStringAsFixed(4)} · ${dateLabel(price.date)}',
              ),
              Text('${units.toStringAsFixed(6)} units'),
              if (data.isCached) const Text('Using cached published data.'),
              const SimulationNote(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm simulation'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
      final repo = ref.read(userRepositoryProvider);
      if (repo == null) throw StateError('Sign in again before saving.');
      final created = await repo.recordContribution(
        Contribution(
          id: _submissionId,
          schemeCode: _scheme,
          amountPaise: amount,
          units: units,
          nav: price.nav,
          navDate: price.date,
          effectiveDate: date,
          goalId: _goal,
        ),
      );
      if (mounted) {
        _amount.clear();
        _submissionId = newRecordId();
        showMessage(
          context,
          created
              ? 'Simulated contribution recorded.'
              : 'Already recorded. Your portfolio is up to date.',
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          context,
          e is StateError ? e.message.toString() : 'Could not record contribution. Check your connection and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsProvider).value ?? [];
    final selected = fundCatalog.firstWhere((f) => f.schemeCode == _scheme);
    return AppCard(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Record a simulated contribution',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              initialValue: _scheme,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Fund'),
              items: fundCatalog
                  .map(
                    (f) => DropdownMenuItem(
                      value: f.schemeCode,
                      child: Text(f.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _scheme = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: 'Amount (₹)',
                helperText: selected.minLumpSumPaise == null
                    ? 'Published lump-sum minimum unavailable.'
                    : 'Published minimum ₹${selected.minLumpSumPaise! / 100}',
              ),
              validator: (v) {
                final error = amountError(v);
                if (error != null) return error;
                return selected.minLumpSumPaise != null &&
                        parsePaise(v!)! < selected.minLumpSumPaise!
                    ? 'Amount is below the published lump-sum minimum.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _goal ?? '',
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Link a goal (optional)',
              ),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('No linked goal'),
                ),
                ...goals.map(
                  (g) => DropdownMenuItem(
                    value: g.id,
                    child: Text(g.name, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _goal = v == '' ? null : v),
            ),
            const SimulationNote(),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Please wait…' : 'Review simulation'),
              ),
            ),
            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      _amount.text =
                          ((selected.minLumpSumPaise ?? 100000) / 100)
                              .toStringAsFixed(2);
                      showMessage(
                        context,
                        'Example amount filled. Review and confirm to create your walkthrough holding.',
                      );
                    },
              child: const Text('Use the walkthrough example amount'),
            ),
          ],
        ),
      ),
    );
  }
}
