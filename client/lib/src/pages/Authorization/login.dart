import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 480,
            ),
            child: SizedBox(
              width: double.infinity,
              child: LoginForm(),
            ),
          )
        ),
      );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose()
  {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: const Text("Good to see you again",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 40
            ),),
          ),
          const SizedBox(height: 30,),
          const Text("Username:"),
          const SizedBox(height: 5,),
          TextFormField(
            controller: usernameController,
            validator: (value) {
              if(value == null || value.isEmpty)
                {
                  return "Please enter your username";
                }
              return null;
            },
            decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter your username"
            ),
          ),
          const SizedBox(height: 30,),
          const Text("Password:"),
          const SizedBox(height: 5,),
          TextFormField(
            controller: passwordController,
            validator: (value) {
              if(value == null || value.isEmpty)
              {
                return "Please enter your password";
              }
              return null;
            },
            decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Enter your password"
            ),
          ),
          const SizedBox(height: 20,),
          ElevatedButton(
            onPressed: () {
              if(!_formKey.currentState!.validate())
              {
                return;
              }
              // ToDo: Sending data to server

            },
            style: ButtonStyle(
              fixedSize: WidgetStateProperty<Size>.fromMap(<WidgetStatesConstraint, Size> {
                WidgetState.any: Size(100, 50)
              }),
              textStyle: WidgetStateProperty.fromMap(<WidgetStatesConstraint, TextStyle> {
                WidgetState.any: TextStyle(
                    fontWeight: FontWeight.bold
                )
              })
            ),
            child: Text("Sign in"))
        ],
      ),
    );
  }
}

