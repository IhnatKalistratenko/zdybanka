import 'package:client/src/services/chat_service.dart';
import 'package:flutter/material.dart';

import '../../models/chat_view.dart';
import 'chat_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  Future<List<ChatView>>? futureChats;

  @override
  void initState() {
    super.initState();

    futureChats = ChatService().getUserChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chats",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
          ),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<List<ChatView>>(
          future: futureChats,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Failed to load your chats. ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              );
            }

            final chats = snapshot.data ?? const <ChatView>[];
            if (chats.isEmpty) {
              return const Center(
                child: Text(
                  'You have no chats yet.',
                  style: TextStyle(color: Color(0xFF718096), fontSize: 16),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: chats.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE5EAF1),
              ),
              itemBuilder: (context, index) {
                final chat = chats[index];

                return ChatCard(
                  chatName: chat.name,
                  lastChatMessage: chat.lastMessage?.content,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatPage(chatId: chat.id),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ChatCard extends StatelessWidget {
  final String chatName;
  final String? lastChatMessage;
  final VoidCallback onTap;

  const ChatCard({
    super.key,
    required this.chatName,
    required this.onTap,
    this.lastChatMessage,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 16,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (lastChatMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      lastChatMessage!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF718096),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF718096),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}



