import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

// "Continue with Google" button used on both the login and registration
// screens. It handles its own loading state and errors, so the pages
// don't need any extra code.
class GoogleSignInButton extends StatefulWidget {
  final String label;

  // Called after a successful Google sign-in. The registration page uses it
  // to close itself, so the user lands on the home screen.
  final VoidCallback? onSuccess;

  const GoogleSignInButton({
    super.key,
    this.label = 'Continue with Google',
    this.onSuccess,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithGoogle();

      // result is null when the user closed the Google window.
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed in with Google')),
        );
        widget.onSuccess?.call();
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Google sign-in failed, please try again');
    } catch (e) {
      debugPrint('Google sign-in failed: $e');
      _showError('Google sign-in failed, please try again');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _isLoading ? null : _handleGoogleSignIn,
        icon: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.g_mobiledata, size: 32),
        label: Text(widget.label, style: const TextStyle(fontSize: 16)),
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}

// Small "---- OR ----" separator between the email form and the Google button.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('OR', style: TextStyle(color: Colors.grey)),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}