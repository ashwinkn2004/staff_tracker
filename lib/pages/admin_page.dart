import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  void _logout() async {
    final box = Hive.box('userBox');
    await box.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.raleway(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: Colors.black),
        ),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _adminTile(
              icon: Icons.location_on,
              title: 'Create Office Location',
              onTap: () {
                Navigator.pushNamed(context, '/createOffice');
              },
            ),
            _adminTile(
              icon: Icons.person_add,
              title: 'Create Staff Account',
              onTap: () {
                Navigator.pushNamed(context, '/createStaff');
              },
            ),
            _adminTile(
              icon: Icons.assignment_ind,
              title: 'Assign Staff to Location',
              onTap: () {
                Navigator.pushNamed(context, '/assignStaffLocation');
              },
            ),
            _adminTile(
              icon: Icons.map,
              title: 'View Live Locations',
              onTap: () {
                Navigator.pushNamed(context, '/viewLocation');
              },
            ),
            _adminTile(
              icon: Icons.history,
              title: 'Simulate Staff Movement',
              onTap: () {
                Navigator.pushNamed(context, '/simulateMovement');
              },
            ),
            _adminTile(
              icon: Icons.access_time,
              title: 'Working Hours Report',
              onTap: () {
                Navigator.pushNamed(context, '/workSummary');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _adminTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white70,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: Colors.black),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
