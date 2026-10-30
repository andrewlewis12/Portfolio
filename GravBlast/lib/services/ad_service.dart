// Updated ad_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'audio_service.dart';

class AdService extends ChangeNotifier {
  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  
  bool _isBannerAdReady = false;
  bool _isInterstitialAdReady = false;
  bool _isRewardedAdReady = false;
  bool _isLoadingBannerAd = false;
  
  // NEW: Track rewarded ad state
  bool _isRewardedAdShowing = false;
  bool _hasReceivedReward = false;
  VoidCallback? _onRewardedCallback;
  BuildContext? _currentContext;
  
  static const String _bannerAdUnitId = kDebugMode 
    ? 'ca-app-pub-3940256099942544/6300978111'
    : 'ca-app-pub-8089459076917347/3026254982';
    
  static const String _interstitialAdUnitId = kDebugMode
    ? 'ca-app-pub-3940256099942544/1033173712'
    : 'ca-app-pub-8089459076917347/1469630734';
    
  static const String _rewardedAdUnitId = kDebugMode
    ? 'ca-app-pub-3940256099942544/5224354917'
    : 'ca-app-pub-8089459076917347/1253136175';
  
  // NEW: Getters for rewarded ad state
  bool get isRewardedAdShowing => _isRewardedAdShowing;
  bool get hasReceivedReward => _hasReceivedReward;
  
  Future<void> init() async {
    await _loadBannerAd();
    _loadInterstitialAd();
    _loadRewardedAd();
  }
  
