import 'package:client/src/models/login_request.dart';
import 'package:client/src/pages/Authorization/register.dart';
import 'package:client/src/pages/events.dart';
import 'package:client/src/services/auth_service.dart';
import 'package:client/src/widgets/error_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatelessWidget {
  static final String pageRoute = "/login";

  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 480),
            child: SizedBox(width: double.infinity, child: LoginForm()),
          ),
        ),
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

  ErrorCardContent? authError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login() async
  {
    if(!_formKey.currentState!.validate())
      {
        return;
      }

    setState(() {
      authError = null;
      _isSubmitting = true;
    });

    LoginRequest request = LoginRequest(username: usernameController.text, password: passwordController.text);

    try {
      await AuthService().login(request);

      if (!mounted) return;

      GoRouter.of(context).go(EventsPage.pageRoute);
    } catch(e) {
      if (!mounted) return;
      setState(() {
        authError = ErrorCardContent(type: "Authorization failed", message: e is AuthServiceException ? e.message : "Failed to perform login. Please try again.");
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
            child: const Text(
              "Good to see you again",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 40),
            ),
          ),
          const SizedBox(height: 30),
          const Text("Username:"),
          const SizedBox(height: 5),
          TextFormField(
            controller: usernameController,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your username";
              }
              return null;
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Enter your username",
            ),
          ),
          const SizedBox(height: 30),
          const Text("Password:"),
          const SizedBox(height: 5),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your password";
              }
              return null;
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: "Enter your password",
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if(authError != null) ErrorCard(error: authError!),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : login,
                  style: ElevatedButton.styleFrom(
                    fixedSize: const Size(200, 50),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  child: _isSubmitting ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ) :
                  const Text("Sign in"),
                ),

                const SizedBox(height: 16),

                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style,
                    children: [
                      const TextSpan(
                        text: "Or if you're not with us yet, you can ",
                      ),
                      TextSpan(
                        text: "register",
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            context.go(RegisterPage.pageRoute);
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
