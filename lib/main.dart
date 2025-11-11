import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/logic/auth_provider.dart';
import 'routes/app_router.dart';
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const NafassApp());
}
class NafassApp extends StatelessWidget {
  const NafassApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(),
        child: MaterialApp(
          title: 'Nafass',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          initialRoute: '/login',
          routes: AppRouter.routes,
        ),    );
  }
}
