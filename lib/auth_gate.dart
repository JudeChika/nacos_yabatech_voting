import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nacos_yabatech_voting/views/home_screen.dart';
import 'package:nacos_yabatech_voting/views/welcome_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // User is not signed in, show welcome screen
        if (!snapshot.hasData) {
          return const WelcomeScreen();
        }

        // User is signed in, show home screen
        return const HomeScreen();
      },
    );
  }
}
