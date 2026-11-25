import 'package:client/src/theme/app_colors.dart';
import 'package:client/src/theme/app_typography.dart';
import 'package:client/src/theme/app_theme.dart';
import 'package:client/src/services/chat_service.dart';
import 'package:client/src/widgets/api_status_banners.dart';
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
        title: const Text("Chats", style: AppTypography.headingMedium),
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
              dismissGlobalApiErrorWhenHandled(snapshot.error);
              return Center(
                child: Text(
                  apiErrorMessage(
                    snapshot.error!,
                    fallback: 'Could not load your chats.',
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }

            final chats = snapshot.data ?? const <ChatView>[];
            if (chats.isEmpty) {
              return Center(
                child: Text(
                  'You have no chats yet.',
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: chats.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.border,
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
      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
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
                    style: AppTypography.titleSmall.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (lastChatMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      lastChatMessage!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
