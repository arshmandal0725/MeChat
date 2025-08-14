import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:me_chat/constants.dart';
import 'package:me_chat/models/user_model.dart';
import 'package:me_chat/widgets/chat_card.dart';
import 'package:me_chat/widgets/search_texrField.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool searchActivated = false;
  String searchText = '';
  List<UserData> filteredUsers = [];

  @override
  void initState() {
    super.initState();
    filteredUsers = getFilteredUsers(); // initial filtered list

    SystemChannels.lifecycle.setMessageHandler(
      (message) {
        if (message.toString().contains('pause')) {
          // Handle offline status
        } else if (message.toString().contains('resume')) {
          // Handle online status
        }
        return Future.value(message);
      },
    );
  }

  List<UserData> getFilteredUsers() {
    return allUsers
        .where((u) =>
            u.name!.toLowerCase().contains(searchText.trim().toLowerCase()) &&
            u.id != currentUser.id)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          searchActivated = false;
        });
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          iconTheme: IconThemeData(color: primaryColor),
          title: searchActivated
              ? SearchTexrfield(
                  onChanged: (String s) {
                    setState(() {
                      searchText = s;
                      filteredUsers = getFilteredUsers();
                    });
                  },
                  textColor: primaryColor,
                  borderColor: primaryColor,
                )
              : Text(
                  'Chats',
                  style: TextStyle(color: primaryColor),
                ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: primaryColor),
              onPressed: () {
                setState(() {
                  searchActivated = !searchActivated;
                });
              },
            ),
            IconButton(
                icon: Icon(Icons.more_vert, color: primaryColor),
                onPressed: () {}),
          ],
        ),
        body: filteredUsers.isEmpty
            ? Center(
                child: Text(
                  'No users found',
                  style: TextStyle(color: primaryColor.withOpacity(0.7)),
                ),
              )
            : ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (ctx, index) {
                  return UserChatCard(
                    user: filteredUsers[index],
                  );
                },
              ),
      ),
    );
  }
}
