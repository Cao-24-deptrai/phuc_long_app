import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'theme/app_theme.dart';
import 'views/splash_view.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PhucLongApp());
}

class PhucLongApp extends StatelessWidget {
  const PhucLongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phuc Long Tea & Coffee',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashView(),
    );
  }
}


