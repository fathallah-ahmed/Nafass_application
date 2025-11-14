import 'package:flutter/material.dart';
import '../../../user/data/models/user_profile_model.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfileModel profile;
  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final avatarRadius = isCompact ? 40.0 : 50.0;
        final verticalPadding = isCompact ? 24.0 : 32.0;

        return Container(
          padding: EdgeInsets.symmetric(
            vertical: verticalPadding,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF1E1F22), const Color(0xFF2A2B30)]
                  : [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
            ),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: avatarRadius,
                backgroundColor: Colors.white,
                backgroundImage: profile.profileImage != null
                    ? NetworkImage(profile.profileImage!)
                    : null,
                child: profile.profileImage == null
                    ? Text(
                        profile.firstName.isNotEmpty
                            ? profile.firstName[0].toUpperCase()
                            : 'U',
                        style: TextStyle(
                          fontSize: isCompact ? 24 : 32,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      )
                    : null,
              ),
              SizedBox(height: isCompact ? 12 : 16),
              Text(
                profile.fullName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isCompact ? 20 : null,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  profile.addictionType,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}