import 'package:flutter/material.dart';
import 'package:client/src/theme/app_typography.dart';

import '../models/event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final Widget trailing;
  final VoidCallback onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.trailing,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    DateTime localDate = date.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(localDate.day)}.'
        '${twoDigits(localDate.month)}.'
        '${localDate.year} '
        '${twoDigits(localDate.hour)}:${twoDigits(localDate.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        onTap: onTap,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    style: AppTypography.titleSmall,
                  ),
                  const SizedBox(height: 10),
                  _infoRow(Icons.calendar_month, _formatDate(event.startTime)),
                  const SizedBox(height: 7),
                  _infoRow(Icons.location_on, event.address),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: event.tags.map((tag) {
                      return Chip(
                        label: Text(
                          tag.name,
                          style: AppTypography.overline,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(width: 64, child: trailing),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTypography.label)),
      ],
    );
  }
}

class EventDistanceTrailing extends StatelessWidget {
  final double distanceKm;

  const EventDistanceTrailing({super.key, required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.near_me_outlined),
        const SizedBox(height: 4),
        Text(
          '${distanceKm.toStringAsFixed(1)} км',
          textAlign: TextAlign.center,
          style: AppTypography.caption,
        ),
        const Icon(Icons.keyboard_arrow_right, size: 28),
      ],
    );
  }
}

class EventArrowTrailing extends StatelessWidget {
  const EventArrowTrailing({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(Icons.keyboard_arrow_right, size: 35)],
    );
  }
}
