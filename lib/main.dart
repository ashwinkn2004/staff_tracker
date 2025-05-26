import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:staff_tracking/pages/signup_page.dart';
import 'package:staff_tracking/utils/routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Required before Firebase initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SignupPage(),
      routes: Routes.getRoutes(),
    );
  }
}
