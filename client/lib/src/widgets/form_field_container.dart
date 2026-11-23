
import 'package:client/src/theme/app_colors.dart';
import 'package:client/src/theme/app_typography.dart';
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
            style: AppTypography.label.copyWith(letterSpacing: 0.5),
            children: [
              TextSpan(text: title, style: AppTypography.caption.copyWith(color: AppColors.onDark)),
              if (required)
                TextSpan(
                  text: ' *',
                  style: AppTypography.caption.copyWith(color: AppColors.error),
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
            style: AppTypography.caption.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
