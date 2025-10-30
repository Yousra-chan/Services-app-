import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file to Firebase Storage
  /// [path] example: "users/profilePics/userId.jpg"
  Future<String> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = ref.putFile(file);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('File upload failed: $e');
    }
  }

  /// Delete a file from Firebase Storage
  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      throw Exception('File deletion failed: $e');
    }
  }

  /// Upload a chat image and get URL
  Future<String> uploadChatImage(
    File file,
    String chatId,
    String messageId,
  ) async {
    final path = "chats/$chatId/$messageId.jpg";
    return await uploadFile(file, path);
  }

  /// Upload provider/service profile image
  Future<String> uploadProfileImage(File file, String userId) async {
    final path = "users/profilePics/$userId.jpg";
    return await uploadFile(file, path);
  }

  /// Upload service image
  Future<String> uploadServiceImage(File file, String serviceId) async {
    final path = "services/$serviceId.jpg";
    return await uploadFile(file, path);
  }
}
