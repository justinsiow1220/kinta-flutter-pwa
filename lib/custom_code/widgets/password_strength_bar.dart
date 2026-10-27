// Automatic FlutterFlow imports
// Imports other custom widgets
// Imports custom actions
// Imports custom functions
import 'package:flutter/material.dart' hide RepeatMode;
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

// Set your widget name, define your parameter, and then add the
// boilerplate code using the green button on the right!
import 'package:password_strength_checker/password_strength_checker.dart';

class PasswordStrengthBar extends StatefulWidget {
  const PasswordStrengthBar({
    super.key,
    this.width,
    this.height,
    this.passwordText,
  });

  final double? width;
  final double? height;
  final String? passwordText;

  @override
  State<PasswordStrengthBar> createState() => _PasswordStrengthBarState();
}

class _PasswordStrengthBarState extends State<PasswordStrengthBar> {
  final ValueNotifier<PasswordStrength?> _passNotifier =
      ValueNotifier<PasswordStrength?>(null);
  Color _currentColor = Colors.grey;

  @override
  void didUpdateWidget(PasswordStrengthBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.passwordText != oldWidget.passwordText) {
      if (widget.passwordText == null || widget.passwordText!.isEmpty) {
        _passNotifier.value = null;
        _currentColor = Colors.grey;
      } else {
        final text = widget.passwordText!;
        PasswordStrength strength;

        // Password complexity check rules
        bool hasUppercase = text.contains(RegExp(r'[A-Z]'));
        bool hasDigits = text.contains(RegExp(r'[0-9]'));
        bool hasSpecial = text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_+-]'));
        int length = text.length;

        if (length >= 8 && hasUppercase && hasDigits && hasSpecial) {
          strength = PasswordStrength.secure;
        } else if (length >= 8 &&
            ((hasUppercase && hasDigits) ||
                (hasDigits && hasSpecial) ||
                (hasUppercase && hasSpecial))) {
          strength = PasswordStrength.strong;
        } else if (length >= 6) {
          strength = PasswordStrength.medium;
        } else {
          strength = PasswordStrength.weak;
        }

        _passNotifier.value = strength;

        setState(() {
          if (strength == PasswordStrength.weak) {
            _currentColor = Colors.red;
          } else if (strength == PasswordStrength.medium) {
            _currentColor = Colors.orange;
          } else if (strength == PasswordStrength.strong) {
            _currentColor = Colors.green; // Strong turns green
          } else if (strength == PasswordStrength.secure) {
            _currentColor = Colors.green;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _passNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height ?? 55.0, // Clean breathing height for bar + bottom
      child: Theme(
        // Forces the package's built-in text to use our dynamic status colors
        data: Theme.of(context).copyWith(
          textTheme: Theme.of(context).textTheme.copyWith(
                bodyMedium: TextStyle(
                  color: _currentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
        ),
        child: PasswordStrengthChecker(
          strength: _passNotifier,
        ),
      ),
    );
  }
}
