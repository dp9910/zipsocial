import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';

class FirebaseConfig {
  static const FirebaseOptions _iosOptions = FirebaseOptions(
    apiKey: 'AIzaSyAKdV34I6mMurtJ-_7hB_qwriD4tN5T13Y',
    appId: '1:919813529279:ios:bb97d10ed77efe471eb00a',
    messagingSenderId: '919813529279',
    projectId: 'zip-social-443a3',
    authDomain: 'zip-social-443a3.firebaseapp.com',
    storageBucket: 'zip-social-443a3.firebasestorage.app',
    iosBundleId: 'com.zipsocial.zipSocial',
  );

  static const FirebaseOptions _androidOptions = FirebaseOptions(
    apiKey: 'AIzaSyAKdV34I6mMurtJ-_7hB_qwriD4tN5T13Y',
    appId: '1:919813529279:android:bb97d10ed77efe471eb00a',
    messagingSenderId: '919813529279',
    projectId: 'zip-social-443a3',
    authDomain: 'zip-social-443a3.firebaseapp.com',
    storageBucket: 'zip-social-443a3.firebasestorage.app',
  );

  static Future<void> initialize() async {
    FirebaseOptions options;
    if (Platform.isIOS) {
      options = _iosOptions;
    } else if (Platform.isAndroid) {
      options = _androidOptions;
    } else {
      throw UnsupportedError('Platform not supported');
    }

    await Firebase.initializeApp(options: options);
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;
}