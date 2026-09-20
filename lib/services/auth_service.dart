import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> superAdminEmails = [
    'markanaumang@gmail.com',
    'gauravnimavat1993@gmail.com',
  ];

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Check if the currently logged-in user is the super admin
  bool get isSuperAdmin {
    final email = currentUser?.email?.toLowerCase();
    return email != null && superAdminEmails.contains(email);
  }

  // Sign In with Email & Password
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await ensureTeacherDocExists();
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Register with Email & Password
  Future<UserCredential> registerWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      await ensureTeacherDocExists();
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Ensure a teacher document exists in Firestore for the current user.
  // Super admin gets all permissions by default; regular teachers get canAddManually only.
  Future<void> ensureTeacherDocExists() async {
    final user = currentUser;
    if (user == null) return;

    try {
      final docRef = _firestore.collection('users').doc(user.uid);
      final doc = await docRef.get();

      if (!doc.exists) {
        final isAdmin = user.email != null && superAdminEmails.contains(user.email!.toLowerCase());
        await docRef.set({
          'email': user.email ?? '',
          'canAddManually': true,
          'canImportCsv': isAdmin,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Log the error but do not rethrow.
      // If we throw here, the auth flow fails in the UI even though the user was successfully authenticated in Firebase Auth.
      debugPrint('Error ensuring teacher doc exists: $e');
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
