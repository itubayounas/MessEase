import 'package:flutter/material.dart';

enum PasswordStrength { weak, mild, strong }

// Coloured bar + label shown under the password field.
// It listens to the controller itself, so the page doesn't need setState.
class PasswordStrengthIndicator extends StatelessWidget {
  final TextEditingController controller;

  const PasswordStrengthIndicator({super.key, required this.controller});

  // Simple rule-based score: +1 for each of
  // 8+ characters, upper & lower case, a number, a symbol.
  PasswordStrength _getStrength(String password) {
    if (password.length < 6) return PasswordStrength.weak;

    int score = 0;
    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[A-Z]'))) {
      score++;
    }
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;

    if (score <= 1) return PasswordStrength.weak;
    if (score <= 3) return PasswordStrength.mild;
    return PasswordStrength.strong;
  }

  String _label(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.mild:
        return 'Mild';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  Color _color(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.mild:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.green;
    }
  }

  double _progress(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.weak:
        return 0.33;
      case PasswordStrength.mild:
        return 0.66;
      case PasswordStrength.strong:
        return 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // A TextEditingController notifies its listeners on every key press,
    // so this builder re-runs while the user types.
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        if (value.text.isEmpty) return const SizedBox.shrink();

        final strength = _getStrength(value.text);
        final color = _color(strength);

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: _progress(strength),
                color: color,
                backgroundColor: Colors.grey.shade300,
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 4),
              Text(
                'Password strength: ${_label(strength)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              if (strength != PasswordStrength.strong)
                const Text(
                  'Tip: use 8+ characters with upper & lower case letters, numbers and symbols',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
        );
      },
    );
  }
}