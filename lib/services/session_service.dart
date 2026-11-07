import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Strict single-device login. The users/{uid} document holds:
//   activeDeviceId - the device that currently owns the login
// While it is set, every other device is refused. It is cleared ONLY when
// the owning device logs out. There is no timeout.
class SessionService {
  // Message for the login screen after a refusal.
  static String? pendingMessage;

  static String? _deviceId;

  // A random id, created once and remembered on this device / browser.
  static Future<String> deviceId() async {
    if (_deviceId != null) return _deviceId!;
    try {
      final prefs = await SharedPreferences.getInstance();
      var id = prefs.getString('deviceId');
      if (id == null) {
        id = _randomId();
        await prefs.setString('deviceId', id);
      }
      return _deviceId = id;
    } catch (_) {
      return _deviceId = _randomId();
    }
  }

  static String _randomId() {
    final r = Random.secure();
    return List.generate(24, (_) => r.nextInt(36).toRadixString(36)).join();
  }

  static DocumentReference<Map<String, dynamic>> _ref(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid);

  // Makes this device the owner of the login. Returns false if a DIFFERENT
  // device already owns it. Returns true if nobody does, or this device does
  // (so reopening the app on the same device always works).
  static Future<bool> claim(String uid) async {
    final id = await deviceId();
    final ref = _ref(uid);

    return FirebaseFirestore.instance.runTransaction<bool>((tx) async {
      final snap = await tx.get(ref);
      final active = snap.data()?['activeDeviceId'] as String?;

      if (active == id) return true; // already ours
      if (active != null) return false; // another device owns it

      tx.update(ref, {'activeDeviceId': id});
      return true;
    });
  }

  // Frees the account, but only if this device is the one that owns it.
  static Future<void> release(String uid) async {
    final id = await deviceId();
    final ref = _ref(uid);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.data()?['activeDeviceId'] == id) {
        tx.update(ref, {'activeDeviceId': FieldValue.delete()});
      }
    });
  }

  // Use this instead of FirebaseAuth.instance.signOut(). If the account
  // cannot be freed (e.g. no internet) the logout is cancelled and an
  // error is thrown, so the account never stays locked by accident.
  static Future<void> signOut() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) await release(user.uid);
    await FirebaseAuth.instance.signOut();
  }
}