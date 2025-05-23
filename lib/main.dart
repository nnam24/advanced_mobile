import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:jarvis_ai_application/providers/email_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

import 'models/conversation.dart';
import 'models/user.dart';
import 'models/knowledge_item.dart';
import 'models/subscription_plan.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/prompt_provider.dart';
import 'providers/ad_provider.dart';
import 'services/ai_bot_service.dart';
import 'services/prompt_service.dart';
import 'services/bot_integration_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/memory_management.dart';

// Optimize the main function to improve app startup performance
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Google Mobile Ads SDK
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize memory management
  MemoryManager().initialize();

  // Create instances that require parameters
  final promptService = PromptService();
  final promptProvider = PromptProvider(promptService: promptService);
  final adProvider = AdProvider();
  final subscriptionProvider = SubscriptionProvider();
  final botIntegrationService = BotIntegrationService();
  final aiBotService = AIBotService();

  // Run the app with optimized providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        // Lazy load providers that aren't needed immediately
        ChangeNotifierProvider.value(value: subscriptionProvider),
        ChangeNotifierProvider.value(value: aiBotService),

        // Updated to use ChangeNotifierProxyProvider2 to inject both dependencies
        ChangeNotifierProxyProvider2<SubscriptionProvider, AIBotService,
            ChatProvider>(
          create: (context) => ChatProvider(
            subscriptionProvider,
            aiBotService,
          ),
          update: (context, subscriptionProvider, aiBotService, previous) =>
              previous ?? ChatProvider(subscriptionProvider, aiBotService),
        ),

        ChangeNotifierProvider.value(value: promptProvider),
        ChangeNotifierProvider.value(value: adProvider),
        ChangeNotifierProvider(create: (_) => EmailProvider()),
        ChangeNotifierProvider.value(value: botIntegrationService),
      ],
      child: const JarvisApp(),
    ),
  );
}

class JarvisApp extends StatefulWidget {
  const JarvisApp({super.key});

  @override
  State<JarvisApp> createState() => _JarvisAppState();
}

class _JarvisAppState extends State<JarvisApp> {
  @override
  void initState() {
    super.initState();

    // Initialize ads after the app is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'Jarvis AI',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      home: authProvider.isAuthenticated
          ? const HomeScreen()
          : const LoginScreen(),
    );
  }
}
