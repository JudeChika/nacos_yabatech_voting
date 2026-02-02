import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:nacos_yabatech_voting/views/war_room.dart';
import 'package:nacos_yabatech_voting/views/voting_screen.dart';
import 'package:nacos_yabatech_voting/views/feed_screen.dart';
import 'package:nacos_yabatech_voting/views/gallery_screen.dart';
import 'package:nacos_yabatech_voting/views/executives_screen.dart';
import 'admin_dashboard.dart';
import 'welcome_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    super.initState();
    // Check for Deep Link on Init (Fixes the Feed sharing issue)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDeepLink();
    });
  }

  void _checkDeepLink() {
    // Check if the current URL has an 'id' parameter (e.g., .../feed?id=123)
    if (Uri.base.queryParameters.containsKey('id')) {
      print("🔗 Deep Link Detected: Navigating to Feed");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FeedScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const Color yabaGreen = Color(0xFF006400);

    // --- 1. DEFINE ADMIN ROLES (Preserved) ---
    // Super Admins: Have full access
    final List<String> superAdminEmails = [
      "jude2chika@gmail.com",
      "emmaexcel0@gmail.com",
      "ayoakeni64@gmail.com",
    ];

    // Pro Admins: Include Super Admins + General Admins
    final List<String> adminEmails = [
      "ekusinakpan9@gmail.com", // Example: Add the PRO's specific email here
      "jude2chika@gmail.com",
      "ayemoandrewgold@gmail.com",
    ];

    // Check permissions
    bool isSuperAdmin = user != null && superAdminEmails.contains(user.email);
    bool isAdmin = user != null && adminEmails.contains(user.email);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Welcome Back,",
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey),
                      ),
                      Text(
                        user?.displayName ?? "NACOSite",
                        style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: yabaGreen),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: yabaGreen.withOpacity(0.1),
                    child: const Icon(Icons.person, color: yabaGreen),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // ADMIN DASHBOARD BUTTON (Visible only to Admins)
              // This preserves the check: Only Admins see this button.
              // We pass 'isSuperAdmin' so the Dashboard knows if they are Super or Pro.
              if (isAdmin) ...[
                _buildAdminEntryButton(context, isSuperAdmin),
                const SizedBox(height: 30),
              ],

              // MAIN MENU GRID
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 1.1,
                children: [
                  _buildMenuCard(context, "Vote", Icons.how_to_vote, Colors.blueAccent, const VotingScreen()),
                  _buildMenuCard(context, "News Feed", Icons.newspaper, Colors.orangeAccent, const FeedScreen()),
                  _buildMenuCard(context, "Executives", Icons.groups, yabaGreen, const ExecutivesScreen()),
                  _buildMenuCard(context, "War Room", Icons.analytics, Colors.redAccent, const WarRoom()),
                ],
              ),

              const SizedBox(height: 30),

              // GALLERY SECTION
              Text("Gallery", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildGalleryCard("Tech Week", Colors.purple.withOpacity(0.6)),
                    _buildGalleryCard("Dinner Night", Colors.pink.withOpacity(0.6)),
                    _buildGalleryCard("Student Life", Colors.blue.withOpacity(0.6)),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Logout Button
              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if(context.mounted) {
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
                              (route) => false
                      );
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text("Logout", style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => page)),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 10),
            Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ).animate().scale(duration: 300.ms),
    );
  }

  Widget _buildGalleryCard(String title, Color color) {
    return Container(
      width: 180,
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

  // --- ADMIN BUTTON WITH ROLE PASSING ---
  Widget _buildAdminEntryButton(BuildContext context, bool isSuperAdmin) {
    return InkWell(
      // Crucial: We pass 'isSuperAdmin' to the dashboard so it can hide/show features
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AdminDashboard(isSuperAdmin: isSuperAdmin))),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.orange)),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.orange),
            SizedBox(width: 10),
            Text("ADMIN CONTROL PANEL", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}