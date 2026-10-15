import 'package:flutter/material.dart';

import 'Chats/chat.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          ChatCard(),
          ChatCard(),
          ChatCard(),
          ChatCard(),
          ChatCard(),
        ],
      )
    );
  }
}

class ChatCard extends StatefulWidget {
  const ChatCard({super.key});

  @override
  State<ChatCard> createState() => _ChatCardState();
}

class _ChatCardState extends State<ChatCard> {
  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () { Navigator.of(context).push(MaterialPageRoute(builder: (context) => ChatPage())); },
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Chat name"),
          Text("Chat last message")
        ],
      ),
    );
  }
}

