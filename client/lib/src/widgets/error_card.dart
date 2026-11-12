import 'package:client/src/theme/app_colors.dart';
import 'package:client/src/theme/app_typography.dart';
import 'package:flutter/material.dart';

class ErrorCardContent {
  final String? type;
  final String message;
  const ErrorCardContent({required this.message, this.type});
}

class ErrorCard extends StatelessWidget {
  final ErrorCardContent error;
  const ErrorCard({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: AppColors.error,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning, color: AppColors.onPrimary),
                  Text(
                    error.type ?? "",
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    error.message,
                    style: AppTypography.body.copyWith(
                      color: AppColors.onPrimary,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
