import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id; // doc id (ownerUid for new scheme; random for legacy)
  final String ownerUid;
  final String name;
  final String description;
  final String? logoUrl;
  final String? logoBase64; // Base64 logo stored in Firestore
  final String? linkedinUrl;
  final bool isApproved;
  final bool naitaRecognized;
  final DateTime createdAt;

  CompanyModel({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.description,
    this.logoUrl,
    this.logoBase64,
    this.linkedinUrl,
    this.isApproved = false,
    this.naitaRecognized = false,
    required this.createdAt,
  });

  factory CompanyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompanyModel(
      id: doc.id,
      ownerUid: data['ownerUid'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      logoUrl: data['logoUrl'],
      logoBase64: data['logoBase64'],
      linkedinUrl: (data['linkedinUrl'] ?? '').toString().trim().isEmpty
          ? null
          : data['linkedinUrl'],
      isApproved: data['isApproved'] ?? false,
      naitaRecognized: data['naitaRecognized'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'ownerUid': ownerUid,
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'logoBase64': logoBase64,
      'linkedinUrl': linkedinUrl,
      'isApproved': isApproved,
      'naitaRecognized': naitaRecognized,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  CompanyModel copyWith({
    String? id,
    String? ownerUid,
    String? name,
    String? description,
    String? logoUrl,
    String? logoBase64,
    String? linkedinUrl,
    bool? isApproved,
    bool? naitaRecognized,
    DateTime? createdAt,
  }) {
    return CompanyModel(
      id: id ?? this.id,
      ownerUid: ownerUid ?? this.ownerUid,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      logoBase64: logoBase64 ?? this.logoBase64,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      isApproved: isApproved ?? this.isApproved,
      naitaRecognized: naitaRecognized ?? this.naitaRecognized,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
