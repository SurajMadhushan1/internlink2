class AppConstants {
  static const String appName = 'InternLink';
  static const String appVersion = '1.0.0';

  // Categories
  static const List<String> categories = [
    'All',
    'IT & Technology',
    'Design & Creative',
    'Marketing & Sales',
    'Finance & Banking',
    'Healthcare',
    'Engineering',
    'Business Development',
    'Human Resources',
    'Operations',
    'Research & Development',
  ];

  // Application Status
  static const String statusSubmitted = 'submitted';
  static const String statusViewed = 'viewed';
  static const String statusShortlisted = 'shortlisted';
  static const String statusRejected = 'rejected';

  // User Roles
  static const String roleUser = 'user';
  static const String roleCompany = 'company';
  static const String roleAdmin = 'admin';

  // File constraints
  static const int maxFileSize = 10 * 1024 * 1024; // 10MB
  static const List<String> allowedFileTypes = ['pdf'];
  static const List<String> allowedImageTypes = ['jpg', 'jpeg', 'png'];

  // Storage paths
  static String profilePath(String uid) => 'profiles/$uid/avatar.jpg';
  static String resumePath(String userId, String appId) =>
      'resumes/$userId/$appId.pdf';
  static String companyLogoPath(String companyId) =>
      'companies/$companyId/logo.jpg';
  static String internshipImagePath(String jobId) =>
      'internships/$jobId/image.jpg';
}
