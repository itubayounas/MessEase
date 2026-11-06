import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new student profile.
  Future<void> createStudentProfile({
    required String uid,
    required String username,
    required String email,
  }) async {
    final userRef = _db.collection('users').doc(uid);

    final usernameRef = _db
        .collection('usernames')
        .doc(username.toLowerCase());

    await _db.runTransaction((transaction) async {
      final usernameSnapshot = await transaction.get(usernameRef);

      if (usernameSnapshot.exists) {
        throw StateError('Username is already taken');
      }

      final user = UserModel(
        uid: uid,
        username: username,
        email: email,
        role: 'student',
      );

      transaction.set(userRef, user.toMap());

      transaction.set(usernameRef, {
        'username': username,
        'uid': uid,
      });
    });
  }

  // Google sign-in skips the registration form, so a brand-new Google user
  // has no profile yet. This creates one (as a student) if it is missing.
  // The username comes from the email, e.g. "tuba.younas@gmail.com" becomes
  // "tubayounas"; a number is added if that name is already taken.
  Future<void> ensureProfileForGoogleUser(User user) async {
    final existing = await _db.collection('users').doc(user.uid).get();
    if (existing.exists) return;

    var base = (user.email ?? 'user')
        .split('@')
        .first
        .replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '');
    if (base.length < 3) base = 'user$base';
    if (base.length > 14) base = base.substring(0, 14);

    for (var i = 0; i < 20; i++) {
      final candidate = i == 0 ? base : '$base$i';
      try {
        await createStudentProfile(
          uid: user.uid,
          username: candidate,
          email: user.email ?? '',
        );
        return;
      } on StateError {
        continue; // name taken, try the next one
      }
    }
    throw StateError('Could not create a username. Please try again.');
  }

  // Get user profile from Firestore.
  Future<UserModel?> getUserProfile(String uid) async {
    final snapshot = await _db.collection('users').doc(uid).get();

    if (!snapshot.exists || snapshot.data() == null) {
      return null;
    }

    return UserModel.fromMap(snapshot.data()!);
  }
}