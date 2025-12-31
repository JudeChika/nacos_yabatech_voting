import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nacos_yabatech_voting/views/manage_executives.dart';
import 'package:nacos_yabatech_voting/views/manage_gallery.dart';
import 'manage_candidates.dart';
import 'manage_news.dart';

class AdminDashboard extends StatelessWidget {
  // 1. Accept Permission Level
  final bool isSuperAdmin;

  const AdminDashboard({super.key, required this.isSuperAdmin});

  @override
  Widget build(BuildContext context) {
    const Color yabaGreen = Color(0xFF006400);

    return Scaffold(
      appBar: AppBar(
        title: Text(isSuperAdmin ? "Admin Control Panel" : "PRO Content Panel", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: yabaGreen,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // 2. MASTER CONTROLS (ELECTION SWITCH) - ONLY FOR SUPER ADMINS
          if (isSuperAdmin)
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('settings').doc('election').snapshots(),
              builder: (context, snapshot) {
                bool isActive = false;
                if (snapshot.hasData && snapshot.data!.exists) {
                  isActive = snapshot.data!.get('isActive') ?? false;
                }

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("ELECTION STATUS", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                              Text(isActive ? "LIVE 🟢" : "OFFLINE 🔴",
                                  style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 12)),
                            ],
                          ),
                          Switch(
                            value: isActive,
                            activeColor: Colors.green,
                            onChanged: (val) async {
                              await FirebaseFirestore.instance
                                  .collection('settings')
                                  .doc('election')
                                  .set({'isActive': val}, SetOptions(merge: true));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: 20),

          // 3. ACTION BUTTONS GRID
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // MANAGE CANDIDATES (Super Admin Only)
                if (isSuperAdmin) ...[
                  Expanded(
                    child: _buildActionButton(
                      context,
                      "Manage\nCandidates",
                      Icons.people,
                      Colors.blue,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageCandidatesScreen())),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],

                // MANAGE NEWS (Everyone)
                Expanded(
                  child: _buildActionButton(
                    context,
                    "Post to\nNews Feed",
                    Icons.campaign,
                    Colors.orange,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageNewsScreen())),
                  ),
                ),
                const SizedBox(width: 10),

                // MANAGE GALLERY (Everyone - PROs usually handle photos too)
                Expanded(
                  child: _buildActionButton(
                    context,
                    "Manage\nGallery",
                    Icons.photo_library,
                    Colors.purple,
                        () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageGalleryScreen())),
                  ),
                ),

                // MANAGE EXCOS (Super Admin Only)
                if (isSuperAdmin) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildActionButton(
                      context,
                      "Manage\nExcos",
                      Icons.badge,
                      Colors.teal,
                          () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ManageExecutivesScreen())),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(height: 1),

          // 4. ACCREDITATION SECTION - ONLY FOR SUPER ADMINS
          if (isSuperAdmin) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              color: Colors.grey[100],
              child: const Text("Student Accreditation", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'voter').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final students = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      var student = students[index];
                      bool isAccredited = student['isAccredited'] ?? false;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isAccredited ? yabaGreen : Colors.grey,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(student['fullName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Matric: ${student['matricNumber']}"),
                        trailing: Switch(
                          value: isAccredited,
                          activeColor: yabaGreen,
                          onChanged: (val) {
                            FirebaseFirestore.instance.collection('users').doc(student.id).update({'isAccredited': val});
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ] else ...[
            // PRO VIEW MESSAGE
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_outline, size: 60, color: Colors.grey),
                    SizedBox(height: 10),
                    Text("Voting & Accreditation Controls\nare restricted to Super Admins.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: color.withOpacity(0.5))),
      ),
      onPressed: onTap,
      child: Column(
        children: [
          Icon(icon, size: 24),
          const SizedBox(height: 5),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}