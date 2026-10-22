
import 'package:flutter/material.dart';

import 'edit_chat.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();

  // TODO: Replace with messages loaded from the backend.
  final List<_Message> _messages = [
    _Message(
      author: 'Олег',
      text: 'Привіт! Як вам новий макет?',
      time: '16:32',
    ),
    _Message(
      author: 'Я',
      text: 'Виглядає добре. Можна трохи змінити відступи.',
      time: '16:45',
      isMine: true,
    ),
    _Message(
      author: 'Марія',
      text: 'Згодна. Я теж помітила кілька моментів.',
      time: '17:10',
    ),
    _Message(
      author: 'Олег',
      text: 'Добре, тоді внесу зміни сьогодні.',
      time: '17:15',
    ),
    _Message(
      author: 'Я',
      text: 'Супер, дякую!',
      time: '17:20',
      isMine: true,
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();

    if (text.isEmpty) return;

    // TODO: Send message to the backend.
    setState(() {
      _messages.add(
        _Message(
          author: 'Я',
          text: text,
          time: TimeOfDay.now().format(context),
          isMine: true,
        ),
      );
    });

    _messageController.clear();
  }

  void _showChatDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return ChatDetailsPopUp(chatName: "Chat name", onEditTap: () {Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditChatPage(initialName: "chat name", initialDescription: "chat description",)));}, participants: ["Maksym", "Olena", "Mykola", "Ivan", "Ivan", "Ivan", "Ivan", "Ivan", "Ivan", "Ivan", "Ivan", "Ivan", "Ivan", "Ivan"], chatDescription: "Description",);
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
          onTap: _showChatDetails,
          borderRadius: BorderRadius.circular(8),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Розробка проєкту',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '5 members',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];

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
                    onPressed: _sendMessage,
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
      ),
    );
  }
}

class _Message {
  final String author;
  final String text;
  final String time;
  final bool isMine;

  const _Message({
    required this.author,
    required this.text,
    required this.time,
    this.isMine = false,
  });
}

class _MessageBubble extends StatelessWidget {
  final _Message message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;

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
                  message.author,
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
                    message.text,
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
                    message.time,
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
      
              // Participants header
              Text(
                'Members (${participants.length})',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF172033),
                ),
              ),
      
              const SizedBox(height: 8),
      
              // Participants list
              if (participants.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'There is no members.',
                    style: TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 14,
                    ),
                  ),
                )
              else
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
      
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

