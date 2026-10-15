import 'package:client/src/pages/Events/event_join.dart';
import 'package:flutter/material.dart';

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
          EventCard(),
          EventCard(),
          EventCard(),
          EventCard(),
          EventCard(),
        ],
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  const EventCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext ctx) => EventJoinPage()));
      },
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text("Event name", style: TextStyle(fontWeight: FontWeight.bold),), Text("Event description"), Text("Location: вул. Лесі Українки 15, м. Луцьк"), Text("Participants: 8/16")],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [Icon(Icons.local_activity), Text("0.3 km")],
          )
        ],
      ),
    );
  }
}

