import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  // Photo de profil sélectionnée depuis la galerie
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

  // Photo de profil prise avec la caméra
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

  // Upload de la photo de profil
  Future<String?> uploadProfileImage(File imageFile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Benutzer nicht angemeldet');
      }

      // Créer une référence unique pour l'image
      final storageRef = _storage
          .ref()
          .child('profile_images')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload du fichier
      final uploadTask = storageRef.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': user.uid,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      // Attendre la fin de l'upload
      final snapshot = await uploadTask;
      
      // Récupérer l'URL de téléchargement
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Bild erfolgreich hochgeladen: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('Fehler beim Hochladen des Bildes: $e');
      return null;
    }
  }

  // Supprimer une photo de profil
  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Benutzer nicht angemeldet');
      }

      // Extraire le chemin du fichier depuis l'URL
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      
      print('Bild erfolgreich gelöscht');
      return true;
      
    } catch (e) {
      print('Fehler beim Löschen des Bildes: $e');
      return false;
    }
  }

  // Vérifier si l'utilisateur a une photo de profil
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