import 'package:client/src/pages/Authorization/login.dart';
import 'package:client/src/pages/chats.dart';
import 'package:client/src/pages/events.dart';
import 'package:client/src/pages/map.dart';
import 'package:client/src/pages/Profile/profile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavBarScaffold extends StatelessWidget {
  Widget child;
  NavBarScaffold({super.key, required this.child});

  void _onItemTapped(int index, BuildContext context)
  {
    switch(index){
      case 0:
        context.go("/events");
        break;
      case 1:
        context.go("/map");
        break;
      case 2:
        context.go("/add-event");
        break;
      case 3:
        context.go("/chats");
        break;
      case 4:
        context.go("/profile");
        break;
    }
  }

  int _calculateIndex(BuildContext context)
  {
    final String location = GoRouterState.of(context).uri.path;

    if(location.startsWith("/events")) return 0;
    if(location.startsWith("/map")) return 1;
    if(location.startsWith("/add-event")) return 2;
    if(location.startsWith("/chats")) return 3;
    if(location.startsWith("/profile")) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateIndex(context),
        onDestinationSelected: (int index) {
          _onItemTapped(index, context);
        },
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(icon: Icon(Icons.event), label: "Events"),
          NavigationDestination(icon: Icon(Icons.map), label: "Map"),
          NavigationDestination(icon: Icon(Icons.add), label: "New Event"),
          NavigationDestination(icon: Icon(Icons.chat_bubble), label: "Chats"),
          NavigationDestination(icon: Icon(Icons.person_2_outlined), selectedIcon: Icon(Icons.person_2), label: "Profile"),
        ],

      ),
      body: child
    );
  }
}
