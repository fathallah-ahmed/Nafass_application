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
  final String? medicalCondition;
  final String? doctorName;
  final String? therapyGoals;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

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
    this.medicalCondition,
    this.doctorName,
    this.therapyGoals,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  String get fullName => '$firstName $lastName';

  static String _stringForKeys(
      Map<String, dynamic> json,
      List<String> keys, {
        String fallback = '',
      }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      return value.toString();
    }
    return fallback;
  }

  static int _intForKeys(
      Map<String, dynamic> json,
      List<String> keys, {
        int fallback = 0,
      }) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value.toString());
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  static double? _doubleForKeys(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value.toString().replaceAll(',', '.'));
      if (parsed != null) return parsed;
    }
    return null;
  }

  static String? _nullableStringForKeys(
      Map<String, dynamic> json,
      List<String> keys,
      ) {
    final value = _stringForKeys(json, keys);
    if (value.isEmpty) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final rawProfileImage = _stringForKeys(
      json,
      const ['profileImage', 'image', 'avatar'],
      fallback: '',
    );

    return UserProfileModel(
      id: _stringForKeys(json, const ['id', 'userId', 'user_id', 'profileId']),
      firstName: _stringForKeys(
        json,
        const ['firstName', 'firstname', 'first_name', 'name'],
      ),
      lastName: _stringForKeys(
        json,
        const ['lastName', 'lastname', 'last_name', 'surname'],
      ),
      age: _intForKeys(json, const ['age', 'Age']),
      gender: _stringForKeys(json, const ['gender', 'sex']),
      email: _stringForKeys(json, const ['email', 'mail']),
      addictionType: _stringForKeys(
        json,
        const ['addictionType', 'addiction_type', 'addiction'],
      ),
      profileImage: rawProfileImage.isEmpty ? null : rawProfileImage,
      weight: _doubleForKeys(json, const ['weight', 'poids']),
      medicalCondition: _nullableStringForKeys(
        json,
        const ['medicalCondition', 'medical_condition', 'condition'],
      ),
      doctorName: _nullableStringForKeys(
        json,
        const ['doctorName', 'doctor_name', 'doctor'],
      ),
      therapyGoals: _nullableStringForKeys(
        json,
        const ['therapyGoals', 'therapy_goals', 'goals'],
      ),
      emergencyContactName: _nullableStringForKeys(
        json,
        const ['emergencyContactName', 'emergency_contact_name'],
      ),
      emergencyContactPhone: _nullableStringForKeys(
        json,
        const ['emergencyContactPhone', 'emergency_contact_phone'],
      ),
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
      'medicalCondition': medicalCondition,
      'doctorName': doctorName,
      'therapyGoals': therapyGoals,
      'emergencyContactName': emergencyContactName,
      'emergencyContactPhone': emergencyContactPhone,
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
    bool removeProfileImage = false,
    bool removeWeight = false,
    String? medicalCondition,
    String? doctorName,
    String? therapyGoals,
    String? emergencyContactName,
    String? emergencyContactPhone,
    bool removeMedicalCondition = false,
    bool removeDoctorName = false,
    bool removeTherapyGoals = false,
    bool removeEmergencyContactName = false,
    bool removeEmergencyContactPhone = false,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      email: email ?? this.email,
      addictionType: addictionType ?? this.addictionType,
      profileImage:
      removeProfileImage ? null : (profileImage ?? this.profileImage),
      weight: removeWeight ? null : (weight ?? this.weight),
      medicalCondition: removeMedicalCondition
          ? null
          : (medicalCondition ?? this.medicalCondition),
      doctorName:
      removeDoctorName ? null : (doctorName ?? this.doctorName),
      therapyGoals:
      removeTherapyGoals ? null : (therapyGoals ?? this.therapyGoals),
      emergencyContactName: removeEmergencyContactName
          ? null
          : (emergencyContactName ?? this.emergencyContactName),
      emergencyContactPhone: removeEmergencyContactPhone
          ? null
          : (emergencyContactPhone ?? this.emergencyContactPhone),
    );
  }
}