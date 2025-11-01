import 'package:cm/components/button.dart';
import 'package:flutter/material.dart';

class Submited extends StatelessWidget {
  const Submited({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("lib/images/bblgo.png"),
              opacity: 0.1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 240),
                    Image.asset(
                      "lib/images/done.png",
                      height: 200,
                    ),
                    const Text(
                      "Submitted Successfully!",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 200),
                    SizedBox(
                      height: 50.0,
                      width: double.infinity,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 95),
                          child: MYButton(
                            text: 'Done',
                            onPressed: () {},
                          )),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
