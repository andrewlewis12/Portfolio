import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'storage_service.dart';

class AudioService extends ChangeNotifier {
  final StorageService _storageService;
  final Map<String, AudioSource> _sounds = {};
  AudioSource? _backgroundMusic;
  SoundHandle? _musicHandle;
  
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _volume = 0.7; // Default volume at 70%
  double _musicVolume = 0.4; // Default music volume at 40%

  AudioService({required StorageService storageService}) 
      : _storageService = storageService;

  /// Initialize SoLoud and preload all sound assets, load settings
  Future<void> init() async {
    await SoLoud.instance.init();
    
    // Load saved settings
    await _loadSettings();

    // Preload sounds from assets into memory
    await _loadSound('ui_click');
    await _loadSound('piece_place');
    await _loadSound('line_clear');
    await _loadSound('combo_low');
    await _loadSound('combo_medium');
    await _loadSound('combo_high');
    await _loadSound('game_over');
    await _loadSound('level_up');
    await _loadSound('gravity_fall');
    
    // Load and start background music
    await _loadBackgroundMusic();
    if (_musicEnabled) {
      await _startBackgroundMusic();
    }
  }

  /// Load settings from storage
  Future<void> _loadSettings() async {
    _soundEnabled = await _storageService.getBool('sound_enabled') ?? true;
    _musicEnabled = await _storageService.getBool('music_enabled') ?? true;
    
    final volInt = await _storageService.getInt('volume');
    _volume = (volInt != null ? volInt.toDouble() / 100.0 : 0.7);
    
    final musicVolInt = await _storageService.getInt('music_volume');
    _musicVolume = (musicVolInt != null ? musicVolInt.toDouble() / 100.0 : 0.4);
    
    // Ensure volumes are within valid range
    _volume = _volume.clamp(0.0, 1.0);
    _musicVolume = _musicVolume.clamp(0.0, 1.0);
    
    notifyListeners();
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    await _storageService.saveBool('sound_enabled', _soundEnabled);
    await _storageService.saveBool('music_enabled', _musicEnabled);
    await _storageService.saveInt('volume', (_volume * 100).round());
    await _storageService.saveInt('music_volume', (_musicVolume * 100).round());
  }

  /// Loads sound from assets and caches it for instant play
  Future<void> _loadSound(String name) async {
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
  }

  /// Load background music
  Future<void> _loadBackgroundMusic() async {
    try {
      if (kIsWeb) {
        _backgroundMusic = await SoLoud.instance.loadAsset(
          'assets/music/background.mp3',
          mode: LoadMode.disk,
        );
      } else {
        _backgroundMusic = await SoLoud.instance.loadAsset(
          'assets/music/background.mp3'
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

  /// Start background music with looping
  Future<void> _startBackgroundMusic() async {
    if (_backgroundMusic == null || !_musicEnabled) return;
    
    try {
      // Stop existing music if playing
      await _stopBackgroundMusic();
      
      // Start the music with looping enabled
      _musicHandle = await SoLoud.instance.play(
        _backgroundMusic!,
        looping: true, // Enable looping
      );
      
      // Set the music volume
      if (_musicHandle != null) {
        SoLoud.instance.setVolume(_musicHandle!, _musicVolume);
      }
      
      if (kDebugMode) {
        print('Background music started with handle: $_musicHandle');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to start background music: $e');
      }
    }
  }

  /// Stop background music
  Future<void> _stopBackgroundMusic() async {
    if (_musicHandle != null) {
      try {
        SoLoud.instance.stop(_musicHandle!);
        _musicHandle = null;
        if (kDebugMode) {
          print('Background music stopped');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error stopping background music: $e');
        }
      }
    }
  }

  /// Update music volume for currently playing music
  void _updateMusicVolume() {
    if (_musicHandle != null && _musicEnabled) {
      SoLoud.instance.setVolume(_musicHandle!, _musicVolume);
    }
  }

  /// Play a sound by its cached AudioSource with volume control
  Future<void> _play(String name) async {
    if (!_soundEnabled) return;
    final sound = _sounds[name];
    if (sound == null) return;

    final handle = await SoLoud.instance.play(sound);
    // Set volume for this specific sound instance
    SoLoud.instance.setVolume(handle, _volume);
  }

  // Public API for individual sounds

  Future<void> playUIClick() => _play('ui_click');
  Future<void> playPiecePlace() => _play('piece_place');
  Future<void> playLineClear() => _play('line_clear');

  Future<void> playCombo(int comboLevel) {
    if (comboLevel <= 3) return _play('combo_low');
    if (comboLevel <= 6) return _play('combo_medium');
    return _play('combo_high');
  }

  Future<void> playGameOver() => _play('game_over');
  Future<void> playLevelUp() => _play('level_up');
  Future<void> playGravityFall() => _play('gravity_fall');

  // Settings management with persistence

  /// Enable or disable sounds globally and save setting
  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
    _saveSettings();
    notifyListeners();
  }

  /// Enable or disable background music and save setting
  Future<void> setMusicEnabled(bool enabled) async {
    _musicEnabled = enabled;
    
    if (_musicEnabled) {
      await _startBackgroundMusic();
    } else {
      await _stopBackgroundMusic();
    }
    
    _saveSettings();
    notifyListeners();
  }

  /// Set master volume (0.0 to 1.0) and save setting
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    _saveSettings();
    notifyListeners();
  }

  /// Set music volume (0.0 to 1.0) and save setting
  void setMusicVolume(double volume) {
    _musicVolume = volume.clamp(0.0, 1.0);
    _updateMusicVolume();
    _saveSettings();
    notifyListeners();
  }

  // Getters
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get volume => _volume;
  double get musicVolume => _musicVolume;
  bool get isMusicPlaying => _musicHandle != null;


  /// Resume music if it was supposed to be playing
  Future<void> resumeMusic() async {
    if (_musicEnabled && _musicHandle == null && _backgroundMusic != null) {
      await _startBackgroundMusic();
    }
  }

  /// Pause music temporarily (without changing settings)
  Future<void> pauseMusic() async {
    await _stopBackgroundMusic();
  }

  /// Dispose all sounds and deinitialize SoLoud
  @override
  Future<void> dispose() async {
    await _stopBackgroundMusic();
    await SoLoud.instance.disposeAllSources();
    SoLoud.instance.deinit();
    super.dispose();
  }
}