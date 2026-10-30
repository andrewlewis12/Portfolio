import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/game_screen.dart';
import 'screens/privacy_screen.dart';
import 'screens/terms_screen.dart';
import 'screens/legal_acceptance_screen.dart';
import 'screens/tutorial_screen.dart';
import 'screens/username_setup_screen.dart'; // ADD THIS
import 'services/audio_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  await Firebase.initializeApp();
  
  runApp(MorphRunnerApp());
}

class MorphRunnerApp extends StatefulWidget {
  @override
  State<MorphRunnerApp> createState() => _MorphRunnerAppState();
}

class _MorphRunnerAppState extends State<MorphRunnerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (AudioService.instance.isInitialized) {
      if (state == AppLifecycleState.paused) {
        AudioService.instance.pauseMusic();
      } else if (state == AppLifecycleState.resumed) {
        AudioService.instance.resumeMusic();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Morph Runner',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: 'Arial',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SplashScreen(),
      routes: {
        '/legal': (context) => LegalAcceptanceScreen(),
        '/username_setup': (context) => UsernameSetupScreen(), // ADD THIS
        '/home': (context) => HomeScreen(),
        '/game': (context) => GameScreen(),
        '/tutorial': (context) => TutorialScreen(),
        '/privacy': (context) => PrivacyScreen(),
        '/terms': (context) => TermsScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}