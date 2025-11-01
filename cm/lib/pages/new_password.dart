import 'package:flutter/material.dart';

class NewPasswordPage extends StatefulWidget {
  const NewPasswordPage({super.key});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // TODO: Replace with Firebase password update logic
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password successfully changed")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Set New Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "New Password"),
                obscureText: true,
                validator: (value) => value == null || value.length < 6
                    ? "Minimum 6 characters"
                    : null,
              ),
              TextFormField(
                controller: _confirmController,
                decoration:
                    const InputDecoration(labelText: "Confirm Password"),
                obscureText: true,
                validator: (value) => value != _passwordController.text
                    ? "Passwords don't match"
                    : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: _submit, child: const Text("Reset Password")),
            ],
          ),
        ),
      ),
    );
  }
}
