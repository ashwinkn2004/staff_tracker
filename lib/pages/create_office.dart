import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateOfficeLocation extends StatefulWidget {
  const CreateOfficeLocation({super.key});

  @override
  State<CreateOfficeLocation> createState() => _CreateOfficeLocationState();
}

class _CreateOfficeLocationState extends State<CreateOfficeLocation> {
  final TextEditingController _officeNameController = TextEditingController();
  LatLng? _selectedLocation;

  void _handleMapTap(LatLng latlng) {
    setState(() {
      _selectedLocation = latlng;
    });
  }
  void _createLocation() async {
    String officeName = _officeNameController.text.trim();

    if (officeName.isEmpty || _selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter office name and select a location.'),
        ),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User not logged in.')));
        return;
      }

      await FirebaseFirestore.instance.collection('office').add({
        'officeName': officeName,
        'id': user.uid,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Office location saved successfully!')),
      );

      // Clear after saving
      _officeNameController.clear();
      setState(() {
        _selectedLocation = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Create Office Location',
          style: GoogleFonts.raleway(
            fontSize: 26,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextFormField(
              controller: _officeNameController,
              style: GoogleFonts.raleway(),
              decoration: InputDecoration(
                labelText: 'Office Name',
                labelStyle: GoogleFonts.raleway(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
                ),
              ),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Tap on the map to choose location',
            style: GoogleFonts.raleway(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Container(
              height: 500,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: FlutterMap(
                  options: MapOptions(
                    center: LatLng(10.0, 76.0),
                    zoom: 13.0,
                    onTap: (_, latlng) => _handleMapTap(latlng),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.staff_tracking',
                    ),
                    if (_selectedLocation != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 40.0,
                            height: 40.0,
                            point: _selectedLocation!,
                            child: const Icon(
                              Icons.location_on,
                              size: 40,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_selectedLocation != null)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Lat: ${_selectedLocation!.latitude}, Lng: ${_selectedLocation!.longitude}',
                style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _createLocation,
              child: Container(
                height: 50,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black,
                ),
                child: Center(
                  child: Text(
                    'Create Office',
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
