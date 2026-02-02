import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'registration_screen.dart';
import 'login_screen.dart';
import 'feed_screen.dart'; // Import FeedScreen

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {

  @override
  void initState() {
    super.initState();
    // Check for Deep Link on Init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDeepLink();
    });
  }

  void _checkDeepLink() {
    // If a user clicks a shared link but isn't logged in, allow them to see the Feed
    if (Uri.base.queryParameters.containsKey('id')) {
      print("🔗 Deep Link Detected (Guest): Navigating to Feed");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FeedScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/yabatech_bg.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  const Color(0xFF006400).withOpacity(0.9), // Yabatech Green
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo or Icon
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset("assets/images/yabatech_logo.png", height: 80, errorBuilder: (c,e,s) => const Icon(Icons.school, size: 60, color: Colors.white)),
                      ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                      const SizedBox(height: 30),

                      Text(
                        "NACOS VOTING",
                        style: GoogleFonts.orbitron(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2.0,
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),

                      Text(
                        "Yaba College of Technology",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ).animate().fadeIn(delay: 500.ms),

                      const SizedBox(height: 50),

                      // Login Button
                      _buildWelcomeButton(
                        context,
                        "LOGIN",
                        const Color(0xFFFFD700), // Gold
                        Colors.black,
                            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
                      ).animate().slideX(begin: -0.2, end: 0, delay: 700.ms).fadeIn(),

                      const SizedBox(height: 15),

                      // Register Button
                      _buildWelcomeButton(
                        context,
                        "REGISTER",
                        Colors.white.withOpacity(0.2),
                        Colors.white,
                            () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationScreen())),
                        isBordered: true,
                      ).animate().slideX(begin: 0.2, end: 0, delay: 900.ms).fadeIn(),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeButton(BuildContext context, String label, Color bgColor, Color textColor, VoidCallback onTap, {bool isBordered = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          border: isBordered ? Border.all(color: Colors.white, width: 1.5) : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5),
          ),
        ),
      ),
    );
  }
}