import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:me_chat/constants.dart';
import 'package:me_chat/models/message_model.dart';
import 'package:me_chat/models/user_model.dart';
import 'package:me_chat/screens/login_screen.dart';
import 'package:me_chat/screens/main_screen.dart';

class AnimationScreen extends StatefulWidget {
  @override
  _AnimationScreenState createState() => _AnimationScreenState();
}

class _AnimationScreenState extends State<AnimationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _sizeAnimation;

  bool _showFinalState = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 2 * 3.1416).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _sizeAnimation = Tween<double>(begin: 50, end: 90).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _startLoopingAnimation(); // Start the animation loop
    _startPreloadSequence(); // Start fetching data
  }

  void _startLoopingAnimation() {
    _controller.addStatusListener((status) {
      if (!_showFinalState) {
        if (status == AnimationStatus.completed) {
          _controller.reverse();
        } else if (status == AnimationStatus.dismissed) {
          _controller.forward();
        }
      }
    });
    _controller.forward(); // Initial start
  }

  Future<void> _startPreloadSequence() async {
    await _preloadData();

    // Stop animation and show final animation
    setState(() {
      _showFinalState = true;
    });

    await Future.delayed(Duration(milliseconds: 900));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => (FirebaseAuth.instance.currentUser != null)
            ? MainScreen()
            : LoginScreen(),
      ),
    );
  }

  Future<void> _preloadData() async {
    try {
      // Fetch all users
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      allUsers = usersSnapshot.docs
          .map((doc) => UserData.fromJson(doc.data()))
          .toList();

      // Fetch all messages
      final messagesSnapshot =
          await FirebaseFirestore.instance.collection('messages').get();

      allMessages = messagesSnapshot.docs
          .map((doc) => Message.fromJson(doc.data()))
          .toList();

      print(
          "✅ Fetched ${allUsers.length} users and ${allMessages.length} messages.");
    } catch (e) {
      print("❌ Error preloading data: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildCenterAnimation() {
    return Transform.rotate(
      angle: _rotationAnimation.value,
      child: Container(
        width: _sizeAnimation.value,
        height: _sizeAnimation.value,
        decoration: BoxDecoration(
          color: primaryColor,
          shape: BoxShape.circle,
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            'assets/images/app_icon.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildFinalAnimation() {
    return TweenAnimationBuilder<Alignment>(
      tween:
          Tween<Alignment>(begin: Alignment.center, end: Alignment.centerLeft),
      duration: Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      builder: (context, alignment, child) {
        return Align(
          alignment: alignment,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Image.asset(
                    'assets/images/app_icon.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(width: 10),
              TweenAnimationBuilder<Offset>(
                tween: Tween<Offset>(begin: Offset(1, 0), end: Offset(0, 0)),
                duration: Duration(milliseconds: 500),
                curve: Curves.easeOut,
                builder: (context, offset, textChild) {
                  return Transform.translate(
                    offset: Offset(offset.dx * 50, 0),
                    child: textChild,
                  );
                },
                child: Text(
                  'MeChat',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _showFinalState
            ? _buildFinalAnimation()
            : AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => _buildCenterAnimation(),
              ),
      ),
    );
  }
}
