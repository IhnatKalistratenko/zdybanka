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
        color: Colors.red[400],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning),
                  Text(error.type ?? "", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17,))
                ],
              ),
              Row(
                children: [
                  Text(error.message),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}