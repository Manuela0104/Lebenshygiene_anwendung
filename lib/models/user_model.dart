/// Benutzer-Datenmodell für die Repräsentation von App-Benutzern
/// 
/// Definiert die grundlegende Struktur für:
/// - Eindeutige Benutzer-Identifikation (UID)
/// - Benutzer-E-Mail-Adresse
/// - Benutzer-Name
/// - Erstellungsdatum des Kontos
/// - Firestore-Integration für Datenserialisierung
/// 
/// Das Modell dient als zentrale Datenstruktur für
/// Benutzerinformationen in der gesamten Anwendung.
class AppUser {
  final String uid;
  final String? email;
  final String? name;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    this.email,
    this.name,
    this.createdAt,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return AppUser(
      uid: doc.id,
      email: data['email'],
      name: data['name'],
      createdAt: data['createdAt']?.toDate(),
    );
  }
}