import 'package:flutter/material.dart';
import 'package:nafass_application/features/calendar/ui/pages/journal_home_page.dart';
import 'package:nafass_application/features/challenges/ui/pages/challenge_details_page.dart';
import 'package:nafass_application/features/challenges/ui/pages/challenge_form_page.dart';
import 'package:nafass_application/features/challenges/ui/pages/challenges_home_page.dart';
import 'package:nafass_application/features/home/ui/pages/home_page.dart';
import '../features/auth/ui/pages/login_page.dart';
import '../features/auth/ui/pages/register_page.dart';
import 'package:nafass_application/features/medicament/ui/pages/medicament_list_page.dart';
import '../features/consumption/ui/pages/consumption_home_page.dart';
import '../features/consumption/ui/pages/consumption_stats_page.dart';
import '../features/profile/ui/pages/edit_profile_page.dart';
import '../features/profile/ui/pages/profile_creation_page.dart';
import '../features/profile/ui/pages/profile_page.dart';

class AppRouter {
  const AppRouter._();

  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
    '/': (context) => const HomePage(),
    '/login': (context) => const LoginPage(),
    '/register': (context) => const RegisterPage(),
    '/journal': (context) => const JournalHomePage(),
    '/challenges': (context) => const ChallengesHomePage(),
    '/challenges/new': (context) => const ChallengeFormPage(),
    '/challenges/details': (context) => const ChallengeDetailsPage(),
    '/meds': (context) => const MedicamentListPage(),
    '/profile': (context) => const ProfilePage(),
    '/create-profile': (context) => const ProfileCreationPage(),
    '/profile/edit': (context) => const EditProfilePage(),
    '/consumption': (context) => const ConsumptionHomePage(),
    '/consumption/stats': (context) => const  ConsumptionStatsPage(),
  };
}