  Future<void> _loadBannerAd() async {
    // Prevent multiple simultaneous loads
    if (_isLoadingBannerAd) {
      if (kDebugMode) {
        print('Banner ad already loading, skipping...');
      }
      return;
    }
    
    _isLoadingBannerAd = true;
    
    // Dispose existing banner ad first
    if (_bannerAd != null) {
      if (kDebugMode) {
        print('Disposing existing banner ad...');
      }
      await _bannerAd!.dispose();
      _bannerAd = null;
      _isBannerAdReady = false;
    }
    
    if (kDebugMode) {
      print('Creating new banner ad...');
    }
    
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (kDebugMode) {
            print('Banner ad loaded successfully');
          }
          _isBannerAdReady = true;
          _isLoadingBannerAd = false;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, err) {
          if (kDebugMode) {
            print('Banner ad failed to load: $err');
          }
          _isBannerAdReady = false;
          _isLoadingBannerAd = false;
          ad.dispose();
          _bannerAd = null;
          notifyListeners();
          
          // Retry after delay
          Future.delayed(const Duration(seconds: 5), () {
            if (!_isBannerAdReady && !_isLoadingBannerAd) {
              _loadBannerAd();
            }
          });
        },
        onAdImpression: (ad) {
          if (kDebugMode) {
            print('Banner ad impression recorded');
          }
        },
        onAdClicked: (ad) {
          if (kDebugMode) {
            print('Banner ad clicked');
          }
        },
        onAdClosed: (ad) {
          if (kDebugMode) {
            print('Banner ad closed');
          }
        },
        onAdOpened: (ad) {
          if (kDebugMode) {
            print('Banner ad opened');
          }
        },
      ),
    );
    
    try {
      await _bannerAd!.load();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading banner ad: $e');
      }
      _isLoadingBannerAd = false;
      _isBannerAdReady = false;
      _bannerAd?.dispose();
      _bannerAd = null;
      notifyListeners();
    }
  }
  
  void _loadInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.dispose();
      _interstitialAd = null;
      _isInterstitialAdReady = false;
    }
    
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialAd!.setImmersiveMode(true);
          notifyListeners();
          if (kDebugMode) {
            print('Interstitial ad loaded');
          }
        },
        onAdFailedToLoad: (error) {
          _isInterstitialAdReady = false;
          notifyListeners();
          if (kDebugMode) {
            print('Interstitial ad failed to load: $error');
          }
        },
      ),
    );
  }
  
  void _loadRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.dispose();
      _rewardedAd = null;
      _isRewardedAdReady = false;
    }
    
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          notifyListeners();
          if (kDebugMode) {
            print('Rewarded ad loaded');
          }
        },
        onAdFailedToLoad: (error) {
          _isRewardedAdReady = false;
          notifyListeners();
          if (kDebugMode) {
            print('Rewarded ad failed to load: $error');
          }
        },
      ),
    );
  }
  
  // FIXED: Return banner ad only if it's actually ready and not disposed
  BannerAd? get bannerAd {
    if (kDebugMode) {
      print('bannerAd getter called: ready=$_isBannerAdReady, ad exists=${_bannerAd != null}');
    }
    
    if (_isBannerAdReady && _bannerAd != null) {
      if (kDebugMode) {
        print('Returning banner ad');
      }
      return _bannerAd;
    }
    
    if (kDebugMode) {
      print('Banner ad not ready or null');
    }
    return null;
  }
  
  bool get isRewardedAdReady => _isRewardedAdReady;
  bool get isBannerAdReady => _isBannerAdReady;
  bool get isLoadingBannerAd => _isLoadingBannerAd;
  
  void showInterstitialAd() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadInterstitialAd();
          if (kDebugMode) {
            print('Interstitial ad failed to show: $error');
          }
        },
        onAdShowedFullScreenContent: (ad) {
          if (kDebugMode) {
            print('Interstitial ad showed');
          }
        },
      );

      _interstitialAd!.show();
      _interstitialAd = null;
      _isInterstitialAdReady = false;
    } else {
      if (kDebugMode) {
        print('Interstitial ad not ready');
      }
    }
  }

  // NEW: Updated showRewardedAd with confirmation support
  void showRewardedAd(VoidCallback onRewarded, [BuildContext? context]) {
    if (_isRewardedAdReady && _rewardedAd != null) {
      // Store callback and context for potential confirmation dialog
      _onRewardedCallback = onRewarded;
      _currentContext = context;
      _isRewardedAdShowing = true;
      _hasReceivedReward = false;
      
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          if (kDebugMode) {
            print('Rewarded ad dismissed. Reward received: $_hasReceivedReward');
          }
          
          // If user closed ad without receiving reward, show confirmation
          if (!_hasReceivedReward && _currentContext != null) {
            _showRewardCancelConfirmation();
          } else {
            // Clean up normally
            _cleanupRewardedAd();
          }
          
          ad.dispose();
          _loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          if (kDebugMode) {
            print('Rewarded ad failed to show: $error');
          }
          _cleanupRewardedAd();
          ad.dispose();
          _loadRewardedAd();
        },
        onAdShowedFullScreenContent: (ad) {
          if (kDebugMode) {
            print('Rewarded ad showed');
          }
        },
      );
      
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          if (kDebugMode) {
            print('User earned reward: ${reward.type} ${reward.amount}');
          }
          _hasReceivedReward = true;
          _onRewardedCallback?.call();
          _cleanupRewardedAd();
        },
      );
      
      _rewardedAd = null;
      _isRewardedAdReady = false;
    } else {
      if (kDebugMode) {
        print('Rewarded ad not ready');
      }
    }
  }
  
  // NEW: Show confirmation when user closes ad without reward
  void _showRewardCancelConfirmation() {
    if (_currentContext == null) {
      _cleanupRewardedAd();
      return;
    }
    
    showDialog(
      context: _currentContext!,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.orange.withOpacity(0.5),
            width: 2,
          ),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Reward Cancelled',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'You closed the ad before receiving your reward!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(Icons.cancel, color: Colors.red, size: 32),
                  const SizedBox(height: 8),
                  const Text(
                    'No Bonus Points',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'No Extra Piece',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Game Over Continues',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'To get rewards, you need to watch the complete ad.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          // Try Again Button (if another ad is available)
          if (_isRewardedAdReady)
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Show the rewarded ad again
                Future.delayed(const Duration(milliseconds: 100), () {
                  showRewardedAd(_onRewardedCallback!, _currentContext);
                });
              },
              icon: Icon(Icons.replay, color: Colors.green, size: 20),
              label: const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          // Continue Button
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _cleanupRewardedAd();
            },
            icon: Icon(Icons.check, color: Colors.cyan, size: 20),
            label: const Text(
              'Continue',
              style: TextStyle(
                color: Colors.cyan,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    ).then((_) {
      // Ensure cleanup happens even if dialog is dismissed
      _cleanupRewardedAd();
    });
  }
  
  // NEW: Clean up rewarded ad state
  void _cleanupRewardedAd() {
    _isRewardedAdShowing = false;
    _hasReceivedReward = false;
    _onRewardedCallback = null;
    _currentContext = null;
    notifyListeners();
  }
  
  // NEW: Force refresh banner ad (for menu screen)
  Future<void> refreshBannerAd() async {
    if (kDebugMode) {
      print('Refreshing banner ad...');
    }
    await _loadBannerAd();
  }
  
  // NEW: Reset state without disposing (for navigation)
  void resetBannerAdState() {
    // Don't dispose the ad, just notify listeners
    notifyListeners();
  }
  
  // NEW: Force refresh all ads
  void refreshAllAds() {
    refreshBannerAd();
    if (!_isInterstitialAdReady) {
      _loadInterstitialAd();
    }
    if (!_isRewardedAdReady) {
      _loadRewardedAd();
    }
  }
  
  @override
  void dispose() {
    if (kDebugMode) {
      print('Disposing AdService...');
    }
    _cleanupRewardedAd();
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}