import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Clase para configuración de Firebase
/// Nota: Normalmente, este archivo se genera con flutterfire configure
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no están configuradas para esta plataforma.',
        );
    }
  }

  // IMPORTANTE: Estos son valores de ejemplo. Debes reemplazarlos con tus propias credenciales
  // desde la consola de Firebase (https://console.firebase.google.com)
  
  // Web
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB1JM2kPvwQs8EoTxPaeZ7MnubBA4ydvBg',
    appId: '1:53886900716:web:5c55181b8a7bfefdab48c9',
    messagingSenderId: '53886900716',
    projectId: 'kwenta-d77ff',
    authDomain: 'kwenta-d77ff.firebaseapp.com',
    storageBucket: 'kwenta-d77ff.appspot.com',
  );

  // Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDlPGOUpwNp-ihxCDlvluEmvL8QsWgIn5c',
    appId: '1:53886900716:android:e8d9ab5320db7260ab48c9',
    messagingSenderId: '53886900716',
    projectId: 'kwenta-d77ff',
    storageBucket: 'kwenta-d77ff.appspot.com',
  );

  // iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDmmqZ9RC8xQ1Cy05xp99kkh2igrZlENPE',
    appId: '1:53886900716:ios:a1a6e9f6df4dc226ab48c9',
    messagingSenderId: '53886900716',
    projectId: 'kwenta-d77ff',
    storageBucket: 'kwenta-d77ff.appspot.com',
    iosBundleId: 'com.example.kwentaApp',
  );

  // macOS
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDmmqZ9RC8xQ1Cy05xp99kkh2igrZlENPE',
    appId: '1:53886900716:ios:a1a6e9f6df4dc226ab48c9',
    messagingSenderId: '53886900716',
    projectId: 'kwenta-d77ff',
    storageBucket: 'kwenta-d77ff.appspot.com',
    iosBundleId: 'com.example.kwentaApp',
  );

  // Windows
  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB1JM2kPvwQs8EoTxPaeZ7MnubBA4ydvBg',
    appId: '1:53886900716:web:c1811b58278e7b40ab48c9',
    messagingSenderId: '53886900716',
    projectId: 'kwenta-d77ff',
    authDomain: 'kwenta-d77ff.firebaseapp.com',
    storageBucket: 'kwenta-d77ff.appspot.com',
  );

  // Linux
  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyB1JM2kPvwQs8EoTxPaeZ7MnubBA4ydvBg',
    appId: '1:53886900716:web:c1811b58278e7b40ab48c9',
    messagingSenderId: '53886900716',
    projectId: 'kwenta-d77ff',
    authDomain: 'kwenta-d77ff.firebaseapp.com',
    storageBucket: 'kwenta-d77ff.appspot.com',
  );
} 