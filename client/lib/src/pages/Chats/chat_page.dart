
import 'dart:async';

import 'package:client/src/services/signalr_service.dart';
import 'package:flutter/material.dart';
import 'package:client/src/models/extended_chat.dart';
import 'package:client/src/models/message.dart';
import 'package:client/src/services/chat_service.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat connection failed: $error')),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: $error')),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
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
          borderRadius: BorderRadius.circular(8),
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF172033),
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (chat != null && chat.description.isNotEmpty)
                      Text(
                        chat.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF718096),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load chat.',
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
          const Divider(height: 1, color: Color(0xFFE5EAF1)),
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
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Write you message...',
                        hintStyle: const TextStyle(
                          color: Color(0xFF8A96A8),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF5F7FA),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _sendMessage,
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF3478F6),
                      foregroundColor: Colors.white,
                      fixedSize: const Size(48, 48),
                    ),
                    icon: const Icon(Icons.send_rounded, size: 21),
                    tooltip: 'Send message',
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
          const Expanded(child: Divider(color: Color(0xFFE5EAF1))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF718096),
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE5EAF1))),
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
      alignment: isMine
          ? Alignment.centerRight
          : Alignment.centerLeft,
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
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF52627A),
                  ),
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMine
                    ? const Color(0xFF3478F6)
                    : const Color(0xFFF0F3F8),
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
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: isMine
                          ? Colors.white
                          : const Color(0xFF172033),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMine
                          ? Colors.white70
                          : const Color(0xFF718096),
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
                    color: Colors.grey.shade300,
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
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF172033),
                          ),
                        ),
                        if (chatDescription != null &&
                            chatDescription!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            chatDescription!,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Color(0xFF718096),
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
                    color: const Color(0xFF3478F6),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFEDF3FF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
      
              const SizedBox(height: 24),
              const Divider(
                height: 1,
                color: Color(0xFFE5EAF1),
              ),
              const SizedBox(height: 20),
      
              if (participants.isNotEmpty) ...[
                Text(
                  'Members (${participants.length})',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF172033),
                  ),
                ),
                const SizedBox(height: 8),
                ...participants.map(
                  (participant) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      participant,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF172033),
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

