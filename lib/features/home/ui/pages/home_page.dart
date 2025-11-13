import 'package:flutter/material.dart';
import 'package:nafass_application/features/auth/logic/auth_provider.dart';
import 'package:nafass_application/features/weather/ui/weather_badge.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final List<_HomeFeature> _features = const [
    _HomeFeature(
      title: 'Tableau de bord',
      icon: Icons.dashboard_customize_rounded,
      description: 'Vue d\'ensemble de votre santé.',
      accent: Color(0xFFE58D98),
    ),
    _HomeFeature(
      title: 'Médicaments',
      icon: Icons.medical_services_rounded,
      description: 'Planifie tes traitements et suivis.',
      route: '/meds',
      accent: Color(0xFF6DC0C5),
    ),
    _HomeFeature(
      title: 'Défis bien-être',
      icon: Icons.flag_rounded,
      description: 'Relève les défis santé hebdomadaires.',
      route: '/challenges',
      accent: Color(0xFFE1A4C4),
    ),
    _HomeFeature(
      title: 'Suivi quotidien',
      icon: Icons.monitor_heart_rounded,
      description: 'Hydratation et habitudes de santé.',
      route: '/consumption',
      accent: Color(0xFFBFD079),
    ),
    _HomeFeature(
      title: 'Journal de bord',
      icon: Icons.edit_note_rounded,
      description: 'Note ton humeur et tes ressentis.',
      route: '/journal',
      accent: Color(0xFF9AA0E8),
    ),
    _HomeFeature(
      title: 'Calendrier',
      icon: Icons.calendar_today_rounded,
      description: 'Planifie tes rendez-vous importants.',
      route: '/calendar',
      accent: Color(0xFF7FC4FF),
    ),
    _HomeFeature(
      title: 'Profil & paramètres',
      icon: Icons.person_rounded,
      description: 'Gère tes informations personnelles.',
      route: '/profile',
      accent: Color(0xFFE0C3A6),
    ),
  ];
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (context, constraints) {
          final bool showNavigationRail = constraints.maxWidth >= 1000;
          final bool extendRail = constraints.maxWidth >= 1250;
          return Scaffold(
              drawer: showNavigationRail ? null : _buildDrawer(context),
              appBar: AppBar(
                automaticallyImplyLeading: !showNavigationRail,
                title: const Text('Nafass Health Center'),
                actions: [
                  IconButton(
                    tooltip: 'Se déconnecter',
                    icon: const Icon(Icons.logout_rounded),
                    onPressed: () {
                      context.read<AuthProvider>().logout();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
              body: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showNavigationRail)
                      NavigationRail(
                        selectedIndex: _selectedIndex,
                        extended: extendRail,
                        destinations: [
                          for (final feature in _features)
                            NavigationRailDestination(
                              icon: Icon(feature.icon),
                              label: Text(feature.title),
                            ),
                        ],
                        onDestinationSelected: (index) {
                          setState(() => _selectedIndex = index);
                          final feature = _features[index];
                          if (feature.route != null) {
                            Navigator.pushNamed(context, feature.route!);
                          }
                        },
                      ),
                    Expanded(
                      child: _HomeContent(
                        features: _features,
                        onFeatureTap: _openFeature,
                      ),
                    ),
                  ],
                ),
              ),
          );
        },
    );
  }
  void _openFeature(_HomeFeature feature) {
    if (feature.route == null) {
      return;
    }
    Navigator.pushNamed(context, feature.route!);
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
        child: SafeArea(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Navigation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
            child: ListView.builder(
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  final feature = _features[index];
                  return ListTile(
                    leading: Icon(feature.icon, color: feature.accent),
                    title: Text(feature.title),
                    subtitle: Text(feature.description),
                    onTap: () {
                      Navigator.pop(context);
                      _openFeature(feature);
                    },
                  );
                },
            ),
        ),
              ],
          ),
        ),
    );
  }
}
class _HomeContent extends StatelessWidget {
  const _HomeContent({
    required this.features,
    required this.onFeatureTap,
  });

  final List<_HomeFeature> features;
  final ValueChanged<_HomeFeature> onFeatureTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final user = authProvider.currentUser;
        final firstName = user?.username ?? '';
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DashboardHeader(
                firstName: firstName,
                email: user?.email,
                isDark: isDark,
              ),
              const SizedBox(height: 20),
              const WeatherBadge(),
              const SizedBox(height: 28),
              Text(
                'Prends soin de toi',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  for (final feature in features.skip(1))
                    _HomeFeatureCard(
                      feature: feature,
                      onTap: () => onFeatureTap(feature),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.firstName,
    required this.email,
    required this.isDark,
  });
  final String firstName;
  final String? email;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final gradientColors = isDark
        ? [const Color(0xFF1E1F22), const Color(0xFF24262A)]
        : [const Color(0xFFF9ECEF), const Color(0xFFEAF6F4)];

    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: colorScheme.primary.withOpacity(isDark ? 0.2 : 0.3),
            ),
        ), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
    Row(
    children: [
    CircleAvatar(
    radius: 32,
      backgroundColor: colorScheme.primary.withOpacity(0.18),
      child: const Icon(Icons.health_and_safety_rounded, size: 36),
    ),
        const SizedBox(width: 16),
        Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName.isEmpty
                      ? 'Bienvenue sur Nafass'
                      : 'Salut $firstName,',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email ?? 'Prêt·e pour une journée équilibrée ?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
        ),
    ],
    ),
          const SizedBox(height: 20),
          Text(
            'Consulte ton tableau de bord pour suivre tes médicaments, tes activités et tes progrès.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ],
    ),
    );
  }
}
class _HomeFeatureCard extends StatelessWidget {
  const _HomeFeatureCard({
    required this.feature,
    required this.onTap,
  });
  final _HomeFeature feature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return SizedBox(
        width: 280,
        child: Material(
            color: colorScheme.surface,
            elevation: 1,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: feature.accent.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    feature.icon,
                    size: 28,
                    color: feature.accent,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  feature.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  feature.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                      ],
                  ),
                ),
            ),
        ),
    );
  }
}
class _HomeFeature {
  const _HomeFeature({
    required this.title,
    required this.icon,
    required this.description,
    this.route,
    required this.accent,
  });

  final String title;
  final IconData icon;
  final String description;
  final String? route;
  final Color accent;
}