import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    debugPrint('SplashScreen - Starting auth check...');
    
    // Delay satu frame supaya widget tree selesai build dulu
    await Future.delayed(Duration.zero);
    if (!mounted) return;
  
    debugPrint('SplashScreen - Calling checkAuthStatus...');
    await context.read<AuthProvider>().checkAuthStatus();
    if (!mounted) return;

    final status = context.read<AuthProvider>().status;
    final user = context.read<AuthProvider>().user;
    final isAdmin = context.read<AuthProvider>().isAdmin;
    
    debugPrint('SplashScreen - Status: $status, User: ${user?.fullName}');

    if (status == AuthStatus.authenticated) {
      // Debug: Print user data
      debugPrint('User ID: ${user?.id}');
      debugPrint('User name: ${user?.fullName}');
      debugPrint('onboardingCompleted: ${user?.onboardingCompleted}');
      debugPrint('onboardingCompleted type: ${user?.onboardingCompleted.runtimeType}');
      debugPrint('onboardingCompleted == true: ${user?.onboardingCompleted == true}');
      
      // Check if user needs onboarding
      // Handle null, false, or undefined as needing onboarding (unless admin)
      final needsOnboarding = !isAdmin && user?.onboardingCompleted != true;
      
      debugPrint('needsOnboarding: $needsOnboarding');
      
      if (needsOnboarding) {
        debugPrint('Redirecting to onboarding...');
        Navigator.pushReplacementNamed(context, '/onboarding');
      } else {
        debugPrint('Redirecting to home...');
        Navigator.pushReplacementNamed(
          context,
          isAdmin ? '/admin-dashboard' : '/home',
        );
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fitness_center, size: 64),
            SizedBox(height: 16),
            Text(
              'Gymbro',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}