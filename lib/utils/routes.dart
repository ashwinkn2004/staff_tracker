import 'package:flutter/material.dart';
import 'package:staff_tracking/pages/admin_page.dart';
import 'package:staff_tracking/pages/assign_staff_location.dart';
import 'package:staff_tracking/pages/create_office.dart';
import 'package:staff_tracking/pages/create_staff.dart';
import 'package:staff_tracking/pages/login_page.dart';
import 'package:staff_tracking/pages/signup_page.dart';
import 'package:staff_tracking/pages/staff_page.dart';
import 'package:staff_tracking/pages/view_location.dart';


class Routes {
  static const String signUp = '/signup';
  static const String login = '/login';
  static const String createOffice = '/createOffice';
  static const String createStaff = '/createStaff';
  static const String staffPage = '/staffPage';
  static const String adminPage = '/adminPage';
  static const String assignStaffLocation = '/assignStaffLocation';
  static const String viewLocation = '/viewLocation';


  static Map<String, WidgetBuilder> getRoutes() {
    return {
      signUp: (BuildContext context) => const SignupPage(),
      login: (BuildContext context) => const LoginScreen(),
      createOffice: (BuildContext context) => const CreateOfficeLocation(),
      createStaff: (BuildContext context) => const CreateStaff(),
      staffPage: (BuildContext context) => const StaffPage(),
      adminPage: (BuildContext context) => const AdminPage(),
      assignStaffLocation: (BuildContext context) => const AssignStaffLocation(),
      viewLocation: (BuildContext context) => const ViewLocation(),
    };
  }
}
