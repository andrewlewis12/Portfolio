// Updated main.dart to include AchievementService

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/game_screen.dart';
import 'services/game_service.dart';
import 'services/ad_service.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';
import 'services/tutorial_service.dart';
import 'services/achievement_service.dart'; // NEW: Add import
import 'screens/splash_screen.dart';
import 'screens/agreement_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Mobile Ads
  await MobileAds.instance.initialize();
  
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize services
  final storageService = StorageService();
  await storageService.init();
  
  final audioService = AudioService(storageService: storageService);
  await audioService.init();

  final adService = AdService();
  await adService.init();
  
  // NEW: Initialize tutorial service
  final tutorialService = TutorialService();
  
  // NEW: Initialize achievement service
  final achievementService = AchievementService(
    storageService: storageService,
    audioService: audioService,
  );
  
  runApp(MyApp(
    storageService: storageService,
    audioService: audioService,
    adService: adService,
    tutorialService: tutorialService,
    achievementService: achievementService, // NEW: Pass achievement service
  ));
}

class MyApp extends StatefulWidget {
  final StorageService storageService;
  final AudioService audioService;
  final AdService adService;
  final TutorialService tutorialService;
  final AchievementService achievementService; // NEW: Add achievement service

  const MyApp({
    Key? key,
    required this.storageService,
    required this.audioService,
    required this.adService,
    required this.tutorialService,
    required this.achievementService, // NEW: Add parameter
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
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

    if (state == AppLifecycleState.paused) {
      widget.audioService.pauseMusic();
    } else if (state == AppLifecycleState.resumed) {
      widget.audioService.resumeMusic();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: widget.storageService),
        ChangeNotifierProvider<AudioService>.value(value: widget.audioService),
        ChangeNotifierProvider<AdService>.value(value: widget.adService),
        ChangeNotifierProvider<TutorialService>.value(value: widget.tutorialService),
        ChangeNotifierProvider<AchievementService>.value(value: widget.achievementService), // NEW: Add achievement service
        ChangeNotifierProvider<GravBlastService>(
          create: (context) => GravBlastService(
            storageService: widget.storageService,
            audioService: widget.audioService,
            adService: widget.adService,
            tutorialService: widget.tutorialService,
            achievementService: widget.achievementService, // NEW: Pass achievement service
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Grav Blast',
        theme: GameTheme.lightTheme,
        darkTheme: GameTheme.darkTheme,
        themeMode: ThemeMode.dark,
        home: const AppInitializer(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// AppInitializer remains the same
class AppInitializer extends StatefulWidget {
  const AppInitializer({Key? key}) : super(key: key);

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  bool _hasAcceptedAgreements = false;
  bool _hasTutorialCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
  }

  Future<void> _checkInitialStatus() async {
    final storageService = context.read<StorageService>();
    
    // Check agreements
    final hasAccepted = await storageService.getBool('agreements_accepted') ?? false;
    
    // Check tutorial completion
    final tutorialCompleted = await storageService.hasTutorialCompleted();
    
    setState(() {
      _hasAcceptedAgreements = hasAccepted;
      _hasTutorialCompleted = tutorialCompleted;
      _isLoading = false;
    });
  }

  Future<void> _onAgreementsAccepted() async {
    final storageService = context.read<StorageService>();
    await storageService.saveBool('agreements_accepted', true);
    
    setState(() {
      _hasAcceptedAgreements = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
          ),
        ),
      );
    }

    // Step 1: Check agreements first
    if (!_hasAcceptedAgreements) {
      return AgreementScreen(onAccepted: _onAgreementsAccepted);
    }

    // Step 2: Check tutorial completion
    if (!_hasTutorialCompleted) {
      // Start tutorial mode in game screen instead of separate tutorial screen
      return const TutorialGameScreen();
    }

    // Step 3: All checks passed, go to splash then menu
    return const SplashScreen();
  }
}

// TutorialGameScreen remains the same but with achievement tracking
class TutorialGameScreen extends StatefulWidget {
  const TutorialGameScreen({Key? key}) : super(key: key);

  @override
  State<TutorialGameScreen> createState() => _TutorialGameScreenState();
}

class _TutorialGameScreenState extends State<TutorialGameScreen> {
  @override
  void initState() {
    super.initState();
    // Start tutorial when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GravBlastService>().startTutorial();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use the same game screen but with tutorial overlay
    return const GravBlastScreen(isTutorialMode: true);
  }
}