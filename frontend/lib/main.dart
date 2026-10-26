import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/supplement_provider.dart';
import 'providers/exercise_upload_provider.dart';
import 'screens/auth/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/homepage_screens.dart';
import 'screens/auth/onboarding_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/admin/admin_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SupplementProvider()),
        ChangeNotifierProvider(create: (_) => ExerciseUploadProvider()),
      ],
      child: const GymbroApp(),
    ),
  );
}

class GymbroApp extends StatelessWidget {
  const GymbroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gymbro',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (_) => const SplashScreen(),
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/onboarding': (_) => const OnboardingPage(),
        '/home': (_) => const HomeScreen(),
        '/admin-dashboard': (_) => const AdminDashboardScreen(),
      },
    );
  }
}