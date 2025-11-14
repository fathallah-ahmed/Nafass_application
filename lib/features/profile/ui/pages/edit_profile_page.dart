import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../user/data/models/user_profile_model.dart';
import '../../logic/profile_provider.dart';
import '../widgets/edit_field.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _genderCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _addictionTypeCtrl;
  late TextEditingController _medicalConditionCtrl;
  late TextEditingController _doctorNameCtrl;
  late TextEditingController _therapyGoalsCtrl;
  late TextEditingController _emergencyContactNameCtrl;
  late TextEditingController _emergencyContactPhoneCtrl;
  UserProfileModel? _profile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_profile == null) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is UserProfileModel) {
        _profile = args;
        _initializeControllers(_profile!);
      } else {
        Navigator.pop(context);
      }
    }
  }

  void _initializeControllers(UserProfileModel profile) {
    _firstNameCtrl = TextEditingController(text: profile.firstName);
    _lastNameCtrl = TextEditingController(text: profile.lastName);
    _emailCtrl = TextEditingController(text: profile.email);
    _ageCtrl = TextEditingController(text: profile.age.toString());
    _genderCtrl = TextEditingController(text: profile.gender);
    _weightCtrl = TextEditingController(text: profile.weight?.toString() ?? '');
    _addictionTypeCtrl = TextEditingController(text: profile.addictionType);
    _medicalConditionCtrl =
        TextEditingController(text: profile.medicalCondition ?? '');
    _doctorNameCtrl = TextEditingController(text: profile.doctorName ?? '');
    _therapyGoalsCtrl = TextEditingController(text: profile.therapyGoals ?? '');
    _emergencyContactNameCtrl =
        TextEditingController(text: profile.emergencyContactName ?? '');
    _emergencyContactPhoneCtrl =
        TextEditingController(text: profile.emergencyContactPhone ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _ageCtrl.dispose();
    _genderCtrl.dispose();
    _weightCtrl.dispose();
    _addictionTypeCtrl.dispose();
    _medicalConditionCtrl.dispose();
    _doctorNameCtrl.dispose();
    _therapyGoalsCtrl.dispose();
    _emergencyContactNameCtrl.dispose();
    _emergencyContactPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _profile == null) return;

    final profileProvider = context.read<ProfileProvider>();
    final weightText = _weightCtrl.text.trim();
    final normalizedWeightText = weightText.replaceAll(',', '.');
    final parsedWeight = normalizedWeightText.isEmpty
        ? null
        : double.tryParse(normalizedWeightText);
    final medicalConditionText = _medicalConditionCtrl.text.trim();
    final doctorNameText = _doctorNameCtrl.text.trim();
    final therapyGoalsText = _therapyGoalsCtrl.text.trim();
    final emergencyContactNameText = _emergencyContactNameCtrl.text.trim();
    final emergencyContactPhoneText = _emergencyContactPhoneCtrl.text.trim();

    final updatedProfile = _profile!.copyWith(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text.trim()) ?? _profile!.age,
      gender: _genderCtrl.text.trim(),
      weight: parsedWeight,
      removeWeight: normalizedWeightText.isEmpty,
      addictionType: _addictionTypeCtrl.text.trim(),
      medicalCondition:
      medicalConditionText.isNotEmpty ? medicalConditionText : null,
      doctorName: doctorNameText.isNotEmpty ? doctorNameText : null,
      therapyGoals: therapyGoalsText.isNotEmpty ? therapyGoalsText : null,
      emergencyContactName: emergencyContactNameText.isNotEmpty
          ? emergencyContactNameText
          : null,
      emergencyContactPhone: emergencyContactPhoneText.isNotEmpty
          ? emergencyContactPhoneText
          : null,
      removeMedicalCondition: medicalConditionText.isEmpty,
      removeDoctorName: doctorNameText.isEmpty,
      removeTherapyGoals: therapyGoalsText.isEmpty,
      removeEmergencyContactName: emergencyContactNameText.isEmpty,
      removeEmergencyContactPhone: emergencyContactPhoneText.isEmpty,
    );

    final success = await profileProvider.updateProfile(updatedProfile);
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour avec succès')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            profileProvider.errorMessage ?? 'Erreur lors de la mise à jour',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'L\'âge est requis';
    }
    final age = int.tryParse(value.trim());
    if (age == null || age < 1 || age > 120) {
      return 'Âge invalide';
    }
    return null;
  }

  String? _validateWeight(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final normalized = value.trim().replaceAll(',', '.');
    final weight = double.tryParse(normalized);
    if (weight == null) {
      return 'Poids invalide';
    }
    if (weight < 1 || weight > 500) {
      return 'Le poids doit être entre 1 et 500 kg';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final cleaned = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.length < 6) {
      return 'Numéro invalide';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isLoading = context.watch<ProfileProvider>().isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le profil'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
        body: SafeArea(
            child: LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding =
                  constraints.maxWidth > 700 ? 48.0 : 16.0;
                  final maxFormWidth =
                  constraints.maxWidth > 640 ? 520.0 : constraints.maxWidth;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 24,
              ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxFormWidth),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              EditField(
                                label: 'Prénom',
                                controller: _firstNameCtrl,
                                validator: (v) => _validateRequired(v, 'Le prénom'),
                              ),
                              EditField(
                                label: 'Nom',
                                controller: _lastNameCtrl,
                                validator: (v) => _validateRequired(v, 'Le nom'),
                              ),
                              EditField(
                                label: 'Email',
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => _validateRequired(v, 'L\'email'),
                              ),
                              EditField(
                                label: 'Âge',
                                controller: _ageCtrl,
                                keyboardType: TextInputType.number,
                                validator: _validateAge,
                              ),
                              EditField(
                                label: 'Genre',
                                controller: _genderCtrl,
                                validator: (v) => _validateRequired(v, 'Le genre'),
                              ),
                              EditField(
                                label: 'Type d\'addiction',
                                controller: _addictionTypeCtrl,
                                validator: (v) =>
                                    _validateRequired(v, 'Le type d\'addiction'),
                              ),
                              EditField(
                                label: 'Poids (kg)',
                                controller: _weightCtrl,
                                keyboardType: TextInputType.number,
                                validator: _validateWeight,
                              ),
                              const SizedBox(height: 24),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Informations de santé',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(height: 8),
                              EditField(
                                label: 'Condition médicale',
                                controller: _medicalConditionCtrl,
                                maxLines: 3,
                                minLines: 3,
                                textCapitalization: TextCapitalization.sentences,
                                hintText:
                                'Décris les diagnostics ou antécédents importants',
                              ),
                              EditField(
                                label: 'Professionnel référent',
                                controller: _doctorNameCtrl,
                                textCapitalization: TextCapitalization.words,
                              ),
                              EditField(
                                label: 'Objectifs thérapeutiques',
                                controller: _therapyGoalsCtrl,
                                maxLines: 3,
                                minLines: 3,
                                textCapitalization: TextCapitalization.sentences,
                              ),
                              const SizedBox(height: 24),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Contact d\'urgence',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(height: 8),
                              EditField(
                                label: 'Nom du contact',
                                controller: _emergencyContactNameCtrl,
                                textCapitalization: TextCapitalization.words,
                              ),
                              EditField(
                                label: 'Téléphone du contact',
                                controller: _emergencyContactPhoneCtrl,
                                keyboardType: TextInputType.phone,
                                validator: _validatePhone,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: Colors.white,
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                      : const Text(
                                    'Enregistrer',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                    ),
                  ),
                ),
              ),
                  );
                },
        ),
      ),
    );
  }
}