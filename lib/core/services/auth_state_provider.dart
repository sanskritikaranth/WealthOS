import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A single shared source of truth for "who is logged in right now."
/// Watching this from any Notifier forces that Notifier to rebuild
/// (and cancel/reopen its Firestore subscriptions) on every login/logout.
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});