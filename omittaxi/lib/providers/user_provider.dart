import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserProvider with ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoggedIn = false;
  String? _token;

  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token ?? _currentUser?.token;

  void login(UserModel user) {
    _currentUser = user;
    _token = user.token;
    _isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _token = null;
    _isLoggedIn = false;
    notifyListeners();
  }

  void updateUser(UserModel user) {
    _currentUser = user;
    notifyListeners();
  }

  bool get isDriver => _currentUser?.userType == 'driver';
  bool get isPassenger => _currentUser?.userType == 'passenger';
}
