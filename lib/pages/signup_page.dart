import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:dropdown_below/dropdown_below.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  List _selectRoleList = [
    {'no': 1, 'keyword': 'Admin'},
    {'no': 2, 'keyword': 'Staff'},
  ];
  List<DropdownMenuItem<Object?>> _dropdownRoleItems = [];
  dynamic _selectedRole;
  bool _showRoleError = false;

  @override
  void initState() {
    super.initState();
    _dropdownRoleItems = _selectRoleList.map((role) {
      return DropdownMenuItem(
        value: role,
        child: Text(role['keyword'], style: GoogleFonts.raleway()),
      );
    }).toList();
  }

  void _onRoleChanged(dynamic selectedRole) {
    setState(() {
      _selectedRole = selectedRole;
      _showRoleError = false;
    });
  }

  void _signUp() async {
    if (_formKey.currentState!.validate() && _selectedRole != null) {
      try {
        String email = _emailController.text.trim();
        String password = _passwordController.text;
        String role = _selectedRole['keyword'].toLowerCase();

        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        // 1. Create user in Firebase Authentication
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password)
            .timeout(const Duration(seconds: 10));

        // 2. Create document in the appropriate collection
        await FirebaseFirestore.instance
            .collection(role)
            .doc(userCredential.user!.uid)
            .set({
              'mail': email,
              'uid': userCredential.user!.uid,
              'role': role,
              'pass': password,
              'createdAt': FieldValue.serverTimestamp(),
            });

        // Hide loading indicator
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Successfully signed up as $role')),
        );

        print('Successfully signed up $email as $role');
      } on FirebaseAuthException catch (e) {
        Navigator.of(context).pop(); // Hide loading indicator
        String errorMessage = 'Signup failed';

        if (e.code == 'weak-password') {
          errorMessage = 'The password provided is too weak';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'The account already exists for that email';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'The email address is invalid';
        } else if (e.code == 'operation-not-allowed') {
          errorMessage = 'Email/password accounts are not enabled';
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
        print('Firebase Auth Error: ${e.message}');
      } on TimeoutException {
        Navigator.of(context).pop(); // Hide loading indicator
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Connection timed out')));
      } catch (e) {
        Navigator.of(context).pop(); // Hide loading indicator
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        print('Error: $e');
      }
    } else {
      setState(() {
        _showRoleError = _selectedRole == null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Center(
                child: Lottie.asset(
                  'assets/signup.json',
                  height: 250,
                  width: 300,
                ),
              ),
              _buildTitle("Sign Up"),
              _buildTextField("Email Address", _emailController),
              _buildPasswordField(
                "Password",
                _passwordController,
                _obscurePassword,
                () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              const SizedBox(height: 10),
              _buildPasswordField(
                "Confirm Password",
                _confirmPasswordController,
                _obscureConfirmPassword,
                () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),
              const SizedBox(height: 10),
              _buildDropdown(),
              const SizedBox(height: 20),
              _buildSignupButton(context),
              _buildLoginText(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 10),
      child: Text(
        text,
        style: GoogleFonts.raleway(fontSize: 35, fontWeight: FontWeight.w900),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextFormField(
        controller: controller,
        decoration: _inputDecoration(label),
        style: GoogleFonts.raleway(),
        validator: (value) =>
            value == null || value.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool obscureText,
    VoidCallback toggleVisibility,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        decoration: _inputDecoration(label).copyWith(
          suffixIcon: IconButton(
            icon: Icon(
              obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey,
            ),
            onPressed: toggleVisibility,
          ),
        ),
        style: GoogleFonts.raleway(),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (label == "Confirm Password" &&
              value != _passwordController.text) {
            return 'Passwords do not match';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownBelow(
            itemWidth: 200,
            itemTextstyle: GoogleFonts.raleway(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
            boxTextstyle: GoogleFonts.raleway(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey,
            ),
            boxPadding: const EdgeInsets.fromLTRB(13, 12, 0, 12),
            boxWidth: 400,
            boxHeight: 45,
            boxDecoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(
                width: 1.5,
                color: _showRoleError ? Colors.red : Colors.grey,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
            hint: Text('Role', style: GoogleFonts.raleway()),
            value: _selectedRole,
            items: _dropdownRoleItems,
            onChanged: _onRoleChanged,
          ),
          if (_showRoleError)
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 5),
              child: Text(
                'Please select a role',
                style: GoogleFonts.raleway(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSignupButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: _signUp,
        child: Container(
          height: 50,
          width: 400,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.black,
          ),
          child: Center(
            child: Text(
              'Create account',
              style: GoogleFonts.raleway(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginText(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Already have an account? ",
          style: GoogleFonts.raleway(fontSize: 15, color: Colors.grey),
        ),
        TextButton(
          onPressed: () => Navigator.pushNamed(context, '/login'),
          child: Text(
            "Login",
            style: GoogleFonts.raleway(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.black,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.raleway(color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.grey, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.grey, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.blue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
    );
  }
}
