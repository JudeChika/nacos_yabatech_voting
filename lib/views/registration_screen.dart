import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _matricController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void dispose() {
    _matricController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleRegistration() async {
    // Debug print to confirm function is called
    print("🔵 Registration button clicked");

    // Validate all fields
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _nameController.text.trim();
    final matric = _matricController.text.trim();

    if (email.isEmpty || password.isEmpty || fullName.isEmpty || matric.isEmpty) {
      print("🔴 Validation failed - empty fields");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    print("🟢 Validation passed, starting registration...");

    // Start loading
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    print("🟡 Loading state set to true");

    try {
      print("⚙️ Calling registerStudent...");

      // Attempt registration
      final String? error = await _authService.registerStudent(
        email: email,
        password: password,
        fullName: fullName,
        matricNumber: matric,
      );

      print("✅ registerStudent completed. Error: ${error ?? 'none'}");

      // Sign out immediately
      print("🔐 Signing out user...");
      await FirebaseAuth.instance.signOut();
      print("✅ Sign out completed");

      // Check if widget is still mounted
      if (!mounted) {
        print("⚠️ Widget not mounted, aborting");
        return;
      }

      // Stop loading
      print("🛑 Stopping loading state...");
      setState(() {
        _isLoading = false;
      });
      print("✅ Loading state set to false");

      // Handle error case
      if (error != null) {
        print("❌ Registration error: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $error"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Success - show dialog
      print("🎉 Registration successful, showing dialog...");

      if (!mounted) return;

      // Use a simpler approach - direct navigation without dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Registration Successful! Please login to continue."),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Wait a moment, then navigate back
      await Future.delayed(const Duration(milliseconds: 2500));

      if (mounted) {
        print("🔙 Navigating back to welcome screen...");
        Navigator.of(context).pop();
      }

    } catch (e) {
      print("💥 Exception caught: $e");

      // Try to sign out even on error
      try {
        await FirebaseAuth.instance.signOut();
      } catch (signOutError) {
        print("⚠️ Sign out error: $signOutError");
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unexpected error: $e"),
          backgroundColor: Colors.red,
        ),
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

          // Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.4),
          ),

          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo/Header with Animation
                    const Icon(
                      Icons.how_to_reg_rounded,
                      color: Color(0xFFFFD700),
                      size: 80,
                    )
                        .animate()
                        .fade(duration: 500.ms)
                        .scale(delay: 200.ms),

                    const SizedBox(height: 10),

                    Text(
                      "NACOS TECHVOTE",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 30),

                    // Glassmorphic Registration Form
                    ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildTextField(
                                "Matric Number",
                                Icons.badge_outlined,
                                _matricController,
                              ),
                              const SizedBox(height: 15),

                              _buildTextField(
                                "Full Name",
                                Icons.person_outline,
                                _nameController,
                              ),
                              const SizedBox(height: 15),

                              _buildTextField(
                                "Email Address",
                                Icons.email_outlined,
                                _emailController,
                              ),
                              const SizedBox(height: 15),

                              _buildTextField(
                                "Password",
                                Icons.lock_outline,
                                _passwordController,
                                isPassword: true,
                              ),
                              const SizedBox(height: 30),

                              // Register Button
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleRegistration,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFFD700),
                                    disabledBackgroundColor: Colors.grey,
                                    foregroundColor: Colors.black,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 5,
                                  ),
                                  child: _isLoading
                                      ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.black,
                                          strokeWidth: 2.5,
                                        ),
                                      ),
                                      SizedBox(width: 15),
                                      Text(
                                        "REGISTERING...",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ],
                                  )
                                      : const Text(
                                    "REGISTER",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().slideY(begin: 0.1, end: 0, duration: 600.ms).fadeIn(),

                    const SizedBox(height: 20),

                    // Back to Login
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text(
                        "Already have an account? Login",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label,
      IconData icon,
      TextEditingController controller, {
        bool isPassword = false,
      }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      enabled: !_isLoading,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFFFFD700)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFFFD700)),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
    );
  }
}