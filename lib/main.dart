import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme_provider.dart';
import 'core/notification_service.dart';
import 'core/database/hive_boxes.dart';
import 'core/auth_gate.dart';

void main() async {
  // Ensure framework engine widgets are cleanly initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Connect to Firebase (Auth + Firestore)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Load local secure environment credentials (.env)
  await dotenv.load(fileName: ".env");

  // Open local NoSQL Hive database caches safely
  await HiveBoxes.initializeAndOpen();

  // Boot up native hardware notification background ports
  await NotificationService.initialize();

  runApp(
    const ProviderScope(
      child: SmartMoneyApp(),
    ),
  );
}

class SmartMoneyApp extends ConsumerWidget {
  const SmartMoneyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Dynamically listen to the active theme mode state pipeline
    final currentThemeMode = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WealthOS',
      themeMode: currentThemeMode,

      // 1. Sleek Modern Light Theme Configuration Blueprint
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF4F5F9),
        primaryColor: const Color(0xFF6C5CE7),
        cardColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4F5F9),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6C5CE7),
          surface: Colors.white,
        ),
      ),

      // 2. ✅ UPDATED: Premium Dark Synth Matte Theme matching your exact image uploads
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0E12),
        primaryColor: const Color(0xFF2EE59D),
        cardColor: const Color(0xFF17181F),
        dividerColor: Colors.transparent,

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0D0E12),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF17181F),
          selectedColor: const Color(0xFF2EE59D),
          side: BorderSide.none,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),

        cardTheme: CardThemeData(
          color: const Color(0xFF17181F),
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide.none,
          ),
        ),

        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2EE59D),
          surface: Color(0xFF17181F),
          onSurface: Colors.white,
          secondary: Color(0xFF8A8F9F),
        ),
      ),
      home: const AuthGate(),
    );
  }
}