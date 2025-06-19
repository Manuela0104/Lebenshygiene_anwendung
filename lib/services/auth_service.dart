import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Inscription
  Future<User?> signUp(String email, String password, String firstName) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'firstName': firstName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      notifyListeners();
      return userCredential.user;
    } catch (e) {
      print("Fehler bei der Registrierung: $e");
      return null;
    }
  }

  // Connexion
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return userCredential.user;
    } catch (e) {
      print("Fehler bei der Anmeldung: $e");
      return null;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // Mise à jour du prénom
  Future<void> updateFirstName(String firstName) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'firstName': firstName,
        });
        notifyListeners();
      }
    } catch (e) {
      print("Fehler bei der Aktualisierung des Vornamens: $e");
    }
  }
}