import 'package:flutter/material.dart';

import '../widgets/event_card.dart';

class Event {
  final String id;
  final String name;
  final String description;
  final String address;
  final DateTime startTime;
  final DateTime endTime;
  final int maxParticipants;
  final int participantsCount;
  final List<String> tags;
  final double distanceKm;

  const Event({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.startTime,
    required this.endTime,
    required this.maxParticipants,
    required this.participantsCount,
    required this.tags,
    required this.distanceKm,
  });
}

// TODO: замінити тестові дані відповіддю від ASP.NET API.
final mockEvents = <Event>[
  Event(
    id: '1',
    name: 'Вечір настільних ігор',
    description:
    'Збираємося разом, щоб познайомитися, '
        'пограти в настільні ігри та приємно провести вечір.',
    address: 'вул. Лесі Українки, 15, Луцьк',
    startTime: DateTime(2026, 10, 29, 18),
    endTime: DateTime(2026, 10, 29, 21),
    maxParticipants: 12,
    participantsCount: 7,
    tags: ['Ігри', 'Спілкування'],
    distanceKm: 0.3,
  ),
  Event(
    id: '2',
    name: 'Спільна пробіжка',
    description:
    'Легка пробіжка в парку для всіх охочих. '
        'Темп комфортний, досвід не обов’язковий.',
    address: 'Центральний парк, Луцьк',
    startTime: DateTime(2026, 10, 30, 9),
    endTime: DateTime(2026, 10, 30, 10),
    maxParticipants: 20,
    participantsCount: 8,
    tags: ['Спорт', 'Здоров’я'],
    distanceKm: 1.2,
  ),
  Event(
    id: '3',
    name: 'Вечір акустичної музики',
    description:
    'Неформальна зустріч музикантів і слухачів. '
        'Можна грати, співати або просто слухати.',
    address: 'вул. Кривий Вал, 10, Луцьк',
    startTime: DateTime(2026, 11, 1, 17),
    endTime: DateTime(2026, 11, 1, 20),
    maxParticipants: 15,
    participantsCount: 10,
    tags: ['Музика', 'Спілкування'],
    distanceKm: 2.4,
  ),
];

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<Event> events = [];

  double maxDistance = 5;
  final Set<String> selectedTags = {};

  DateTime? startFrom;
  DateTime? endBefore;

  String sortBy = 'date';

  bool isLoading = false;
  String? errorMessage;

  final List<String> availableTags = [
    'Ігри',
    'Спілкування',
    'Спорт',
    'Здоров’я',
    'Музика',
    'Навчання',
  ];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  // TODO: замінити mockEvents на запит до API.
  // Наприклад: GET /api/events?...
  Future<void> _loadEvents() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Імітуємо отримання даних із сервера.
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      );

      if (!mounted) return;

      setState(() {
        events = mockEvents;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage = 'Не вдалося завантажити події.';
        isLoading = false;
      });
    }
  }

  List<Event> get filteredEvents {
    final result = events.where((event) {
      if (event.distanceKm > maxDistance) return false;

      // Якщо вибрано кілька тегів, достатньо збігу
      // хоча б з одним із них.
      if (selectedTags.isNotEmpty &&
          !event.tags.any(selectedTags.contains)) {
        return false;
      }

      if (startFrom != null &&
          event.startTime.isBefore(startFrom!)) {
        return false;
      }

      if (endBefore != null &&
          event.endTime.isAfter(
            DateTime(
              endBefore!.year,
              endBefore!.month,
              endBefore!.day,
              23,
              59,
              59,
            ),
          )) {
        return false;
      }

      return true;
    }).toList();

    switch (sortBy) {
      case 'distance':
        result.sort(
              (a, b) => a.distanceKm.compareTo(b.distanceKm),
        );
      case 'name':
        result.sort((a, b) => a.name.compareTo(b.name));
      default:
        result.sort(
              (a, b) => a.startTime.compareTo(b.startTime),
        );
    }

    return result;
  }

  Future<void> _pickDate({
    required bool isStart,
  }) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: (isStart ? startFrom : endBefore) ??
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
        endBefore = selected;
      }
    });
  }

  void _resetFilters() {
    setState(() {
      maxDistance = 5;
      selectedTags.clear();
      startFrom = null;
      endBefore = null;
      sortBy = 'date';
    });
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
    final filtered = filteredEvents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Пошук подій'),
        actions: [
          IconButton(
            tooltip: 'Оновити список',
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
                    'Знайдені події',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                  const Spacer(),
                  Text('${filtered.length}'),
                ],
              ),
            ),
            Expanded(
              child: _buildEventList(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return ExpansionTile(
      initiallyExpanded: true,
      title: const Text(
        'Фільтри',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      leading: const Icon(Icons.tune),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        Row(
          children: [
            const Text('Відстань'),
            const Spacer(),
            Text('${maxDistance.toStringAsFixed(1)} км'),
          ],
        ),
        Slider(
          value: maxDistance,
          min: 0.5,
          max: 50,
          divisions: 99,
          label: '${maxDistance.toStringAsFixed(1)} км',
          onChanged: (value) {
            setState(() => maxDistance = value);
          },
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Теги',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 0,
          children: availableTags.map((tag) {
            return FilterChip(
              label: Text(tag),
              selected: selectedTags.contains(tag),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedTags.add(tag);
                  } else {
                    selectedTags.remove(tag);
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
                      ? 'Початок від'
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
                  endBefore == null
                      ? 'Завершення до'
                      : _formatDate(endBefore!),
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
            labelText: 'Сортування',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(
              value: 'date',
              child: Text('За датою початку'),
            ),
            DropdownMenuItem(
              value: 'distance',
              child: Text('За відстанню'),
            ),
            DropdownMenuItem(
              value: 'name',
              child: Text('За назвою'),
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
          child: TextButton(
            onPressed: _resetFilters,
            child: const Text('Скинути фільтри'),
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
              child: const Text('Спробувати ще раз'),
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
              Text('Подій за заданими фільтрами не знайдено.'),
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
          onTap: () => _showEventDetails(event),
        );
      },
    );
  }

  void _showEventDetails(Event event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              20 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
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
                    Icons.calendar_month,
                    'Початок',
                    _formatDate(event.startTime),
                  ),
                  _detailRow(
                    Icons.event_available,
                    'Завершення',
                    _formatDate(event.endTime),
                  ),
                  _detailRow(
                    Icons.location_on,
                    'Адреса',
                    event.address,
                  ),
                  _detailRow(
                    Icons.people,
                    'Учасники',
                    '${event.participantsCount} '
                        'із ${event.maxParticipants}',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Опис',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(event.description),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: event.tags
                        .map((tag) => Chip(label: Text(tag)))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: event.participantsCount >=
                          event.maxParticipants
                          ? null
                          : () {
                        // TODO: POST /api/events/{id}/join
                        Navigator.pop(context);
                      },
                      child: Text(
                        event.participantsCount >=
                            event.maxParticipants
                            ? 'Немає вільних місць'
                            : 'Доєднатися',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(
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
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
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