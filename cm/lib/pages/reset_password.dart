import 'package:flutter/material.dart';

class ResetPasswordPage extends StatelessWidget {
  const ResetPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Reset Password")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Enter your email to receive a reset code"),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Trigger Firebase password reset
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Reset code sent")),
                );
              },
              child: const Text("Send Reset Code"),
            ),
          ],
        ),
      ),
    );
  }
}
