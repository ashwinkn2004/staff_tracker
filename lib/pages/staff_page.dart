import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StaffPage extends StatefulWidget {
  const StaffPage({super.key});

  @override
  State<StaffPage> createState() => _StaffPageState();
}

class _StaffPageState extends State<StaffPage> {
  bool isPunchedIn = false;
  bool isNearOffice = false;
  bool hasLocationAssigned = true;

  List<Map<String, dynamic>> punchLog = [];
  List<Map<String, dynamic>> gpsLog = [];

  Timer? locationTimer;

  double? assignedLat;
  double? assignedLong;

  @override
  void initState() {
    super.initState();
    _checkAndFetchLocation();
  }

  Future<void> _checkAndFetchLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('staff')
        .doc(user.uid)
        .get();

    if (!doc.exists || !doc.data()!.containsKey('latitude')) {
      setState(() {
        hasLocationAssigned = false;
        isNearOffice = false;
      });
      return;
    }

    assignedLat = doc['latitude'];
    assignedLong = doc['longitude'];

    _checkProximity();
  }

  Future<void> _checkProximity() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      assignedLat!,
      assignedLong!,
    );

    setState(() {
      isNearOffice = distance <= 5000; // within 500 meters
    });
  }

  void _togglePunch() {
    final now = DateTime.now();
    final entryType = isPunchedIn ? 'out' : 'in';

    punchLog.add({'type': entryType, 'time': now});

    if (!isPunchedIn) {
      _startLocationTracking();
    } else {
      _stopLocationTracking();
    }

    setState(() {
      isPunchedIn = !isPunchedIn;
    });
  }

  void _startLocationTracking() {
    locationTimer = Timer.periodic(const Duration(minutes: 2), (_) {
      final location = {
        'time': DateTime.now(),
        'latitude': 9.123456, // Simulated lat
        'longitude': 76.543210, // Simulated long
      };
      gpsLog.add(location);
      print("Tracked location: $location");
    });
  }

  void _stopLocationTracking() {
    locationTimer?.cancel();
  }

  Duration getTotalWorkedDuration() {
    Duration total = Duration.zero;
    DateTime? lastIn;
    for (var entry in punchLog) {
      if (entry['type'] == 'in') {
        lastIn = entry['time'];
      } else if (entry['type'] == 'out' && lastIn != null) {
        total += entry['time'].difference(lastIn);
        lastIn = null;
      }
    }
    return total;
  }

  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }

  void _logout() async {
    final box = Hive.box('userBox');
    await box.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final totalWorked = getTotalWorkedDuration();
    final formatter = DateFormat('hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text("Staff Dashboard", style: GoogleFonts.raleway()),
        centerTitle: true,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          onPressed: _logout,
          icon: const Icon(Icons.logout, color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (!hasLocationAssigned) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Location not assigned. Please contact the admin.',
                  style: GoogleFonts.raleway(),
                ),
              ),
            ] else ...[
              ElevatedButton(
                onPressed: isNearOffice ? _togglePunch : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isPunchedIn ? Colors.red : Colors.green,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  isPunchedIn ? 'Punch Out' : 'Punch In',
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isNearOffice ? Colors.green[100] : Colors.red[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isNearOffice
                      ? 'You are near the office. Punch is enabled.'
                      : 'You are outside the geofence. Punch is disabled.',
                  style: GoogleFonts.raleway(),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Punch Log",
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: punchLog.length,
                itemBuilder: (context, index) {
                  final item = punchLog[index];
                  return ListTile(
                    leading: Icon(
                      item['type'] == 'in' ? Icons.login : Icons.logout,
                      color: item['type'] == 'in' ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      "${item['type'] == 'in' ? 'In' : 'Out'} at ${formatter.format(item['time'])}",
                      style: GoogleFonts.raleway(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Total Worked: ${totalWorked.inHours}h ${totalWorked.inMinutes.remainder(60)}m",
              style: GoogleFonts.raleway(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
