import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:me_chat/backend/api.dart';
import 'package:me_chat/constants.dart';
import 'package:me_chat/models/user_model.dart';
import 'package:me_chat/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false;
  String? _name;
  String? _about;
  final formKey = GlobalKey<FormState>();

  Future<void> signOut() async {
    try {
      await APIs.auth.signOut();
      await GoogleSignIn().signOut();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('SignOut Error: $e');
    }
  }

  Future<File?> pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  Future<void> updateProfileImage(File file) async {
    setState(() => isLoading = true);

    try {
      await APIs.updateProfileImage(file);
      final newImageUrl = APIs.getProfileImageUrl(currentUser.id!);

      await APIs.update(currentUser.name!, currentUser.about!, newImageUrl);
      currentUser.image = newImageUrl;

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Image Upload Error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Profile Screen',
            style:
                TextStyle(fontWeight: FontWeight.normal, color: primaryColor)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        color: Colors.white,
                      ),
                      child: isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.black))
                          : Image.network(
                              '${currentUser.image}?t=${DateTime.now().millisecondsSinceEpoch}',
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            (loadingProgress
                                                    .expectedTotalBytes ??
                                                1)
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.error, color: Colors.red),
                            ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: primaryColor, width: 3),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    right: 15,
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: primaryColor,
                      ),
                      child: IconButton(
                        onPressed: () async {
                          File? file = await pickImageFromGallery();
                          if (file != null) await updateProfileImage(file);
                        },
                        icon: const Icon(Icons.edit,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                currentUser.email ?? '',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 60),
              TextFormField(
                initialValue: currentUser.name ?? '',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter your name' : null,
                onSaved: (newValue) => _name = newValue,
                style: const TextStyle(color: Colors.white),
                decoration: inputDecoration('Name', Icons.person),
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: currentUser.about ?? '',
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter about info' : null,
                onSaved: (newValue) => _about = newValue,
                style: const TextStyle(color: Colors.white),
                decoration: inputDecoration('About', Icons.info_outline),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    try {
                      await APIs.update(_name!, _about!, currentUser.image!);
                      currentUser.name = _name!;
                      currentUser.about = _about!;
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          successSnackBar('Profile updated!'),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          errorSnackBar('Update failed!'),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child:
                    const Text('Update', style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: SizedBox(
        height: 45,
        width: 120,
        child: FloatingActionButton(
          backgroundColor: Colors.deepOrange,
          onPressed: signOut,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Colors.white, size: 18),
              SizedBox(width: 4),
              Text('Logout', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: Colors.white70),
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      hintText: label,
      hintStyle: const TextStyle(color: Colors.white38),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white),
      ),
    );
  }

  SnackBar successSnackBar(String message) => SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );

  SnackBar errorSnackBar(String message) => SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      );
}
