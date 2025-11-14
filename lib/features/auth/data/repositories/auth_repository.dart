import 'package:uuid/uuid.dart';

import '../../../../core/storage/local_json_store.dart';
import '../models/user_model.dart';

class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => 'AuthException: $message';
}

class AuthRepository {
  AuthRepository({LocalJsonStore? store}) : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  final Uuid _uuid = const Uuid();

  static const String _userFile = 'user.json';

  Future<List<UserModel>> _readUsers() async {
    final data = await _store.readList(_userFile);
    return data.map(UserModel.fromJson).toList();
  }

  Future<void> _writeUsers(List<UserModel> users) async {
    await _store.writeList(
      _userFile,
      users.map((user) => user.toJson()).toList(),
    );
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final users = await _readUsers();
    try {
      return users.firstWhere(
            (user) =>
        user.email.toLowerCase() == email.toLowerCase() &&
            user.password == password,
      );
    } catch (_) {
      return null;
    }
  }

  Future<UserModel> register({
    required String username,
    required String lastName,
    required String email,
    required String password,
  }) async {
    final users = await _readUsers();
    final hasEmail = users.any(
          (user) => user.email.toLowerCase() == email.toLowerCase(),
    );

    if (hasEmail) {
      throw AuthException('Email is already registered.');
    }

    final user = UserModel(
      id: _uuid.v4(),
      username: username,
      lastName: lastName,
      email: email,
      password: password,
    );

    await _writeUsers(<UserModel>[...users, user]);
    return user;
  }
  Future<bool> deleteUser(String userId) async {
    final users = await _readUsers();
    final updatedUsers = users.where((user) => user.id != userId).toList();

    if (updatedUsers.length == users.length) {
      return false;
    }

    await _writeUsers(updatedUsers);
    return true;
  }
}