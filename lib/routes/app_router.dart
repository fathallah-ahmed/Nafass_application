import 'package:flutter/material.dart';
import 'package:nafass_application/features/home/ui/pages/home_page.dart';
import '../features/auth/ui/pages/login_page.dart';
import '../features/auth/ui/pages/register_page.dart';

class AppRouter {
  const AppRouter._();

  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
    '/': (context) => const HomePage(),
    '/login': (context) => const LoginPage(),
    '/register': (context) => const RegisterPage(),
  };
}