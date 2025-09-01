import 'package:cloud_firestore/cloud_firestore.dart';

class InternshipModel {
  final String id;
  final String companyId;
  final String title;
  final String description;
  final String category;
  final List<String> skills;
  final String location;
  final String type;
  final String? stipend;
  final DateTime deadline;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isActive;

  // Additional fields for display
  final String? companyName;
  final String? companyLogoUrl;
  final bool? companyNaitaRecognized;

  InternshipModel({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    required this.category,
    this.skills = const [],
    required this.location,
    required this.type,
    this.stipend,
    required this.deadline,
    this.imageUrl,
    required this.createdAt,
    this.isActive = true,
    this.companyName,
    this.companyLogoUrl,
    this.companyNaitaRecognized,
  });

  factory InternshipModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InternshipModel(
      id: doc.id,
      companyId: data['companyId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? '',
      skills: List<String>.from(data['skills'] ?? []),
      location: data['location'] ?? '',
      type: data['type'] ?? '',
      stipend: data['stipend'],
      deadline: (data['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      imageUrl: data['imageUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      companyName: data['companyName'],
      companyLogoUrl: data['companyLogoUrl'],
      companyNaitaRecognized: data['companyNaitaRecognized'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'title': title,
      'description': description,
      'category': category,
      'skills': skills,
      'location': location,
      'type': type,
      'stipend': stipend,
      'deadline': Timestamp.fromDate(deadline),
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'companyName': companyName,
      'companyLogoUrl': companyLogoUrl,
      'companyNaitaRecognized': companyNaitaRecognized,
      // Add search keywords for better filtering
      'searchKeywords': _generateSearchKeywords(),
    };
  }

  List<String> _generateSearchKeywords() {
    final keywords = <String>[];

    // Add title words
    keywords.addAll(title.toLowerCase().split(' '));

    // Add company name words if available
    if (companyName != null) {
      keywords.addAll(companyName!.toLowerCase().split(' '));
    }

    // Add skills
    keywords.addAll(skills.map((s) => s.toLowerCase()));

    // Add category
    keywords.add(category.toLowerCase());

    // Add location
    keywords.addAll(location.toLowerCase().split(' '));

    return keywords.toSet().toList(); // Remove duplicates
  }

  InternshipModel copyWith({
    String? id,
    String? companyId,
    String? title,
    String? description,
    String? category,
    List<String>? skills,
    String? location,
    String? type,
    String? stipend,
    DateTime? deadline,
    String? imageUrl,
    DateTime? createdAt,
    bool? isActive,
    String? companyName,
    String? companyLogoUrl,
    bool? companyNaitaRecognized,
  }) {
    return InternshipModel(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      skills: skills ?? this.skills,
      location: location ?? this.location,
      type: type ?? this.type,
      stipend: stipend ?? this.stipend,
      deadline: deadline ?? this.deadline,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      companyName: companyName ?? this.companyName,
      companyLogoUrl: companyLogoUrl ?? this.companyLogoUrl,
      companyNaitaRecognized:
          companyNaitaRecognized ?? this.companyNaitaRecognized,
    );
  }

  bool get isExpired => deadline.isBefore(DateTime.now());

  String get timeLeft {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) return 'Expired';

    if (difference.inDays > 0) {
      return '${difference.inDays} days left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours left';
    } else {
      return '${difference.inMinutes} minutes left';
    }
  }

  @override
  String toString() {
    return 'InternshipModel(id: $id, title: $title, companyName: $companyName)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InternshipModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
