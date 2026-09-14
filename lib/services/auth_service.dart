import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String superAdminEmail = 'markanaumang@gmail.com';

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // Check if the currently logged-in user is the super admin
  bool get isSuperAdmin {
    return currentUser?.email?.toLowerCase() == superAdminEmail;
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

    final docRef = _firestore.collection('teachers').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      final isAdmin = user.email?.toLowerCase() == superAdminEmail;
      await docRef.set({
        'email': user.email ?? '',
        'canAddManually': true,
        'canImportCsv': isAdmin,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
