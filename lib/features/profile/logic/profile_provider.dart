import 'package:flutter/material.dart';
import '../../user/data/models/user_profile_model.dart';
import '../data/repositories/profile_repository.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({ProfileRepository? repository})
      : _repository = repository ?? ProfileRepository();

  final ProfileRepository _repository;
  bool _isLoading = false;
  String? _errorMessage;
  UserProfileModel? _currentProfile;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserProfileModel? get currentProfile => _currentProfile;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<bool> loadProfile(String userId) async {
    _setLoading(true);
    _setError(null);
    try {
      final profile = await _repository.getProfileByUserId(userId);
      if (profile == null) {
        // Ne pas définir d'erreur, juste définir le profil à null
        _currentProfile = null;
        notifyListeners();
        return false;
      }
      _currentProfile = profile;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur de chargement du profil: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required int age,
    required String gender,
    required String email,
    required String addictionType,
    String? profileImage,
    double? weight,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final profile = await _repository.createProfile(
        userId: userId,
        firstName: firstName,
        lastName: lastName,
        age: age,
        gender: gender,
        email: email,
        addictionType: addictionType,
        profileImage: profileImage,
        weight: weight,
      );
      _currentProfile = profile;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Erreur de création du profil: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProfile(UserProfileModel updatedProfile) async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _repository.updateProfile(updatedProfile);
      if (success) {
        _currentProfile = updatedProfile;
        notifyListeners();
      } else {
        _setError('Échec de la mise à jour du profil');
      }
      return success;
    } catch (e) {
      _setError('Erreur de mise à jour du profil: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProfile(String userId) async {
    _setLoading(true);
    _setError(null);
    try {
      final success = await _repository.deleteProfile(userId);
      if (success) {
        _currentProfile = null;
        notifyListeners();
      } else {
        _setError('Échec de la suppression du profil');
      }
      return success;
    } catch (e) {
      _setError('Erreur de suppression du profil: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void clearProfile() {
    _currentProfile = null;
    _errorMessage = null;
    notifyListeners();
  }
}