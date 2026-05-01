import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/trader/trader_home.dart';
import 'screens/buyer/buyer_home.dart';
import 'screens/transporter/transporter_home.dart';

void main() {
  final storage = StorageService();
  final api = ApiService(storage);
  final auth = AuthService(api, storage);

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(auth)..checkAuthStatus(),
      child: const JongleiApp(),
    ),
  );
}

class JongleiApp extends StatelessWidget {
  const JongleiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jonglei Fish Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1565C0)),
        useMaterial3: true,
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return _homeForRole(auth.currentUser!.role);
          }
          return const LoginScreen();
        },
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/register': (_) => const RegisterScreen(),
        '/trader': (_) => const TraderHomeScreen(),
        '/buyer': (_) => const BuyerHomeScreen(),
        '/transporter': (_) => const TransporterHomeScreen(),
      },
    );
  }

  Widget _homeForRole(String role) {
    switch (role) {
      case 'BUYER':
        return const BuyerHomeScreen();
      case 'TRANSPORTER':
      case 'DRIVER':
        return const TransporterHomeScreen();
      default:
        return const TraderHomeScreen();
    }
  }
}
