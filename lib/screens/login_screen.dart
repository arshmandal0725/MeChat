import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:me_chat/backend/api.dart';
import 'package:me_chat/constants.dart';
import 'package:me_chat/screens/main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final firebaseAuth = FirebaseAuth.instance;
  bool _isLoading = false;

  // Function to check and create user in Firestore
  Future<void> _checkAndFetchUsers() async {
    if (!await APIs.userExists()) {
      await APIs.createUser();
    }
  }

  // Google Sign-In Flow
  Future<User?> signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      // Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      // If user cancels
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return null;
      }

      // Get auth details
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Get credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential =
          await firebaseAuth.signInWithCredential(credential);

      // Check and create user in Firestore
      await _checkAndFetchUsers();

      return userCredential.user;
    } catch (e) {
      print('Error signing in with Google: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(child: Text('Error signing in with Google: $e')),
          ],
        ),
      ));
      setState(() => _isLoading = false);
      return null;
    }
  }

  // Loading or Login UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: (_isLoading)
          ? Center(
              child: LoadingAnimationWidget.flickr(
                  leftDotColor: primaryColor,
                  rightDotColor: Colors.white,
                  size: 50),
            )
          : _buildLoginUI(),
    );
  }

  Widget _buildLoginUI() {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/images/app_icon.png',
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          bottom: -70,
          right: -70,
          child: Image.asset(
            'assets/images/Screenshot_2025-07-08_at_2.57.48_PM-removebg-preview.png',
            width: 300,
            height: 300,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Connect',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                'Chat',
                style: TextStyle(
                    color: primaryColor,
                    fontSize: 60,
                    fontWeight: FontWeight.bold),
              ),
              Text(
                'Chill with your Friends',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 180),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final user = await signInWithGoogle();
                    if (user != null) {
                      print("✅ Signed in as ${user.displayName}");
                      setState(() => _isLoading = false);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => MainScreen()),
                      );
                    } else {
                      print("❌ Google sign-in failed or cancelled.");
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      backgroundColor: primaryColor),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/google.png'),
                      const SizedBox(width: 10),
                      const Text(
                        'Sign in with Google',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -40,
          left: -150,
          child: Image.asset(
            'assets/images/Screenshot_2025-07-08_at_2.57.48_PM-removebg-preview.png',
            width: 300,
            height: 300,
          ),
        ),
      ],
    );
  }
}
