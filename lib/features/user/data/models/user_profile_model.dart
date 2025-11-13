class UserProfileModel {
  final String id;
  final String firstName;
  final String lastName;
  final int age;
  final String gender;
  final String email;
  final String addictionType;
  final String? profileImage;
  final double? weight;

  UserProfileModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.gender,
    required this.email,
    required this.addictionType,
    this.profileImage,
    this.weight,
  });

  String get fullName => '$firstName $lastName';

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      age: (json['age'] ?? 0) is int ? json['age'] : int.parse('${json['age'] ?? 0}'),
      gender: json['gender'] ?? '',
      email: json['email'] ?? '',
      addictionType: json['addictionType'] ?? '',
      profileImage: json['profileImage'],
      weight: json['weight'] != null ? (json['weight'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'age': age,
      'gender': gender,
      'email': email,
      'addictionType': addictionType,
      'profileImage': profileImage,
      'weight': weight,
    };
  }

  UserProfileModel copyWith({
    String? id,
    String? firstName,
    String? lastName,
    int? age,
    String? gender,
    String? email,
    String? addictionType,
    String? profileImage,
    double? weight,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      addictionType: addictionType ?? this.addictionType,
      profileImage: profileImage ?? this.profileImage,
      weight: weight ?? this.weight,
    );
  }
}