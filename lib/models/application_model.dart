import 'package:cloud_firestore/cloud_firestore.dart';

class ApplicationModel {
  final String id;
  final String jobId;
  final String companyId;
  final String userId;
  final String resumeUrl;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields for display
  final String? jobTitle;
  final String? companyName;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final List<String>? userSkills;

  ApplicationModel({
    required this.id,
    required this.jobId,
    required this.companyId,
    required this.userId,
    required this.resumeUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.jobTitle,
    this.companyName,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.userSkills,
  });

  factory ApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ApplicationModel(
      id: doc.id,
      jobId: data['jobId'] ?? '',
      companyId: data['companyId'] ?? '',
      userId: data['userId'] ?? '',
      resumeUrl: data['resumeUrl'] ?? '',
      status: data['status'] ?? 'submitted',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      jobTitle: data['jobTitle'],
      companyName: data['companyName'],
      userName: data['userName'],
      userEmail: data['userEmail'],
      userPhone: data['userPhone'],
      userSkills: data['userSkills'] != null
          ? List<String>.from(data['userSkills'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'jobId': jobId,
      'companyId': companyId,
      'userId': userId,
      'resumeUrl': resumeUrl,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'jobTitle': jobTitle,
      'companyName': companyName,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'userSkills': userSkills,
    };
  }

  ApplicationModel copyWith({
    String? id,
    String? jobId,
    String? companyId,
    String? userId,
    String? resumeUrl,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? jobTitle,
    String? companyName,
    String? userName,
    String? userEmail,
    String? userPhone,
    List<String>? userSkills,
  }) {
    return ApplicationModel(
      id: id ?? this.id,
      jobId: jobId ?? this.jobId,
      companyId: companyId ?? this.companyId,
      userId: userId ?? this.userId,
      resumeUrl: resumeUrl ?? this.resumeUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      jobTitle: jobTitle ?? this.jobTitle,
      companyName: companyName ?? this.companyName,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      userSkills: userSkills ?? this.userSkills,
    );
  }

  String get statusDisplayName {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'viewed':
        return 'Viewed';
      case 'shortlisted':
        return 'Shortlisted';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unknown';
    }
  }

  @override
  String toString() {
    return 'ApplicationModel(id: $id, jobTitle: $jobTitle, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApplicationModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
