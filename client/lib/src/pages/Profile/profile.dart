import 'package:client/src/pages/Profile/edit_profile.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(30, 50, 0, 0),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Profile",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  letterSpacing: 1.5
                ),),
                SizedBox(height: 10,),
                TextButton.icon(onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => EditProfile())
                  );
                }, icon: Icon(Icons.edit), label: Text("Edit profile"),)
              ],
            ),
          ),
          SizedBox(height: 30,),
          Divider(
            thickness: 0.5,
          ),
          OutlinedButton(onPressed: () {},
              child: Text("My events")),
          OutlinedButton(onPressed: () {},
              child: Text("Joined events")),
          OutlinedButton(onPressed: () {},
              child: Text("Visited events")),
          OutlinedButton(onPressed: () {},
              child: Text("Exit profile")),
        ],
      ),
    );
  }
}
