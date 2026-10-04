import 'package:client/src/pages/Authorization/login.dart';
import 'package:client/src/pages/chats.dart';
import 'package:client/src/pages/events.dart';
import 'package:client/src/pages/map.dart';
import 'package:client/src/pages/profile.dart';
import 'package:flutter/material.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  int currentPageIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            currentPageIndex = index;
          });
        },
        selectedIndex: currentPageIndex,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: [
          NavigationDestination(icon: Icon(Icons.event), label: "Events"),
          NavigationDestination(icon: Icon(Icons.map), label: "Map"),
          NavigationDestination(icon: Icon(Icons.add), label: "New Event"),
          NavigationDestination(icon: Icon(Icons.chat_bubble), label: "Chats"),
          NavigationDestination(icon: Icon(Icons.person_2_outlined), selectedIcon: Icon(Icons.person_2), label: "Profile"),
        ],

      ),
      body: <Widget> [
        EventsPage(),
        MapPage(),
        EventsPage(),
        ChatsPage(),
        ProfilePage()
      ][currentPageIndex],
    );
  }
}
