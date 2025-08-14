import 'package:flutter/material.dart';
import 'package:me_chat/models/message_model.dart';
import 'package:me_chat/models/user_model.dart';

Color primaryColor = const Color.fromARGB(255, 84, 202, 88);

UserData currentUser = UserData(
    id: '',
    isOonline: false,
    createdAt: '',
    image: '',
    email: '',
    pushToken: '',
    about: '',
    lastActive: '',
    name: '');

List<UserData> allUsers = [];
List<Message> allMessages = [];
