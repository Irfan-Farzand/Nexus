import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileProvider with ChangeNotifier {
  final _fire = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  // Local cached profile
  Map<String, dynamic>? profile;
  bool isLoading = false;

  File? imageFile;
  bool saving = false;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  // Laravel server base URL
  static const String baseUrl = '';

  Future<void> fetchProfile() async {
    if (uid == null) return;
    isLoading = true;
    notifyListeners();

    try {
      final doc = await _fire.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        profile = Map<String, dynamic>.from(doc.data()!);

        // 🔹 CRITICAL FIX: Convert photoUrl to full URL immediately after fetching
        if (profile!['photoUrl'] != null && profile!['photoUrl'].toString().isNotEmpty) {
          final rawPhotoUrl = profile!['photoUrl'].toString();
          final fullPhotoUrl = getFullImageUrl(rawPhotoUrl);
          profile!['photoUrl'] = fullPhotoUrl; // Replace with full URL

          debugPrint('Raw photoUrl: $rawPhotoUrl');
          debugPrint('Converted to full URL: $fullPhotoUrl');
        }
      } else {
        profile = null;
      }

      debugPrint('Final profile data: $profile');
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> createProfile({required String name, required String email}) async {
    if (uid == null) return;

    try {
      await _fire.collection('users').doc(uid).set({
        'name': name,
        'email': email,
        'photoUrl': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      profile = {'name': name, 'email': email, 'photoUrl': ''};
      notifyListeners();
    } catch (e) {
      debugPrint('Error creating profile: $e');
    }
  }

  Future<String?> updateProfile({required String name, File? imageFile}) async {
    if (uid == null) return 'Not authenticated';

    setSaving(true);

    try {
      String? photoUrl;

      if (imageFile != null) {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/upload/image'),
        );
        request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));
        final response = await request.send();

        if (response.statusCode == 200) {
          final body = await response.stream.bytesToString();
          final data = jsonDecode(body);

          // Dono 'url' aur 'path' check karo
          photoUrl = data['url'] ?? data['path'];

          debugPrint('Server response: $photoUrl');
        } else {
          setSaving(false);
          return 'Failed to upload image to server';
        }
      }

      // Prepare update data - Firestore mein relative path hi save karo
      final updateData = <String, dynamic>{
        'name': name,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Only add photoUrl if we have a new one
      if (photoUrl != null) {
        //  Firestore mein relative path hi save karo
        updateData['photoUrl'] = photoUrl;
      }

      // Update Firestore
      await _fire.collection('users').doc(uid).update(updateData);

      // Update local profile - yahan full URL use karo display ke liye
      if (profile != null) {
        profile = Map<String, dynamic>.from(profile!);
        profile!['name'] = name;
        if (photoUrl != null) {
          final fullPhotoUrl = getFullImageUrl(photoUrl);
          profile!['photoUrl'] = fullPhotoUrl;
          debugPrint('Stored full photoUrl in profile: $fullPhotoUrl');
        }
      } else {
        profile = {
          'name': name,
          'photoUrl': photoUrl != null ? getFullImageUrl(photoUrl) : '',
        };
      }

      // Clear the temporary image file
      this.imageFile = null;

      setSaving(false);
      notifyListeners();
      return null;
    } catch (e) {
      setSaving(false);
      debugPrint('Error updating profile: $e');
      return e.toString();
    }
  }
  void setImageFile(File? file) {
    imageFile = file;
    notifyListeners();
  }

  void setSaving(bool value) {
    saving = value;
    notifyListeners();
  }

  String getFullImageUrl(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) return '';



    // Agar complete URL hai aur already public/ hai to as-is return karo
    if (photoUrl.startsWith('http://') || photoUrl.startsWith('https://')) {
      return photoUrl;
    }

    // Agar relative path hai to direct /ho/public/storage/ add karo
    return 'url/$photoUrl';
  }
  // 🔹 Helper method to validate if a URL is valid for NetworkImage
  bool isValidNetworkImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return url.startsWith('http://') || url.startsWith('https://');
  }
}
