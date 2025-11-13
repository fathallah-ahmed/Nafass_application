import 'package:flutter/material.dart';
import 'package:nafass_application/features/calendar/logic/journal_provider.dart';
import 'package:nafass_application/core/utils/notification_service.dart';
import 'package:nafass_application/features/challenges/logic/challenges_provider.dart';
import 'package:nafass_application/features/medicament/logic/medicament_provider.dart';
import 'package:nafass_application/features/medicament/logic/prises_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'features/profile/logic/profile_provider.dart';
import 'routes/app_router.dart';
import 'package:nafass_application/features/auth/logic/auth_provider.dart';



Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'fr';
  await initializeDateFormatting('fr');
  final notificationService = NotificationService();
  await notificationService.init();
  runApp(NafassApp(notificationService: notificationService));
}
class NafassApp extends StatelessWidget {
  const NafassApp({super.key, required this.notificationService});

  final NotificationService notificationService;

  static const Color _primaryPink = Color(0xFFE58D98);
  static const Color _secondaryLilac = Color(0xFFBFD079);
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ProfileProvider>(create: (_) => ProfileProvider()),
        ChangeNotifierProxyProvider<AuthProvider, JournalProvider>(
          create: (context) => JournalProvider(
            authProvider: context.read<AuthProvider>(),
            notificationService: notificationService,
          ),
          update: (context, auth, previous) {
            final provider = previous ?? JournalProvider(
              authProvider: auth,
              notificationService: notificationService,
            );
            provider.updateAuth(auth);
            return provider;
          },
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChallengesProvider>(
          create: (context) => ChallengesProvider(
            authProvider: context.read<AuthProvider>(),
            notificationService: notificationService,
          ),
          update: (context, auth, previous) {
            final provider = previous ?? ChallengesProvider(
              authProvider: auth,
              notificationService: notificationService,
            );
            provider.updateAuth(auth);
            return provider;
          },
        ),
        ChangeNotifierProvider<PrisesProvider>(
          create: (_) => PrisesProvider()..load(),
        ),
        ChangeNotifierProvider<MedicamentProvider>(
          create: (context) => MedicamentProvider(
            prisesProvider: context.read<PrisesProvider>(),
          )..load(),
        ),
      ],
      child: MaterialApp(
        title: 'Nafass',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(), // Optional: define a dark theme
        themeMode: ThemeMode.system,
        initialRoute: '/login',
        routes: AppRouter.routes,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [
          Locale('fr'),
          Locale('en'),
        ],
      ),
    );
  }
  ThemeData _buildLightTheme() {
    const background = Color(0xFFFFFFFF);
    const surface = Color(0xFFFFFFFF);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryPink,
      brightness: Brightness.light,
      primary: _primaryPink,
      secondary: _secondaryLilac,
      surface: surface,
      background: background,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const background = Color(0xFF141518);
    const surface = Color(0xFF1E1F22);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _primaryPink,
      brightness: Brightness.dark,
      primary: _primaryPink,
      secondary: _secondaryLilac,
      background: background,
      surface: surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
      ),
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.4),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
