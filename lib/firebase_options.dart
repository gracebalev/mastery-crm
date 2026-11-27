// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

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
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDUBTecEK3irw_Nz5DVYwnKtXrKQHUdfug',
    appId: '1:1087367885966:web:ea6947cab8a8490eb885df',
    messagingSenderId: '1087367885966',
    projectId: 'mastery-crm-515920',
    authDomain: 'mastery-crm-515920.firebaseapp.com',
    storageBucket: 'mastery-crm-515920.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyANTgTMx376XS0KIRLe4Z-yc6TkDvGnaTA',
    appId: '1:1087367885966:android:c740a23f63594470b885df',
    messagingSenderId: '1087367885966',
    projectId: 'mastery-crm-515920',
    storageBucket: 'mastery-crm-515920.firebasestorage.app',
  );
}
