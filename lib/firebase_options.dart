// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    // ignore: missing_enum_constant_in_switch
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
    }

    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCf3NenrraXrGi2XX1Ue438ygLfXXNPyG4',
    appId: '1:248209452813:android:f6717fb29303cdf8484a44',
    messagingSenderId: '248209452813',
    projectId: 'flutter-taxi-chinghsien',
    storageBucket: 'flutter-taxi-chinghsien.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyArk6Uqg5PSQrhn2-p8SIGQRfMq_a9OUEY',
    appId: '1:248209452813:ios:8da4bc7bbbfe164a484a44',
    messagingSenderId: '248209452813',
    projectId: 'flutter-taxi-chinghsien',
    storageBucket: 'flutter-taxi-chinghsien.appspot.com',
    iosClientId: '248209452813-5e9kopkhnn8btohq8houin94knndl4vq.apps.googleusercontent.com',
    iosBundleId: 'com.chijia.flutter-taxi-chinghsien',
  );
}
