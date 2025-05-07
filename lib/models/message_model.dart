class Message {
  final String fromId;
  final String toId;
  final String message;
  final String sent;
  final String read;
  final String type;

  Message({
    required this.fromId,
    required this.toId,
    required this.message,
    required this.sent,
    required this.read,
    required this.type,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      fromId: json['fromId'] as String,
      toId: json['toId'] as String,
      message: json['message'] as String,
      sent: json['sent'] as String,
      read: json['read'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fromId': fromId,
      'toId': toId,
      'message': message,
      'sent': sent,
      'read': read,
      'type': type,
    };
  }
}
