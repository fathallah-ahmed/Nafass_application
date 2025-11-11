class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.lastName,
    required this.email,
    required this.password,
  });

  final String id;
  final String username;
  final String lastName;
  final String email;
  final String password;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      username: json['username'] as String,
      lastName: json['lastname'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'lastname': lastName,
      'email': email,
      'password': password,
    };
  }
}