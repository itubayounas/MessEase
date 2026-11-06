import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;

import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/google_sign_in_button.dart';
import '../widgets/password_strength_indicator.dart';
import '../utils/validators.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();

  final _auth = FirebaseAuth.instance;
  final _authService = AuthService();
  final _userService = UserService();

  // Text controllers
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  // Username availability states
  bool _checkingUsername = false;
  bool? _usernameAvailable;

  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();

    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // -----------------------------------------
  // USERNAME AVAILABILITY CHECK
  // -----------------------------------------

  void _onUsernameChanged(String value) {
    _debounce?.cancel();

    final username = value.trim();

    // Check basic username validation first.
    if (Validators.validateUsername(username) != null) {
      setState(() {
        _checkingUsername = false;
        _usernameAvailable = null;
      });
      return;
    }

    setState(() {
      _checkingUsername = true;
      _usernameAvailable = null;
    });

    // Wait 500ms before checking Firestore.
    _debounce = Timer(
      const Duration(milliseconds: 500),
      () async {
        try {
          final available =
              await _authService.isUsernameAvailable(username);

          // Ignore outdated results.
          if (!mounted ||
              username != _usernameController.text.trim()) {
            return;
          }

          setState(() {
            _usernameAvailable = available;
            _checkingUsername = false;
          });
        } catch (e) {
          debugPrint('Username check failed: $e');

          if (mounted) {
            setState(() {
              _checkingUsername = false;
              _usernameAvailable = null;
            });
          }
        }
      },
    );
  }

  // -----------------------------------------
  // REGISTRATION
  // -----------------------------------------

  Future<void> _handleRegister() async {
    // Validate all input fields.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      // Check username availability again before registration.
      final available =
          await _authService.isUsernameAvailable(username);

      if (!available) {
        _showError('This username is already taken.');
        return;
      }

      // Step 1: Create account in Firebase Authentication.
      final credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user!;

      try {
        // Step 2: Save username in Firebase Auth profile.
        await user.updateDisplayName(username);

        // Step 3: Create user profile and reserve username
        // atomically in Firestore.
        await _userService.createStudentProfile(
          uid: user.uid,
          username: username,
          email: email,
        );
      } catch (e) {
        // If profile creation fails, remove the newly created
        // Authentication account to avoid an incomplete account.
        try {
          await user.delete();
        } catch (deleteError) {
          debugPrint(
            'Account cleanup failed: $deleteError',
          );
        }

        rethrow;
      }

      // Step 4: Registration completed successfully.
      // Firebase logs the new user in automatically when the account is
      // created, so log out again. The user then logs in from the login page.
      await _auth.signOut();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please log in.'),
          backgroundColor: Colors.green,
        ),
      );

      // Return to login page.
      Navigator.pop(context);

    } on FirebaseAuthException catch (e) {
      _showError(_messageForAuthError(e));

    } on FirebaseException catch (e) {
      _showError(
        e.message ?? 'Database error. Please try again.',
      );

    } on StateError catch (e) {
      _showError(e.message.toString());

    } catch (e) {
      debugPrint('Registration error: $e');
      _showError('Something went wrong. Please try again.');

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // -----------------------------------------
  // FIREBASE AUTH ERROR MESSAGES
  // -----------------------------------------

  String _messageForAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email.';

      case 'invalid-email':
        return 'Please enter a valid email address.';

      case 'weak-password':
        return 'Your password is too weak.';

      case 'operation-not-allowed':
        return 'Email and password registration is not enabled.';

      case 'network-request-failed':
        return 'Network error. Check your internet connection.';

      default:
        return e.message ??
            'Authentication failed. Please try again.';
    }
  }

  // -----------------------------------------
  // SHOW ERROR MESSAGE
  // -----------------------------------------

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // -----------------------------------------
  // USERNAME STATUS MESSAGE
  // -----------------------------------------

  Widget _buildUsernameStatus() {
    if (_checkingUsername) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text(
          'Checking username availability...',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      );
    }

    if (_usernameAvailable == null) {
      return const SizedBox.shrink();
    }

    final available = _usernameAvailable!;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        available
            ? 'Username is available'
            : 'Username is already taken',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: available ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  // -----------------------------------------
  // REGISTRATION UI
  // -----------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),

          child: Form(
            key: _formKey,

            child: ListView(
              children: [

                const SizedBox(height: 20),

                const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Create an account to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 28),

                // USERNAME
                CustomTextField(
                  controller: _usernameController,
                  label: 'Username',
                  icon: Icons.person_outline,
                  validator: Validators.validateUsername,
                  onChanged: _onUsernameChanged,
                ),

                _buildUsernameStatus(),

                const SizedBox(height: 16),

                // EMAIL
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),

                const SizedBox(height: 16),

                // PASSWORD
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  isPassword: true,
                  validator: Validators.validatePassword,
                ),

                // PASSWORD STRENGTH
                PasswordStrengthIndicator(
                  controller: _passwordController,
                ),

                const SizedBox(height: 16),

                // CONFIRM PASSWORD
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  icon: Icons.lock_outline,
                  isPassword: true,

                  validator: (value) {
                    return Validators.validateConfirmPassword(
                      value,
                      _passwordController.text,
                    );
                  },
                ),

                const SizedBox(height: 24),

                // REGISTER BUTTON
                SizedBox(
                  height: 48,

                  child: ElevatedButton(
                    onPressed:
                        _isLoading ? null : _handleRegister,

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),

                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,

                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )

                        : const Text(
                            'Register',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                const OrDivider(),

                const SizedBox(height: 20),

                // GOOGLE SIGN UP
                GoogleSignInButton(
                  label: 'Sign up with Google',
                  onSuccess: () => Navigator.pop(context),
                ),

                const SizedBox(height: 16),

                // LOGIN NAVIGATION
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [
                    const Text(
                      'Already have an account?',
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },

                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}