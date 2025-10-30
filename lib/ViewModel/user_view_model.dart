import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/usermodel.dart';

class UserViewModel extends ChangeNotifier {
  final UserService _userService = UserService();

  UserModel? currentUser;
  bool isLoading = false;

  Future<void> fetchCurrentUser(String userId) async {
    isLoading = true;
    notifyListeners();

    currentUser = await _userService.getUserById(userId);

    isLoading = false;
    notifyListeners();
  }

  Future<void> updateUser(UserModel user) async {
    await _userService.updateUser(user);
    currentUser = user;
    notifyListeners();
  }
}
