import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> registerUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );

      final String uid = userCredential.user!.uid;

      await userCredential.user!.updateDisplayName(name.trim());

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': role,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Authentication error occurred';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Login failed';
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }

  Stream<User?> get authStateChanges {
    return _auth.authStateChanges();
  }
}
