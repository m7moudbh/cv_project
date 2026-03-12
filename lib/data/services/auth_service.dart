import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  // ─── Register ───────────────────────────────────────────────────────────────
  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String fullName,
    String? jobTitle,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(fullName);

      // Save user profile to Firestore
      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set({
        'uid': credential.user!.uid,
        'email': email.trim(),
        'fullName': fullName,
        'jobTitle': jobTitle ?? '',
        'photoUrl': '',
        'bio': '',
        'phone': '',
        'location': '',
        'website': '',
        'linkedIn': '',
        'github': '',
        'skills': [],
        'experience': [],
        'education': [],
        'projects': [],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ─── Login ──────────────────────────────────────────────────────────────────
  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Handle Remember Me
      await _handleRememberMe(email: email, remember: rememberMe);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ─── Logout ─────────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Delete Account ──────────────────────────────────────────────────────────
  // Firebase requires recent login before deletion — we re-authenticate first
  Future<void> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null) throw 'No user signed in';

    try {
      // Step 1: Re-authenticate (required by Firebase for sensitive operations)
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Step 2: Delete Firestore data first
      await _firestore.collection('users').doc(user.uid).delete();

      // Step 3: Clear saved login preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Step 4: Delete Firebase Auth account
      await user.delete();

    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'Failed to delete account: $e';
    }
  }

  // ─── Password Reset ──────────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ─── Remember Me ────────────────────────────────────────────────────────────
  Future<void> _handleRememberMe({
    required String email,
    required bool remember,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (remember) {
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_savedEmailKey, email);
    } else {
      await prefs.setBool(_rememberMeKey, false);
      await prefs.remove(_savedEmailKey);
    }
  }

  Future<Map<String, dynamic>> getSavedLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'rememberMe': prefs.getBool(_rememberMeKey) ?? false,
      'email': prefs.getString(_savedEmailKey) ?? '',
    };
  }

  // ─── Firestore User Data ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  Future<void> updateUserData(
      String uid, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(uid).update(data);
  }

  // ─── Error Handler ───────────────────────────────────────────────────────────
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return e.message ?? 'An unexpected error occurred.';
    }
  }
}