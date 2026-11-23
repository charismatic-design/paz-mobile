import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/paz_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/main_shell.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style to match Obsidian Dark
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: PazColors.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final storage = StorageService();
  final token = await storage.getToken();
  final hasSession = token != null && token.isNotEmpty;

  runApp(PazApp(initialScreen: hasSession ? const MainShell() : const LoginScreen()));
}

class PazApp extends StatelessWidget {
  final Widget initialScreen;

  const PazApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PAZ Terminal',
      debugShowCheckedModeBanner: false,
      theme: PazTheme.darkTheme,
      home: initialScreen,
    );
  }
}
