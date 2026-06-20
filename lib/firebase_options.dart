import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // TODO: Replace with real values from flutterfire configure
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      default: throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBWXe7jSsp6MMWYtHzyzTtBBOf-myQX0Yk',
    appId: '1:191066993568:web:88e10a0fe1f5912c086ac5',
    messagingSenderId: '191066993568',
    projectId: 'elenacash-b899b',
    authDomain: 'elenacash-b899b.firebaseapp.com',
    storageBucket: 'elenacash-b899b.firebasestorage.app',
    measurementId: 'G-V6B6Z0GVSC',
  );
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBWXe7jSsp6MMWYtHzyzTtBBOf-myQX0Yk',
    appId: '1:191066993568:android:TODO',
    messagingSenderId: '191066993568',
    projectId: 'elenacash-b899b',
    storageBucket: 'elenacash-b899b.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBWXe7jSsp6MMWYtHzyzTtBBOf-myQX0Yk',
    appId: '1:191066993568:ios:TODO',
    messagingSenderId: '191066993568',
    projectId: 'elenacash-b899b',
    storageBucket: 'elenacash-b899b.firebasestorage.app',
    iosBundleId: 'com.elenacash.app',
  );
}
