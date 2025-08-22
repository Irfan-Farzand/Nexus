import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tasknest/providers/auth_provider.dart';
import 'package:tasknest/providers/auth_provider.dart' as auth_provider;
import 'package:tasknest/routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:tasknest/services/notification_service.dart';
import 'package:tasknest/widgets/custom_button.dart';
import 'package:tasknest/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter email and password")),
      );
      return;
    }

    final provider = Provider.of<auth_provider.AuthProvider>(
      context,
      listen: false,
    );

    try {
      await provider.login(email, password);

      final token = await NotificationService.getFcmToken();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

      if (token != null && uid != null) {
        final snapshot = await userDoc.get();
        if (snapshot.exists) {
          await userDoc.update({'fcmToken': token});
        } else {
          await userDoc.set({
            'fcmToken': token,
            'email': email,
            'photoUrl': '',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } on FirebaseAuthException catch (e) {
      String msg = "Login Failed";
      if (e.code == 'user-not-found') {
        msg = "No user found with this email.";
      } else if (e.code == 'wrong-password') {
        msg = "Incorrect password.";
      } else if (e.code == 'invalid-email') {
        msg = "Invalid email address.";
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading =
        Provider.of<auth_provider.AuthProvider>(context).isLoading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo.shade900, Colors.blue.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: "app-logo",
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image.asset(
                        'assets/icon/icon.png',
                        height: 120,
                        width: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Welcome Back ",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in to continue",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 30),
                  CustomTextField(
                    controller: emailController,
                    label: "Email",
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: passwordController,
                    label: "Password",
                  ),
                  const SizedBox(height: 30),
                  isLoading
                      ? const CircularProgressIndicator()
                      : CustomButton(
                    text: "Login",
                    onPressed: _login,
                  ),
                  const SizedBox(height: 15),
                  Divider(color: Colors.grey.shade400, thickness: 0.5),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.signup),
                    child: Text(
                      "Don’t have an account? Sign Up",
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
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
