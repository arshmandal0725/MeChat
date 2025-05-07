import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:me_chat/backend/api.dart';
import 'package:me_chat/models/message_model.dart';
import 'package:me_chat/models/user_model.dart';
import 'package:me_chat/screens/chat_screen.dart';

class UserChatCard extends StatefulWidget {
  const UserChatCard({super.key, required this.user});
  final UserData user;

  @override
  State<UserChatCard> createState() => _UserChatCardState();
}

class _UserChatCardState extends State<UserChatCard> {
  List<Message> _messages = [];
  int _unread = 0;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ChatScreen(user: widget.user),
          ),
        );
      },
      child: StreamBuilder(
        stream: APIs.firestore.collection('messages').snapshots(),
        builder: (context, snapshot) {
          _messages.clear();
          _unread = 0;

          if (snapshot.hasData) {
            final data = snapshot.data!.docs;

            // Loop through messages
            for (var doc in data) {
              final msg = Message.fromJson(doc.data());

              final isBetweenCurrentUserAndThisUser =
                  (msg.fromId == APIs.currentUser!.uid &&
                          msg.toId == widget.user.id) ||
                      (msg.fromId == widget.user.id &&
                          msg.toId == APIs.currentUser!.uid);

              if (isBetweenCurrentUserAndThisUser) {
                _messages.add(msg);

                // Count unread messages sent to the current user
                if (msg.toId == APIs.currentUser!.uid && msg.read.isEmpty) {
                  _unread++;
                }
              }
            }

            // Sort messages by the sent time in descending order
            _messages.sort((a, b) => DateTime.parse(b.sent)
                .compareTo(DateTime.parse(a.sent))); // Sorting by sent time

            if (_messages.isEmpty) {
              return Container();
            }
          }

          final lastMsg = _messages.isNotEmpty ? _messages.first : null;

          return Card(
            margin: const EdgeInsets.all(10),
            color: const Color.fromARGB(255, 243, 243, 243),
            child: ListTile(
              title: Text(
                widget.user.name ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                lastMsg?.message ?? widget.user.about ?? '',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              trailing: lastMsg == null
                  ? const SizedBox()
                  : lastMsg.fromId == APIs.currentUser!.uid
                      ? Text(
                          DateFormat('d MMM')
                              .format(DateTime.parse(lastMsg.sent)),
                          style: const TextStyle(fontSize: 11),
                        )
                      : _unread > 0
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Text(
                                '$_unread',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : const SizedBox(),
              leading: CircleAvatar(
                backgroundColor: Colors.grey,
                radius: 25,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.network(
                    widget.user.image ?? '',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
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
          );
        },
      ),
    );
  }
}
