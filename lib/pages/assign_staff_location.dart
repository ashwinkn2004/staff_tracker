import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_below/dropdown_below.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AssignStaffLocation extends StatefulWidget {
  const AssignStaffLocation({super.key});

  @override
  State<AssignStaffLocation> createState() => _AssignStaffLocationState();
}

class _AssignStaffLocationState extends State<AssignStaffLocation> {
  final CollectionReference staffCollection = FirebaseFirestore.instance
      .collection('staff');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Assign Staff to Location",
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: staffCollection.snapshots(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error state
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading staff data."));
          }

          // No staff found
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No staff available",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            );
          }

          // Staff available
          final staffList = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: staffList.length,
            itemBuilder: (context, index) {
              final staff = staffList[index];
              final staffName = staff['staffName'] ?? 'No Name';
              final staffEmail = staff['email'] ?? 'No Email';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white70,
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(
                    staffName,
                    style: GoogleFonts.raleway(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(staffEmail, style: GoogleFonts.raleway()),
                  trailing: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.black),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12,
                          ), // smooth corners
                        ),
                      ),
                    ),
                    onPressed: () {
                      _showLocationDialog(staff.id, staffName);
                    },
                    child: Text(
                      "Assign",
                      style: GoogleFonts.raleway(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.w600, // optional: to make it a bit bold
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showLocationDialog(String staffId, String staffName) {
    String? selectedLocation;
    double? selectedLatitude;
    double? selectedLongitude;
    List<Map<String, dynamic>> officeList = [];
    bool loading = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            // Fetch offices from Firestore once
            if (loading) {
              FirebaseFirestore.instance
                  .collection('office')
                  .get()
                  .then((snapshot) {
                    final offices = snapshot.docs.map((doc) {
                      return {
                        'officeName': doc['officeName'] ?? '',
                        'latitude': doc['latitude'],
                        'longitude': doc['longitude'],
                      };
                    }).toList();

                    setStateDialog(() {
                      officeList = offices;
                      loading = false;
                    });
                  })
                  .catchError((error) {
                    setStateDialog(() {
                      loading = false;
                    });
                  });
            }

            // Prepare DropdownBelow items
            List<DropdownMenuItem<Object?>> dropdownItems = officeList
                .map(
                  (office) => DropdownMenuItem(
                    value: office['officeName'],
                    child: Text(
                      office['officeName'] ?? '',
                      style: GoogleFonts.raleway(color: Colors.black),
                    ),
                  ),
                )
                .toList();

            return AlertDialog(
              backgroundColor: Colors.white, // Set background to white
              title: Text(
                "Assign Location to $staffName",
                style: GoogleFonts.raleway(),
              ),
              content: loading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownBelow(
                      itemWidth: 200,
                      itemTextstyle: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      boxTextstyle: GoogleFonts.raleway(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Colors.black,
                      ),
                      boxPadding: const EdgeInsets.fromLTRB(13, 12, 0, 12),
                      boxWidth: 250,
                      boxHeight: 45,
                      boxDecoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(width: 1.5, color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey,
                      ),
                      hint: Text(
                        'Select Office Location',
                        style: GoogleFonts.raleway(color: Colors.grey),
                      ),
                      value: selectedLocation,
                      items: dropdownItems,
                      onChanged: (value) {
                        setStateDialog(() {
                          selectedLocation = value as String?;

                          // Find selected office's lat & long
                          final office = officeList.firstWhere(
                            (office) =>
                                office['officeName'] == selectedLocation,
                            orElse: () => {},
                          );
                          selectedLatitude = office['latitude'];
                          selectedLongitude = office['longitude'];
                        });
                      },
                    ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: GoogleFonts.raleway()),
                ),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.black),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  onPressed: selectedLocation == null
                      ? null
                      : () async {
                          await FirebaseFirestore.instance
                              .collection('staff')
                              .doc(staffId)
                              .update({
                                'location': selectedLocation,
                                'latitude': selectedLatitude,
                                'longitude': selectedLongitude,
                              });
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Assigned $selectedLocation to $staffName',
                                style: GoogleFonts.raleway(),
                              ),
                            ),
                          );
                        },
                  child: Text(
                    "Assign",
                    style: GoogleFonts.raleway(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
