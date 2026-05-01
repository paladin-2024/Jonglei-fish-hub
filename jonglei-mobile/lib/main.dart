import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

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
      theme: _buildTheme(),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) return _homeForRole(auth.currentUser!.role);
          return const LoginScreen();
        },
      ),
      routes: {
        '/login':       (_) => const LoginScreen(),
        '/register':    (_) => const RegisterScreen(),
        '/trader':      (_) => const TraderHomeScreen(),
        '/buyer':       (_) => const BuyerHomeScreen(),
        '/transporter': (_) => const TransporterHomeScreen(),
      },
    );
  }

  ThemeData _buildTheme() {
    const seed = Color(0xFF00897B); // teal-600
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
      primary: const Color(0xFF00695C),
      onPrimary: Colors.white,
      secondary: const Color(0xFF26A69A),
      surface: Colors.white,
      surfaceContainerHighest: const Color(0xFFE0F2F1),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00695C),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00897B), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIconColor: const Color(0xFF78909C),
        labelStyle: const TextStyle(color: Color(0xFF78909C)),
      ),
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
