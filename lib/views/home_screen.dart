import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nacos_yabatech_voting/views/war_room.dart';
import 'package:nacos_yabatech_voting/views/voting_screen.dart';
import 'package:nacos_yabatech_voting/views/feed_screen.dart';
import 'package:nacos_yabatech_voting/views/gallery_screen.dart';
import 'package:nacos_yabatech_voting/views/executives_screen.dart';
import 'admin_dashboard.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const Color yabaGreen = Color(0xFF006400);
    const Color yabaYellow = Color(0xFFFFD700);

    // --- 1. DEFINE ROLES ---
    final List<String> superAdminEmails = [
      "jude2chika@gmail.com",
      "emmaexcel0@gmail.com",
      "ayoakeni64@gmail.com",
    ];

    final List<String> proEmails = [
      "ekusinakpan9@gmail.com", // Example: Add the PRO's specific email here
      "jude2chika@gmail.com",
      "ayemoandrewgold@gmail.com",
    ];

    // Check Permissions
    final bool isSuperAdmin = user != null && superAdminEmails.contains(user.email);
    final bool isPro = user != null && proEmails.contains(user.email);
    final bool hasAdminAccess = isSuperAdmin || isPro;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text("NACOS HUB",
            style: GoogleFonts.orbitron(color: yabaGreen, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                      (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: yabaGreen));
          }

          var userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          String name = userData['fullName'] ?? "Student";
          String matric = userData['matricNumber'] ?? "N/A";
          bool isAccredited = userData['isAccredited'] ?? false;

          bool hasVotedAny = false;
          if (userData.containsKey('votedPositions')) {
            hasVotedAny = (userData['votedPositions'] as Map<String, dynamic>).isNotEmpty;
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroHeader(name, matric, yabaGreen),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildStatusBadge(isAccredited, hasVotedAny, yabaGreen, yabaYellow),
                      const SizedBox(height: 25),

                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('settings').doc('election').snapshots(),
                        builder: (context, settingsSnapshot) {
                          bool isLive = false;
                          if (settingsSnapshot.hasData && settingsSnapshot.data!.exists) {
                            try {
                              isLive = settingsSnapshot.data!.get('isActive');
                            } catch (e) { isLive = false; }
                          }
                          return _buildVotingButton(context, isAccredited, isLive, yabaGreen);
                        },
                      ),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Expanded(child: _buildWarRoomButton(context, yabaGreen)),
                          const SizedBox(width: 10),
                          Expanded(child: _buildGalleryButton(context, Colors.purple)),
                        ],
                      ),

                      const SizedBox(height: 10),

                      _buildExcoButton(context, Colors.blueGrey),

                      const SizedBox(height: 20),

                      // --- 2. ADMIN BUTTON (SHOWN FOR BOTH ROLES) ---
                      if (hasAdminAccess)
                        _buildAdminEntryButton(context, isSuperAdmin).animate().scale(delay: 400.ms),

                      const SizedBox(height: 30),

                      _buildHorizontalGallerySection(context),

                      const SizedBox(height: 50),

                      Center(
                        child: Column(
                          children: [
                            Text("Developed by Jude Chika (+2349136621524)",
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                            const SizedBox(height: 2),
                            Text("Courtesy of NACOS Executives, 2025 set",
                                style: GoogleFonts.poppins(fontSize: 10, color: Colors.green[400], fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ... [Keep _buildHeroHeader, _buildStatusBadge, etc. exactly as they were] ...
  // Paste your existing helper widgets here (_buildHeroHeader, _buildStatusBadge, etc.)

  // Re-adding the helper widgets for completeness to avoid errors
  Widget _buildHeroHeader(String name, String matric, Color green) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
      decoration: BoxDecoration(color: green, borderRadius: const BorderRadius.only(bottomRight: Radius.circular(50))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Welcome back,", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16)),
          Text(name.toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text("Matric No: $matric", style: GoogleFonts.poppins(color: Colors.white54, fontSize: 14)),
        ],
      ),
    ).animate().slideX();
  }

  Widget _buildStatusBadge(bool isAccredited, bool hasVotedAny, Color green, Color yellow) {
    String statusText = isAccredited ? "VERIFIED" : "PENDING";
    IconData statusIcon = isAccredited ? Icons.verified : Icons.hourglass_empty;
    Color statusColor = isAccredited ? yellow : Colors.orange;

    if (hasVotedAny) {
      statusText = "ACTIVE VOTER";
      statusIcon = Icons.how_to_vote;
      statusColor = Colors.lightBlueAccent;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 30),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Accreditation Status", style: TextStyle(fontSize: 12, color: Colors.grey)),
              Text(statusText, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: green)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVotingButton(BuildContext context, bool isAccredited, bool isElectionLive, Color green) {
    bool canEnterVotingBooth = isElectionLive && isAccredited;
    String buttonText = !isElectionLive ? "ELECTION CLOSED" : (!isAccredited ? "AWAITING ACCREDITATION" : "CAST YOUR VOTE");
    Color buttonColor = canEnterVotingBooth ? green : Colors.grey;

    return GestureDetector(
      onTap: canEnterVotingBooth ? () => Navigator.push(context, MaterialPageRoute(builder: (context) => const VotingScreen())) : null,
      child: Container(
        height: 70,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: canEnterVotingBooth ? [buttonColor, const Color(0xFF004D00)] : [Colors.grey.shade400, Colors.grey.shade600]),
          boxShadow: canEnterVotingBooth ? [BoxShadow(color: green.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.how_to_vote, color: Colors.white.withOpacity(canEnterVotingBooth ? 1 : 0.5), size: 30),
            const SizedBox(width: 15),
            Text(buttonText, style: GoogleFonts.orbitron(color: Colors.white.withOpacity(canEnterVotingBooth ? 1 : 0.7), fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    ).animate(target: canEnterVotingBooth ? 1 : 0).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildWarRoomButton(BuildContext context, Color green) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WarRoom())),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: green, width: 2),
          color: Colors.white,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, color: green),
              Text("LIVE RESULTS", style: GoogleFonts.poppins(color: green, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryButton(BuildContext context, Color color) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GalleryScreen())),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
          color: Colors.white,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo_library, color: color),
              Text("EVENT GALLERY", style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExcoButton(BuildContext context, Color color) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ExecutivesScreen())),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
          color: Colors.white,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.groups, color: color),
              const SizedBox(width: 10),
              Text("KNOW YOUR EXECUTIVES", style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalGallerySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Departmental Feed", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const FeedScreen())),
              child: const Text("View All", style: TextStyle(color: Color(0xFF006400), fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 160,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildGalleryCard("Election News", Colors.blueAccent),
              _buildGalleryCard("Upcoming Events", Colors.orangeAccent),
              _buildGalleryCard("Student Life", Colors.purpleAccent),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryCard(String title, Color color) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color,
      ),
      padding: const EdgeInsets.all(15),
      alignment: Alignment.bottomLeft,
      child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }

  // --- 3. UPDATED ADMIN BUTTON ---
  Widget _buildAdminEntryButton(BuildContext context, bool isSuperAdmin) {
    return InkWell(
      // Pass the permission level to the dashboard
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminDashboard(isSuperAdmin: isSuperAdmin))),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.orange),
            SizedBox(width: 10),
            Text("ADMIN CONTROL PANEL", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          ],
        ),
      ),
    );
  }
}