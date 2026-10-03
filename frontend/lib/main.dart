import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'providers/auth_provider.dart';
import 'providers/complaint_provider.dart';
import 'providers/notification_provider.dart';
import 'constants/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/citizen/citizen_home_screen.dart';
import 'screens/officer/officer_home_screen.dart';
import 'screens/admin/admin_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CityPulseApp());
}

class CityPulseApp extends StatelessWidget {
  final ApiService? apiService;

  const CityPulseApp({super.key, this.apiService});

  @override
  Widget build(BuildContext context) {
    final client = apiService ?? ApiService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(apiService: client)..tryAutoLogin(),
        ),
        ChangeNotifierProvider(
          create: (_) => ComplaintProvider(apiService: client),
        ),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(apiService: client),
        ),
      ],
      child: MaterialApp(
        title: 'CityPulse - Real-time Urban Issue Reporting & Resolution',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading && auth.currentUser == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!auth.isAuthenticated) {
              return const LoginScreen();
            }

            if (auth.isAdmin) {
              return const AdminHomeScreen();
            }

            if (auth.isOfficer) {
              return const OfficerHomeScreen();
            }

            return const CitizenHomeScreen();
          },
        ),
      ),
    );
  }
}
