import 'package:flutter/material.dart';

import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository();

  final AuthRepository _repository;

  bool _isLoading = false;
  String? _errorMessage;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserModel? get currentUser => _currentUser;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final user = await _repository.login(email: email, password: password);
      if (user == null) {
        _setError('Invalid email or password.');
        return false;
      }
      _currentUser = user;
      notifyListeners();
      return true;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register({
    required String username,
    required String lastName,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    if (password != confirmPassword) {
      _setError('Passwords do not match.');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      await _repository.register(
        username: username,
        lastName: lastName,
        email: email,
        password: password,
      );
      return true;
    } on AuthException catch (error) {
      _setError(error.message);
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }
}