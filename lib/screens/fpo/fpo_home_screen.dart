import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class FpoHomeScreen extends StatelessWidget {
  const FpoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FPO Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              AuthService().logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome FPO 🌾',
          style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
