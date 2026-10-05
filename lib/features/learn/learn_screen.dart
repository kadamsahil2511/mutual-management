import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/calculations.dart';
import '../../core/input.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key, this.articleId});
  final String? articleId;
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late final _articles = rootBundle
      .loadString('assets/data/learning.json')
      .then((s) => (jsonDecode(s) as List).cast<Map<String, dynamic>>());
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<List<Map<String, dynamic>>>(
        future: _articles,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const PageFrame(
              title: 'Learn',
              children: [
                Text(
                  'Learning content could not be loaded. Reload this page to retry.',
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const PageFrame(title: 'Learn', children: [LoadingState()]);
          }
          final articles = snapshot.data!;
          if (widget.articleId != null) {
            final found = articles.where((a) => a['id'] == widget.articleId);
            if (found.isEmpty) {
              return PageFrame(
                title: 'Article unavailable',
                children: [
                  TextButton(
                    onPressed: () => context.go('/learn'),
                    child: const Text('All articles'),
                  ),
                ],
              );
            }
            final article = found.first;
            return PageFrame(
              title: article['title'],
              subtitle: article['summary'],
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article['body'],
                        style: const TextStyle(
                          fontSize: 18,
                          height: 1.8,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SourceLink(
                        label: 'Read the official source',
                        url: article['sourceUrl'],
                      ),
                      if (article['videoUrl'] != null)
                        SourceLink(
                          label: 'Watch the official explainer',
                          url: article['videoUrl'],
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/learn'),
                  child: const Text('Back to learning'),
                ),
              ],
            );
          }
          return PageFrame(
            title: isMobileLayout(context)
                ? 'Learn the essentials'
                : 'A little knowledge.\nA better beginning.',
            subtitle: isMobileLayout(context)
                ? 'Six short reads. Build your confidence.'
                : 'Understand the essentials, explore the numbers, and make space for informed decisions.',
            children: [
              if (isMobileLayout(context)) ...[
                for (final a in articles) ...[
                  AppCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.auto_stories_outlined,
                        color: AppColors.primary,
                      ),
                      title: Text(a['title']),
                      subtitle: Text(a['summary']),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/learn/${a['id']}'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  onPressed: () => context.push('/calculators'),
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('Open calculators'),
                ),
              ] else ...[
                ResponsiveGrid(
                  children: [
                    for (final a in articles)
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.auto_stories_outlined, size: 32),
                            const SizedBox(height: 24),
                            Text(
                              a['title'],
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 16),
                            Text(a['summary']),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: () =>
                                  context.push('/learn/${a['id']}'),
                              child: const Text('Read article →'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 64),
                const SectionTitle(
                  'Plan with the numbers',
                  subtitle: 'Change the assumptions. See how time and contributions affect the estimate.',
                ),
                const LearningCalculator(),
              ],
              const SizedBox(height: 24),
              const AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Case-study pricing reference',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'These figures reproduce the classroom brief. They are examples, not current offers or charges from this application.',
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Direct mutual funds: 0% commission\nRegular funds: fund expense ratio; no extra charge\nStock trading: ₹20 per trade or 0.05%\nFixed deposits: up to 7.5% interest; no fees',
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Stock trading is informational. This app executes no stock trades, fund orders, or fixed-deposit bookings.',
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
}

class LearningCalculator extends StatefulWidget {
  const LearningCalculator({super.key});
  @override
  State<LearningCalculator> createState() => _LearningCalculatorState();
}

class _LearningCalculatorState extends State<LearningCalculator> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController(text: '1000');
  final _years = TextEditingController(text: '5');
  final _rate = TextEditingController(text: '0');
  String _mode = 'SIP';
  double? _result;
  @override
  void dispose() {
    _amount.dispose();
    _years.dispose();
    _rate.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_form.currentState!.validate()) return;
    final amount = parsePaise(_amount.text)! / 100;
    final months = int.parse(_years.text) * 12;
    final rate = double.parse(_rate.text);
    setState(
      () => _result = _mode == 'Goal'
          ? requiredMonthly(
              target: amount,
              initial: 0,
              months: months,
              annualReturn: rate,
            )
          : futureValue(
              initial: _mode == 'Lump sum' ? amount : 0,
              monthly: _mode == 'SIP' ? amount : 0,
              months: months,
              annualReturn: rate,
            ),
    );
  }

  @override
  Widget build(BuildContext context) => AppCard(
    child: Form(
      key: _form,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final mode in ['SIP', 'Lump sum', 'Goal'])
                ChoiceChip(
                  label: Text(mode),
                  selected: _mode == mode,
                  onSelected: (_) => setState(() {
                    _mode = mode;
                    _result = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _amount,
            decoration: InputDecoration(
              labelText: _mode == 'Goal'
                  ? 'Target amount (₹)'
                  : _mode == 'SIP'
                  ? 'Monthly amount (₹)'
                  : 'Initial amount (₹)',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: amountError,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _years,
            decoration: const InputDecoration(labelText: 'Years'),
            keyboardType: TextInputType.number,
            validator: (v) {
              final n = int.tryParse(v ?? '');
              return n == null || n < 1 || n > 50
                  ? 'Enter 1 to 50 years.'
                  : null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _rate,
            decoration: const InputDecoration(
              labelText: 'Assumed annual return (%)',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              return n == null || !n.isFinite || n < 0 || n > 30
                  ? 'Use an assumption between 0% and 30%.'
                  : null;
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Default 0%. This is a planning estimate, not a forecast. Monthly contributions occur at the end of each month. Taxes, inflation, and fees are excluded.',
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              onPressed: _calculate,
              child: const Text('Calculate'),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 24),
            Text(
              _mode == 'Goal'
                  ? 'Estimated monthly contribution'
                  : 'Estimated future value',
            ),
            MoneyText(_result!, size: 32),
          ],
        ],
      ),
    ),
  );
}
