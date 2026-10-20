import "package:flutter/material.dart";

class EventCard extends StatelessWidget {
  final Widget trailing;
  const EventCard({super.key, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {},
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Event name", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 7),
              RichText(
                text: TextSpan(
                  children: [
                    WidgetSpan(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                        child: Icon(Icons.calendar_month, size: 19),
                      ),
                    ),
                    TextSpan(text: "29.10.2026"),
                  ],
                ),
              ),
              SizedBox(height: 7),
              RichText(
                text: TextSpan(
                  children: [
                    WidgetSpan(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
                        child: Icon(Icons.location_on, size: 19),
                      ),
                    ),
                    TextSpan(text: "вул. Лесі Українки 15, м. Луцьк"),
                  ],
                ),
              ),
              SizedBox(height: 7),
            ],
          ),
          trailing
        ],
      ),
    );
  }
}

class EventArrowTrailing extends StatelessWidget {
  const EventArrowTrailing({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Icon(Icons.keyboard_arrow_right, size: 35,)],
    );
  }
}

class EventDistanceTrailing extends StatelessWidget {
  const EventDistanceTrailing({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Icon(Icons.local_activity), Text("0.3 km")],
    );
  }
}
