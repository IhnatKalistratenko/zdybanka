import 'package:client/src/pages/navbar_scaffold.dart';
import 'package:client/src/pages/Authorization/login.dart';
import 'package:client/src/pages/chats.dart';
import 'package:client/src/pages/events.dart';
import 'package:client/src/pages/map.dart';
import 'package:client/src/pages/Profile/profile.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';

import '../src/pages/Authorization/register.dart';
import '../src/pages/Events/event_create.dart';

final GlobalKey<NavigatorState> _rootNavigatiorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter router = GoRouter(navigatorKey: _rootNavigatiorKey,
    routes:
[
  ShellRoute(
    navigatorKey: _shellNavigatorKey,
    builder: (BuildContext context, GoRouterState state, Widget child)
    {
      return NavBarScaffold(child: child);
    },
    routes: [
      GoRoute(path: "/events", builder: (context, state) => EventsPage()),
      GoRoute(path: "/map", builder: (context, state) => MapPage()),
      GoRoute(path: "/add-event", builder: (context, state) => CreateEventPage()),
      GoRoute(path: "/chats", builder: (context, state) => ChatsPage()),
      GoRoute(path: "/profile", builder: (context, state) => ProfilePage()),
    ]
  ),
  GoRoute(path: LoginPage.pageRoute, builder: (context, state) => LoginPage()),
  GoRoute(path: RegisterPage.pageRoute, builder: (context, state) => RegisterPage()),
],
  initialLocation: "/profile"
);

