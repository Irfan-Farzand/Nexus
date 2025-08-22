import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tasknest/routes/app_routes.dart';

class EmailVerificationScreen extends StatefulWidget {
  @override
  _EmailVerificationScreenState createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isVerifying = false;
  Timer? _checkTimer;

  @override
  void initState() {
    super.initState();
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      checkEmailVerified(autoCheck: true);
    });
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    super.dispose();
  }

  Future<void> checkEmailVerified({bool autoCheck = false}) async {
    if (!autoCheck) {
      setState(() => _isVerifying = true);
    }

    User? user = FirebaseAuth.instance.currentUser;
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    if (user != null && user.emailVerified) {
      _checkTimer?.cancel();
      Navigator.pushReplacementNamed(context, AppRoutes.home);
      return;
    }

    if (!autoCheck) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email not verified yet! Please check your inbox.'),
        ),
      );
    }

    if (!autoCheck) {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> resendVerificationEmail() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification email resent! Check your inbox.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resend email: $e')),
      );
    }
  }

  void changeEmail() {
    // Purana account sign out karke signup screen par bhejna
    FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, AppRoutes.signup);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade700, Colors.teal.shade300],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mark_email_unread,
                      size: 100, color: Colors.teal.shade700),
                  const SizedBox(height: 20),
                  Text(
                    "Verify Your Email",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'We sent a verification link to your email. Please verify to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                  const SizedBox(height: 30),
                  _isVerifying
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                    onPressed: () => checkEmailVerified(autoCheck: false),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.teal.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.check_circle_outline,
                        color: Colors.white),
                    label: const Text(
                      "I have verified my email",
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextButton(
                    onPressed: resendVerificationEmail,
                    child: const Text(
                      "Resend Verification Email",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: changeEmail,
                    child: const Text(
                      "Change Email (Go back to Signup)",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
