import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/auth_repository.dart';
import '../features/funds/fund_repository.dart';
import '../features/funds/fund_models.dart';
import '../features/plans/user_repository.dart';
import '../features/plans/user_models.dart';

final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override at startup'),
);
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(FirebaseAuth.instance),
);
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);
final userRepositoryProvider = Provider<UserRepository?>((ref) {
  final user = ref.watch(authStateProvider).value;
  return user == null
      ? null
      : UserRepository(FirebaseFirestore.instance, user.uid);
});
final goalsProvider = StreamProvider<List<Goal>>(
  (ref) => ref.watch(userRepositoryProvider)?.watchGoals() ?? Stream.value([]),
);
final sipsProvider = StreamProvider<List<Sip>>(
  (ref) => ref.watch(userRepositoryProvider)?.watchSips() ?? Stream.value([]),
);
final contributionsProvider = StreamProvider<List<Contribution>>(
  (ref) =>
      ref.watch(userRepositoryProvider)?.watchContributions() ??
      Stream.value([]),
);
final fundRepositoryProvider = Provider<FundRepository>(
  (ref) => FundRepository(ref.watch(preferencesProvider)),
);
final fundProvider = FutureProvider.family<FundData, String>(
  (ref, code) => ref.watch(fundRepositoryProvider).fetchFund(code),
);
