import 'package:flutter/material.dart';
import '../../../user/data/models/user_profile_model.dart';

class ProfileInfoCard extends StatelessWidget {
  final UserProfileModel profile;
  const ProfileInfoCard({super.key, required this.profile});

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations personnelles',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow('Email', profile.email, Icons.email_outlined),
            _buildInfoRow('Âge', '${profile.age} ans', Icons.cake_outlined),
            _buildInfoRow('Genre', profile.gender, Icons.person_outline),
            if (profile.weight != null)
              _buildInfoRow(
                'Poids',
                '${profile.weight} kg',
                Icons.monitor_weight_outlined,
              ),
          ],
        ),
      ),
    );
  }
}