
import 'package:flutter/material.dart';

class FormFieldContainer extends StatelessWidget {
  final String title;
  final bool required;
  final String? errorText;
  final Widget child;

  const FormFieldContainer({
    super.key,
    required this.title,
    required this.child,
    this.required = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            children: [
              TextSpan(text: title),
              if (required)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: Colors.red.shade400),
                ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        child,
        if (errorText != null) ...[
          const SizedBox(height: 5),
          Text(
            errorText!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}
