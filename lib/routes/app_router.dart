import 'package:flutter/material.dart';
import 'package:nafass_application/features/calendar/ui/pages/journal_home_page.dart';
import 'package:nafass_application/features/challenges/ui/pages/challenge_details_page.dart';
import 'package:nafass_application/features/challenges/ui/pages/challenge_form_page.dart';
import 'package:nafass_application/features/challenges/ui/pages/challenges_home_page.dart';
import 'package:nafass_application/features/home/ui/pages/home_page.dart';
import '../features/auth/ui/pages/login_page.dart';
import '../features/auth/ui/pages/register_page.dart';
import 'package:nafass_application/features/medicament/ui/pages/medicament_list_page.dart';

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
  };
}