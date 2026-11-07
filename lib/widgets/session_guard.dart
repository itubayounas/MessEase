import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/session_service.dart';

// Wraps a signed-in screen. It claims the single-device session first
// (showing a spinner) and signs the user out with a message if a different
// device already owns the account.
class SessionGuard extends StatefulWidget {
  final String uid;
  final Widget child;

  const SessionGuard({super.key, required this.uid, required this.child});

  @override
  State<SessionGuard> createState() => _SessionGuardState();
}

class _SessionGuardState extends State<SessionGuard> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    bool ok;
    try {
      ok = await SessionService.claim(widget.uid);
    } catch (e) {
      // Strict mode: if we can't verify the session, don't let the user in.
      debugPrint('Session check failed: $e');
      SessionService.pendingMessage =
          'Could not verify your login. Check your internet and try again.';
      await FirebaseAuth.instance.signOut();
      return;
    }
    if (!mounted) return;

    if (!ok) {
      SessionService.pendingMessage =
          'This account is already logged in on another device. '
          'Log out there first, then try again.';
      // Plain signOut: this device does not own the session.
      await FirebaseAuth.instance.signOut();
      return;
    }

    setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}