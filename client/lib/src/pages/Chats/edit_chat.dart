import 'package:client/src/theme/app_typography.dart';
import 'package:client/src/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:client/src/services/chat_service.dart';
import 'package:client/src/widgets/api_status_banners.dart';

class EditChatPage extends StatefulWidget {
  final String chatId;
  final String initialName;
  final String? initialDescription;

  const EditChatPage({
    super.key,
    required this.chatId,
    required this.initialName,
    this.initialDescription,
  });

  @override
  State<EditChatPage> createState() => _EditChatPageState();
}

class _EditChatPageState extends State<EditChatPage> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  bool _isSaving = false;

  bool get _hasChanges =>
      _nameController.text.trim() != widget.initialName.trim() ||
      _descriptionController.text.trim() !=
          (widget.initialDescription ?? '').trim();

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.initialName);

    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _nameController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.removeListener(_onFieldChanged);
    _descriptionController.removeListener(_onFieldChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Chat name is required.';
    }

    if (name.length < 3) {
      return 'Chat name must be at least 3 characters long.';
    }

    if (name.length > 50) {
      return 'Chat name cannot be longer than 50 characters.';
    }

    return null;
  }

  String? _validateDescription(String? value) {
    final description = value?.trim() ?? '';

    if (description.length > 1000) {
      return 'Description cannot be longer than 1,000 characters.';
    }

    return null;
  }

  Future<void> _saveChanges() async {
    // Validate both fields.
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    setState(() {
      _isSaving = true;
    });

    try {
      await ChatService().updateChat(
        chatId: widget.chatId,
        name: name,
        description: description,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      dismissGlobalApiErrorWhenHandled(error);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            apiErrorMessage(error, fallback: 'Could not save chat changes.'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit chat')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit chat',
                style: AppTypography.headingSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Change your chat name and description.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 25),
                child: Divider(),
              ),

              // Chat name
              const Text('Chat name', style: AppTypography.title),
              const SizedBox(height: 5),
              const Text('This name will appear in the chat list.'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                validator: _validateName,
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter a chat name',
                  counterText: '',
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nameController,
                  builder: (context, value, child) {
                    return Text(
                      '${value.text.length}/50',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 25),
                child: Divider(),
              ),

              // Chat description
              const Text('Chat description', style: AppTypography.title),
              const SizedBox(height: 5),
              const Text(
                'Briefly describe what this chat is for. '
                'This field is optional.',
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                validator: _validateDescription,
                maxLength: 1000,
                maxLines: 5,
                minLines: 3,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter a chat description',
                  alignLabelWithHint: true,
                  counterText: '',
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _descriptionController,
                  builder: (context, value, child) {
                    return Text(
                      '${value.text.length}/1000',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 25),

              // One button for both fields
              SizedBox(
                width: double.infinity,
                child: DegradedModeBuilder(
                  builder: (context, isDegraded) => ElevatedButton(
                    onPressed: isDegraded || _isSaving || !_hasChanges
                        ? null
                        : _saveChanges,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Text(
                            'Save changes',
                            style: AppTypography.button,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
