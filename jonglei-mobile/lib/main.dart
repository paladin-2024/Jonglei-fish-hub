import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'widgets/offline_banner.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/role_selection_screen.dart';
import 'screens/trader/trader_home.dart';
import 'screens/buyer/buyer_home.dart';
import 'screens/transporter/transporter_home.dart';
import 'screens/border_official/border_official_home.dart';
import 'screens/shared/fish_encyclopedia_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Only runs when google-services.json is present
  try { await Firebase.initializeApp(); } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Firebase is optional — app works without google-services.json.
  // Add the file from Firebase Console to enable push notifications.
  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    firebaseReady = true;
  } catch (e) {
    debugPrint('[Firebase] Not configured — push notifications disabled. ($e)');
  }

  await Hive.initFlutter();

  final storage = StorageService();
  final api     = ApiService(storage);
  final auth    = AuthService(api, storage);

  if (firebaseReady) {
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    // Store FCM token for server-side push targeting
    FirebaseMessaging.instance.getToken().then((token) {
      if (token != null) storage.setString('fcm_token', token);
    });
  }

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
      builder: (context, child) => OfflineBanner(child: child!),
      home: const SplashScreen(),
      routes: {
        '/splash':          (_) => const SplashScreen(),
        '/onboarding':      (_) => const OnboardingScreen(),
        '/login':           (_) => const LoginScreen(),
        '/register':        (_) => const RegisterScreen(),
        '/role-select':     (_) => const RoleSelectionScreen(),
        '/trader':          (_) => const TraderHomeScreen(),
        '/buyer':           (_) => const BuyerHomeScreen(),
        '/transporter':     (_) => const TransporterHomeScreen(),
        '/border-official': (_) => const BorderOfficialHomeScreen(),
        '/encyclopedia':    (_) => const FishEncyclopediaScreen(),
      },
    );
  }
}
