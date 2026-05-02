import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/trader/trader_home.dart';
import 'screens/buyer/buyer_home.dart';
import 'screens/transporter/transporter_home.dart';
import 'screens/border_official/border_official_home.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
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
      theme: AppTheme.theme,
      home: const SplashScreen(),
      routes: {
        '/splash':       (_) => const SplashScreen(),
        '/onboarding':   (_) => const OnboardingScreen(),
        '/login':        (_) => const LoginScreen(),
        '/register':     (_) => const RegisterScreen(),
        '/role-select':  (_) => const RoleSelectionScreen(),
        '/trader':       (_) => const TraderHomeScreen(),
        '/buyer':        (_) => const BuyerHomeScreen(),
        '/transporter':       (_) => const TransporterHomeScreen(),
        '/border-official':   (_) => const BorderOfficialHomeScreen(),
      },
    );
  }
}
