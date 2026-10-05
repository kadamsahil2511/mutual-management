import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/input.dart';
import '../../core/widgets.dart';

class DepositsScreen extends StatefulWidget {
  const DepositsScreen({super.key});
  @override
  State<DepositsScreen> createState() => _DepositsScreenState();
}

class _DepositsScreenState extends State<DepositsScreen> {
  late final _rates = rootBundle
      .loadString('assets/data/deposits.json')
      .then((s) => (jsonDecode(s) as List).cast<Map<String, dynamic>>());
  final _form = GlobalKey<FormState>();
  final _principal = TextEditingController(text: '10000');
  int _selected = 0;
  double? _maturity;
  @override
  void dispose() {
    _principal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'A steadier place\nto start.',
    subtitle: 'Explore published fixed-deposit rates and estimate maturity. Check current terms directly with the bank before making a decision.',
    children: [
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _rates,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text(
              'Deposit data could not be loaded. Reload this page to retry.',
            );
          }
          if (!snapshot.hasData) return const LoadingState();
          final rates = snapshot.data!;
          if (rates.isEmpty) {
            return const EmptyState(
              title: 'No published rates available',
              message:
                  'Check the official bank sites for current deposit rates.',
            );
          }
          final selected = rates[_selected];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ResponsiveGrid(
                children: [
                  for (final rate in rates)
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.account_balance_outlined, size: 32),
                          const SizedBox(height: 24),
                          Text(
                            rate['bank'],
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Metric(
                            label: '${rate['tenureMonths']} months',
                            value:
                                '${(rate['annualRate'] as num).toStringAsFixed(2)}% p.a.',
                            large: true,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Effective ${dateLabel(DateTime.parse(rate['effectiveDate']))}',
                          ),
                          const SizedBox(height: 12),
                          Text(rate['note']),
                          const SizedBox(height: 16),
                          SourceLink(
                            label: 'Official bank rates',
                            url: rate['sourceUrl'],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 48),
              const SectionTitle(
                'Estimate your maturity',
                subtitle: 'A simple quarterly-compounding illustration, before taxes.',
              ),
              AppCard(
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<int>(
                        initialValue: _selected,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Deposit option',
                        ),
                        items: [
                          for (var i = 0; i < rates.length; i++)
                            DropdownMenuItem(
                              value: i,
                              child: Text(
                                '${rates[i]['bank']} · ${rates[i]['tenureMonths']} months · ${rates[i]['annualRate']}%',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (v) => setState(() {
                          _selected = v!;
                          _maturity = null;
                        }),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _principal,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Deposit amount (₹)',
                        ),
                        validator: amountError,
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton(
                          onPressed: () {
                            if (!_form.currentState!.validate()) return;
                            setState(
                              () => _maturity =
                                  parsePaise(_principal.text)! /
                                  100 *
                                  math.pow(
                                    1 + (selected['annualRate'] as num) / 400,
                                    (selected['tenureMonths'] as num) / 3,
                                  ),
                            );
                          },
                          child: const Text('Estimate maturity'),
                        ),
                      ),
                      if (_maturity != null) ...[
                        const SizedBox(height: 24),
                        const Text('Estimated maturity amount'),
                        MoneyText(_maturity!, size: 32),
                      ],
                      const SizedBox(height: 24),
                      const Text(
                        'Assumes quarterly compounding for the full tenure. Actual maturity depends on bank terms, dates, payout frequency, taxes, and premature withdrawal rules. This application does not book deposits.',
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
