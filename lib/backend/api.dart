import 'dart:io';
import 'package:me_chat/models/message_model.dart';
import 'package:path/path.dart' as path;
import 'package:mime/mime.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:me_chat/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class APIs {
  static final supabase = Supabase.instance.client;
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final currentUser = auth.currentUser;

  /// Checks if user exists in Firestore
  static Future<bool> userExists() async {
    try {
      final exists =
          (await firestore.collection('users').doc(currentUser!.uid).get())
              .exists;
      print('✅ User existence check successful: $exists');
      return exists;
    } catch (e) {
      print('❌ Error checking user existence: $e');
      return false;
    }
  }

  /// Uploads image file to Supabase storage and updates Firestore flag
  static Future<bool> uploadFile(File imageFile) async {
    final fileBytes = await imageFile.readAsBytes();
    final fileName = path.basename(imageFile.path);
    final mimeType = lookupMimeType(fileName);
    final firebaseUid = currentUser!.uid;

    try {
      await supabase.storage.from('mechat').uploadBinary(
            'profilePic/$firebaseUid',
            fileBytes,
            fileOptions: FileOptions(contentType: mimeType),
          );

      //await changeDp();
      print('✅ File uploaded to Supabase storage');
      return true;
    } catch (e) {
      print('❌ File upload failed: $e');
      return false;
    }
  }

  static Future<void> updateProfileImage(File file) async {
    try {
      final fileName =
          'profilePic/${APIs.currentUser!.uid}'; // Unique file name

      // Attempt to upload and update the profile image

      await APIs.supabase.storage.from('mechat').update(fileName, file);
      print('Done updating');
      // If successful, print the response and update the UI
    } catch (e) {
      print('🔥 Error in updating image: $e');

      print('⬆️ Uploading new image...');
      await APIs.uploadFile(file);
    }
  }

  /// Returns the public URL of profile image from Supabase
  static String getProfileImageUrl(String firebaseUid) {
    try {
      final url = supabase.storage
          .from('mechat')
          .getPublicUrl('profilePic/$firebaseUid');
      print('✅ Public profile image URL generated: $url');
      return url;
    } catch (e) {
      print('❌ Error getting profile image URL: $e');
      return '';
    }
  }

  /// Creates a new user entry in Firestore
  static Future<void> createUser() async {
    try {
      UserData user = UserData(
        id: currentUser!.uid,
        isOonline: false,
        createdAt: "",
        image: currentUser!.photoURL,
        email: currentUser!.email,
        pushToken: "",
        about: 'Hey , I am very Happy',
        lastActive: "",
        name: currentUser!.displayName,
      );

      await firestore
          .collection('users')
          .doc(currentUser!.uid)
          .set(user.toJson());
      print('✅ New user created in Firestore');
    } catch (e) {
      print('❌ Error creating user: $e');
    }
  }

  static Future<void> createMessage(Message msj) async {
    try {
      await firestore
          .collection('messages')
          .doc("${currentUser!.uid}__${Timestamp.now()}")
          .set(msj.toJson());
      print('✅ New user created in Firestore');
    } catch (e) {
      print('❌ Error creating user: $e');
    }
  }

  /// Updates user name and about fields
  static Future<void> update(String name, String about, String image) async {
    try {
      await firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update({"name": name, "about": about, "image": image});
      print('✅ User details updated: name=$name, about=$about');
    } catch (e) {
      print('❌ Error updating user details: $e');
    }
  }

  static Future<void> updateOnlineStatus(bool status) async {
    try {
      await firestore.collection('users').doc(currentUser!.uid).update(
          {"is_oonline": status, "last_active": DateTime.now().toString()});
      print('✅ User details updated');
    } catch (e) {
      print('❌ Error updating user details: $e');
    }
  }

  static Future<void> markMessagesAsRead(Message msj) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .where('fromId', isEqualTo: msj.fromId)
          .get();

      if (querySnapshot.docs.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in querySnapshot.docs) {
        batch.update(doc.reference, {'read': DateTime.now().toString()});
      }

      await batch.commit();
      print("Messages marked as read for fromId: ${msj.fromId}");
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }
}
