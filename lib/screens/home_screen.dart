import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:me_chat/backend/api.dart';
import 'package:me_chat/models/user_model.dart';
import 'package:me_chat/screens/all_users_screen.dart';
import 'package:me_chat/screens/profile_screen.dart';
import 'package:me_chat/widgets/chat_card.dart';
import 'package:me_chat/widgets/search_texrField.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _checkUser();
    APIs.updateOnlineStatus(true);
    SystemChannels.lifecycle.setMessageHandler(
      (message) {
        print('Message : $message');

        if (message.toString().contains('pause')) {
          APIs.updateOnlineStatus(false);
        }

        if (message.toString().contains('resume')) {
          APIs.updateOnlineStatus(true);
        }
        return Future.value(message);
      },
    );
  }

  Future<void> _checkUser() async {
    if (!await APIs.userExists()) {
      await APIs.createUser();
    }
  }

  List<UserData> onSearchUsers(String searchText) {
    if (searchText.isEmpty) return users;
    List<UserData> newUser = users
        .where((u) =>
            u.name!.toLowerCase().contains(searchText.trim().toLowerCase()))
        .toList();
    return newUser;
  }

  List<UserData> users = [];
  UserData? user;
  bool searchActivated = false;
  String searchText = '';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          searchActivated = false;
        });
      },
      child: Scaffold(
        appBar: (searchActivated)
            ? AppBar(
                title: SearchTexrfield(onChanged: (String s) {
                  searchText = s;
                  onSearchUsers(searchText);
                  setState(() {});
                }),
                actions: [
                  IconButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => ProfileScreen(
                                      user: user!,
                                    )));
                      },
                      icon: Icon(Icons.more_vert))
                ],
              )
            : AppBar(
                title: Text('MeChat'),
                actions: [
                  IconButton(
                      onPressed: () {
                        setState(() {
                          searchActivated = !searchActivated;
                        });
                      },
                      icon: Icon(Icons.search)),
                  IconButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (ctx) => ProfileScreen(
                                      user: user!,
                                    )));
                      },
                      icon: Icon(Icons.more_vert))
                ],
              ),
        backgroundColor: Colors.white,
        body: StreamBuilder(
            stream: APIs.firestore.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final data = snapshot.data?.docs;
                users.clear();
                for (var i in data!) {
                  UserData u = UserData(
                      id: i.data()["id"],
                      isOonline: i.data()["is_oonline"],
                      createdAt: i.data()["created_at"],
                      image: i.data()["image"],
                      email: i.data()["email"],
                      pushToken: i.data()["push_token"],
                      about: i.data()["about"],
                      lastActive: i.data()["last_active"],
                      name: i.data()["name"]);

                  if (u.id == APIs.currentUser!.uid) {
                    user = u;
                  } else {
                    users.add(u);
                  }
                }
              }
              final filteredUsers = onSearchUsers(searchText);
              return ListView.builder(
                  itemCount: filteredUsers.length,
                  itemBuilder: (ctx, index) {
                    return UserChatCard(
                      user: filteredUsers[index],
                    );
                  });
            }),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => AllUsersScreen()));
          },
          child: Icon(Icons.add_comment),
        ),
      ),
    );
  }
}
