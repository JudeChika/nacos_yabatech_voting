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
      // -----------------------------------------------------------------------
      final QuerySnapshot result = await _db
          .collection('users')
          .where('matricNumber', isEqualTo: matricNumber)
          .limit(1)
          .get();

      if (result.docs.isNotEmpty) {
        return "This Matric Number is already registered with another account.";
      }

      // -----------------------------------------------------------------------
      // STEP 2: CREATE USER IN FIREBASE AUTH
      // -----------------------------------------------------------------------
      UserCredential authResult = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 30));

      User? user = authResult.user;

      // -----------------------------------------------------------------------
      // STEP 3: CREATE FIRESTORE PROFILE
      // -----------------------------------------------------------------------
      if (user != null) {
        await _db.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'fullName': fullName,
          'matricNumber': matricNumber,
          'email': email,
          'isAccredited': false,
          'hasVoted': false,
          'votedPositions': {},
          'role': 'voter',
          'registrationDate': FieldValue.serverTimestamp(),
        });
      }

      return null; // Success

    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return "This email is already registered. Please login instead.";
        case 'weak-password':
          return "Password is too weak.";
        default:
          return e.message ?? "Authentication error: ${e.code}";
      }
    } catch (e) {
      return "Unexpected error: ${e.toString()}";
    }
  }

  // LOGIN logic
  Future<String?> loginStudent(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      ).timeout(const Duration(seconds: 30));
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Login error: ${e.code}";
    } catch (e) {
      return "Unexpected error: ${e.toString()}";
    }
  }

  // --- NEW FEATURE: PASSWORD RESET ---
  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Error sending reset email.";
    } catch (e) {
      return "Unexpected error: ${e.toString()}";
    }
  }
}