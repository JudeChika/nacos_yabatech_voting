import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nacos_yabatech_voting/auth_gate.dart';
import 'firebase_options.dart';
// 1. IMPORT THIS FOR WEB ROUTING
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. ACTIVATE PATH URL STRATEGY (Removes the # from URLs)
  usePathUrlStrategy();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const NacosVoteApp());
}

class NacosVoteApp extends StatelessWidget {
  const NacosVoteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NACOS Yabatech Vote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF006400),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006400),
          secondary: const Color(0xFFFFD700),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFD700),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
      home: const AuthGate(),

      // This route captures the deep link and passes it to AuthGate
      // AuthGate -> Home/Welcome -> initState checks URL -> Navigates to Feed
      routes: {
        '/feed': (context) => const AuthGate(),
      },
    );
  }
}