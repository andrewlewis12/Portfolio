import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

import 'package:morph_runner/services/audio_service.dart';

class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  AdService._();
  int _gamesPlayed = 0;

  // Separate banner ads for different screens
  BannerAd? _homeBannerAd;
  BannerAd? _gameBannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  bool _homeBannerAdLoaded = false;
  bool _gameBannerAdLoaded = false;
  bool _interstitialAdLoaded = false;
  bool _rewardedAdLoaded = false;
  
  // Track which screen is currently active
  bool _homeScreenActive = false;
  bool _gameScreenActive = false;
  
  // Simplified tracking - show interstitial on every game start/restart
  DateTime? _lastInterstitialShown;
  static const int _minSecondsBetweenInterstitials = 5;
  
  // Flag to track if we should show an interstitial on next game start
  bool _shouldShowInterstitialOnNextGame = false;

  // Test ad unit IDs (replace with real ones for production)
  static final String _bannerAdUnitId = kDebugMode 
      ? 'ca-app-pub-3940256099942544/6300978111' // Test banner
      : Platform.isAndroid
          ? 'ca-app-pub-8089459076917347/8423304905'
          : 'ca-app-pub-PUBLISHER_ID/IOS_BANNER_ID';
          
  static final String _interstitialAdUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/1033173712' // Test interstitial
      : Platform.isAndroid
          ? 'ca-app-pub-8089459076917347/5126724582'
          : 'ca-app-pub-PUBLISHER_ID/IOS_INTERSTITIAL_ID';
          
  static final String _rewardedAdUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917' // Test rewarded
      : Platform.isAndroid
          ? 'ca-app-pub-8089459076917347/7891438978'
          : 'ca-app-pub-PUBLISHER_ID/IOS_REWARDED_ID';

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    
    // Set request configuration for better ad targeting
    final RequestConfiguration requestConfig = RequestConfiguration(
      testDeviceIds: kDebugMode ? ['TEST_DEVICE_ID'] : [],
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
      tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
    );
    MobileAds.instance.updateRequestConfiguration(requestConfig);
    
    // Preload ads
    _loadHomeBannerAd();
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  void _loadHomeBannerAd() {
    print('Loading new home banner ad...');
    _homeBannerAd?.dispose();
    _homeBannerAd = null;
    _homeBannerAdLoaded = false;
    
    _homeBannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Home banner ad loaded successfully');
          _homeBannerAdLoaded = true;
        },
        onAdFailedToLoad: (ad, error) {
          print('Home banner ad failed to load: $error');
          _homeBannerAdLoaded = false;
          ad.dispose();
          _homeBannerAd = null;
          // Retry after delay
          Future.delayed(Duration(seconds: 10), () {
            if (_homeScreenActive) {
              _loadHomeBannerAd();
            }
          });
        },
        onAdOpened: (ad) => print('Home banner ad opened'),
        onAdClosed: (ad) => print('Home banner ad closed'),
        onAdImpression: (ad) => print('Home banner ad impression'),
      ),
    );
    _homeBannerAd?.load();
  }

  void _loadGameBannerAd() {
    _gameBannerAd?.dispose();
    _gameBannerAd = null;
    _gameBannerAdLoaded = false;
    
    _gameBannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('Game banner ad loaded');
          _gameBannerAdLoaded = true;
        },
        onAdFailedToLoad: (ad, error) {
          print('Game banner ad failed to load: $error');
          _gameBannerAdLoaded = false;
          ad.dispose();
          _gameBannerAd = null;
          // Retry after delay
          Future.delayed(Duration(seconds: 10), () => _loadGameBannerAd());
        },
        onAdOpened: (ad) => print('Game banner ad opened'),
        onAdClosed: (ad) => print('Game banner ad closed'),
        onAdImpression: (ad) => print('Game banner ad impression'),
      ),
    );
    _gameBannerAd?.load();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('Interstitial ad loaded');
          _interstitialAd = ad;
          _interstitialAdLoaded = true;
          
          _interstitialAd?.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          print('Interstitial ad failed to load: $error');
          _interstitialAdLoaded = false;
          // Retry after delay
          Future.delayed(Duration(seconds: 15), () => _loadInterstitialAd());
        },
      ),
    );
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('Rewarded ad loaded');
          _rewardedAd = ad;
          _rewardedAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
          _rewardedAdLoaded = false;
          // Retry after delay
          Future.delayed(Duration(seconds: 20), () => _loadRewardedAd());
        },
      ),
    );
  }

  // FIXED: Get home banner ad widget with proper state management and unique keys
  Widget? getHomeBannerAdWidget() {
    // Double-check that the ad is still valid
    if (_homeBannerAdLoaded && _homeBannerAd != null) {
      try {
        // Create a completely new widget instance with a unique key to prevent reuse
        return Container(
          key: ValueKey('home_banner_${_homeBannerAd.hashCode}_${DateTime.now().millisecondsSinceEpoch}'),
          width: _homeBannerAd!.size.width.toDouble(),
          height: _homeBannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _homeBannerAd!),
        );
      } catch (e) {
        print('Error creating home banner AdWidget: $e');
        // If there's an error, mark as not loaded and reload
        _homeBannerAdLoaded = false;
        Future.microtask(() => _loadHomeBannerAd());
        return null;
      }
    }
    return null;
  }

  // Get game banner ad widget
  Widget? getGameBannerAdWidget() {
    if (_gameBannerAdLoaded && _gameBannerAd != null) {
      return Container(
        width: _gameBannerAd!.size.width.toDouble(),
        height: _gameBannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _gameBannerAd!),
      );
    }
    return null;
  }

  // Legacy method for backward compatibility - returns home banner
  Widget? getBannerAdWidget() {
    return getHomeBannerAdWidget();
  }

  // FIXED: Home screen lifecycle management with proper delays
  void onHomeScreenCreated() {
    print('Home screen created');
    _homeScreenActive = true;
    
    // Wait a frame before loading the ad to ensure clean state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(milliseconds: 300), () {
        if (_homeScreenActive) {
          _loadHomeBannerAd();
        }
      });
    });
  }

  void onHomeScreenDisposed() {
    print('Home screen disposed');
    _homeScreenActive = false;
    
    // Immediately dispose the home banner ad and clear state
    if (_homeBannerAd != null) {
      _homeBannerAd!.dispose();
      _homeBannerAd = null;
    }
    _homeBannerAdLoaded = false;
  }

  // Call this when game screen is created
  void onGameScreenCreated() {
    _gameScreenActive = true;
    if (!_gameBannerAdLoaded || _gameBannerAd == null) {
      _loadGameBannerAd();
    }
  }

  // Call this when game screen is disposed
  void onGameScreenDisposed() {
    _gameScreenActive = false;
    _gameBannerAd?.dispose();
    _gameBannerAd = null;
    _gameBannerAdLoaded = false;
  }

  // FIXED: Better navigation handling
  void onNavigatingToHome() {
    _homeScreenActive = true;
    // Ensure home banner ad is ready
    if (!_homeBannerAdLoaded || _homeBannerAd == null) {
      _loadHomeBannerAd();
    }
  }

  void onNavigatingToGame() {
    _gameScreenActive = true;
    // Prepare game banner ad
    if (!_gameBannerAdLoaded || _gameBannerAd == null) {
      _loadGameBannerAd();
    }
  }

  // Show interstitial ad
  Future<bool> showInterstitialAd() async {
    if (!_shouldShowInterstitial()) {
      return false;
    }

    
    if (_interstitialAdLoaded && _interstitialAd != null) {
      final completer = Completer<bool>();
      AudioService.instance.stopMusic();

      _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          print('Interstitial ad dismissed');
          ad.dispose();
          _interstitialAdLoaded = false;
          _lastInterstitialShown = DateTime.now();
          _loadInterstitialAd();
          completer.complete(true);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Interstitial ad failed to show: $error');
          ad.dispose();
          _interstitialAdLoaded = false;
          _loadInterstitialAd();
          completer.complete(false);
        },
        onAdShowedFullScreenContent: (ad) {
          print('Interstitial ad showed');
        },
      );

      _interstitialAd?.show();
      return await completer.future;
    }

    print('Interstitial ad not ready to show');
    return false;
  }

  // Show rewarded ad with callback
  Future<bool> showRewardedAd({
    required Function() onUserEarnedReward,
    Function()? onAdDismissed,
  }) async {
    if (_rewardedAdLoaded && _rewardedAd != null) {
      AudioService.instance.stopMusic();
      _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          AudioService.instance.resumeMusic();
          ad.dispose();
          _rewardedAdLoaded = false;
          onAdDismissed?.call();
          _loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          AudioService.instance.resumeMusic();
          print('Rewarded ad failed to show: $error');
          ad.dispose();
          _rewardedAdLoaded = false;
          _loadRewardedAd();
        },
      );

      await _rewardedAd?.show(
        onUserEarnedReward: (ad, reward) {
          AudioService.instance.resumeMusic();
          print('User earned reward: ${reward.amount} ${reward.type}');
          onUserEarnedReward();
        },
      );
      return true;
    }
    return false;
  }

  void onGameStartFromHome() {
    onNavigatingToGame(); // Only prepare banners
  }

  // Call this when a game ends (for restart scenarios)
  void onGameEnd() {
    _gamesPlayed++;

    // Show interstitial every third game
    _shouldShowInterstitialOnNextGame = _gamesPlayed % 3 == 0;
  }

  bool _shouldShowInterstitial() {
    if (_lastInterstitialShown != null) {
      final secondsSinceLastAd = DateTime.now()
          .difference(_lastInterstitialShown!)
          .inSeconds;
      if (secondsSinceLastAd < _minSecondsBetweenInterstitials) {
        print('Too soon since last interstitial: ${secondsSinceLastAd}s');
        return false;
      }
    }

    bool shouldShow = _shouldShowInterstitialOnNextGame && _interstitialAdLoaded;
    
    if (shouldShow) {
      _shouldShowInterstitialOnNextGame = false;
    }
    
    return shouldShow;
  }

  // Force show interstitial (for testing or special cases)
  Future<bool> forceShowInterstitialAd() async {
    if (_interstitialAdLoaded && _interstitialAd != null) {
      _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAdLoaded = false;
          _lastInterstitialShown = DateTime.now();
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          print('Force interstitial ad failed to show: $error');
          ad.dispose();
          _interstitialAdLoaded = false;
          _loadInterstitialAd();
        },
      );

      await _interstitialAd?.show();
      return true;
    }
    return false;
  }

  // Check if ads are available
  bool get isHomeBannerAdReady => _homeBannerAdLoaded && _homeBannerAd != null;
  bool get isGameBannerAdReady => _gameBannerAdLoaded && _gameBannerAd != null;
  bool get isBannerAdReady => isHomeBannerAdReady; // Legacy compatibility
  bool get isInterstitialAdReady => _interstitialAdLoaded;
  bool get isRewardedAdReady => _rewardedAdLoaded;

  // Get banner ad height for layout calculations
  double get bannerHeight => 50.0;

  // Refresh banner ads if needed
  void refreshHomeBannerAd() {
    _loadHomeBannerAd();
  }

  void refreshGameBannerAd() {
    _loadGameBannerAd();
  }

  // Legacy method for backward compatibility
  void refreshBannerAd() {
    refreshHomeBannerAd();
  }
  
  // General screen disposal method (deprecated - use specific methods)
  void onScreenDisposed() {
    // This method is now deprecated, use specific disposal methods
  }

  // Dispose all ads
  void dispose() {
    _homeBannerAd?.dispose();
    _gameBannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}