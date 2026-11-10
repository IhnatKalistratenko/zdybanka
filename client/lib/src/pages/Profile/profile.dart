import 'package:client/src/pages/Authorization/login.dart';
import 'package:client/src/pages/Profile/edit_profile.dart';
import 'package:client/src/services/auth_service.dart';
import 'package:client/src/services/event_service.dart';
import 'package:client/src/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/event.dart';
import '../../models/user.dart';
import '../../widgets/event_card.dart';
import '../../widgets/event_details_widget.dart';

class ProfilePage extends StatefulWidget {
  static final String pageRoute = "/profile";
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  late Future<User> futureUser;
  late Future<List<Event>> futureEvents;

  @override
  void initState() {
    super.initState();

    futureUser = UserService().getUser();
    futureEvents = EventService().getMyEvents();
  }

  void _reloadEvents() {
    if (!mounted) return;
    setState(() {
      futureEvents = EventService().getMyEvents();
    });
  }

  Future<void> onExitClick() async {
    await AuthService().logout();
    if(!mounted) return;
    GoRouter.of(context).go(LoginPage.pageRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: FutureBuilder(
            future: futureUser,
            builder: (context, snapshot) {
              if(snapshot.hasError) {
                return Text("${snapshot.error}");
              }
              else if(snapshot.hasData) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.fromLTRB(30, 50, 30, 0),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                snapshot.data!.username,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              OutlinedButton.icon(
                                label: Text("Exit"),
                                onPressed: onExitClick,
                                style: ButtonStyle(
                                  shape: WidgetStatePropertyAll(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadiusGeometry.circular(8.0),
                                    ),
                                  ),
                                  side: WidgetStatePropertyAll(
                                    BorderSide(color: Colors.red[400]!),
                                  ),
                                  foregroundColor: WidgetStatePropertyAll(
                                    Colors.red[400],
                                  ),
                                ),
                                icon: Icon(Icons.exit_to_app, color: Colors.red[400]),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (context) => EditProfile()),
                              );
                            },
                            icon: Icon(Icons.edit),
                            label: Text("Edit profile"),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 30),
                    Divider(thickness: 0.5),
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
                        child: Column(
                          children: [
                            EventsList(
                              title: "My events",
                              icon: Icon(Icons.calendar_month),
                              eventsFuture: futureEvents,
                              selectEvents: (events) => events
                                  .where((event) => event.userStatus.toLowerCase() == 'created')
                                  .toList(),
                              detailsWidgetBuilder: (id) => OwnedEventDetailsWidget(
                                eventId: id,
                                onDeleteCallback: _reloadEvents,
                              ),
                            ),
                            SizedBox(height: 10),
                            EventsList(title: "Joined events",
                              icon: Icon(Icons.people),
                              eventsFuture: futureEvents,
                              selectEvents: (events) => events
                                  .where((event) => event.userStatus.toLowerCase() == 'joined')
                                  .toList(),
                              detailsWidgetBuilder: (id) => JoinedEventDetailsWidget(
                                eventId: id,
                                onLeaveCallback: _reloadEvents,
                              ),),
                            SizedBox(height: 10),
                            EventsList(title: "Past events",
                              icon: Icon(Icons.update),
                              eventsFuture: futureEvents,
                              selectEvents: (events) => events
                                  .where((event) => event.userStatus.toLowerCase() == 'past')
                                  .toList(),
                              detailsWidgetBuilder: (id) => JoinedEventDetailsWidget(
                                eventId: id,
                                onLeaveCallback: _reloadEvents,
                              ),),
                          ],
                        )
                    ),
                  ],
                );


              }

              return const CircularProgressIndicator();
            },
          ),
        ),
      ),
    );
  }
}

class EventsList extends StatefulWidget {
  final String title;
  final Icon icon;
  final Future<List<Event>> eventsFuture;
  final List<Event> Function(List<Event>) selectEvents;
  final Widget Function(String) detailsWidgetBuilder;
  const EventsList({super.key, required this.title, required this.icon, required this.eventsFuture, required this.selectEvents, required this.detailsWidgetBuilder});

  @override
  State<EventsList> createState() => _EventsListState();
}

class _EventsListState extends State<EventsList> {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      collapsedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      collapsedBackgroundColor: Colors.white,
      backgroundColor: Colors.white,
      title: RichText(
        text: TextSpan(
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.3),
          children: [
            WidgetSpan(child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 10, 0),
              child: widget.icon,
            )),
            TextSpan(
                text: widget.title
            )
          ],
        ),
      ),
      children: [
        FutureBuilder<List<Event>>(
          future: widget.eventsFuture,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Could not load events: ${snapshot.error}'),
              );
            }
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              );
            }
            final events = widget.selectEvents(snapshot.data!);
            if (events.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No events found.'),
              );
            }
            return Column(
              children: events.map<Widget>((event) => EventCard(
                trailing: const EventArrowTrailing(),
                event: event,
                onTap: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  showDragHandle: true,
                  builder: (_) => widget.detailsWidgetBuilder(event.id),
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
}
