import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:me_chat/backend/api.dart';
import 'package:me_chat/constants.dart';
import 'package:me_chat/models/message_model.dart';
import 'package:me_chat/models/user_model.dart';
import 'package:intl/intl.dart';

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

  String formatDateTime(String timestamp) {
    try {
      final dt = DateTime.tryParse(timestamp);
      if (dt == null) return '';
      return DateFormat("d MMM h:mm a").format(dt);
    } catch (e) {
      return '';
    }
  }

  String formatTime(String timestamp) {
    try {
      final dt = DateTime.tryParse(timestamp);
      if (dt == null) return '';
      return DateFormat('h:mm a').format(dt);
    } catch (e) {
      return '';
    }
  }

  Future<void> markMessagesAsRead() async {
    final query = await APIs.firestore
        .collection('messages')
        .where('toId', isEqualTo: APIs.currentUser!.uid)
        .where('fromId', isEqualTo: widget.user.id)
        .where('read', isEqualTo: '')
        .get();

    for (var doc in query.docs) {
      await doc.reference.update({'read': DateTime.now().toIso8601String()});
    }
  }

  void _toggleEmojiPicker() {
    setState(() => _isEmojiPickerVisible = !_isEmojiPickerVisible);

    if (_isEmojiPickerVisible) {
      _focusNode.unfocus();
    } else {
      _focusNode.requestFocus();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        iconTheme: IconThemeData(color: primaryColor),
        backgroundColor: Colors.black,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade800,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.network(
                  widget.user.image ?? '',
                  errorBuilder: (ctx, error, stack) =>
                      const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.user.name ?? '',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                StreamBuilder(
                  stream: APIs.firestore
                      .collection('users')
                      .where('id', isEqualTo: widget.user.id)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                      return const SizedBox();
                    final user = snapshot.data!.docs.first.data();
                    final isOnline = user['is_oonline'] ?? false;
                    final lastActive = user['last_active'] ?? '';
                    return Text(
                      isOnline
                          ? 'Online'
                          : 'last seen ${formatDateTime(lastActive)}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11),
                    );
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
              stream: APIs.firestore.collection('messages').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                messages.clear();

                for (var doc in snapshot.data!.docs) {
                  final msg = Message.fromJson(doc.data());
                  if ((msg.fromId == APIs.currentUser!.uid &&
                          msg.toId == widget.user.id) ||
                      (msg.fromId == widget.user.id &&
                          msg.toId == APIs.currentUser!.uid)) {
                    messages.add(msg);
                  }
                }

                messages.sort((a, b) {
                  final aTime = DateTime.tryParse(a.sent) ?? DateTime.now();
                  final bTime = DateTime.tryParse(b.sent) ?? DateTime.now();
                  return aTime.compareTo(bTime);
                });

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (ctx, index) => TextBox(msj: messages[index]),
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
                      TextPosition(offset: msjController.text.length));
              },
              textEditingController: msjController,
              config: Config(
                height: 250,
                checkPlatformCompatibility: true,
              ),
            ),
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.emoji_emotions,
                              color: Colors.white70),
                          onPressed: _toggleEmojiPicker,
                        ),
                        Expanded(
                          child: TextField(
                            controller: msjController,
                            focusNode: _focusNode,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Type a message',
                              hintStyle: TextStyle(color: Colors.white54),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.white70),
                          onPressed: () {
                            if (msjController.text.trim().isEmpty) return;
                            final msg = Message(
                              fromId: APIs.currentUser!.uid,
                              toId: widget.user.id!,
                              message: msjController.text.trim(),
                              sent: DateTime.now().toIso8601String(),
                              read: '',
                              type: 'text',
                            );
                            APIs.createMessage(msg);
                            msjController.clear();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    final isMe = msj.fromId == APIs.currentUser!.uid;
    final bgColor = isMe ? Colors.green : Colors.grey.shade800;
    final textColor = isMe ? Colors.white : Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Text(msj.message, style: TextStyle(color: textColor)),
            ),
            const SizedBox(height: 2),
            Text(
              DateFormat('h:mm a')
                  .format(DateTime.tryParse(msj.sent) ?? DateTime.now()),
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
