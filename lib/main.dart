import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/auth_wrapper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const AgriConnectApp());
}

class AgriConnectApp extends StatelessWidget {
  const AgriConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriConnect AI',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: const AuthWrapper(),
    );
  }
}
