import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'models/conversation.dart';
import 'models/user.dart';
import 'models/message.dart';
import 'models/ai_bot.dart';
import 'models/knowledge_item.dart';
import 'models/subscription_plan.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/prompt_provider.dart';
import 'services/ai_bot_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/memory_management.dart';

// Optimize the main function to improve app startup performance
void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

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

  // Run the app with optimized providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        // Lazy load providers that aren't needed immediately
        ChangeNotifierProvider.value(value: ChatProvider()),
        ChangeNotifierProvider.value(value: AIBotService()),
        ChangeNotifierProvider.value(value: SubscriptionProvider()),
        ChangeNotifierProvider.value(value: PromptProvider()),
      ],
      child: const JarvisApp(),
    ),
  );
}

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

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
