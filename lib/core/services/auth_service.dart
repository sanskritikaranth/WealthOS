import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// The live stream of auth state — used by AuthGate to reactively
  /// switch between Login and Dashboard, including on app restart.
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static bool get isLoggedIn => _auth.currentUser != null;

  static String? get currentUserEmail => _auth.currentUser?.email;

  static String? get currentUserId => _auth.currentUser?.uid;

  /// Returns null on success, or a human-readable error message on failure.
  static Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    }
  }

  /// Returns null on success, or a human-readable error message on failure.
  static Future<String?> logIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapError(e);
    }
  }

  static Future<void> logOut() async {
    await _auth.signOut();
  }

  static String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}