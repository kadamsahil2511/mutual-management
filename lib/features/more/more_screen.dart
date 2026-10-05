import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/record_widgets.dart';
import '../../core/theme.dart';
import '../../core/widgets.dart';
import '../learn/learn_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    return PageFrame(
      title: 'Your investing toolkit',
      subtitle: 'Learn, plan and manage your account.',
      children: [
        AppCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(
              user?.displayName?.isNotEmpty == true
                  ? user!.displayName!
                  : user == null
                  ? 'Welcome, explorer'
                  : 'Your account',
            ),
            subtitle: Text(
              user == null
                  ? 'Sign in to save and sync your plans'
                  : 'Manage your account',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/account'),
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              _ToolTile(
                'Calculators',
                'SIP, lump sum and goal estimates',
                Icons.calculate_outlined,
                '/calculators',
              ),
              const Divider(height: 1),
              _ToolTile(
                'Risk comfort',
                'Five questions to understand your approach',
                Icons.tune_rounded,
                '/risk',
              ),
              const Divider(height: 1),
              _ToolTile(
                'Learn',
                'Short articles and official videos',
                Icons.auto_stories_outlined,
                '/learn',
              ),
              const Divider(height: 1),
              _ToolTile(
                'Fixed deposits',
                'Published rates and maturity estimates',
                Icons.account_balance_outlined,
                '/deposits',
              ),
              const Divider(height: 1),
              _ToolTile(
                'Activity',
                'Your simulated contribution history',
                Icons.receipt_long_outlined,
                '/portfolio/activity',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        AppCard(
          child: _ToolTile(
            'About this app',
            'How the practice portfolio works',
            Icons.info_outline,
            '/about',
          ),
        ),
        const SizedBox(height: 8),
        const SimulationNote(),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile(this.title, this.subtitle, this.icon, this.route);
  final String title, subtitle, route;
  final IconData icon;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 8),
    leading: Icon(icon, color: AppColors.primary),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right, size: 20),
    onTap: () => context.push(route),
  );
}

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    return PageFrame(
      title: user == null
          ? 'Your account'
          : 'Hello, ${user.displayName?.split(' ').firstOrNull ?? 'investor'}',
      subtitle: user == null
          ? 'Save your goals and pick up where you left off.'
          : 'Your plans, across your devices.',
      children: [
        if (user == null)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 56,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Explore freely. Create an account whenever you want to save a goal or practice an investment.',
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.push('/auth?next=%2Faccount'),
                  child: const Text('Sign in or create account'),
                ),
              ],
            ),
          )
        else ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EMAIL',
                  style: TextStyle(fontSize: 12, color: AppColors.body),
                ),
                const SizedBox(height: 8),
                Text(
                  user.email ?? 'Email unavailable',
                  style: const TextStyle(color: AppColors.ink),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () => context.push('/auth/reset'),
                  icon: const Icon(Icons.lock_reset),
                  label: const Text('Reset password'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            icon: const Icon(Icons.logout),
            label: const Text('Sign out'),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialog) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text(
                    'Your saved plans will be here when you return.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('Stay signed in'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              );
              if (confirmed != true) return;
              try {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/more');
              } catch (_) {
                if (context.mounted) {
                  showMessage(context, 'Unable to sign out. Please retry.');
                }
              }
            },
          ),
        ],
        const SizedBox(height: 24),
        const Text(
          'New accounts start empty. Your contributions are practice records, and no money is moved. Sign out when using a shared device.',
        ),
      ],
    );
  }
}

class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});
  @override
  Widget build(BuildContext context) => const PageFrame(
    title: 'Plan with the numbers',
    subtitle: 'Try a contribution amount or work backwards from a goal.',
    children: [LearningCalculator()],
  );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => const PageFrame(
    title: 'A place to practise',
    subtitle: 'Mutual Management · 1.1.0',
    children: [
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '1. Explore real funds',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Compare published NAVs, dated scheme details and the available holdings disclosures.',
            ),
            SizedBox(height: 20),
            Text(
              '2. Make a plan',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'Choose a goal and schedule a monthly or quarterly practice SIP. You confirm each installment yourself.',
            ),
            SizedBox(height: 20),
            Text(
              '3. Follow your progress',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text(
              'See how recorded units are valued and where your disclosed holdings overlap.',
            ),
          ],
        ),
      ),
      SizedBox(height: 20),
      Text(
        'NAVs can be delayed, holdings are partial and dated, and future returns are unknown. No real investment orders, withdrawals or bank connections are offered.',
      ),
      SimulationNote(),
      SourceLink(
        label: 'Data sources and coverage',
        url: 'https://github.com/kadamsahil2511/mutual-management/blob/main/docs/DATA_SOURCES.md',
      ),
    ],
  );
}
