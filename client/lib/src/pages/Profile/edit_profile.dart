import 'package:flutter/material.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit profile"), elevation: 0.7),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Edit profile",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
              ),
              Text("Manage your account settings", style: TextStyle()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 25),
                child: Divider(),
              ),
        
              UsernameForm(),
        
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 25),
                child: Divider(),
              ),
        
              PasswordForm(),
            ],
          ),
        ),
      ),
    );
  }
}

class UsernameForm extends StatefulWidget {
  const UsernameForm({super.key});

  @override
  State<UsernameForm> createState() => _UsernameFormState();
}

class _UsernameFormState extends State<UsernameForm> {
  final TextEditingController _usernameController = TextEditingController(
    text: "Username",
  );

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Username",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        SizedBox(height: 5),
        Text("Change the name displayed on your profile."),
        SizedBox(height: 5),
        Text("Username", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        TextField(
          decoration: InputDecoration(border: OutlineInputBorder()),
          controller: _usernameController,
        ),
        SizedBox(height: 10),
        ErrorCard(),
        ElevatedButton(
          onPressed: () {},
          style: ButtonStyle(
            padding: WidgetStateProperty.fromMap(
              <WidgetStatesConstraint, EdgeInsetsGeometry>{
                WidgetState.any: EdgeInsetsGeometry.symmetric(
                  vertical: 20,
                  horizontal: 30,
                ),
              },
            ),
          ),
          child: Text("Save"),
        ),
      ],
    );
  }
}

class PasswordForm extends StatefulWidget {
  const PasswordForm({super.key});

  @override
  State<PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  @override void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Password",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        SizedBox(height: 5),
        Text("Enter your current password and choose a new one."),
        SizedBox(height: 5),
        Text("Current password", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        TextField(
            decoration: InputDecoration(
                border: OutlineInputBorder()
            ),
          controller: _currentPasswordController,
        ),
        SizedBox(height: 5),
        Text("New password", style: TextStyle(fontWeight: FontWeight.bold)),
        SizedBox(height: 5),
        TextField(
          decoration: InputDecoration(
              border: OutlineInputBorder()
          ),
          controller: _newPasswordController,
        ),
        SizedBox(height: 10),
        SuccessCard(),
        ElevatedButton(
          onPressed: () {},
          style: ButtonStyle(
            padding: WidgetStateProperty.fromMap(
              <WidgetStatesConstraint, EdgeInsetsGeometry>{
                WidgetState.any: EdgeInsetsGeometry.symmetric(
                  vertical: 20,
                  horizontal: 30,
                ),
              },
            ),
          ),
          child: Text("Save"),
        ),
      ],
    );
  }
}

class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: Colors.red[400],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning),
                  Text("Validation error", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17,))
                ],
              ),
              Row(
                children: [
                  Text("Your username must contain at least 3 characters."),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class SuccessCard extends StatelessWidget {
  const SuccessCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        color: Colors.green[400],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info),
                  SizedBox(width: 5,),
                  Text("Success", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17,))
                ],
              ),
              Row(
                children: [
                  Text("Your password was successfully changed."),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

