import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'registration_screen.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
            child: Center( // Wrapped in Center to ensure vertical/horizontal centering if needed
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center, // Aligns items vertically
                    crossAxisAlignment: CrossAxisAlignment.center, // Aligns items horizontally
                    children: [
                      // Removed fixed SizedBox(height: 150) to allow natural centering

                      // Animated NACOS Logo
                      Image.asset(
                        "assets/images/nacos_logo.png",
                        width: 120,
                        height: 120,
                      )
                          .animate()
                          .scale(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.bounceOut,
                      )
                          .fadeIn(duration: const Duration(milliseconds: 500)),

                      const SizedBox(height: 20),

                      // UPDATED TITLE TEXT
                      Text(
                        "NACOS TECHVOTE",
                        textAlign: TextAlign.center, // <--- This centers the text even if it wraps
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontSize: 40, // Reduced from 50 to fit mobile screens better
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 10),

                      // UPDATED SUBTITLE TEXT
                      Text(
                        "Secure • Transparent • Real-time",
                        textAlign: TextAlign.center, // <--- Added centering here too
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 17,
                        ),
                      ).animate().fadeIn(delay: 500.ms),

                      const SizedBox(height: 50),

                      // Login Button
                      _buildWelcomeButton(
                        context,
                        "LOGIN",
                        const Color(0xFFFFD700), // Yellow
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