// Firebase options for project veltra67 (iOS + Android apps).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Veltra web is not configured. Run flutterfire configure.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyA9rgNdMF3xyHDgw4QyRErKnkcwf3wXc3c',
    appId: '1:606217642968:ios:a84283a0dcf10c1f1a08ad',
    messagingSenderId: '606217642968',
    projectId: 'veltra67',
    storageBucket: 'veltra67.firebasestorage.app',
    iosBundleId: 'com.veltra.veltra',
  );

  /// Android app registered in Firebase project veltra67.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCuBAkZIvA_Nl_75e9i6twT6abJ2hN-u3c',
    appId: '1:606217642968:android:a8dcabed403674e31a08ad',
    messagingSenderId: '606217642968',
    projectId: 'veltra67',
    storageBucket: 'veltra67.firebasestorage.app',
  );
}
