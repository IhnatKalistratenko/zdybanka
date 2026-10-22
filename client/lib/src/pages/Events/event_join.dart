import 'package:flutter/material.dart';

class EventJoinPage extends StatefulWidget {
  const EventJoinPage({super.key});

  @override
  State<EventJoinPage> createState() => _EventJoinPageState();
}

class _EventJoinPageState extends State<EventJoinPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Event page"),),
        body: Text("Event join page"));
  }
}
