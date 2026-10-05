import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers.dart';
import 'core/theme.dart';
import 'firebase_options.dart';

SemanticsHandle? _webSemantics;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  if (kIsWeb) _webSemantics ??= SemanticsBinding.instance.ensureSemantics();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: false,
    );
    if (const bool.fromEnvironment('USE_EMULATORS')) {
      const host = String.fromEnvironment(
        'EMULATOR_HOST',
        defaultValue: kIsWeb ? '127.0.0.1' : '10.0.2.2',
      );
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    }
    final preferences = await SharedPreferences.getInstance();
    runApp(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(preferences)],
        child: const MutualManagementApp(),
      ),
    );
  } catch (_) {
    runApp(
      MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Mutual Management could not start. Please check your connection.',
                  ),
                  const SizedBox(height: 24),
                  FilledButton(onPressed: main, child: const Text('Try again')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
