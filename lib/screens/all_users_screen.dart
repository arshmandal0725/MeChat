import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:me_chat/backend/api.dart';
import 'package:me_chat/models/user_model.dart';
import 'package:me_chat/screens/chat_screen.dart';
import 'package:me_chat/screens/profile_screen.dart';
import 'package:me_chat/widgets/search_texrField.dart';

class AllUsersScreen extends StatefulWidget {
  const AllUsersScreen({super.key});

  @override
  State<AllUsersScreen> createState() => _AllUsersScreenState();
}

class _AllUsersScreenState extends State<AllUsersScreen> {
  @override
  void initState() {
    super.initState();
    _checkUser();
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
                leading: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(CupertinoIcons.home)),
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
                leading: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(CupertinoIcons.home)),
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
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => ChatScreen(user: users[index]),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.all(10),
                        color: const Color.fromARGB(255, 243, 243, 243),
                        child: ListTile(
                          title: Text(
                            users[index].name ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            users[index].about ?? '',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey,
                            radius: 25,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(25),
                              child: Image.network(
                                users[index].image ?? '',
                                width: 200,
                                height: 200,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                      child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.black,
                                      size: 25,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  });
            }),
      ),
    );
  }
}
