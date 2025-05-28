// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:staff_tracking/utils/routes.dart';
import 'firebase_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:staff_tracking/pages/signup_page.dart';
import 'package:staff_tracking/pages/admin_page.dart';
import 'package:staff_tracking/pages/staff_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Hive.initFlutter();
  await Hive.openBox('userBox');

  final box = Hive.box('userBox');
  final role = box.get('role');

  runApp(MyApp(role: role));
}

class MyApp extends StatelessWidget {
  final String? role;
  const MyApp({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    Widget startPage;
    if (role == 'admin') {
      startPage = const AdminPage();
    } else if (role == 'staff') {
      startPage = const StaffPage();
    } else {
      startPage = const SignupPage();
    }

    return MaterialApp(
      home: startPage,
      routes: Routes.getRoutes(),
    );
  }
}
