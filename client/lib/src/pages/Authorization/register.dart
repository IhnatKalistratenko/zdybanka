import 'package:client/src/theme/app_typography.dart';
import 'package:client/src/models/register_request.dart';
import 'package:client/src/services/auth_service.dart';
import 'package:client/src/widgets/error_card.dart';
import 'package:client/src/widgets/api_status_banners.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'login.dart';

class RegisterPage extends StatelessWidget {
  static const String pageRoute = "/register";

  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: const SizedBox(
              width: double.infinity,
              child: RegisterForm(),
            ),
          ),
        ),
      ),
    );
  }
}

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  ErrorCardContent? registerError;
  bool _isSubmitting = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      registerError = null;
      _isSubmitting = true;
    });

    final request = RegisterRequest(
      username: usernameController.text,
      password: passwordController.text,
    );

    try {
      await AuthService().register(request);

      if (!mounted) return;

      context.go(LoginPage.pageRoute);
    } catch (e) {
      dismissGlobalApiErrorWhenHandled(e);
      if (!mounted) return;

      setState(() {
        registerError = ErrorCardContent(
          type: "Registration failed",
          message: apiErrorMessage(
            e,
            fallback: 'Could not create your account. Please try again later.',
          ),
        );
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
          const Center(
            child: Text("Register", style: AppTypography.headingLarge),
          ),
          const SizedBox(height: 30),
          const Text("Username:"),
          const SizedBox(height: 5),
          TextFormField(
            controller: usernameController,
            autocorrect: false,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Please enter your username";
              }
              return null;
            },
            decoration: const InputDecoration(hintText: "Enter your username"),
          ),
          const SizedBox(height: 30),
          const Text("Password:"),
          const SizedBox(height: 5),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your password";
              }
              return null;
            },
            decoration: const InputDecoration(hintText: "Enter your password"),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (registerError != null) ...[
                  ErrorCard(error: registerError!),
                  const SizedBox(height: 12),
                ],
                DegradedModeBuilder(
                  builder: (context, isDegraded) => ElevatedButton(
                    onPressed: _isSubmitting || isDegraded ? null : register,
                    style: ElevatedButton.styleFrom(
                      fixedSize: const Size(200, 50),
                      textStyle: AppTypography.button,
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Sign up"),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text("Or if you are already with us you may "),
                    TextButton(
                      onPressed: () {
                        context.go(LoginPage.pageRoute);
                      },
                      child: const Text("log in"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
