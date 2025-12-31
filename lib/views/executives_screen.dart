import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class ExecutivesScreen extends StatelessWidget {
  const ExecutivesScreen({super.key});

  // --- UPDATED CALL FUNCTION ---
  Future<void> _makeCall(BuildContext context, String phoneNumber, String name) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    // 1. Check if a Phone App exists on the device
    if (await canLaunchUrl(launchUri)) {

      // 2. Seek User Permission (Confirmation Dialog)
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Make a Call"),
            content: Text("Do you want to call $name?\nNumber: $phoneNumber"),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx), // User denied permission
                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006400),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  Navigator.pop(ctx); // Close dialog
                  // 3. Initiate the Call
                  await launchUrl(launchUri);
                },
                child: const Text("Call"),
              ),
            ],
          ),
        );
      }
    } else {
      // No Phone App Found
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No calling app found on this device."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        title: Text("KNOW YOUR EXCOS", style: GoogleFonts.orbitron(color: const Color(0xFF006400), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF006400)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('executives').orderBy('rank').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Executives list not updated yet."));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),

                    // --- CIRCULAR AVATAR WITH TOP ALIGNMENT ---
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                        image: (doc['imageUrl'] != "")
                            ? DecorationImage(
                          image: NetworkImage(doc['imageUrl']),
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                        )
                            : null,
                      ),
                      child: (doc['imageUrl'] == "")
                          ? const Icon(Icons.person, color: Colors.grey)
                          : null,
                    ),

                    // --- TEXT DETAILS ---
                    title: Text(doc['name'], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(doc['position'], style: const TextStyle(color: Color(0xFF006400), fontWeight: FontWeight.w600)),
                        if (doc['phone'] != "")
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(doc['phone'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ),
                      ],
                    ),

                    // --- CALL BUTTON (Updated to pass 'context' and 'name') ---
                    trailing: IconButton(
                      icon: const CircleAvatar(backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.phone, color: Color(0xFF006400))),
                      onPressed: () => _makeCall(context, doc['phone'], doc['name']),
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
}