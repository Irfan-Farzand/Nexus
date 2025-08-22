import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasknest/providers/auth_provider.dart' as auth_provider;
import 'package:tasknest/providers/profile_provider.dart';
import 'package:tasknest/routes/app_routes.dart';
import 'package:tasknest/services/notification_service.dart';
import 'package:tasknest/widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import 'email_verification_screen.dart';

class SignupScreen extends StatelessWidget {
  SignupScreen({super.key});

  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();

  Future<void> _signup(BuildContext context) async {
    final auth = Provider.of<auth_provider.AuthProvider>(
      context,
      listen: false,
    );
    final profile = Provider.of<ProfileProvider>(context, listen: false);

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      await auth.signup(context,name, email, password );

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => EmailVerificationScreen()),
      );

      final user = auth.user;
      await user?.reload();

      if (user != null && user.emailVerified) {
        final finalName = name.isEmpty ? 'User' : name;

        await profile.createProfile(name: finalName, email: email);
        await profile.fetchProfile();

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
              'name': finalName,
              'photoUrl': '',
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        Navigator.pushReplacementNamed(context, AppRoutes.home);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please verify your email first.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      String msg = "Sign up failed";
      if (e.code == 'email-already-in-use') {
        msg = "Email already in use.";
      } else if (e.code == 'invalid-email') {
        msg = "Invalid email address.";
      } else if (e.code == 'weak-password') {
        msg = "Password is too weak.";
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
    final isLoading = context.watch<auth_provider.AuthProvider>().isLoading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade900, Colors.purple.shade400],
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
                color: Colors.white.withOpacity(0.92),
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
                    "Create Account ",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign up to get started",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 30),
                  CustomTextField(
                    controller: nameController,
                    label: "Full Name",
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: emailController,
                    label: "Email",
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: passwordController,
                    label: "Password",
                    obscureText: true,
                  ),
                  const SizedBox(height: 30),
                  isLoading
                      ? const CircularProgressIndicator()
                      : CustomButton(
                    text: "Sign Up",
                    onPressed: () => _signup(context),
                  ),
                  const SizedBox(height: 15),
                  Divider(color: Colors.grey.shade400, thickness: 0.5),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.login),
                    child: Text(
                      "Already have an account? Login",
                      style: TextStyle(
                        color: Colors.purple.shade700,
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
