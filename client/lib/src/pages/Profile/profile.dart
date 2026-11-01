import 'package:client/src/config/storage_config.dart';
import 'package:client/src/pages/Authorization/login.dart';
import 'package:client/src/pages/Profile/edit_profile.dart';
import 'package:client/src/pages/events.dart';
import 'package:client/src/services/auth_service.dart';
import 'package:client/src/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/user.dart';
import '../../widgets/event_card.dart';

class ProfilePage extends StatefulWidget {
  static final String pageRoute = "/profile";
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  late Future<User> futureUser;

  @override
  void initState() {
    super.initState();

    futureUser = UserService().getUser();
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
                            ),
                            SizedBox(height: 10),
                            EventsList(title: "Joined events",
                              icon: Icon(Icons.people),),
                            SizedBox(height: 10),
                            EventsList(title: "Past events",
                              icon: Icon(Icons.update),),
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
  const EventsList({super.key, required this.title, required this.icon});

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
        EventCard(trailing: EventArrowTrailing(), event: mockEvents[0], onTap: () {  },),
        EventCard(trailing: EventArrowTrailing(), event: mockEvents[0], onTap: () {  },),
        EventCard(trailing: EventArrowTrailing(), event: mockEvents[0], onTap: () {  },),
        EventCard(trailing: EventArrowTrailing(), event: mockEvents[0], onTap: () {  },),
      ],
    );
  }
}
