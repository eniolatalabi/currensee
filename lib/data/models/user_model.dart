import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  final String email;
  final String firstName;
  final String lastName;
  final String? photoURL;
  final DateTime? createdAt;

  AppUser({
    required this.uid,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.photoURL,
    this.createdAt,
  });

  /// 🔹 CopyWith helper
  AppUser copyWith({
    String? uid,
    String? email,
    String? firstName,
    String? lastName,
    String? photoURL,
    DateTime? createdAt,
  }) {
    return AppUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      photoURL: photoURL ?? this.photoURL,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 🔹 Guest check
  bool get isGuest => uid == 'guest';

  /// 🔹 Convert Firestore document → AppUser
  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      uid: data['uid'] ?? '',
      email: data['email'] ?? '',
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// 🔹 Convert AppUser → Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'photoURL': photoURL,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
    };
  }
}
