import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:me_chat/backend/api.dart';
import 'package:me_chat/models/user_model.dart';
import 'package:me_chat/screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user});
  final UserData user;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = false; // Track if the image is being uploaded
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
          MaterialPageRoute(builder: (ctx) => const LoginScreen()),
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
    setState(() {
      isLoading = true; // Start loading
    });

    try {
      print('🗑 Updating previous image...');
      await APIs.updateProfileImage(file);

      await APIs.update(widget.user.name!, widget.user.about!,
          APIs.getProfileImageUrl(APIs.currentUser!.uid));

      setState(() {
        isLoading = false; // Stop loading
      });
    } catch (e) {
      print('🔥 Error in picking or uploading image: $e');
      setState(() {
        isLoading = false; // Stop loading even if there's an error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Screen',
            style: TextStyle(fontWeight: FontWeight.normal)),
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
                  // Profile Image
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
                                color: Colors.black,
                              ),
                            )
                          : Image.network(
                              ('${widget.user.image}?t=${DateTime.now().millisecondsSinceEpoch}'),
                              fit: BoxFit.cover,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
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
                                  const Icon(Icons.error),
                            ),
                    ),
                  ),
                  // Border Circle (placed behind so it doesn't block interaction)
                  Positioned.fill(
                    child: Container(
                      height: 150,
                      width: 150,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.black, width: 2),
                          color: Colors.transparent),
                    ),
                  ),
                  // Edit Icon
                  Positioned(
                    bottom: 5,
                    right: 15,
                    child: Container(
                      height: 40,
                      width: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: Colors.black,
                      ),
                      child: IconButton(
                        onPressed: () async {
                          print('🟡 Edit button clicked');

                          try {
                            File? file = await pickImageFromGallery();
                            print('📷 Picked file: ${file?.path}');

                            if (file != null) {
                              await updateProfileImage(file);
                            } else {
                              print('❌ No image picked');
                            }
                          } catch (e) {
                            print('🔥 Error in picking or uploading image: $e');
                          }
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
                widget.user.email ?? '',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 60),
              TextFormField(
                initialValue: widget.user.name ?? '',
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter your name'
                    : null,
                onSaved: (newValue) => _name = newValue,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person),
                  label: const Text('Name'),
                  hintText: 'Name',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                initialValue: widget.user.about ?? '',
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Please enter about info'
                    : null,
                onSaved: (newValue) => _about = newValue,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.info_outline),
                  label: const Text('About'),
                  hintText: 'About',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();
                    try {
                      await APIs.update(_name!, _about!, widget.user.image!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Update Successful!'),
                            backgroundColor: Colors.black,
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Update Failed!'),
                            backgroundColor: Colors.red,
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child:
                    const Text('Update', style: TextStyle(color: Colors.white)),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.logout, color: Colors.white, size: 18),
              SizedBox(width: 4),
              Text('Logout', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
