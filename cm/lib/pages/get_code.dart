import 'package:flutter/material.dart';

class GetCodePage extends StatefulWidget {
  const GetCodePage({super.key});

  @override
  State<GetCodePage> createState() => _GetCodePageState();
}

class _GetCodePageState extends State<GetCodePage> {
  final _codeController = TextEditingController();

  void _verifyCode() {
    if (_codeController.text.isNotEmpty) {
      // TODO: Add Firebase or verification logic
      Navigator.pushNamed(context, '/reg_password'); // go to set password page
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter the code!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify Email")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("Enter the verification code sent to your email"),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: "Code"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _verifyCode,
              child: const Text("Verify"),
            ),
          ],
        ),
      ),
    );
  }
}
