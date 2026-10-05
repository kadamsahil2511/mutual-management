import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers.dart';
import 'theme.dart';

Future<bool> requireAccount(BuildContext context, WidgetRef ref) async {
  if (ref.read(authStateProvider).value != null) return true;
  final next = GoRouterState.of(context).uri.toString();
  await context.push('/auth?next=${Uri.encodeComponent(next)}');
  return context.mounted && ref.read(authStateProvider).value != null;
}

void showMessage(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));

class SimulationNote extends StatelessWidget {
  const SimulationNote({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 12),
    child: Text(
      'SIMULATION · No money is moved. No automatic debits or real orders.',
      style: TextStyle(fontSize: 13, color: AppColors.body),
    ),
  );
}

class RecordStatus<T> extends StatelessWidget {
  const RecordStatus({
    super.key,
    required this.value,
    required this.child,
    required this.onRetry,
  });
  final AsyncValue<T> value;
  final Widget child;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => value.when(
    data: (_) => child,
    loading: () => const Padding(
      padding: EdgeInsets.all(24),
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (_, _) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Your records could not be loaded. Check your connection.'),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
