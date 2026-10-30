import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../utils/game_data.dart';

class AudioService extends ChangeNotifier {
  static AudioService? _instance;
  static AudioService get instance => _instance ??= AudioService._();
  AudioService._();

  final Map<String, AudioSource> _sounds = {};
  AudioSource? _backgroundMusic;
  AudioSource? _gameMusic;
  SoundHandle? _musicHandle;
  
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _volume = 0.7;
  double _musicVolume = 0.4;
  
  bool _isInitialized = false;
  String? _currentMusicTrack;
  String? _pendingMusicTrack; // Track what should be playing

  /// Initialize SoLoud and preload all sound assets, load settings
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      await SoLoud.instance.init();
      
      // Load saved settings from GameData
      await _loadSettings();

      // Preload UI sounds
      await _loadSound('ui_click');
      
      // Preload game sounds
      await _loadSound('player_move');
      await _loadSound('player_dash');
      await _loadSound('shape_morph');
      await _loadSound('obstacle_pass');
      await _loadSound('collision_shape');
      await _loadSound('collision_x');
      await _loadSound('score_increase');
      await _loadSound('speed_increase');
      await _loadSound('game_over');
      await _loadSound('new_high_score');
      await _loadSound('power_up');
      
      // Load music tracks
      await _loadBackgroundMusic();
      await _loadGameMusic();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('AudioService initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AudioService initialization failed: $e');
      }
    }
  }

  /// Load settings from GameData
  Future<void> _loadSettings() async {
    _soundEnabled = GameData.soundEnabled;
    _musicEnabled = GameData.musicEnabled;
    _volume = GameData.volume;
    _musicVolume = GameData.musicVolume;
    
    if (kDebugMode) {
      print('AudioService loaded settings: sound=$_soundEnabled, music=$_musicEnabled, volume=$_volume, musicVolume=$_musicVolume');
    }
    
    notifyListeners();
  }

  /// Save settings to GameData
  Future<void> _saveSettings() async {
    await GameData.setSoundEnabled(_soundEnabled);
    await GameData.setMusicEnabled(_musicEnabled);
    await GameData.setVolume(_volume);
    await GameData.setMusicVolume(_musicVolume);
    
    if (kDebugMode) {
      print('AudioService saved settings: sound=$_soundEnabled, music=$_musicEnabled, volume=$_volume, musicVolume=$_musicVolume');
    }
  }

  /// Loads sound from assets and caches it for instant play
  Future<void> _loadSound(String name) async {
    try {
      if (kIsWeb) {
        // On web, load with LoadMode.disk for better performance
        _sounds[name] = await SoLoud.instance.loadAsset(
          'assets/sounds/$name.wav',
          mode: LoadMode.disk,
        );
      } else {
        // On mobile/desktop, load fully into memory for low latency
        _sounds[name] = await SoLoud.instance.loadAsset('assets/sounds/$name.wav');
      }
      
      if (kDebugMode) {
        print('Loaded sound: $name');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load sound $name: $e');
      }
    }
  }

  /// Load background music for menus
  Future<void> _loadBackgroundMusic() async {
    try {
      if (kIsWeb) {
        _backgroundMusic = await SoLoud.instance.loadAsset(
          'assets/music/menu_background.mp3',
          mode: LoadMode.disk,
        );
      } else {
        _backgroundMusic = await SoLoud.instance.loadAsset(
          'assets/music/menu_background.mp3'
        );
      }
      if (kDebugMode) {
        print('Background music loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load background music: $e');
      }
    }
  }

  /// Sets the playback rate of the currently playing music track.
  /// (Used for speeding up game music based on game speed)
  void setGameMusicPlaybackRate(double rate) {
    if (_musicHandle != null && _currentMusicTrack == 'game_background') {
      try {
        SoLoud.instance.setRelativePlaySpeed(_musicHandle!, rate.clamp(0.1, 4.0));
        if (kDebugMode) {
          print('Music playback rate set to: $rate');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Failed to set playback rate: $e');
        }
      }
    }
  }
  
  /// Load game music for gameplay
  Future<void> _loadGameMusic() async {
    try {
      if (kIsWeb) {
        _gameMusic = await SoLoud.instance.loadAsset(
          'assets/music/game_background.mp3',
          mode: LoadMode.disk,
        );
      } else {
        _gameMusic = await SoLoud.instance.loadAsset(
          'assets/music/game_background.mp3'
        );
      }
      if (kDebugMode) {
        print('Game music loaded successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load game music: $e');
      }
    }
  }

  /// Start background music with looping
  Future<void> _startMusic(AudioSource? musicSource, String trackName) async {
    if (musicSource == null || !_musicEnabled) {
      _pendingMusicTrack = trackName; // Remember what should be playing
      return;
    }
    
    try {
      // Don't restart if already playing the same track
      if (_currentMusicTrack == trackName && _musicHandle != null) {
        // Just update the volume if it's already playing
        _updateMusicVolume();
        return;
      }
      
      // Stop existing music if playing
      await _stopMusic();
      
      // Start the music with looping enabled
      _musicHandle = await SoLoud.instance.play(
        musicSource,
        looping: true,
      );
      
      // Set the music volume immediately after starting
      if (_musicHandle != null) {
        SoLoud.instance.setVolume(_musicHandle!, _musicVolume);
        _currentMusicTrack = trackName;
        _pendingMusicTrack = trackName;
        
        if (kDebugMode) {
          print('Started music track: $trackName with volume: $_musicVolume');
        }
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Failed to start music track $trackName: $e');
      }
    }
  }

  /// Stop current music
  Future<void> _stopMusic() async {
    if (_musicHandle != null) {
      try {
        SoLoud.instance.stop(_musicHandle!);
        _musicHandle = null;
        _currentMusicTrack = null;
        if (kDebugMode) {
          print('Music stopped');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error stopping music: $e');
        }
      }
    }
  }

  /// Update music volume for currently playing music
  void _updateMusicVolume() {
    if (_musicHandle != null && _musicEnabled) {
      SoLoud.instance.setVolume(_musicHandle!, _musicVolume);
      if (kDebugMode) {
        print('Updated music volume to: $_musicVolume');
      }
    }
  }

  /// Resume pending music if music was re-enabled
  Future<void> _resumePendingMusic() async {
    if (_pendingMusicTrack != null && _musicEnabled) {
      final pendingTrack = _pendingMusicTrack!;
      _pendingMusicTrack = null; // Clear to avoid infinite loop
      
      if (pendingTrack == 'menu_background') {
        await startMenuMusic();
      } else if (pendingTrack == 'game_background') {
        await startGameMusic();
      }
    }
  }

  /// Play a sound by its cached AudioSource with volume control
  Future<void> _play(String name) async {
    if (!_soundEnabled || !_isInitialized) return;
    final sound = _sounds[name];
    if (sound == null) {
      if (kDebugMode) {
        print('Sound not found: $name');
      }
      return;
    }

    try {
      await SoLoud.instance.play(
        sound,
        volume: _volume.clamp(0.0, 1.0),
      );

      
      if (kDebugMode) {
        print('Played sound $name with volume: $_volume');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to play sound $name: $e');
      }
    }
  }

  // Public API for music control

  /// Start menu background music
  Future<void> startMenuMusic() async {
    await _startMusic(_backgroundMusic, 'menu_background');
  }

  /// Start game background music
  Future<void> startGameMusic() async {
    await _startMusic(_gameMusic, 'game_background');
  }

  /// Stop all music
  Future<void> stopMusic() async {
    await _stopMusic();
  }

  // Public API for UI sounds

  Future<void> playUIClick() => _play('ui_click');

  // Public API for game sounds - FIXED: Use volumeMultiplier instead of volumeOverride

  Future<void> playPlayerMove() => _play('player_move');
  Future<void> playPlayerDash() => _play('player_dash');
  Future<void> playShapeMorph() => _play('shape_morph');
  Future<void> playObstaclePass() => _play('obstacle_pass');
  
  Future<void> playCollision({bool isX = false}) {
    if (isX) {
      return _play('collision_x');
    } else {
      return _play('collision_shape');
    }
  }

  Future<void> playGameOver() => _play('game_over');
  Future<void> playNewHighScore() => _play('new_high_score');
  Future<void> playPowerUp() => _play('power_up');

  // Advanced game-specific sound methods

  /// Play sound based on current game speed (pitch variation)
  Future<void> playMovementSound(double gameSpeed) async {
    await playPlayerMove();
  }

  /// Play collision sound with haptic feedback integration
  Future<void> playCollisionWithHaptics({bool isX = false}) async {
    await playCollision(isX: isX);
    
    // Trigger haptic feedback if enabled
    if (GameData.vibrateEnabled) {
      if (isX) {
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.mediumImpact();
      }
    }
  }

  /// Play sound sequence for successful obstacle navigation
  Future<void> playSuccessSequence() async {
    await playObstaclePass();
    await Future.delayed(Duration(milliseconds: 100));
  }

  // Settings management with persistence and immediate application

  /// Enable or disable sounds globally and save setting
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await _saveSettings();
    notifyListeners();
    
    if (kDebugMode) {
      print('Sound enabled set to: $enabled');
    }
  }

  /// Enable or disable background music and save setting
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    
    if (!_musicEnabled) {
      await _stopMusic();
    } else {
      // Resume pending music or restart appropriate music
      await _resumePendingMusic();
    }
    
    await _saveSettings();
    notifyListeners();
    
    if (kDebugMode) {
      print('Music enabled set to: $enabled');
    }
  }

  /// Set master volume (0.0 to 1.0) and save setting
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _saveSettings();
    notifyListeners();
    
    if (kDebugMode) {
      print('Volume set to: $_volume (affects new sounds)');
    }
  }

  /// Set music volume (0.0 to 1.0) and save setting - Apply immediately
  Future<void> setMusicVolume(double volume) async {
    _musicVolume = volume.clamp(0.0, 1.0);
    
    // IMPORTANT: Apply the volume change immediately to currently playing music
    _updateMusicVolume();
    
    await _saveSettings();
    notifyListeners();
    
    if (kDebugMode) {
      print('Music volume set to: $_musicVolume and applied to current track');
    }
  }

  // Getters
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get volume => _volume;
  double get musicVolume => _musicVolume;
  bool get isMusicPlaying => _musicHandle != null;
  bool get isInitialized => _isInitialized;

  /// Resume music if it was supposed to be playing
  Future<void> resumeMusic() async {
    if (_musicEnabled) {
      await _resumePendingMusic();
    }
  }

  /// Pause music temporarily (without changing settings)
  Future<void> pauseMusic() async {
    await _stopMusic();
  }

  /// Crossfade between music tracks
  Future<void> crossfadeToGameMusic() async {
    if (!_musicEnabled) {
      _pendingMusicTrack = 'game_background';
      return;
    }
    
    // Simple crossfade: stop current and start new
    await _stopMusic();
    await Future.delayed(Duration(milliseconds: 100));
    await startGameMusic();
    
    // NEW: Apply the initial speed based on the base game speed
    setGameMusicPlaybackRate(1.0); 
    
  }

  Future<void> crossfadeToMenuMusic() async {
    if (!_musicEnabled) {
      _pendingMusicTrack = 'menu_background';
      return;
    }
    
    await _stopMusic();
    await Future.delayed(Duration(milliseconds: 100));
    await startMenuMusic();
  }

  /// Dispose all sounds and deinitialize SoLoud
  @override
  Future<void> dispose() async {
    await _stopMusic();
    
    if (_isInitialized) {
      try {
        await SoLoud.instance.disposeAllSources();
        SoLoud.instance.deinit();
      } catch (e) {
        if (kDebugMode) {
          print('Error disposing AudioService: $e');
        }
      }
    }
    
    _isInitialized = false;
    super.dispose();
  }
}