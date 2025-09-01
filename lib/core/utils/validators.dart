class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)\.]+$');
    if (!phoneRegex.hasMatch(value) || value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL is required';
    }
    final urlRegex = RegExp(r'^https?:\/\/.+\..+');
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL (must start with http:// or https://)';
    }
    return null;
  }

  static String? linkedinUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'LinkedIn URL is required';
    }
    final linkedinRegex = RegExp(r'^https?:\/\/(www\.)?linkedin\.com\/');
    if (!linkedinRegex.hasMatch(value)) {
      return 'Please enter a valid LinkedIn URL';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? skills(List<String>? skills) {
    if (skills == null || skills.isEmpty) {
      return 'Please add at least one skill';
    }
    return null;
  }

  static String? futureDate(DateTime? date) {
    if (date == null) {
      return 'Please select a date';
    }
    if (date.isBefore(DateTime.now())) {
      return 'Please select a future date';
    }
    return null;
  }
}
