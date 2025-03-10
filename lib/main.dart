import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:final_application/pages/home_page.dart';
import 'package:final_application/pages/login_page.dart';
import 'package:final_application/pages/register_page.dart';
import 'package:final_application/pages/forgot_password_page.dart';
import 'package:final_application/pages/verify_email_page.dart';
import 'package:final_application/pages/subscription_page.dart';
import 'package:final_application/services/subscription_service.dart';
import 'package:final_application/services/iap_service.dart';
import 'package:final_application/services/ad_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// Import this for AdWidget
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );

  // Initialize subscription service first
  try {
    await SubscriptionService.instance.init();
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing subscription service: $e');
    }
  }

  // Initialize other services in the background to avoid blocking the UI
  _initializeServicesInBackground();

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

Future<void> _initializeServicesInBackground() async {
  try {
    // Initialize ad service
    await AdService.instance.init();
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing ad service: $e');
    }
  }

  try {
    // Initialize IAP service
    await IAPService.instance.init();
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing IAP service: $e');
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Final Application',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.blue),
        ),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/verify-email': (context) => const VerifyEmailPage(),
        '/subscription': (context) => const SubscriptionPage(),
      },
    );
  }
}

extension ContextExtension on BuildContext {
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  void showLoading() {
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  void hideLoading() {
    if (Navigator.canPop(this)) {
      Navigator.pop(this);
    }
  }
}
