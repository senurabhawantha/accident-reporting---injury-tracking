import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cm/components/button.dart';
import 'package:cm/components/textfeild.dart';
import 'package:cm/pages/contact_us.dart';
import 'package:cm/pages/dashboard.dart';
import 'package:cm/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAutoLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoLogin() async {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Reload user data to ensure fresh user details
        await user.reload();
        // Get fresh user reference after reload
        final freshUser = FirebaseAuth.instance.currentUser;
        if (freshUser != null) {
          // Defer navigation to avoid locking Navigator during page load
          Future.microtask(() {
            if (!mounted) return;
            _navigateToDashboard(freshUser);
          });
        }
      } catch (e) {
        print('Auto-login check failed: $e');
      }
    }
  }

  void _navigateToDashboard(User user) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DashboardScreen(
          token: user.uid,
          nic: user.email ?? "",
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      // Add a small delay to ensure Firebase completes user setup
      await Future.delayed(const Duration(milliseconds: 200));

      final user = credential.user;
      if (user != null) {
        try {
          // Reload user to ensure fresh data
          await user.reload();
          
          // Add another small delay after reload
          await Future.delayed(const Duration(milliseconds: 100));
          
          // Get fresh user reference
          final freshUser = FirebaseAuth.instance.currentUser;
          if (freshUser != null) {
            // Save to SharedPreferences
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('uid', freshUser.uid);
            await prefs.setString('email', freshUser.email ?? "");

            _navigateToDashboard(freshUser);
          }
        } catch (e) {
          print('User reload error: $e');
          // Even if reload fails, try to navigate with the credential user
          _navigateToDashboard(user);
        }
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = "No user found with this email.";
          break;
        case 'wrong-password':
          message = "Incorrect password.";
          break;
        case 'invalid-email':
          message = "Invalid email format.";
          break;
        case 'too-many-requests':
          message = "Too many attempts. Please try again later.";
          break;
        default:
          message = "Login failed. Please check your credentials.";
      }
      _showDialog("Login Failed", message);
    } catch (e) {
      _showDialog("Error", "An unexpected error occurred: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDialog(String title, String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK")),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Logo
            Image.asset(
              'lib/images/careulogo.png',
              height: 100,
            ),

            const SizedBox(height: 30),

            // Welcome Text
            const Text(
              "Welcome to Claim Mate",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Simplifying your insurance claims',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 40),

            // Login Form
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 0,
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 30),

                          // Email field
                          MYTextField(
                            controller: _emailController,
                            hintText: "Enter your email",
                            labelText: "Email",
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          // Password field
                          MYTextField(
                            controller: _passwordController,
                            hintText: "Enter your password",
                            labelText: "Password",
                            obscureText: true,
                            prefixIcon: Icons.lock_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 30),

                          // Sign in button
                          MYButton(
                            text: "Sign In",
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                            width: double.infinity,
                          ),

                          const SizedBox(height: 20),

                          // Sign Up
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(color: Colors.grey),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Use Future.microtask to defer navigation until after
                                  // the current call stack and any pending navigations complete
                                  Future.microtask(() {
                                    if (!mounted) return;
                                    Navigator.of(context).pushNamed('/register');
                                  });
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Contact Us
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Having trouble? ",
                                style: TextStyle(color: Colors.grey),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const ContactUs(),
                                    ),
                                  );
                                },
                                child: Text(
                                  "Contact Us",
                                  style: TextStyle(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
