import 'dart:async';
import 'package:client/src/services/user_service.dart';
import 'package:client/src/widgets/error_card.dart';
import 'package:flutter/material.dart';
import '../../models/user.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late Future<User> futureUser;

  @override
  void initState() {
    super.initState();
    futureUser = UserService().getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit profile"), elevation: 0.7),
      body: FutureBuilder<User>(
        future: futureUser,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Failed to load user: ${snapshot.error}"));
          }

          final user = snapshot.data;
          if (user == null) {
            return const Center(child: Text("User information is unavailable."));
          }

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Edit profile",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                  ),
                  const Text("Manage your account settings"),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 25),
                    child: Divider(),
                  ),
                  UsernameForm(user: user),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0, vertical: 25),
                    child: Divider(),
                  ),
                  PasswordForm(userId: user.id),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class UsernameForm extends StatefulWidget {
  final User user;

  const UsernameForm({super.key, required this.user});

  @override
  State<UsernameForm> createState() => _UsernameFormState();
}

class _UsernameFormState extends State<UsernameForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _usernameController;
  late String _originalUsername;
  ErrorCardContent? _errorMessage;
  bool _showSuccess = false;
  bool _isSaving = false;
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _originalUsername = widget.user.username;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  Future<void> sendUsername() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _showSuccess = false;
    });
    _successTimer?.cancel();

    try {
      final updatedUser = await UserService().updateUsername(
        userId: widget.user.id,
        username: _usernameController.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _originalUsername = updatedUser.username;
        _showSuccess = true;
      });
      _successTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _showSuccess = false);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorCardContent(
          type: "Username update failed",
          message: error is UserServiceException
              ? error.message
              : "Failed to update username. Please try again.",
        );
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                decoration: const InputDecoration(border: OutlineInputBorder()),
                controller: _usernameController,
                onChanged: (_) => setState(() {
                  _errorMessage = null;
                  _showSuccess = false;
                }),
                validator: (value) {
                  final username = value?.trim() ?? "";
                  if (username.isEmpty) return "Username must not be empty.";
                  if (username == _originalUsername) {
                    return "Enter a username different from your current one.";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_errorMessage != null) ErrorCard(error: _errorMessage!),
        if (_showSuccess)
          const SuccessCard(message: "Your username was successfully updated."),
        ElevatedButton(
          onPressed: _isSaving ||
                  _usernameController.text.trim() == _originalUsername ||
                  _usernameController.text.trim().isEmpty
              ? null
              : sendUsername,
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
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Save"),
        ),
      ],
    );
  }
}

class PasswordForm extends StatefulWidget {
  final String userId;

  const PasswordForm({super.key, required this.userId});

  @override
  State<PasswordForm> createState() => _PasswordFormState();
}

class _PasswordFormState extends State<PasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  ErrorCardContent? _errorMessage;
  bool _showSuccess = false;
  bool _isSaving = false;
  Timer? _successTimer;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  Future<void> sendPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _showSuccess = false;
    });
    _successTimer?.cancel();

    try {
      await UserService().updatePassword(
        userId: widget.userId,
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      setState(() => _showSuccess = true);
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _successTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) setState(() => _showSuccess = false);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = ErrorCardContent(
          type: "Password update failed",
          message: error is UserServiceException
              ? error.message
              : "Failed to update password. Please try again.",
        );
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _handlePasswordChanged() {
    setState(() {
      _errorMessage = null;
      _showSuccess = false;
    });
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
        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Current password",
                  border: OutlineInputBorder(),
                ),
                controller: _currentPasswordController,
                obscureText: true,
                onChanged: (_) => _handlePasswordChanged(),
                validator: (value) => value == null || value.isEmpty
                    ? "Enter your current password."
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "New password",
                  border: OutlineInputBorder(),
                ),
                controller: _newPasswordController,
                obscureText: true,
                onChanged: (_) => _handlePasswordChanged(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Enter a new password.";
                  }
                  if (value == _currentPasswordController.text) {
                    return "New password must differ from current password.";
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_errorMessage != null) ErrorCard(error: _errorMessage!),
        if (_showSuccess)
          const SuccessCard(message: "Your password was successfully changed."),
        ElevatedButton(
          onPressed: _isSaving ||
                  _newPasswordController.text.isEmpty ||
                  _newPasswordController.text == _currentPasswordController.text
              ? null
              : sendPassword,
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
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text("Save"),
        ),
      ],
    );
  }
}



class SuccessCard extends StatelessWidget {
  final String message;

  const SuccessCard({super.key, required this.message});

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
                  Text(message),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

