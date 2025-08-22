import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tasknest/providers/profile_provider.dart';
import 'package:tasknest/routes/app_routes.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProfileProvider>(context, listen: false).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProv = Provider.of<ProfileProvider>(context);
    final authProv = Provider.of<AuthProvider>(context, listen: false);

    if (profileProv.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final data = profileProv.profile ?? {};
    final name = data['name'] ?? 'No name';
    final email = data['email'] ?? authProv.user?.email ?? 'No email';
    final photo = (data['photoUrl'] ?? '') as String;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Profile", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF4A90E2), Color(0xFF50E3C2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            child: Card(
              elevation: 20,
              shadowColor: Colors.black38,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Profile Picture
                    Hero(
                      tag: "profile_pic",
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: photo.isEmpty
                            ? const AssetImage('assets/image/photo.png')
                            : NetworkImage(photo) as ImageProvider,
                        onBackgroundImageError: (exception, stackTrace) {
                          debugPrint('Failed to load profile image: $exception');
                          // You could set a fallback image here
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Name
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Email
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),

                    const SizedBox(height: 25),

                    // Action Buttons
                    _buildActionButton(
                      icon: Icons.edit,
                      text: "Edit Profile",
                      color: Colors.blueAccent,
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.editProfile),
                    ),
                    const SizedBox(height: 14),
                    _buildActionButton(
                      icon: Icons.logout,
                      text: "Logout",
                      color: Colors.redAccent,
                      onTap: () {
                        authProv.logout();
                        Navigator.pushReplacementNamed(
                            context, AppRoutes.login);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                    color: color, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: Colors.black45),
          ],
        ),
      ),
    );
  }
}
