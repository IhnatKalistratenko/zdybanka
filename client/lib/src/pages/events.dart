import 'package:flutter/material.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

import '../models/event.dart';
import '../models/event_query.dart';
import '../models/event_tag.dart';
import '../services/event_service.dart';
import '../services/tag_service.dart';
import '../tools.dart';
import '../widgets/event_card.dart';
import '../widgets/event_details_widget.dart';

class EventsPage extends StatefulWidget {
  static final String pageRoute = "/events";
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final EventService _eventService = EventService();
  final TagService _tagService = TagService();

  List<Event> events = [];
  List<EventTag> availableTags = [];

  double maxDistanceKm = 5;
  final Set<String> selectedTags = {};

  DateTime? startFrom;
  DateTime? endTo;

  String sortBy = 'StartDate';

  bool isLoading = false;
  bool isLoadingTags = false;
  String? errorMessage;
  String? tagErrorMessage;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    startFrom = DateTime(now.year, now.month, now.day);
    _loadPageData();
  }

  Future<void> _loadPageData() async {
    await Future.wait([_loadEvents(), _loadTags()]);
  }

  Future<void> _loadEvents() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      LatLong userPosition = await determinePosition();
      final loadedEvents = await _eventService.getEvents(
        EventQuery(
          status: 'Active',
          userStatus: 'Available',
          startFrom: startFrom?.toUtc(),
          endTo: endTo == null
              ? null
              : DateTime(endTo!.year, endTo!.month, endTo!.day, 23, 59, 59).toUtc(),
          userLongitude: userPosition.longitude,
          userLatitude: userPosition.latitude,
          radiusMeters: maxDistanceKm * 1000,
          tags: selectedTags,
          orderMethod: sortBy,
          page: 1,
          pageSize: 20,
        ),
      );

      if (!mounted) return;

      setState(() {
        events = loadedEvents;
        isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = _errorText(error, 'Could not load events.');
        isLoading = false;
      });
    }
  }

  Future<void> _loadTags() async {
    setState(() {
      isLoadingTags = true;
      tagErrorMessage = null;
    });

    try {
      final tags = await _tagService.getTags();
      if (!mounted) return;
      setState(() {
        availableTags = tags;
        isLoadingTags = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        tagErrorMessage = _errorText(error, 'Could not load tags.');
        isLoadingTags = false;
      });
    }
  }

  String _errorText(Object error, String fallback) {
    final message = error.toString().trim();
    return message.isEmpty ? fallback : message;
  }

  Future<void> _pickDate({
    required bool isStart,
  }) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: (isStart ? startFrom : endTo) ??
          DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (selected == null) return;

    setState(() {
      if (isStart) {
        startFrom = selected;
      } else {
        endTo = selected;
      }
    });
  }

  void _resetFilters() {
    setState(() {
      maxDistanceKm = 5;
      selectedTags.clear();
      final now = DateTime.now();
      startFrom = DateTime(now.year, now.month, now.day);
      endTo = null;
      sortBy = 'StartDate';
    });
    _loadEvents();
  }

  String _formatDate(DateTime date) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${twoDigits(date.day)}.'
        '${twoDigits(date.month)}.'
        '${date.year} '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find event'),
        actions: [
          IconButton(
            tooltip: 'Update list',
            onPressed: _loadEvents,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilters(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Events found',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const Spacer(),
                  Text('${events.length}'),
                ],
              ),
            ),
            Expanded(
              child: _buildEventList(events),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return ExpansionTile(
      initiallyExpanded: false,
      title: const Text(
        'Filters',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      leading: const Icon(Icons.tune),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Row(
          children: [
            const Text('Distance'),
            const Spacer(),
            Text('${maxDistanceKm.toStringAsFixed(1)} km'),
          ],
        ),
        Slider(
          value: maxDistanceKm,
          min: 1,
          max: 50,
          divisions: 99,
          label: '${maxDistanceKm.toStringAsFixed(1)} km',
          onChanged: (value) {
            setState(() => maxDistanceKm = value);
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Tags',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 6),
        if (isLoadingTags)
          const LinearProgressIndicator()
        else if (tagErrorMessage != null)
          Row(
            children: [
              Expanded(child: Text(tagErrorMessage!)),
              IconButton(
                tooltip: 'Retry loading tags',
                onPressed: _loadTags,
                icon: const Icon(Icons.refresh),
              ),
            ],
          )
        else
          Wrap(
          spacing: 8,
          runSpacing: 0,
          children: availableTags.map((tag) {
            return FilterChip(
              label: Text(tag.name),
              selected: selectedTags.contains(tag.id),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedTags.add(tag.id);
                  } else {
                    selectedTags.remove(tag.id);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(isStart: true),
                icon: const Icon(Icons.calendar_month),
                label: Text(
                  startFrom == null
                      ? 'Starting from'
                      : _formatDate(startFrom!),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickDate(isStart: false),
                icon: const Icon(Icons.event_available),
                label: Text(
                  endTo == null
                      ? 'Ending by'
                      : _formatDate(endTo!),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: sortBy,
          decoration: const InputDecoration(
            labelText: 'Sort by',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(
              value: 'StartDate',
              child: Text('Start date'),
            ),
            DropdownMenuItem(
              value: 'Distance',
              child: Text('Distance'),
            ),
            DropdownMenuItem(
              value: 'Name',
              child: Text('Name'),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => sortBy = value);
            }
          },
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: Wrap(
            spacing: 8,
            children: [
              TextButton(
                onPressed: _resetFilters,
                child: const Text('Reset filters'),
              ),
              FilledButton(
                onPressed: isLoading ? null : _loadEvents,
                child: const Text('Apply filters'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventList(List<Event> filtered) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(errorMessage!),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _loadEvents,
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy, size: 48),
              SizedBox(height: 12),
              Text('No events match the selected filters.'),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final event = filtered[index];

        return EventCard(
          event: event,
          trailing: EventDistanceTrailing(
            distanceKm: event.distanceKm,
          ),
          onTap: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (_) => JoinableEventDetailsWidget(
              eventId: event.id,
              onJoinCallback: () {
                _loadEvents();
              },
            ),
          ),
        );
      },
    );
  }
}
