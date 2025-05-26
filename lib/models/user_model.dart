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