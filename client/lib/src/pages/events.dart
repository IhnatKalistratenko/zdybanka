import 'package:client/src/pages/Events/event_join.dart';
import 'package:flutter/material.dart';
import '../widgets/event_card.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          EventCard(trailing: EventDistanceTrailing()),
          EventCard(trailing: EventDistanceTrailing()),
          EventCard(trailing: EventDistanceTrailing()),
          EventCard(trailing: EventDistanceTrailing()),
          EventCard(trailing: EventDistanceTrailing()),
        ],
      ),
    );
  }
}
