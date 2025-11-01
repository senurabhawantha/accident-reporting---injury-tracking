import 'package:flutter/material.dart';

class RestGetCodePage extends StatelessWidget {
  const RestGetCodePage({super.key});

  @override
  Widget build(BuildContext context) {
    final codeController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text("Enter Code")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Enter the code you received via email"),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(labelText: "Reset Code"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // TODO: Validate code and navigate to NewPasswordPage
                Navigator.pushNamed(context, "/new_password");
              },
              child: const Text("Verify Code"),
            ),
          ],
        ),
      ),
    );
  }
}
