import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String role;
  final String name;
  final String email;
  final String? phone;
  final List<String> skills;
  final String? photoUrl;
  final String? resumeUrl;
  final DateTime createdAt;

  // NEW: store avatar as Base64 string (no Storage)
  final String? photoBase64;

  UserModel({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
    this.phone,
    this.skills = const [],
    this.photoUrl,
    this.resumeUrl,
    required this.createdAt,
    this.photoBase64, // NEW
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      role: data['role'] ?? 'user',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      skills: List<String>.from(data['skills'] ?? []),
      photoUrl: data['photoUrl'],
      resumeUrl: data['resumeUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoBase64: data['photoBase64'] as String?, // NEW
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'role': role,
      'name': name,
      'email': email,
      'phone': phone,
      'skills': skills,
      'photoUrl': photoUrl,
      'resumeUrl': resumeUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      if (photoBase64 != null) 'photoBase64': photoBase64, // NEW
    };
  }

  UserModel copyWith({
    String? uid,
    String? role,
    String? name,
    String? email,
    String? phone,
    List<String>? skills,
    String? photoUrl,
    String? resumeUrl,
    DateTime? createdAt,
    String? photoBase64, // NEW
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      skills: skills ?? this.skills,
      photoUrl: photoUrl ?? this.photoUrl,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      createdAt: createdAt ?? this.createdAt,
      photoBase64: photoBase64 ?? this.photoBase64, // NEW
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, role: $role, name: $name, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
