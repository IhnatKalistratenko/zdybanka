
import 'package:flutter/material.dart';

class EditChatPage extends StatefulWidget {
  final String initialName;
  final String? initialDescription;

  const EditChatPage({
    super.key,
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

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.initialName,
    );

    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Назва чату є обов’язковою.';
    }

    if (name.length < 3) {
      return 'Назва повинна містити щонайменше 3 символи.';
    }

    if (name.length > 50) {
      return 'Назва не може перевищувати 50 символів.';
    }

    return null;
  }

  String? _validateDescription(String? value) {
    final description = value?.trim() ?? '';

    if (description.length > 1000) {
      return 'Опис не може перевищувати 1000 символів.';
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
      // TODO: Call the chat service here.
      // Example integration point:
      // await chatService.updateChat(...);
      //
      // Pass the chat identifier and updated values according
      // to the actual service/API contract.

      // TODO: After a successful service response:
      // if (!mounted) return;
      // Navigator.pop(context, updatedChat);

    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Не вдалося зберегти зміни чату.'),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Редагування чату'),
        elevation: 0.7,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Редагування чату',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Color(0xFF172033),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Змініть назву та опис вашого чату.',
                style: TextStyle(
                  color: Color(0xFF718096),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 25),
                child: Divider(),
              ),

              // Chat name
              const Text(
                'Назва чату',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Назва відображатиметься у списку чатів.',
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                validator: _validateName,
                maxLength: 50,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Назва',
                  hintText: 'Введіть назву чату',
                  border: OutlineInputBorder(),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
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
              const Text(
                'Опис чату',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Коротко розкажіть, для чого створено цей чат. '
                    'Поле необов’язкове.',
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
                  labelText: 'Опис',
                  hintText: 'Введіть опис чату',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 25),

              // One button for both fields
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3478F6),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text(
                    'Зберегти зміни',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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
