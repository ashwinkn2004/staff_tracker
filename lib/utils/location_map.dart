import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

class LocationMap extends StatelessWidget {
  final Map<String, dynamic> staffData;

  const LocationMap({super.key, required this.staffData});

  @override
  Widget build(BuildContext context) {
    final double currentLat =
        (staffData['currentLatitude'] as num?)?.toDouble() ?? 0;
    final double currentLong =
        (staffData['currentLongitude'] as num?)?.toDouble() ?? 0;
    final double officeLat = (staffData['latitude'] as num?)?.toDouble() ?? 0;
    final double officeLong = (staffData['longitude'] as num?)?.toDouble() ?? 0;

    final mapCenter = LatLng(
      currentLat != 0 ? currentLat : officeLat,
      currentLong != 0 ? currentLong : officeLong,
    );

    final int totalWorkedSeconds = staffData['totalWorkedSeconds'] ?? 0;
    final int hours = totalWorkedSeconds ~/ 3600;
    final int minutes = (totalWorkedSeconds % 3600) ~/ 60;

    return Scaffold(
      appBar: AppBar(
        title: Text("Staff Location Map", style: GoogleFonts.raleway(
          fontWeight: FontWeight.w600,
        ),),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const SizedBox(height: 10), // small padding above map
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 500,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 8,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FlutterMap(
                  options: MapOptions(center: mapCenter, zoom: 15.0),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(officeLat, officeLong),
                          width: 80,
                          height: 80,
                          child: Column(
                            children: const [
                              Icon(
                                Icons.business_center_outlined,
                                color: Colors.indigo,
                                size: 38,
                              ),
                              Text("Office", style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        Marker(
                          point: LatLng(currentLat, currentLong),
                          width: 80,
                          height: 80,
                          child: Column(
                            children: const [
                              Icon(
                                Icons.location_pin,
                                color: Colors.deepOrange,
                                size: 38,
                              ),
                              Text("Staff", style: TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "Total Worked: ${hours}h ${minutes}m",
              style: GoogleFonts.raleway(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
