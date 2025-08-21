import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Authentifizierungsservice für die Verwaltung von Benutzeranmeldungen
/// 
/// Bietet zentrale Funktionalitäten für:
/// - Benutzerregistrierung mit E-Mail und Passwort
/// - Benutzeranmeldung und -abmeldung
/// - Passwort-Reset-Funktionalität
/// - Integration mit Firebase Auth und Firestore
/// - Automatische Benutzerprofil-Erstellung bei Registrierung
/// - Change Notifier für State Management
/// 
/// Der Service dient als zentrale Schnittstelle für alle
/// authentifizierungsbezogenen Operationen in der App.
class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  // Registrierung
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
        'profileImageUrl': null,
      });
      
      notifyListeners();
      return userCredential.user;
    } catch (e) {
      print("Fehler bei der Registrierung: $e");
      return null;
    }
  }

  // Anmeldung
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

  // Abmeldung
  Future<void> signOut() async {
    await _auth.signOut();
    notifyListeners();
  }

  // Aktualisierung des Vornamens
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

  // Aktualisierung der Profilbild-URL
  Future<void> updateProfileImageUrl(String imageUrl) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'profileImageUrl': imageUrl,
        });
        notifyListeners();
      }
    } catch (e) {
      print("Fehler bei der Aktualisierung der Profilbild-URL: $e");
    }
  }

  // Profilbild-URL abrufen
  Future<String?> getProfileImageUrl() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        return doc.data()?['profileImageUrl'];
      }
      return null;
    } catch (e) {
      print("Fehler beim Abrufen der Profilbild-URL: $e");
      return null;
    }
  }

  // Passwort zurücksetzen
  Future<String?> resetPassword(String email) async {
    try {
      print('🔄 Starte Passwort-Reset für: $email');
      print('📧 Firebase Auth Status: ${_auth.currentUser?.uid ?? "Kein Benutzer angemeldet"}');
      
      await _auth.sendPasswordResetEmail(email: email);
      print('✅ Passwort-Reset E-Mail erfolgreich gesendet an: $email');
      return 'success';
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase Auth Fehler: ${e.code} - ${e.message}');
      switch (e.code) {
        case 'user-not-found':
          return 'Kein Benutzer mit dieser E-Mail-Adresse gefunden.';
        case 'invalid-email':
          return 'Ungültige E-Mail-Adresse.';
        case 'too-many-requests':
          return 'Zu viele Anfragen. Versuchen Sie es später erneut.';
        default:
          return 'Ein Fehler ist aufgetreten: ${e.message}';
      }
    } catch (e) {
      print('❌ Unerwarteter Fehler: $e');
      return 'Ein unerwarteter Fehler ist aufgetreten.';
    }
  }
}