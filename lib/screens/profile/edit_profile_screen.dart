import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/profile_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatelessWidget {
  final nameCtrl = TextEditingController();

  Future<void> pickImage(BuildContext context) async {
    final prov = Provider.of<ProfileProvider>(context, listen: false);
    final res = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (res != null) prov.setImageFile(File(res.path));
  }

  Future<void> save(BuildContext context) async {
    final prov = Provider.of<ProfileProvider>(context, listen: false);

    final err = await prov.updateProfile(
      name: nameCtrl.text.trim(),
      imageFile: prov.imageFile,
    );

    if (err == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
        Navigator.pop(context);
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $err')),
        );
      }
    }
  }

  // 🔹 Simplified since ProfileProvider now always returns full URLs
  Widget buildProfileImage(ProfileProvider prov) {
    final photo = prov.profile?['photoUrl'] as String?;

    // Priority 1: Show locally picked image
    if (prov.imageFile != null) {
      debugPrint('Using local file image');
      return CircleAvatar(
        radius: 60,
        backgroundColor: Colors.blue[50],
        backgroundImage: FileImage(prov.imageFile!),
      );
    }

    // Priority 2: Show network image if valid (ProfileProvider now ensures it's always a full URL)
    if (photo != null && photo.isNotEmpty) {
      debugPrint('Attempting to load image from: $photo');

      if (photo.startsWith('http://') || photo.startsWith('https://')) {
        return CircleAvatar(
          radius: 60,
          backgroundColor: Colors.blue[50],
          backgroundImage: NetworkImage(photo),
          onBackgroundImageError: (exception, stackTrace) {
            debugPrint('Error loading network image: $exception');
          },
        );
      } else {
        debugPrint('Invalid network image URL: $photo');
      }
    }

    // Priority 3: Show default image
    debugPrint('Using default asset image');
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.blue[50],
      backgroundImage: const AssetImage('assets/image/photo.png'),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, prov, child) {
        final p = prov.profile;

        // Only update text controller if it's different to avoid cursor jumping
        if (nameCtrl.text != (p?['name'] ?? '')) {
          nameCtrl.text = p?['name'] ?? '';
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Edit Profile', style: TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor: Colors.blue[700],
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Stack(
                  children: [
                    GestureDetector(
                      onTap: () => pickImage(context),
                      child: buildProfileImage(prov),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[700],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.edit, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  controller: nameCtrl,
                  label: 'Full Name',
                  filled: true,
                  fillColor: Colors.blue[50],
                  borderRadius: 14,
                  labelColor: Colors.blue[800],
                  textColor: Colors.blue[900],
                ),
                const SizedBox(height: 30),
                prov.saving
                    ? const CircularProgressIndicator(color: Colors.blue)
                    : CustomButton(
                  text: 'Save',
                  onPressed: () => save(context),
                  color: Colors.blue[700],
                  textColor: Colors.white,
                  height: 50,
                  borderRadius: 14,
                  fontSize: 17,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}