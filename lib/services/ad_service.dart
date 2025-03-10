import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:final_application/models/user_subscription.dart';
import 'package:final_application/services/subscription_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // Test ad units - replace with real ones for production
  static String _testBannerAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716';

  static String _testInterstitialAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';

  static String _testRewardedAdUnitId =
      Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';

  // Subscription service
  final SubscriptionService _subscriptionService = SubscriptionService.instance;

  // Banner ad
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // Interstitial ad
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;

  // Rewarded ad
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;

  // Flag to indicate if ads are enabled
  bool _adsEnabled = false;
  bool _isInitialized = false;

  // Getters
  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;
  bool get isRewardedAdLoaded => _isRewardedAdLoaded;
  bool get adsEnabled => _adsEnabled;
  bool get isInitialized => _isInitialized;

  // Singleton pattern with proper initialization
  static AdService? _instance;
  static AdService get instance {
    _instance ??= AdService._internal();
    return _instance!;
  }

  factory AdService() => instance;

  AdService._internal();

  // Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Temporarily disable ads completely to avoid crashes
      print('Ads disabled temporarily');
      _adsEnabled = false;
      _isInitialized = true;
      return;

      // The code below is commented out until proper AdMob setup is done
      /*
      await MobileAds.instance.initialize();
      _adsEnabled = true;
      
      // Only load ads for free users
      if (!_subscriptionService.subscription.isProActive) {
        loadBannerAd();
        loadInterstitialAd();
        loadRewardedAd();
      }
      
      // Listen for subscription changes
      _subscriptionService.subscriptionStream.listen((subscription) {
        if (subscription.isProActive) {
          // Dispose ads for Pro users
          disposeBannerAd();
          disposeInterstitialAd();
          disposeRewardedAd();
        } else if (_adsEnabled) {
          // Reload ads for free users
          loadBannerAd();
          loadInterstitialAd();
          loadRewardedAd();
        }
      });
      */
    } catch (e) {
      print('Failed to initialize ads: $e');
      _adsEnabled = false;
      _isInitialized =
          true; // Still mark as initialized to avoid repeated attempts
    }
  }

  // Load a banner ad
  void loadBannerAd() {
    if (!_adsEnabled) return;

    try {
      _bannerAd = BannerAd(
        adUnitId: _testBannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isBannerAdLoaded = true;
          },
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
            _bannerAd = null;
            _isBannerAdLoaded = false;
            print('Banner ad failed to load: $error');
          },
        ),
      );

      _bannerAd?.load();
    } catch (e) {
      print('Error loading banner ad: $e');
      _isBannerAdLoaded = false;
    }
  }

  // Load an interstitial ad
  void loadInterstitialAd() {
    if (!_adsEnabled) return;

    try {
      InterstitialAd.load(
        adUnitId: _testInterstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdLoaded = true;
          },
          onAdFailedToLoad: (error) {
            _isInterstitialAdLoaded = false;
            print('Interstitial ad failed to load: $error');
          },
        ),
      );
    } catch (e) {
      print('Error loading interstitial ad: $e');
      _isInterstitialAdLoaded = false;
    }
  }

  // Load a rewarded ad
  void loadRewardedAd() {
    if (!_adsEnabled) return;

    try {
      RewardedAd.load(
        adUnitId: _testRewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
          },
          onAdFailedToLoad: (error) {
            _isRewardedAdLoaded = false;
            print('Rewarded ad failed to load: $error');
          },
        ),
      );
    } catch (e) {
      print('Error loading rewarded ad: $e');
      _isRewardedAdLoaded = false;
    }
  }

  // Show an interstitial ad
  Future<void> showInterstitialAd() async {
    if (!_adsEnabled || !_isInitialized) return;

    if (_subscriptionService.subscription.isProActive) {
      return; // Don't show ads to Pro users
    }

    if (!_isInterstitialAdLoaded) {
      loadInterstitialAd();
      return;
    }

    try {
      _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isInterstitialAdLoaded = false;
          loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isInterstitialAdLoaded = false;
          loadInterstitialAd();
          print('Failed to show interstitial ad: $error');
        },
      );

      await _interstitialAd?.show();
    } catch (e) {
      print('Error showing interstitial ad: $e');
    }
  }

  // Show a rewarded ad
  Future<void> showRewardedAd({Function(RewardItem)? onRewarded}) async {
    // Always give the reward regardless of ad status for now
    onRewarded?.call(RewardItem(5, 'tokens'));
    return;

    /*
    if (_subscriptionService.subscription.isProActive) {
      // Pro users automatically get the reward
      onRewarded?.call(const RewardItem(amount: 5, type: 'tokens'));
      return;
    }
    
    if (!_adsEnabled || !_isInitialized) {
      // If ads are disabled, still give the reward
      onRewarded?.call(const RewardItem(amount: 5, type: 'tokens'));
      return;
    }
    
    if (!_isRewardedAdLoaded) {
      loadRewardedAd();
      // Still give the reward in debug mode
      if (kDebugMode) {
        onRewarded?.call(const RewardItem(amount: 5, type: 'tokens'));
      }
      return;
    }
    
    try {
      _rewardedAd?.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _isRewardedAdLoaded = false;
          loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _isRewardedAdLoaded = false;
          loadRewardedAd();
          print('Failed to show rewarded ad: $error');
        },
      );
      
      await _rewardedAd?.show(
        onUserEarnedReward: (ad, reward) {
          onRewarded?.call(reward);
        },
      );
    } catch (e) {
      print('Error showing rewarded ad: $e');
      // Still give the reward in debug mode
      if (kDebugMode) {
        onRewarded?.call(const RewardItem(amount: 5, type: 'tokens'));
      }
    }
    */
  }

  // Dispose of banner ad
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }

  // Dispose of interstitial ad
  void disposeInterstitialAd() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdLoaded = false;
  }

  // Dispose of rewarded ad
  void disposeRewardedAd() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdLoaded = false;
  }

  // Dispose of all resources
  void dispose() {
    disposeBannerAd();
    disposeInterstitialAd();
    disposeRewardedAd();
  }
}
