import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_constants.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _imagePicker = ImagePicker();

  // Upload profile image
  static Future<String> uploadProfileImage(String uid, XFile imageFile) async {
    try {
      final path = AppConstants.profilePath(uid);
      final ref = _storage.ref().child(path);

      final uploadTask = ref.putFile(File(imageFile.path));
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload profile image: ${e.toString()}';
    }
  }

  // Upload company logo
  static Future<String> uploadCompanyLogo(
      String companyId, XFile imageFile) async {
    try {
      final path = AppConstants.companyLogoPath(companyId);
      final ref = _storage.ref().child(path);

      final uploadTask = ref.putFile(File(imageFile.path));
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload company logo: ${e.toString()}';
    }
  }

  // Upload internship image
  static Future<String> uploadInternshipImage(
      String jobId, XFile imageFile) async {
    try {
      final path = AppConstants.internshipImagePath(jobId);
      final ref = _storage.ref().child(path);

      final uploadTask = ref.putFile(File(imageFile.path));
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload internship image: ${e.toString()}';
    }
  }

  // Upload resume
  static Future<String> uploadResume(
      String userId, String appId, PlatformFile resumeFile) async {
    try {
      final path = AppConstants.resumePath(userId, appId);
      final ref = _storage.ref().child(path);

      final uploadTask = ref.putFile(File(resumeFile.path!));
      final snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw 'Failed to upload resume: ${e.toString()}';
    }
  }

  // Pick image from gallery or camera
  static Future<XFile?> pickImage(
      {ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Validate file size
        final file = File(image.path);
        final fileSize = await file.length();

        if (fileSize > AppConstants.maxFileSize) {
          throw 'Image size must be less than ${AppConstants.maxFileSize ~/ (1024 * 1024)}MB';
        }

        // Validate file type
        final extension = image.path.split('.').last.toLowerCase();
        if (!AppConstants.allowedImageTypes.contains(extension)) {
          throw 'Only ${AppConstants.allowedImageTypes.join(', ')} files are allowed';
        }
      }

      return image;
    } catch (e) {
      throw 'Failed to pick image: ${e.toString()}';
    }
  }

  // Pick PDF file
  static Future<PlatformFile?> pickPdfFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: AppConstants.allowedFileTypes,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;

        // Validate file size
        if (file.size > AppConstants.maxFileSize) {
          throw 'File size must be less than ${AppConstants.maxFileSize ~/ (1024 * 1024)}MB';
        }

        // Validate file type
        final extension = file.extension?.toLowerCase();
        if (!AppConstants.allowedFileTypes.contains(extension)) {
          throw 'Only ${AppConstants.allowedFileTypes.join(', ')} files are allowed';
        }

        return file;
      }

      return null;
    } catch (e) {
      throw 'Failed to pick PDF file: ${e.toString()}';
    }
  }

  // Delete file from storage
  static Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      throw 'Failed to delete file: ${e.toString()}';
    }
  }

  // Get upload progress stream
  static Stream<double> getUploadProgress(UploadTask uploadTask) {
    return uploadTask.snapshotEvents.map((snapshot) {
      return snapshot.bytesTransferred / snapshot.totalBytes;
    });
  }

  // Validate file
  static bool validateFile(
      String filePath, List<String> allowedExtensions, int maxSize) {
    final file = File(filePath);

    // Check file size
    final fileSize = file.lengthSync();
    if (fileSize > maxSize) {
      return false;
    }

    // Check file extension
    final extension = filePath.split('.').last.toLowerCase();
    return allowedExtensions.contains(extension);
  }

  // Get file size in human readable format
  static String getFileSizeString(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
