import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'user_service.dart';

// Keeps the Firebase calls for the extra auth features in one place,
// so the screens stay clean and both pages can reuse them.
class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // google_sign_in must be initialized only once for the whole app,
  // so this flag is static (shared by every AuthService object).
  static bool _googleInitialized = false;

  // ---------- Google sign-in ----------
  // Returns null if the user just closed the Google window.
  // A new Google account is created in Firebase automatically, and a
  // student profile is created for it if it doesn't have one yet,
  // so the same method works for both login and registration.
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final UserCredential credential;

      if (kIsWeb) {
        // On web Firebase handles everything with a popup.
        credential = await _auth.signInWithPopup(GoogleAuthProvider());
      } else {
        // Android / iOS: pick the Google account, then give its token to Firebase.
        if (!_googleInitialized) {
          await GoogleSignIn.instance.initialize();
          _googleInitialized = true;
        }

        final account = await GoogleSignIn.instance.authenticate();
        final googleCredential = GoogleAuthProvider.credential(
          idToken: account.authentication.idToken,
        );
        credential = await _auth.signInWithCredential(googleCredential);
      }

      // Make sure the user has a Firestore profile (new Google users don't).
      final user = credential.user;
      if (user != null) {
        try {
          await UserService().ensureProfileForGoogleUser(user);
        } catch (e) {
          // Don't leave someone signed in without a profile.
          await _auth.signOut();
          rethrow;
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'popup-closed-by-user' ||
          e.code == 'cancelled-popup-request') {
        return null;
      }
      rethrow;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  // ---------- Forgot password ----------
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email);
  }

  // ---------- Username availability ----------
  // Every taken username is a document in the "usernames" collection,
  // and the lowercase name is the document id, so "Tuba" and "tuba"
  // count as the same name.
  Future<bool> isUsernameAvailable(String username) async {
    final doc =
        await _db.collection('usernames').doc(username.toLowerCase()).get();
    return !doc.exists;
  }

  Future<void> saveUsername(String username, String uid) {
    return _db.collection('usernames').doc(username.toLowerCase()).set({
      'username': username,
      'uid': uid,
    });
  }
}