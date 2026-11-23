import 'package:flutter/material.dart';

import '../models/event.dart';
import '../services/event_service.dart';
import '../pages/Events/event_edit.dart';

/// Shared event details UI. Subclasses provide the action for the user's
/// relationship to the event.
abstract class EventDetailsWidget extends StatefulWidget {
  final String eventId;

  const EventDetailsWidget({super.key, required this.eventId});
}

class JoinableEventDetailsWidget extends EventDetailsWidget {
  final VoidCallback? onJoinCallback;

  const JoinableEventDetailsWidget({
    super.key,
    required super.eventId,
    this.onJoinCallback,
  });

  @override
  State<JoinableEventDetailsWidget> createState() =>
      _JoinableEventDetailsState();
}

class JoinedEventDetailsWidget extends EventDetailsWidget {
  final VoidCallback? onLeaveCallback;

  const JoinedEventDetailsWidget({
    super.key,
    required super.eventId,
    this.onLeaveCallback,
  });

  @override
  State<JoinedEventDetailsWidget> createState() => _JoinedEventDetailsState();
}

class OwnedEventDetailsWidget extends EventDetailsWidget {
  final VoidCallback? onDeleteCallback;

  const OwnedEventDetailsWidget({
    super.key,
    required super.eventId,
    this.onDeleteCallback,
  });

  @override
  State<OwnedEventDetailsWidget> createState() => _OwnedEventDetailsState();
}

abstract class _EventDetailsState<T extends EventDetailsWidget>
    extends State<T> {
  late Future<Event> _eventFuture;

  @override
  void initState() {
    super.initState();
    _eventFuture = EventService().getEventById(widget.eventId);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.eventId != widget.eventId) {
      _eventFuture = EventService().getEventById(widget.eventId);
    }
  }

  Widget buildEventAction(BuildContext context, Event event);

  String _formatDate(DateTime date) {
    DateTime localDate = date.toLocal();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${twoDigits(localDate.day)}.${twoDigits(localDate.month)}.${localDate.year} '
        '${twoDigits(localDate.hour)}:${twoDigits(localDate.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: FutureBuilder<Event>(
          future: _eventFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Could not load event details.'),
              );
            }

            final event = snapshot.data!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    event.name,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  _detailRow(
                    context,
                    Icons.calendar_month,
                    'Starts',
                    _formatDate(event.startTime),
                  ),
                  _detailRow(
                    context,
                    Icons.event_available,
                    'Ends',
                    _formatDate(event.endTime),
                  ),
                  _detailRow(
                    context,
                    Icons.location_on,
                    'Address',
                    event.address,
                  ),
                  _detailRow(
                    context,
                    Icons.people,
                    'Participants',
                    '${event.participantsCount} of ${event.maxParticipants}',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Description',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(event.description),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: event.tags
                        .map((tag) => Chip(label: Text(tag.name)))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  buildEventAction(context, event),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _detailRow(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _JoinableEventDetailsState
    extends _EventDetailsState<JoinableEventDetailsWidget> {
  bool _isJoining = false;

  Future<void> _handleJoinEvent(Event event) async {
    if (_isJoining || event.participantsCount >= event.maxParticipants) return;

    setState(() => _isJoining = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await EventService().joinEvent(event.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onJoinCallback?.call();
      messenger.showSnackBar(
        const SnackBar(content: Text('You joined the event.')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not join event: $error')),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  Widget buildEventAction(BuildContext context, Event event) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _isJoining || event.participantsCount >= event.maxParticipants
            ? null
            : () => _handleJoinEvent(event),
        child: Text(
          _isJoining
              ? 'Joining...'
              : event.participantsCount >= event.maxParticipants
              ? 'No spots available'
              : 'Join event',
        ),
      ),
    );
  }
}

class _JoinedEventDetailsState
    extends _EventDetailsState<JoinedEventDetailsWidget> {
  bool _isLeaving = false;

  Future<void> _handleLeaveEvent(Event event) async {
    if (_isLeaving) return;

    setState(() => _isLeaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await EventService().leaveEvent(event.id);
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onLeaveCallback?.call();
      messenger.showSnackBar(
        const SnackBar(content: Text('You left the event.')),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Could not leave event: $error')),
      );
    } finally {
      if (mounted) setState(() => _isLeaving = false);
    }
  }

  @override
  Widget buildEventAction(BuildContext context, Event event) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isLeaving ? null : () => _handleLeaveEvent(event),
        child: Text(_isLeaving ? 'Leaving...' : 'Leave event'),
      ),
    );
  }
}

class _OwnedEventDetailsState
    extends _EventDetailsState<OwnedEventDetailsWidget> {
  bool _isDeleting = false;

  Future<void> _deleteEvent(BuildContext context, Event event) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('“${event.name}” will be permanently deleted.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    setState(() => _isDeleting = true);
    try {
      await EventService().deleteEvent(widget.eventId);
      if (!mounted) return;
      Navigator.pop(context);
      widget.onDeleteCallback?.call();
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Event deleted.')));
    } catch (error) {
      if (!mounted) return;
      widget.onDeleteCallback?.call();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete event: $error')));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget buildEventAction(BuildContext context, Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => EditEventPage(eventId: event.id)),
          ),
          icon: const Icon(Icons.edit),
          label: const Text('Edit event'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isDeleting ? null : () => _deleteEvent(context, event),
          icon: _isDeleting
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_outline),
          label: const Text('Delete event'),
        ),
      ],
    );
  }
}
