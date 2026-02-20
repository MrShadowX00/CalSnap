import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBrVmHkcHyt0lqC_d_O_dJLTTvKLILlUtg',
    appId: '1:885294130047:android:6024c3925bd913ff05b04a',
    messagingSenderId: '885294130047',
    projectId: 'calsnap-app-2025',
    storageBucket: 'calsnap-app-2025.firebasestorage.app',
  );

  // TODO: Replace with your actual Firebase config from flutterfire configure

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD2M5oqgrPxpvgfMoSGWCxQWZ0g_vYTr2Q',
    appId: '1:885294130047:ios:c73d18a651f5e97005b04a',
    messagingSenderId: '885294130047',
    projectId: 'calsnap-app-2025',
    storageBucket: 'calsnap-app-2025.firebasestorage.app',
    iosBundleId: 'com.mrkhojaev.calsnap',
  );

}