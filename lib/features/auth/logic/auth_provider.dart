import 'package:flutter/material.dart';

import '../data/repositories/auth_repository.dart';
import '../data/models/user_model.dart';
import 'package:nafass_application/core/utils/mailing_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthRepository? repository,
    MailingService? mailingService,
  })  : _repository = repository ?? AuthRepository(),
        _mailingService = mailingService ?? MailingService();

  final AuthRepository _repository;
  final MailingService _mailingService;

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
      final user = await _repository.register(
        username: username,
        lastName: lastName,
        email: email,
        password: password,
      );

      // On le considère comme connecté après inscription
      _currentUser = user;
      notifyListeners();

      // On envoie l'email de bienvenue via le backend Python
      try {
        await _mailingService.sendWelcomeEmail(
          email: user.email,
          firstName: user.username,
          lastName: user.lastName,
        );
      } catch (error) {
        debugPrint('Welcome email failed: $error');
      }

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

  Future<bool> deleteAccount() async {
    final userId = _currentUser?.id;

    if (userId == null) {
      _setError('Aucun utilisateur à supprimer.');
      return false;
    }

    _setLoading(true);
    _setError(null);

    try {
      final deleted = await _repository.deleteUser(userId);
      if (deleted) {
        _currentUser = null;
        notifyListeners();
      } else {
        _setError('Impossible de supprimer le compte utilisateur.');
      }
      return deleted;
    } finally {
      _setLoading(false);
    }
  }
}