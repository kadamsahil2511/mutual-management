// Firebase app configuration for Mutual Management.
// These client identifiers are public Firebase configuration, not credentials.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('No iOS Firebase app is registered for this project.');
      default:
        throw UnsupportedError('Mutual Management Firebase is configured for web and Android.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCDHLLOwlVuNSAVKx7PwEaAmtaUVrKk9HE',
    appId: '1:361540844123:web:0a42648f21de1f97869d7e',
    messagingSenderId: '361540844123',
    projectId: 'device-streaming-f3ea5c85',
    authDomain: 'device-streaming-f3ea5c85.firebaseapp.com',
    storageBucket: 'device-streaming-f3ea5c85.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCDHLLOwlVuNSAVKx7PwEaAmtaUVrKk9HE',
    appId: '1:361540844123:android:5a6d83c12c00b1fa869d7e',
    messagingSenderId: '361540844123',
    projectId: 'device-streaming-f3ea5c85',
    storageBucket: 'device-streaming-f3ea5c85.firebasestorage.app',
  );

}
