import 'package:flutter/material.dart';
import 'package:staff_tracking/pages/login_page.dart';
import 'package:staff_tracking/pages/signup_page.dart';

class Routes {
  static const String signUp = '/signup';
  static const String login = '/login';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      signUp: (BuildContext context) => const SignupPage(),
      login: (BuildContext context) => const LoginScreen(),
    };
  }
}
