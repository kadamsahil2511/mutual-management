import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../core/widgets.dart';

const _questions = <({String title, String note, List<String> answers})>[
  (
    title: 'When might you need this money?',
    note: 'A longer horizon can give an investment more time to recover from market falls.',
    answers: ['Within 3 years', 'In 3 to 7 years', 'After 7 years'],
  ),
  (
    title: 'How prepared are you for an unexpected expense?',
    note: 'Think about accessible savings outside any investment you are considering.',
    answers: [
      'I am still building an emergency reserve',
      'I have some accessible savings',
      'I have a comfortable emergency reserve',
    ],
  ),
  (
    title: 'How would you react to a temporary 20% fall?',
    note: 'Imagine seeing the fall in your own balance, even when markets may later recover.',
    answers: [
      'I would want to sell to prevent more loss',
      'I would pause and review my plan',
      'I could stay invested for my long-term goal',
    ],
  ),
  (
    title: 'How familiar are you with mutual funds?',
    note: 'Experience does not remove risk, but understanding the product helps you make considered choices.',
    answers: [
      'I am learning the basics',
      'I understand that returns and principal can vary',
      'I have experienced a full market cycle',
    ],
  ),
  (
    title: 'How much does this goal depend on this money?',
    note: 'Consider the effect a loss would have on your essential needs and commitments.',
    answers: [
      'I cannot afford to lose any of it',
      'I have some flexibility in the amount or date',
      'I have other resources and a flexible timeline',
    ],
  ),
];

class RiskScreen extends StatefulWidget {
  const RiskScreen({super.key});

  @override
  State<RiskScreen> createState() => _RiskScreenState();
}

class _RiskScreenState extends State<RiskScreen> {
  final List<int?> _answers = List.filled(_questions.length, null);
  int _current = 0;
  bool _complete = false;

  @override
  Widget build(BuildContext context) {
    if (_complete) return _result(context);
    final question = _questions[_current];
    return PageFrame(
      title: 'Know your comfort zone.',
      subtitle: 'Five questions to explore how you think about time, uncertainty, and investing. An educational reflection, not investment advice or a fund risk rating.',
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SmallLabel('Question ${_current + 1} of ${_questions.length}'),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(
                  value: (_current + 1) / _questions.length,
                  minHeight: 4,
                  backgroundColor: AppColors.strong,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                question.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  height: 1.25,
                  letterSpacing: -.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                question.note,
                style: const TextStyle(color: AppColors.body, height: 1.6),
              ),
              const SizedBox(height: 28),
              for (var index = 0; index < question.answers.length; index++) ...[
                _AnswerOption(
                  key: ValueKey('risk-option-$_current-$index'),
                  text: question.answers[index],
                  selected: _answers[_current] == index,
                  onTap: () => setState(() => _answers[_current] = index),
                ),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton(
                    key: const ValueKey('risk-next'),
                    onPressed: _answers[_current] == null
                        ? null
                        : () => setState(() {
                            if (_current == _questions.length - 1) {
                              _complete = true;
                            } else {
                              _current++;
                            }
                          }),
                    child: Text(
                      _current == _questions.length - 1
                          ? 'See my profile'
                          : 'Continue',
                    ),
                  ),
                  if (_current > 0)
                    OutlinedButton(
                      onPressed: () => setState(() => _current--),
                      child: const Text('Back'),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Your answers stay on this screen and are not saved. This exercise cannot assess your full financial circumstances or capacity for loss.',
          style: TextStyle(color: AppColors.body, fontSize: 13, height: 1.6),
        ),
      ],
    );
  }

  Widget _result(BuildContext context) {
    final score = _answers.fold(0, (sum, answer) => sum + (answer ?? 0));
    final title = score <= 3
        ? 'Capital preservation'
        : score <= 7
        ? 'Balanced growth'
        : 'Long-term growth';
    final description = score <= 3
        ? 'Your answers put stability and access to money first. Start by learning how liquidity, credit quality, and interest-rate changes affect debt funds. Even debt mutual funds can lose value.'
        : score <= 7
        ? 'Your answers balance growth with some concern about market falls. Learn how a mix of assets can change a portfolio’s fluctuations, and why hybrid funds still carry market risk.'
        : 'Your answers suggest a longer horizon and more comfort with market fluctuations. Learn how equity funds diversify across businesses, and why steep falls and long recovery periods are still possible.';
    return PageFrame(
      title: 'Your learning profile',
      subtitle: 'A starting point for your research. This is not a suitability assessment or a recommendation to buy a particular fund.',
      children: [
        AppCard(
          color: AppColors.dark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SmallLabel('A reflection, not a prescription', dark: true),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w400,
                  height: 1.15,
                  color: Colors.white,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                description,
                style: const TextStyle(
                  color: AppColors.onDarkSoft,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: () => context.go('/learn'),
                child: const Text('Build your understanding'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        const SectionTitle('Keep the whole picture in view.'),
        const ResponsiveGrid(
          maxColumns: 3,
          children: [
            _LearningPoint(
              number: '01',
              title: 'Give every goal a date.',
              body: 'The money you need soon may need a different approach from money for a distant goal.',
            ),
            _LearningPoint(
              number: '02',
              title: 'Read the Riskometer.',
              body: 'Check the latest scheme documents, costs, investment mandate, and fund Riskometer before deciding.',
            ),
            _LearningPoint(
              number: '03',
              title: 'Review with context.',
              body: 'Revisit your needs when life changes. A SEBI-registered investment adviser can assess your full circumstances.',
            ),
          ],
        ),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton(
              onPressed: () => context.go('/funds'),
              child: const Text('Explore funds'),
            ),
            OutlinedButton(
              onPressed: () => setState(() {
                _current = 0;
                _complete = false;
                _answers.fillRange(0, _answers.length, null);
              }),
              child: const Text('Start again'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnswerOption extends StatelessWidget {
  const _AnswerOption({
    super.key,
    required this.text,
    required this.selected,
    required this.onTap,
  });
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: Material(
      color: selected ? AppColors.strong : AppColors.canvas,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.hairline,
          width: selected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? AppColors.primary : AppColors.body,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
            ],
          ),
        ),
      ),
    ),
  );
}

class _LearningPoint extends StatelessWidget {
  const _LearningPoint({
    required this.number,
    required this.title,
    required this.body,
  });
  final String number;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => AppCard(
    color: AppColors.soft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(number, style: numberStyle(size: 14, color: AppColors.body)),
        const SizedBox(height: 24),
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
      ],
    ),
  );
}
