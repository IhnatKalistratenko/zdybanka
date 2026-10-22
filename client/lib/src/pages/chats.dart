import 'package:flutter/material.dart';

import 'Chats/chat.dart';

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with chats loaded from the backend.
    final chats = [
      ("Розробка проєкту", "Олег: Скинув оновлений макет..."),
      ("Університет", "Аня: Завтра пара о 10:00, не забудь!"),
      ("Гітара", "Данило: Чудово! До завтра!"),
      ("Міський чат", "Ірина: Хтось знає, що з транспортом..."),
      ("Кіно та серіали", "Максим: Я подивився перші 2 серії..."),
      ("Просто поговорити", null),
    ];

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
        child: ListView.separated(
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
              chatName: chat.$1,
              lastChatMessage: chat.$2,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatPage()));
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



