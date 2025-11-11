import 'package:flutter/material.dart';
import 'package:nafass_application/features/auth/logic/auth_provider.dart';
import 'package:provider/provider.dart';


class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const Color _brandPink = Color(0xFFE58D98);
  static const Color _brandGreenLilac = Color(0xFFBFD079);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final gradientDecoration = isDark
        ? null
        : const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF7F2FA),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF141518) : colorScheme.background,
      appBar: AppBar(
        title: Text(
          'Nafass',
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor:
        isDark ? const Color(0xFF1E1F22) : colorScheme.surface.withOpacity(0.95),
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            color: colorScheme.primary,
            tooltip: 'Se déconnecter',
            onPressed: () {
              final authProvider = context.read<AuthProvider>();
              authProvider.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Container(
        decoration: gradientDecoration,
        child: SafeArea(
          child: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              final user = authProvider.currentUser;
              return LayoutBuilder(
                builder: (context, constraints) {
                  final horizontalPadding = constraints.maxWidth > 900
                      ? constraints.maxWidth * 0.2
                      : 24.0;

                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WelcomeCard(
                          fullName: '${user?.lastName} ${user?.username}',
                          email: user?.email,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                        GridView.count(
                          shrinkWrap: true,
                          crossAxisCount: 2,
                          mainAxisSpacing: 20,
                          crossAxisSpacing: 20,
                          childAspectRatio: 1.05,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _HomeCard(
                              title: 'Défis',
                              icon: Icons.flag_rounded,
                              accentColor: _brandPink,
                              onTap: () => Navigator.pushNamed(context, '/challenges'),
                            ),
                            _HomeCard(
                              title: 'Médicaments',
                              icon: Icons.medication_rounded,
                              accentColor: _brandGreenLilac,
                              onTap: () => Navigator.pushNamed(context, '/meds'),
                            ),
                            _HomeCard(
                              title: 'Suivi',
                              icon: Icons.monitor_heart_rounded,
                              accentColor: _brandPink,
                              onTap: () => Navigator.pushNamed(context, '/consumption'),
                            ),
                            _HomeCard(
                              title: 'Calendrier',
                              icon: Icons.calendar_today_rounded,
                              accentColor: _brandGreenLilac,
                              onTap: () => Navigator.pushNamed(context, '/calendar'),
                            ),
                            _HomeCard(
                              title: 'Profil',
                              icon: Icons.person_rounded,
                              accentColor: _brandPink,
                              onTap: () => Navigator.pushNamed(context, '/profile'),
                            ),
                            _HomeCard(
                              title: 'Paramètres',
                              icon: Icons.settings_rounded,
                              accentColor: _brandGreenLilac,
                              onTap: () {
                                // TODO: implémenter la navigation vers les paramètres
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.fullName,
    required this.email,
    required this.isDark,
  });

  final String? fullName;
  final String? email;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final backgroundColor = isDark
        ? const Color(0xFF1F2024)
        : colorScheme.surfaceVariant.withOpacity(0.9);

    final accent = isDark
        ? HomePage._brandPink.withOpacity(0.22)
        : HomePage._brandPink.withOpacity(0.16);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? colorScheme.outlineVariant.withOpacity(0.45)
              : colorScheme.outlineVariant.withOpacity(0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.spa_rounded,
              color: colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName == null || fullName!.isEmpty
                      ? 'Bonjour Nafassien·ne'
                      : 'Bonjour, ${fullName!}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email == null || email!.isEmpty
                      ? 'Prenez un moment pour respirer et continuer votre parcours.'
                      : email!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    final accentBackground =
    isDark ? accentColor.withOpacity(0.14) : accentColor.withOpacity(0.18);

    return Material(
      color: isDark ? const Color(0xFF1E1F22) : colorScheme.surface,
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: isDark
                ? null
                : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.surface,
                colorScheme.surfaceVariant.withOpacity(0.4),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accentBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  size: 30,
                  color: isDark
                      ? colorScheme.onSurface
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}