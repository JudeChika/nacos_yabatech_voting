import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Register Student logic
  Future<String?> registerStudent({
    required String email,
    required String password,
    required String fullName,
    required String matricNumber,
  }) async {
    print("📝 AuthService: Starting registration for $email");

    try {
      // -----------------------------------------------------------------------
      // STEP 1: DUPLICATE MATRIC NUMBER CHECK
      // Query the database to see if this Matric Number exists on ANY account.
      // -----------------------------------------------------------------------
      final QuerySnapshot result = await _db
          .collection('users')
          .where('matricNumber', isEqualTo: matricNumber)
          .limit(1) // Stop searching as soon as we find one match
          .get();

      if (result.docs.isNotEmpty) {
        print("⛔ Registration Blocked: Matric Number $matricNumber already exists.");
        return "This Matric Number is already registered with another account.";
      }

      // -----------------------------------------------------------------------
      // STEP 2: CREATE USER IN FIREBASE AUTH
      // (This automatically handles the duplicate Email check)
      // -----------------------------------------------------------------------
      print("🔐 AuthService: Creating Firebase Auth user...");

      UserCredential authResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print("⏰ AuthService: Firebase Auth timeout");
          throw Exception("Registration timeout. Please check your internet connection.");
        },
      );

      print("✅ AuthService: Firebase Auth user created - UID: ${authResult.user?.uid}");

      User? user = authResult.user;

      // -----------------------------------------------------------------------
      // STEP 3: CREATE FIRESTORE PROFILE
      // -----------------------------------------------------------------------
      if (user != null) {
        print("💾 AuthService: Creating Firestore document...");

        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName,
          'matricNumber': matricNumber,
          'email': email,
          'isAccredited': false,
          'hasVoted': false,
          'votedPositions': {}, // Initialize empty map for vote tracking
          'role': 'voter',
          'registrationDate': FieldValue.serverTimestamp(),
        }).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print("⏰ AuthService: Firestore write timeout");
            throw Exception("Database write timeout. Please try again.");
          },
        );

        print("✅ AuthService: Firestore document created successfully");
      } else {
        print("❌ AuthService: User object is null after creation");
        return "User creation failed - no user object returned";
      }

      print("🎉 AuthService: Registration completed successfully");
      return null; // Success (null means no error)

    } on FirebaseAuthException catch (e) {
      print("❌ AuthService: FirebaseAuthException - Code: ${e.code}");

      // Specific Firebase Auth Errors
      switch (e.code) {
        case 'email-already-in-use':
          return "This email is already registered. Please login instead.";
        case 'invalid-email':
          return "Invalid email address format.";
        case 'operation-not-allowed':
          return "Email/password accounts are not enabled. Contact support.";
        case 'weak-password':
          return "Password is too weak. Please use a stronger password.";
        case 'network-request-failed':
          return "Network error. Please check your internet connection.";
        default:
          return e.message ?? "Authentication error: ${e.code}";
      }

    } on FirebaseException catch (e) {
      //print("❌ AuthService: FirebaseException - Code: ${e.code}");
      return "Database error: ${e.message}";

    } catch (e) {
      print("❌ AuthService: Generic exception - $e");
      return "Unexpected error: ${e.toString()}";
    }
  }

  // LOGIN logic
  Future<String?> loginStudent(String email, String password) async {
    print("🔑 AuthService: Attempting login for $email");

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print("⏰ AuthService: Login timeout");
          throw Exception("Login timeout. Please check your internet connection.");
        },
      );

      print("✅ AuthService: Login successful");
      return null; // Success

    } on FirebaseAuthException catch (e) {
      print("❌ AuthService: Login failed - Code: ${e.code}");

      switch (e.code) {
        case 'user-not-found':
          return "No account found with this email. Please register first.";
        case 'wrong-password':
          return "Incorrect password. Please try again.";
        case 'invalid-email':
          return "Invalid email address format.";
        case 'user-disabled':
          return "This account has been disabled. Please contact support.";
        case 'network-request-failed':
          return "Network error. Please check your internet connection.";
        default:
          return e.message ?? "Login error: ${e.code}";
      }
    } catch (e) {
      print("❌ AuthService: Login exception - $e");
      return "Unexpected error: ${e.toString()}";
    }
  }
}