import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id;
  final String ownerUid;
  final String name;
  final String description;
  final String? logoUrl;
  final String? linkedinUrl; // nullable now
  final bool isApproved;
  final bool naitaRecognized;
  final DateTime createdAt;

  CompanyModel({
    required this.id,
    required this.ownerUid,
    required this.name,
    required this.description,
    this.logoUrl,
    this.linkedinUrl,
    this.isApproved = false,
    this.naitaRecognized = false,
    required this.createdAt,
  });

  factory CompanyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawLinkedIn = (data['linkedinUrl'] ?? '').toString().trim();
    return CompanyModel(
      id: doc.id,
      ownerUid: data['ownerUid'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      logoUrl: data['logoUrl'],
      linkedinUrl:
          rawLinkedIn.isEmpty ? null : rawLinkedIn, // normalize empty->null
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
      'linkedinUrl':
          (linkedinUrl?.trim().isEmpty ?? true) ? null : linkedinUrl!.trim(),
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
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      isApproved: isApproved ?? this.isApproved,
      naitaRecognized: naitaRecognized ?? this.naitaRecognized,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'CompanyModel(id: $id, name: $name, isApproved: $isApproved)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompanyModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
