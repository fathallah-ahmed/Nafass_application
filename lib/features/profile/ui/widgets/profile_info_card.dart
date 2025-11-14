import 'package:flutter/material.dart';
import '../../../user/data/models/user_profile_model.dart';

class ProfileInfoCard extends StatelessWidget {
  final UserProfileModel profile;
  const ProfileInfoCard({super.key, required this.profile});

  Widget _buildInfoRow(String label, String? value, IconData icon) {
    final display = (value == null || value.trim().isEmpty)
        ? 'Non renseigné'
        : value.trim();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  display,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                  softWrap: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context,
      String title,
      List<Widget> children,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),

        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth > 400 ? 24.0 : 16.0;
        final weightDisplay = profile.weight != null
            ? '${profile.weight!.toStringAsFixed(
          profile.weight! % 1 == 0 ? 0 : 1,
        )} kg'
            : null;

        return Card(
          margin: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: 16,
          ),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  context,
                  'Informations personnelles',
                  [
                    _buildInfoRow('Email', profile.email, Icons.email_outlined),
                    _buildInfoRow(
                      'Âge',
                      '${profile.age} ans',
                      Icons.cake_outlined,
                    ),
                    _buildInfoRow('Genre', profile.gender, Icons.person_outline),
                    _buildInfoRow(
                      'Type d\'addiction',
                      profile.addictionType,
                      Icons.healing_outlined,
                    ),
                    if (weightDisplay != null)
                      _buildInfoRow(
                        'Poids',
                        weightDisplay,
                        Icons.monitor_weight_outlined,
                      ),
                  ],
                ),
                const Divider(height: 32),
                _buildSection(
                  context,
                  'Suivi de santé',
                  [
                    _buildInfoRow(
                      'Condition médicale',
                      profile.medicalCondition,
                      Icons.monitor_heart_outlined,
                    ),
                    _buildInfoRow(
                      'Professionnel référent',
                      profile.doctorName,
                      Icons.medical_information_outlined,
                    ),
                    _buildInfoRow(
                      'Objectifs thérapeutiques',
                      profile.therapyGoals,
                      Icons.flag_outlined,
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildSection(
                  context,
                  'Contact d\'urgence',
                  [
                    _buildInfoRow(
                      'Nom',
                      profile.emergencyContactName,
                      Icons.contact_page_outlined,
                    ),
                    _buildInfoRow(
                      'Téléphone',
                      profile.emergencyContactPhone,
                      Icons.phone_in_talk_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}