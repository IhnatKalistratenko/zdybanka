import 'dart:async';

import 'package:client/src/theme/app_colors.dart';
import 'package:client/src/theme/app_typography.dart';
import 'package:client/src/theme/app_theme.dart';
import 'package:client/src/services/signalr_service.dart';
import 'package:flutter/material.dart';
import 'package:client/src/models/extended_chat.dart';
import 'package:client/src/models/message.dart';
import 'package:client/src/services/chat_service.dart';
import 'package:client/src/widgets/api_status_banners.dart';
import 'package:client/src/config/http_config.dart';

import 'edit_chat.dart';

class ChatPage extends StatefulWidget {
  final String chatId;

  const ChatPage({super.key, required this.chatId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  late Future<ExtendedChat> _chatFuture;
  ExtendedChat? _loadedChat;
  late StreamSubscription<Message> _messageStream;
  final SignalrService _signalrService = SignalrService();
  final List<Message> _liveMessages = [];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _chatFuture = ChatService().getChatById(widget.chatId);
    _messageStream = _signalrService.messages.listen((message) {
      if (!mounted || message.chatId != widget.chatId) return;
      setState(() {
        if (!_liveMessages.any((existing) => existing.id == message.id)) {
          _liveMessages.add(message);
        }
      });
    });
    unawaited(_connectToChat());
  }

  Future<void> _connectToChat() async {
    try {
      await _chatFuture;
      if (!mounted) return;
      await _signalrService.connect();
      if (!mounted) return;
      await _signalrService.joinChat(widget.chatId);
    } catch (error) {
      if (!mounted) return;
      dismissGlobalApiErrorWhenHandled(error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            apiErrorMessage(error, fallback: 'Could not connect to the chat.'),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _messageStream.cancel();
    unawaited(_disconnectFromChat());
    super.dispose();
  }

  Future<void> _disconnectFromChat() async {
    try {
      await _signalrService.leaveChat(widget.chatId);
    } catch (_) {
      // The connection may already have been lost while leaving the page.
    } finally {
      await _signalrService.dispose();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();

    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    try {
      await _signalrService.sendMessage(widget.chatId, text);
      if (mounted) _messageController.clear();
    } catch (error) {
      dismissGlobalApiErrorWhenHandled(error);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              apiErrorMessage(error, fallback: 'Could not send the message.'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showChatDetails(ExtendedChat chat) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return ChatDetailsPopUp(
          chatName: chat.name,
          chatDescription: chat.description,
          onEditTap: () async {
            final updated = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => EditChatPage(
                  chatId: chat.id,
                  initialName: chat.name,
                  initialDescription: chat.description,
                ),
              ),
            );
            if (updated == true && mounted) {
              Navigator.of(context).pop();
              setState(() {
                _chatFuture = ChatService().getChatById(widget.chatId);
              });
            }
          },
          participants: const [],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        leading: const BackButton(),
        titleSpacing: 0,
        title: InkWell(
          onTap: () {
            final chat = _loadedChat;
            if (chat != null) _showChatDetails(chat);
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: FutureBuilder<ExtendedChat>(
              future: _chatFuture,
              builder: (context, snapshot) {
                final chat = snapshot.data;
                if (chat != null) _loadedChat = chat;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat?.name ?? 'Chat',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (chat != null && chat.description.isNotEmpty)
                      Text(
                        chat.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      body: FutureBuilder<ExtendedChat>(
        future: _chatFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            dismissGlobalApiErrorWhenHandled(snapshot.error);
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  apiErrorMessage(
                    snapshot.error!,
                    fallback: 'Could not load the chat.',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final chat = snapshot.data!;
          final messages = <Message>[
            ...chat.messages,
            ..._liveMessages.where(
              (live) => !chat.messages.any((loaded) => loaded.id == live.id),
            ),
          ]..sort((left, right) => left.sentAt.compareTo(right.sentAt));
          return Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? const Center(child: Text('No messages yet.'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        itemCount: messages.length * 2,
                        itemBuilder: (context, index) {
                          final messageIndex = index ~/ 2;
                          final message = messages[messageIndex];
                          final isDateDivider = index.isEven;

                          if (isDateDivider &&
                              (messageIndex == 0 ||
                                  !_isSameDay(
                                    messages[messageIndex - 1].sentAt,
                                    message.sentAt,
                                  ))) {
                            return _MessageDateDivider(date: message.sentAt);
                          }
                          if (isDateDivider) return const SizedBox.shrink();
                          return _MessageBubble(message: message);
                        },
                      ),
              ),

              // Message input
              const Divider(height: 1, color: AppColors.border),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 5,
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) {
                            if (!apiClient.degradedMode.isDegraded) {
                              _sendMessage();
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Write you message...',
                            hintStyle: AppTypography.body.copyWith(
                              color: AppColors.textMuted,
                            ),
                            filled: true,
                            fillColor: AppColors.background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DegradedModeBuilder(
                        builder: (context, isDegraded) => IconButton.filled(
                          onPressed: isDegraded || _isSending
                              ? null
                              : _sendMessage,
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.onPrimary,
                            fixedSize: const Size(48, 48),
                          ),
                          icon: const Icon(Icons.send_rounded, size: 21),
                          tooltip: 'Send message',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

bool _isSameDay(DateTime first, DateTime second) {
  final firstLocal = first.toLocal();
  final secondLocal = second.toLocal();
  return firstLocal.year == secondLocal.year &&
      firstLocal.month == secondLocal.month &&
      firstLocal.day == secondLocal.day;
}

class _MessageDateDivider extends StatelessWidget {
  final DateTime date;

  const _MessageDateDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    final localDate = date.toLocal();
    final label =
        '${localDate.day} ${_monthName(localDate.month)} ${localDate.year}';

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.border)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.border)),
        ],
      ),
    );
  }
}

String _monthName(int month) => const [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
][month - 1];

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isOwner;
    final sender = isMine ? 'You' : message.senderName;
    final sentAt = message.sentAt.toLocal();
    final time =
        '${sentAt.hour.toString().padLeft(2, '0')}:${sentAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMine) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 5),
                child: Text(
                  sender,
                  style: AppTypography.label.copyWith(
                    color: AppColors.secondary,
                  ),
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMine ? AppColors.primary : AppColors.chatBubble,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMine ? 18 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message.content,
                    style: AppTypography.body.copyWith(
                      color: isMine
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: AppTypography.overline.copyWith(
                      color: isMine
                          ? AppColors.onPrimaryMuted
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatDetailsPopUp extends StatelessWidget {
  final String chatName;
  final String? chatDescription;
  final List<String> participants;
  final VoidCallback onEditTap;

  const ChatDetailsPopUp({
    super.key,
    required this.chatName,
    this.chatDescription,
    required this.participants,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.disabled,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Chat information
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chatName,
                          style: AppTypography.headingSmall.copyWith(
                            fontSize: 22,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (chatDescription != null &&
                            chatDescription!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            chatDescription!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: onEditTap,
                    tooltip: 'Edit chat',
                    icon: const Icon(Icons.edit_outlined),
                    color: AppColors.primary,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primarySurface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: 20),

              if (participants.isNotEmpty) ...[
                Text(
                  'Members (${participants.length})',
                  style: AppTypography.title.copyWith(
                    fontSize: 17,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...participants.map(
                  (participant) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      participant,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
