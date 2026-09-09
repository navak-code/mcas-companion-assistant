import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/app_state_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_dashboard_screen.dart';
import 'screens/onboarding_presets_screen.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final storageService = StorageService();
  await storageService.init();
  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        ChangeNotifierProvider<AppStateProvider>(
          create: (_) => AppStateProvider(storageService: storageService),
        ),
      ],
      child: const McasCompanionApp(),
    ),
  );
}

class McasCompanionApp extends StatelessWidget {
  const McasCompanionApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MCAS Companion',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal, brightness: Brightness.light),
      ),
      home: const RootGate(),
    );
  }
}

class RootGate extends StatelessWidget {
  const RootGate({super.key});
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    if (provider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!provider.isAuthenticated) {
      return const AuthScreen();
    }
    if (!provider.isOnboardingCompleted) {
      return const OnboardingPresetsScreen();
    }
    return const HomeDashboardScreen();
  }
}
