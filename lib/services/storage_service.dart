import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

/// Speicherservice für die Verwaltung von Dateien und Bildern
/// 
/// Bietet zentrale Funktionalitäten für:
/// - Profilbild-Auswahl aus der Galerie
/// - Profilbild-Aufnahme mit der Kamera
/// - Upload von Bildern zu Firebase Storage
/// - Löschen von Dateien aus dem Cloud Storage
/// - Automatische Bildoptimierung und -komprimierung
/// - Sichere Dateiverwaltung mit Benutzer-spezifischen Pfaden
/// 
/// Der Service behandelt alle datei- und speicherbezogenen
/// Operationen für die Anwendung.
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  // Profilbild aus der Galerie auswählen
  Future<File?> pickProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Fehler beim Auswählen des Bildes: $e');
      return null;
    }
  }

  // Profilbild mit der Kamera aufnehmen
  Future<File?> takeProfileImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Fehler beim Aufnehmen des Bildes: $e');
      return null;
    }
  }

  // Upload des Profilbildes
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;
      
      final String fileName = 'profile_${user.uid}.jpg';
      final Reference ref = _storage.ref().child('profile_images/$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      
      // Auf das Ende des Uploads warten
      final TaskSnapshot snapshot = await uploadTask;
      
      // Download-URL abrufen
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Bild erfolgreich hochgeladen: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('Fehler beim Hochladen des Bildes: $e');
      return null;
    }
  }

  // Profilbild löschen
  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Benutzer nicht angemeldet');
      }

      // Dateipfad aus der URL extrahieren
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      
      print('Bild erfolgreich gelöscht');
      return true;
      
    } catch (e) {
      print('Fehler beim Löschen des Bildes: $e');
      return false;
    }
  }

  // Überprüfen ob der Benutzer ein Profilbild hat
  Future<bool> hasProfileImage() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final result = await _storage
          .ref()
          .child('profile_images')
          .listAll();

      return result.items.any((item) => item.name.startsWith('${user.uid}_'));
    } catch (e) {
      print('Fehler beim Überprüfen des Profilbildes: $e');
      return false;
    }
  }
} 