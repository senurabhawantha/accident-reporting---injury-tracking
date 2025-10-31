import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cm/pages/login_page.dart';
import 'package:cm/pages/register.dart';
import 'package:cm/pages/add_sample_data_page.dart';
import 'package:cm/pages/reg_vehicles.dart';

Future<void> main() async {
  // Ensure that Firebase is initialized before the app starts
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Claim Mate',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/add-sample-data': (context) => const AddSampleDataPage(),
        '/reg-vehicles': (context) => const RegVehicles(),
      },
    );
  }
}
