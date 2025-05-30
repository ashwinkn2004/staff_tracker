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
  double? currentLat;
  double? currentLong;

  String? locationName;

  late Box userBox;

  @override
  void initState() {
    super.initState();
    _initHiveAndLoadData();
    _checkAndFetchLocation();
  }

  Future<void> _initHiveAndLoadData() async {
    userBox = Hive.box('userBox');
    // Load punchLog from Hive if exists
    final savedPunchLog = userBox.get('punchLog');
    final savedIsPunchedIn = userBox.get('isPunchedIn', defaultValue: false);

    if (savedPunchLog != null) {
      punchLog = List<Map<String, dynamic>>.from(
        (savedPunchLog as List).map((e) => Map<String, dynamic>.from(e)),
      );
    }
    setState(() {
      isPunchedIn = savedIsPunchedIn;
    });

    // If punched in, start location tracking immediately
    if (isPunchedIn) {
      _startLocationTracking();
    }
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

    if (doc.data()!.containsKey('locationName')) {
      locationName = doc['locationName'];
    }

    await _checkProximity();
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

    currentLat = position.latitude;
    currentLong = position.longitude;

    double distance = Geolocator.distanceBetween(
      currentLat!,
      currentLong!,
      assignedLat!,
      assignedLong!,
    );

    setState(() {
      isNearOffice = distance <= 5000; // 5 km = 5000 meters
    });
  }

  void _togglePunch() async {
    final now = DateTime.now();
    final entryType = isPunchedIn ? 'out' : 'in';

    punchLog.add({'type': entryType, 'time': now});

    // Save punch log & state in Hive
    await userBox.put('punchLog', punchLog);
    await userBox.put('isPunchedIn', !isPunchedIn);

    if (!isPunchedIn) {
      _startLocationTracking();
    } else {
      _stopLocationTracking();
    }

    // Update total worked time in Firestore
    await _updateTotalWorkedInFirestore();

    setState(() {
      isPunchedIn = !isPunchedIn;
    });
  }

  void _startLocationTracking() {
    locationTimer = Timer.periodic(const Duration(minutes: 2), (_) async {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentLat = position.latitude;
      currentLong = position.longitude;

      final location = {
        'time': DateTime.now(),
        'latitude': currentLat,
        'longitude': currentLong,
      };
      gpsLog.add(location);
      print("Tracked location: $location");

      // Upload location to Firestore for admin access
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('staff')
            .doc(user.uid)
            .collection('locationLogs')
            .add({
              'time': location['time'],
              'latitude': location['latitude'],
              'longitude': location['longitude'],
            });
      }
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
    // If currently punched in without punch out, count time till now
    if (isPunchedIn && lastIn != null) {
      total += DateTime.now().difference(lastIn);
    }
    return total;
  }

  Future<void> _updateTotalWorkedInFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final totalDuration = getTotalWorkedDuration();

    // Update total worked time and current location
    await FirebaseFirestore.instance.collection('staff').doc(user.uid).update({
      'totalWorkedSeconds': totalDuration.inSeconds,
      'currentLatitude': currentLat,
      'currentLongitude': currentLong,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  void _logout() async {
    final box = Hive.box('userBox');
    await box.clear();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _stopLocationTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalWorked = getTotalWorkedDuration();
    final formatter = DateFormat('hh:mm a');

    return WillPopScope(
      onWillPop: () async => false, // prevent logout on back
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("Staff Dashboard", style: GoogleFonts.raleway(
            fontWeight: FontWeight.w600,
            color: Colors.black,
            fontSize: 26,
          )),
          centerTitle: true,
          backgroundColor: Colors.white,
          leading: IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.black),
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
                if (assignedLat != null &&
                    assignedLong != null &&
                    currentLat != null &&
                    currentLong != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (locationName != null)
                          Text(
                            "Allocated Location: $locationName",
                            style: GoogleFonts.raleway(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Text(
                          "Allocated Coords: (${assignedLat!.toStringAsFixed(5)}, ${assignedLong!.toStringAsFixed(5)})",
                        ),
                        Text(
                          "Your Coords: (${currentLat!.toStringAsFixed(5)}, ${currentLong!.toStringAsFixed(5)})",
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isNearOffice
                              ? '✅ You are within 5 km radius.'
                              : '❌ You are outside the 5 km radius.',
                          style: GoogleFonts.raleway(
                            color: isNearOffice ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                      color: Colors.black
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
                "Total Worked: "
                "${totalWorked.inHours.toString().padLeft(2, '0')}:"
                "${totalWorked.inMinutes.remainder(60).toString().padLeft(2, '0')}",
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
