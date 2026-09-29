import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth/login_screen.dart';
import 'farmer/farmer_home_screen.dart';
import 'buyer/buyer_home_screen.dart';
import 'fpo/fpo_home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // Firebase is checking login status
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is NOT logged in
        if (authSnapshot.data == null) {
          return const LoginScreen();
        }

        // User IS logged in
        final User user = authSnapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // Firestore error
            if (userSnapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Firestore Error:\n${userSnapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }

            // User document doesn't exist
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return Scaffold(
                appBar: AppBar(title: const Text('AgriConnect AI')),
                body: const Center(
                  child: Text(
                    'User profile not found in Firestore.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              );
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>;

            final String role =
                data['role']?.toString().toLowerCase() ?? 'farmer';

            // Open dashboard according to role
            if (role == 'buyer') {
              return const BuyerHomeScreen();
            }

            if (role == 'fpo') {
              return const FpoHomeScreen();
            }

            return const FarmerHomeScreen();
          },
        );
      },
    );
  }
}
