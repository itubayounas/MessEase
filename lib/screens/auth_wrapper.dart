import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_dashboard.dart';
import 'login_page.dart';
import 'student_dashboard.dart';
import '../services/session_service.dart';
import '../widgets/session_guard.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Waiting for Firebase Authentication
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is not logged in
        final user = authSnapshot.data;

        if (user == null) {
          return const LoginPage();
        }

        // User is logged in: listen to their Firestore profile.
        // This is a live stream, not a one-time read. If the profile is saved
        // a moment AFTER the account is created (registration, first Google
        // sign-in), this screen updates by itself instead of showing an error.
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              debugPrint('Profile error: ${profileSnapshot.error}');
              return _messageScreen('Error loading user profile.');
            }

            final data = profileSnapshot.data?.data();

            // No profile yet (still loading, or being created right now): wait.
            if (data == null) {
              return _messageScreen(
                'Setting up your account...',
                showSpinner: true,
              );
            }

            // trim() so a stray space such as "admin " in Firestore still works.
            final role =
                (data['role'] as String? ?? '').trim().toLowerCase();
            final username =
                data['username'] as String? ?? user.email ?? 'User';

            // Navigate according to role
            if (role == 'student') {
              // Students may be logged in on one device at a time.
              return SessionGuard(
                uid: user.uid,
                child: StudentDashboard(username: username),
              );
            }

            if (role == 'admin') {
              return AdminDashboard(username: username);
            }

            return _messageScreen('Invalid user role.');
          },
        );
      },
    );
  }

  // Simple message screen with a Log out button, so nobody gets stuck on it.
  Widget _messageScreen(String message, {bool showSpinner = false}) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSpinner) ...[
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
            ],
            Text(message),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => SessionService.signOut(),
              child: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}