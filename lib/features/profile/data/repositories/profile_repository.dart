import '../../../../core/storage/local_json_store.dart';
import '../../../user/data/models/user_profile_model.dart';
class ProfileRepository {
  ProfileRepository({LocalJsonStore? store})
      : _store = store ?? LocalJsonStore();

  final LocalJsonStore _store;
  static const String _profileFile = 'profiles.json';

  Future<List<UserProfileModel>> _readProfiles() async {
    final data = await _store.readList(_profileFile);
    final profiles = data.map(UserProfileModel.fromJson).toList();
    final Map<String, UserProfileModel> uniqueProfiles = {};

    for (final profile in profiles) {
      if (profile.id.isEmpty) {
        continue;
      }
      uniqueProfiles[profile.id] = profile;
    }

    return uniqueProfiles.values.toList();
  }

  Future<void> _writeProfiles(List<UserProfileModel> profiles) async {
    await _store.writeList(
      _profileFile,
      profiles.map((profile) => profile.toJson()).toList(),
    );
  }

  Future<List<UserProfileModel>> getAllProfiles() async {
    return _readProfiles();
  }

  Future<UserProfileModel?> getProfileByUserId(String userId) async {
    final profiles = await _readProfiles();
    try {
      return profiles.firstWhere((profile) => profile.id == userId);
    } catch (_) {
      return null;
    }
  }

  Future<UserProfileModel> createProfile({
    required String userId,
    required String firstName,
    required String lastName,
    required int age,
    required String gender,
    required String email,
    required String addictionType,
    String? profileImage,
    double? weight,
    String? medicalCondition,
    String? doctorName,
    String? therapyGoals,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) async {
    final profiles = await _readProfiles();

    final profile = UserProfileModel(
      id: userId,
      firstName: firstName,
      lastName: lastName,
      age: age,
      gender: gender,
      email: email,
      addictionType: addictionType,
      profileImage: profileImage,
      weight: weight,
      medicalCondition: medicalCondition,
      doctorName: doctorName,
      therapyGoals: therapyGoals,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
    );

    final existingIndex = profiles.indexWhere((existing) => existing.id == userId);
    if (existingIndex != -1) {
      profiles[existingIndex] = profile;
    } else {
      profiles.add(profile);
    }
    await _writeProfiles(profiles);
    return profile;
  }

  Future<bool> updateProfile(UserProfileModel profile) async {
    final profiles = await _readProfiles();
    final index = profiles.indexWhere((p) => p.id == profile.id);

    if (index == -1) return false;

    profiles[index] = profile;
    await _writeProfiles(profiles);
    return true;
  }

  Future<bool> deleteProfile(String userId) async {
    final profiles = await _readProfiles();
    final initialLength = profiles.length;

    profiles.removeWhere((profile) => profile.id == userId);

    if (profiles.length == initialLength) return false;

    await _writeProfiles(profiles);
    return true;
  }
}
