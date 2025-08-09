import 'package:flutter/foundation.dart';
import 'package:smart_pad_app/models/user_model.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _loggedInUser;
  UserModel? get user => _loggedInUser;
  bool get isLoggedIn => _loggedInUser != null;

  void setUser(UserModel user) {
    _loggedInUser = user;
    notifyListeners();
  }

  void clearUser() {
    _loggedInUser = null;
    notifyListeners();
  }
}
