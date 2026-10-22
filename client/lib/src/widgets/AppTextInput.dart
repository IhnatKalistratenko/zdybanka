import 'package:flutter/material.dart';

class AppFormInput extends StatefulWidget {
  final Widget title;
  final String? inputHintText;
  final TextEditingController controller;
  final int? maxLength;
  final int? maxLines;
  final TextInputType? keyboardType;
  const AppFormInput({super.key, required this.title, required this.controller, this.inputHintText, this.maxLength, this.keyboardType, this.maxLines});

  @override
  State<AppFormInput> createState() => _AppFormInputState();
}

class _AppFormInputState extends State<AppFormInput> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.title,
        SizedBox(height: 5),
      TextField(
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          hintText: widget.inputHintText,

        ),
        controller: widget.controller,
      )
      ],
    );
  }
}
