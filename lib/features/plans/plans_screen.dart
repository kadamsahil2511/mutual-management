import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/calculations.dart';
import '../../core/input.dart';
import '../../core/providers.dart';
import '../../core/record_widgets.dart';
import '../../core/widgets.dart';
import '../funds/reference_data.dart';
import 'user_models.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key, this.schemeCode});
  final String? schemeCode;
  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen> {
  Goal? _editing;
  String? _busyId;
  final _selectedDue = <String, DateTime>{};
  Future<void> _record(Sip sip, DateTime due) async {
    if (_busyId != null) return;
    final id = installmentId(sip.id, due);
    setState(() => _busyId = id);
    try {
      final data = await ref
          .read(fundRepositoryProvider)
          .fetchFund(sip.schemeCode, forceRefresh: true);
      final price = data.navOnOrBefore(due);
      if (price == null || due.difference(price.date).inDays > 7) {
        throw StateError(
          'No recent published NAV is available on or before this installment.',
        );
      }
      if (!mounted) return;
      final units = sip.amountPaise / 100 / price.nav;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          scrollable: true,
          title: const Text('Record simulated installment?'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(data.reference.name),
              const SizedBox(height: 16),
              MoneyText(sip.amountPaise / 100),
              Text('Scheduled ${DateFormat.yMMMd().format(due)}'),
              Text(
                'NAV ₹${price.nav.toStringAsFixed(4)} · ${DateFormat.yMMMd().format(price.date)}',
              ),
              Text('${units.toStringAsFixed(6)} units'),
              if (data.isCached) const Text('Using a cached published NAV.'),
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
      if (confirm != true) return;
      final repo = ref.read(userRepositoryProvider);
      if (repo == null) {
        throw StateError('Sign in again to save this installment.');
      }
      final created = await repo.recordContribution(
        Contribution(
          id: id,
          schemeCode: sip.schemeCode,
          amountPaise: sip.amountPaise,
          units: units,
          nav: price.nav,
          navDate: price.date,
          effectiveDate: due,
          sipId: sip.id,
          goalId: sip.goalId,
        ),
      );
      if (mounted) {
        showMessage(
          context,
          created
              ? 'Simulated installment recorded.'
              : 'This installment was already recorded.',
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          context,
          'Could not record installment. ${e is StateError ? e.message : 'Check your connection and retry.'}',
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _cancel(Sip sip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel future installments?'),
        content: const Text(
          'Recorded simulated contributions remain in your portfolio.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep plan'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel SIP'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ref.read(userRepositoryProvider)!.cancelSip(sip.id);
    } catch (_) {
      if (mounted) showMessage(context, 'Unable to cancel. Please retry.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final goals = ref.watch(goalsProvider);
    final sips = ref.watch(sipsProvider);
    final contributions = ref.watch(contributionsProvider);
    final records = contributions.value ?? [];
    final recordedIds = records.map((e) => e.id).toSet();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return PageFrame(
      title: 'Make room for\nwhat matters.',
      subtitle: 'A goal gives your money a direction. Build a plan, then practice one installment at a time.',
      children: [
        const SimulationNote(),
        if (ref.watch(authStateProvider).value == null)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Explore a plan below. Sign in when you are ready to save it.',
                ),
                TextButton(
                  onPressed: () => context.push('/auth?next=%2Fplans'),
                  child: const Text('Sign in to sync your plans'),
                ),
              ],
            ),
          ),
        Text('Your goals', style: Theme.of(context).textTheme.headlineMedium),
        RecordStatus(
          value: goals,
          onRetry: () => ref.invalidate(goalsProvider),
          child: Column(
            children: [
              for (final goal in goals.value ?? <Goal>[])
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppCard(
                    child: Builder(
                      builder: (context) {
                        final saved = records
                            .where((c) => c.goalId == goal.id)
                            .fold<int>(0, (sum, c) => sum + c.amountPaise);
                        final months =
                            ((goal.targetDate.year - today.year) * 12 +
                                    goal.targetDate.month -
                                    today.month)
                                .clamp(0, 1200);
                        final required = requiredMonthly(
                          target: goal.targetPaise / 100,
                          initial: saved / 100,
                          months: months,
                          annualReturn: goal.assumedAnnualReturn,
                        );
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              spacing: 16,
                              children: [
                                Text(
                                  goal.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                TextButton(
                                  onPressed: () =>
                                      setState(() => _editing = goal),
                                  child: const Text('Edit goal'),
                                ),
                              ],
                            ),
                            MoneyText(goal.targetPaise / 100, size: 28),
                            Text(
                              'Target ${DateFormat.yMMMd().format(goal.targetDate)}',
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: (saved / goal.targetPaise).clamp(0, 1),
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '₹${(saved / 100).toStringAsFixed(2)} contributed · ${(saved / goal.targetPaise * 100).toStringAsFixed(1)}% of target',
                            ),
                            Text(
                              required.isFinite
                                  ? 'Estimated monthly amount: ₹${required.toStringAsFixed(2)} at ${goal.assumedAnnualReturn}% assumed annual return.'
                                  : 'Target date reached. Edit the date to calculate a monthly plan.',
                            ),
                            const Text(
                              'Progress tracks contributions, not a promised future value.',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              if (goals.value?.isEmpty ?? false)
                const EmptyState(
                  title: 'Every goal starts somewhere.',
                  message: 'Create your first goal below. Your account begins with no investments.',
                ),
            ],
          ),
        ),
        GoalForm(
          key: ValueKey(_editing?.id ?? 'new'),
          initial: _editing,
          onSaved: () => setState(() => _editing = null),
        ),
        const SizedBox(height: 24),
        Text(
          'Your SIP plans',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        RecordStatus(
          value: sips,
          onRetry: () => ref.invalidate(sipsProvider),
          child: Column(
            children: [
              for (final sip in sips.value ?? <Sip>[])
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fundCatalog
                              .firstWhere((f) => f.schemeCode == sip.schemeCode)
                              .name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        MoneyText(sip.amountPaise / 100),
                        Text(
                          '${sip.intervalMonths == 1 ? 'Monthly' : 'Quarterly'} · original day ${sip.startDate.day} · ${sip.isActive ? 'Active' : 'Cancelled'}',
                        ),
                        if (sip.isActive) ...[
                          RecordStatus(
                            value: contributions,
                            onRetry: () =>
                                ref.invalidate(contributionsProvider),
                            child: Builder(
                              builder: (context) {
                                final due = <DateTime>[];
                                DateTime? next;
                                for (var i = 0; i < 1200; i++) {
                                  final date = installmentDate(
                                    sip.startDate,
                                    i,
                                    sip.intervalMonths,
                                  );
                                  if (date.isAfter(today)) {
                                    next = date;
                                    break;
                                  }
                                  if (!recordedIds.contains(
                                    installmentId(sip.id, date),
                                  )) {
                                    due.add(date);
                                  }
                                }
                                final selectedDue =
                                    due.contains(_selectedDue[sip.id])
                                    ? _selectedDue[sip.id]!
                                    : due.firstOrNull;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (due.isEmpty)
                                      Text(
                                        next == null
                                            ? 'All installments are recorded.'
                                            : 'Next installment ${DateFormat.yMMMd().format(next)}',
                                      ),
                                    if (due.isNotEmpty)
                                      Text(
                                        '${due.length} due · Choose an installment to record.',
                                      ),
                                    if (due.length > 1) ...[
                                      const SizedBox(height: 12),
                                      DropdownButtonFormField<DateTime>(
                                        key: ValueKey(
                                          '${sip.id}_${selectedDue!.toIso8601String()}',
                                        ),
                                        initialValue: selectedDue,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Due installment',
                                        ),
                                        items: due
                                            .map(
                                              (date) => DropdownMenuItem(
                                                value: date,
                                                child: Text(
                                                  DateFormat.yMMMd().format(
                                                    date,
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                        onChanged: (date) => setState(
                                          () => _selectedDue[sip.id] = date!,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (due.isNotEmpty)
                                      FilledButton.tonal(
                                        onPressed: _busyId == null
                                            ? () => _record(sip, selectedDue!)
                                            : null,
                                        child: Text(
                                          _busyId != null
                                              ? 'Please wait…'
                                              : 'Record ${DateFormat.yMMMd().format(selectedDue!)}',
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ),
                          TextButton(
                            onPressed: () => _cancel(sip),
                            child: const Text('Cancel future installments'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              if (sips.value?.isEmpty ?? false)
                const EmptyState(
                  title: 'Build a steady habit.',
                  message: 'Schedule a monthly or quarterly simulation. You confirm each installment yourself.',
                ),
            ],
          ),
        ),
        SipForm(schemeCode: widget.schemeCode),
      ],
    );
  }
}

class GoalForm extends ConsumerStatefulWidget {
  const GoalForm({super.key, this.initial, required this.onSaved});
  final Goal? initial;
  final VoidCallback onSaved;
  @override
  ConsumerState<GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<GoalForm> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _amount = TextEditingController(
    text: widget.initial == null
        ? ''
        : (widget.initial!.targetPaise / 100).toStringAsFixed(2),
  );
  late final _date = TextEditingController(
    text: dateInput(
      widget.initial?.targetDate ??
          DateTime(
            DateTime.now().year + 3,
            DateTime.now().month,
            DateTime.now().day,
          ),
    ),
  );
  late final _rate = TextEditingController(
    text: (widget.initial?.assumedAnnualReturn ?? 0).toString(),
  );
  bool _busy = false;
  @override
  void dispose() {
    for (final c in [_name, _amount, _date, _rate]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!await requireAccount(context, ref) || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(userRepositoryProvider)!
          .saveGoal(
            Goal(
              id: widget.initial?.id ?? newRecordId(),
              name: _name.text.trim(),
              targetPaise: parsePaise(_amount.text)!,
              targetDate: parseDate(_date.text)!,
              assumedAnnualReturn: double.parse(_rate.text),
            ),
          );
      if (mounted) {
        showMessage(context, 'Goal saved.');
        _name.clear();
        _amount.clear();
        widget.onSaved();
      }
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          'Could not save goal. Check your connection and retry.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppCard(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initial == null ? 'Create a goal' : 'Edit your goal',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _name,
            decoration: const InputDecoration(
              labelText: 'Goal name',
              hintText: 'Education, a home, a holiday…',
            ),
            maxLength: 80,
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Name your goal.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Target amount (₹)'),
            validator: amountError,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _date,
            decoration: const InputDecoration(
              labelText: 'Target date (YYYY-MM-DD)',
            ),
            validator: (v) {
              final d = parseDate(v ?? '');
              return d == null || !d.isAfter(DateTime.now()) || d.year > 2100
                  ? 'Enter a future date before 2101.'
                  : null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Assumed annual return (%)',
            ),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              return n == null || !n.isFinite || n < 0 || n > 30
                  ? 'Use an assumption from 0% to 30%.'
                  : null;
            },
          ),
          const SizedBox(height: 12),
          const Text(
            'Default 0%. This editable assumption is for planning; returns are not guaranteed. Contributions are made at month end.',
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(_busy ? 'Saving…' : 'Save goal'),
            ),
          ),
        ],
      ),
    ),
  );
}

class SipForm extends ConsumerStatefulWidget {
  const SipForm({super.key, this.schemeCode});
  final String? schemeCode;
  @override
  ConsumerState<SipForm> createState() => _SipFormState();
}

class _SipFormState extends ConsumerState<SipForm> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _date = TextEditingController(text: dateInput(DateTime.now()));
  late String _scheme =
      fundCatalog.any((f) => f.schemeCode == widget.schemeCode)
      ? widget.schemeCode!
      : fundCatalog.first.schemeCode;
  String? _goal;
  int _interval = 1;
  bool _busy = false;
  @override
  void dispose() {
    _amount.dispose();
    _date.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (!await requireAccount(context, ref) || !mounted) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(userRepositoryProvider)!
          .saveSip(
            Sip(
              id: newRecordId(),
              schemeCode: _scheme,
              amountPaise: parsePaise(_amount.text)!,
              startDate: parseDate(_date.text)!,
              intervalMonths: _interval,
              goalId: _goal,
            ),
          );
      if (mounted) {
        _amount.clear();
        showMessage(
          context,
          'Simulated SIP saved. Confirm each installment when it is due.',
        );
      }
    } catch (_) {
      if (mounted) {
        showMessage(
          context,
          'Could not save SIP. Check your connection and retry.',
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
              'Set up a simulated SIP',
              style: Theme.of(context).textTheme.titleLarge,
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
                labelText: 'Installment amount (₹)',
                helperText: selected.minSipPaise == null
                    ? 'Published SIP minimum unavailable.'
                    : 'Published monthly minimum ₹${selected.minSipPaise! / 100}',
              ),
              validator: (v) {
                final error = amountError(v);
                if (error != null) return error;
                return selected.minSipPaise != null &&
                        parsePaise(v!)! < selected.minSipPaise!
                    ? 'Amount is below the published SIP minimum.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _date,
              decoration: const InputDecoration(
                labelText: 'First installment (YYYY-MM-DD)',
              ),
              validator: (v) {
                final d = parseDate(v ?? '');
                return d == null || d.year < 2000 || d.year > 2100
                    ? 'Enter a date from 2000 to 2100.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _interval,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: const [
                DropdownMenuItem(
                  value: 1,
                  child: Text('Monthly', overflow: TextOverflow.ellipsis),
                ),
                DropdownMenuItem(
                  value: 3,
                  child: Text('Quarterly', overflow: TextOverflow.ellipsis),
                ),
              ],
              onChanged: (v) => setState(() => _interval = v!),
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
            const SizedBox(height: 12),
            const Text(
              'Your original day is preserved: January 31 → February 28 → March 31. Historical installments use the published NAV on or before their due date.',
            ),
            if (_interval == 3)
              const Text(
                'Quarterly simulations use the monthly minimum for practice. Actual AMC quarterly terms may differ.',
              ),
            const SimulationNote(),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton(
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Saving…' : 'Save simulated SIP'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
