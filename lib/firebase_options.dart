import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyB8yadGxwpzikH4tgH84k2SbYyXBpm6-JQ",
    authDomain: "mindtrace-ai-3ee0c.firebaseapp.com",
    projectId: "mindtrace-ai-3ee0c",
    storageBucket: "mindtrace-ai-3ee0c.firebasestorage.app",
    messagingSenderId: "770968981522",
    appId: "1:770968981522:web:6133b3a579502fb38fc8cb",
    measurementId: "G-7ND1X36YVZ",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCBqCXMKFXJY4zaDLk-EnH7IpyZhgqXU1s',
    appId: '1:770968981522:android:64ee8c08fb2e63618fc8cb',
    messagingSenderId: '770968981522',
    projectId: 'mindtrace-ai-3ee0c',
    storageBucket: 'mindtrace-ai-3ee0c.firebasestorage.app',
  );
}
