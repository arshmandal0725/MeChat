import 'package:flutter/material.dart';
import 'package:me_chat/backend/api.dart';
import 'package:me_chat/constants.dart';
import 'package:me_chat/models/user_model.dart';
import 'package:me_chat/screens/all_users_screen.dart';
import 'package:me_chat/screens/home_screen.dart';
import 'package:me_chat/screens/profile_screen.dart';
import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int selectedIndex = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    for (UserData user in allUsers) {
      if (user.id == APIs.auth.currentUser!.uid) {
        currentUser = user;
      }
    }
    pageController = PageController();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void onTabTapped(int index) {
    setState(() {
      selectedIndex = index;
    });
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutQuad,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView(
        controller: pageController,
        physics:
            const NeverScrollableScrollPhysics(), // 👉 Prevent swipe between tabs (optional)
        onPageChanged: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
        children: [HomeScreen(), AllUsersScreen(), ProfileScreen()],
      ),
      bottomNavigationBar: SizedBox(
        height:
            65, // Reduces overall nav bar height but keeps icons and drop intact
        child: WaterDropNavBar(
          iconSize: 25,
          bottomPadding: 15,
          waterDropColor: primaryColor,
          backgroundColor: Colors.black,
          selectedIndex: selectedIndex,
          onItemSelected: onTabTapped,
          barItems: [
            BarItem(
              filledIcon: Icons.chat,
              outlinedIcon: Icons.chat_bubble_outline_outlined,
            ),
            BarItem(
              filledIcon: Icons.group,
              outlinedIcon: Icons.group_outlined,
            ),
            BarItem(
              filledIcon: Icons.settings,
              outlinedIcon: Icons.settings_outlined,
            ),
          ],
        ),
      ),
    );
  }
}
