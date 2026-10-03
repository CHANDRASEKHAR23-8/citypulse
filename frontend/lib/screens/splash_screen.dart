import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../constants/app_theme.dart';
import 'auth/login_screen.dart';
import 'citizen/citizen_home_screen.dart';
import 'officer/officer_home_screen.dart';
import 'admin/admin_home_screen.dart';

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
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final loggedIn = await auth.tryAutoLogin();

    if (!mounted) return;

    if (loggedIn && auth.currentUser != null) {
      if (auth.isAdmin) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
      } else if (auth.isOfficer) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OfficerHomeScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CitizenHomeScreen()));
      }
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_city_rounded, size: 64, color: AppTheme.primary),
            SizedBox(height: 16),
            Text(
              'CityPulse',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 8),
            CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}
