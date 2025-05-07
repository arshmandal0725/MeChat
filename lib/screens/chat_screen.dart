import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:me_chat/backend/api.dart';
import 'package:me_chat/models/message_model.dart';
import 'package:me_chat/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' as foundation;

String formatTime(String timestampString) {
  final dateTime = DateTime.parse(timestampString);
  return DateFormat('h:mm a').format(dateTime); // e.g., 5:00 PM
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.user});
  final UserData user;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Message> messages = [];
  final TextEditingController msjController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isEmojiPickerVisible = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    markMessagesAsRead();
  }

  String formatDateTimeFromString(String dateTimeString) {
    final dateTime = DateTime.parse(dateTimeString);
    return DateFormat("d MMM h:mm a").format(dateTime);
  }

  Future<void> markMessagesAsRead() async {
    try {
      final querySnapshot = await APIs.firestore
          .collection('messages')
          .where('toId', isEqualTo: APIs.currentUser!.uid)
          .where('fromId', isEqualTo: widget.user.id)
          .where('read', isEqualTo: '')
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({'read': DateTime.now().toString()});
      }
    } catch (e) {
      debugPrint("Error marking messages as read: $e");
    }
  }

  void _toggleEmojiPicker() {
    setState(() {
      _isEmojiPickerVisible = !_isEmojiPickerVisible;
    });

    if (_isEmojiPickerVisible) {
      _focusNode.unfocus(); // Hide the keyboard
    } else {
      _focusNode.requestFocus(); // Show the keyboard
    }
  }

  void _scrollToBottom() {
    // Scroll to the bottom of the ListView when the screen loads or when a new message is added
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey,
              radius: 23,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Image.network(
                  widget.user.image!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.person, color: Colors.black);
                  },
                ),
              ),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.user.name!,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                StreamBuilder(
                  stream: APIs.firestore
                      .collection('users')
                      .where("id", isEqualTo: widget.user.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    }

                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final data = snapshot.data!.docs[0];
                      final bool status = data["is_oonline"] ?? false;
                      final String lastseen =
                          data["last_active"] ?? "${DateTime.now()}";

                      return Text(
                        status
                            ? "Online"
                            : "last seen on ${formatDateTimeFromString(lastseen)}",
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                )
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: APIs.firestore.collection("messages").snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }

                final data = snapshot.data!.docs;
                messages.clear();

                // Collect the messages from the snapshot
                for (var doc in data) {
                  final parts = doc.id.split('__');
                  if (parts.first == APIs.currentUser!.uid &&
                          doc["toId"] == widget.user.id ||
                      parts.first == widget.user.id &&
                          doc["toId"] == APIs.currentUser!.uid) {
                    messages.add(Message.fromJson(doc.data()));
                  }
                }

                // Sort messages by the 'sent' timestamp (ascending order)
                messages.sort((a, b) {
                  final aTime = DateTime.parse(a.sent);
                  final bTime = DateTime.parse(b.sent);
                  return aTime.compareTo(bTime); // Ascending order
                });

                // Scroll to the bottom when messages are loaded or updated
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return TextBox(msj: msg);
                  },
                );
              },
            ),
          ),
          if (_isEmojiPickerVisible)
            EmojiPicker(
              onEmojiSelected: (category, emoji) {
                msjController
                  ..text += emoji.emoji
                  ..selection = TextSelection.fromPosition(
                    TextPosition(offset: msjController.text.length),
                  );
              },
              onBackspacePressed: () {
                final text = msjController.text;
                if (text.isNotEmpty) {
                  msjController
                    ..text = text.characters.skipLast(1).toString()
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: msjController.text.length),
                    );
                }
              },
              textEditingController: msjController,
              config: Config(
                height: 256,
                checkPlatformCompatibility: true,
                emojiViewConfig: EmojiViewConfig(
                  emojiSizeMax: 28 *
                      (foundation.defaultTargetPlatform == TargetPlatform.iOS
                          ? 1.20
                          : 1.0),
                ),
                viewOrderConfig: const ViewOrderConfig(
                  top: EmojiPickerItem.categoryBar,
                  middle: EmojiPickerItem.emojiView,
                  bottom: EmojiPickerItem.searchBar,
                ),
                skinToneConfig: const SkinToneConfig(),
                categoryViewConfig: const CategoryViewConfig(),
                bottomActionBarConfig: const BottomActionBarConfig(),
                searchViewConfig: const SearchViewConfig(),
              ),
            ),
          Container(
            width: double.infinity,
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                    color: Colors.black,
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _toggleEmojiPicker,
                          icon: const Icon(Icons.emoji_emotions,
                              color: Colors.white),
                        ),
                        Expanded(
                          child: TextField(
                            focusNode: _focusNode,
                            style: TextStyle(color: Colors.white),
                            controller: msjController,
                            maxLines: null,
                            decoration: const InputDecoration(
                              hintText: 'Type Something',
                              hintStyle: TextStyle(color: Colors.white),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.image, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.camera, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: IconButton(
                    onPressed: () {
                      if (msjController.text.trim().isEmpty) return;
                      final _msj = Message(
                        fromId: APIs.currentUser!.uid,
                        toId: widget.user.id!,
                        message: msjController.text.trim(),
                        sent: DateTime.now().toString(),
                        read: '',
                        type: 'text',
                      );
                      APIs.createMessage(_msj);
                      msjController.clear();
                    },
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

class TextBox extends StatelessWidget {
  const TextBox({super.key, required this.msj});
  final Message msj;

  @override
  Widget build(BuildContext context) {
    return (msj.fromId != APIs.currentUser!.uid)
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                          bottomRight: Radius.circular(22),
                        ),
                      ),
                      child: Text(msj.message),
                    ),
                  ],
                ),
                Text(formatTime(msj.sent), style: TextStyle(fontSize: 12)),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(22),
                          topRight: Radius.circular(22),
                          bottomLeft: Radius.circular(22),
                        ),
                      ),
                      child: Text(msj.message,
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(formatTime(msj.sent), style: TextStyle(fontSize: 12)),
                    Image.asset(
                      (msj.read != "")
                          ? 'assets/images/seen_tick.png'
                          : 'assets/images/unseen_tick.png',
                      scale: 25,
                    )
                  ],
                ),
              ],
            ),
          );
  }
}
