import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  // Singleton pattern
  static final AdService _instance = AdService._internal();

  factory AdService() => _instance;

  AdService._internal();

  // Your actual AdMob app ID
  static const String appId = 'ca-app-pub-5917361125307707~7798342779';

  // Ad unit IDs - Replace with your actual ad units in production
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544/6300978111' // Test ad unit
          : 'ca-app-pub-5917361125307707/XXXXXXXXXX'; // Your Android ad unit
    } else if (Platform.isIOS) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544/2934735716' // Test ad unit
          : 'ca-app-pub-5917361125307707/XXXXXXXXXX'; // Your iOS ad unit
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544/1033173712' // Test ad unit
          : 'ca-app-pub-5917361125307707/XXXXXXXXXX'; // Your Android ad unit
    } else if (Platform.isIOS) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544/4411468910' // Test ad unit
          : 'ca-app-pub-5917361125307707/XXXXXXXXXX'; // Your iOS ad unit
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544/5224354917' // Test ad unit
          : 'ca-app-pub-5917361125307707/XXXXXXXXXX'; // Your Android ad unit
    } else if (Platform.isIOS) {
      return kDebugMode
          ? 'ca-app-pub-3940256099942544/1712485313' // Test ad unit
          : 'ca-app-pub-5917361125307707/XXXXXXXXXX'; // Your iOS ad unit
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  // Banner ad
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  // Interstitial ad
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdLoaded = false;
  int _interstitialLoadAttempts = 0;
  final int _maxInterstitialLoadAttempts = 3;

  // Rewarded ad
  RewardedAd? _rewardedAd;
  bool _isRewardedAdLoaded = false;
  int _rewardedLoadAttempts = 0;
  final int _maxRewardedLoadAttempts = 3;

  // Getters
  bool get isBannerAdLoaded => _isBannerAdLoaded;

  bool get isInterstitialAdLoaded => _isInterstitialAdLoaded;

  bool get isRewardedAdLoaded => _isRewardedAdLoaded;

  BannerAd? get bannerAd => _bannerAd;

  // Initialize the Mobile Ads SDK
  Future<void> initialize() async {
    // Request non-personalized ads only
    final params = RequestConfiguration(
      tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
      tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
      maxAdContentRating: MaxAdContentRating.pg,
      testDeviceIds: ['kGADSimulatorID'], // Add your test device IDs here
    );
    MobileAds.instance.updateRequestConfiguration(params);

    // Load initial ads
    loadBannerAd();
    loadInterstitialAd();
    loadRewardedAd();
  }

  // Load banner ad
  void loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          debugPrint('Banner ad loaded successfully');
          _isBannerAdLoaded = true;
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: ${error.message}');
          ad.dispose();
          _isBannerAdLoaded = false;

          // Retry after a delay
          Future.delayed(const Duration(minutes: 1), () {
            if (_bannerAd == null) {
              loadBannerAd();
            }
          });
        },
        onAdOpened: (ad) => debugPrint('Banner ad opened'),
        onAdClosed: (ad) => debugPrint('Banner ad closed'),
      ),
    );

    _bannerAd!.load();
  }

  // Load interstitial ad
  void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('Interstitial ad loaded successfully');
          _interstitialAd = ad;
          _isInterstitialAdLoaded = true;
          _interstitialLoadAttempts = 0;

          // Set callback for ad closing
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Interstitial ad dismissed');
              ad.dispose();
              _isInterstitialAdLoaded = false;
              loadInterstitialAd(); // Load the next interstitial
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Interstitial ad failed to show: ${error.message}');
              ad.dispose();
              _isInterstitialAdLoaded = false;
              loadInterstitialAd(); // Try to load another one
            },
            onAdShowedFullScreenContent: (ad) {
              debugPrint('Interstitial ad showed successfully');
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Interstitial ad failed to load: ${error.message}');
          _isInterstitialAdLoaded = false;
          _interstitialLoadAttempts += 1;
          _interstitialAd = null;

          if (_interstitialLoadAttempts < _maxInterstitialLoadAttempts) {
            Future.delayed(const Duration(minutes: 1), () {
              loadInterstitialAd();
            });
          }
        },
      ),
    );
  }

  // Show interstitial ad
  Future<bool> showInterstitialAd() async {
    if (_interstitialAd == null) {
      debugPrint('Interstitial ad not loaded yet');
      return false;
    }

    try {
      await _interstitialAd!.show();
      return true;
    } catch (e) {
      debugPrint('Error showing interstitial ad: $e');
      _interstitialAd!.dispose();
      _isInterstitialAdLoaded = false;
      loadInterstitialAd(); // Try to load another one
      return false;
    }
  }

  // Load rewarded ad
  void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('Rewarded ad loaded successfully');
          _rewardedAd = ad;
          _isRewardedAdLoaded = true;
          _rewardedLoadAttempts = 0;

          // Set callback for ad closing
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('Rewarded ad dismissed');
              ad.dispose();
              _isRewardedAdLoaded = false;
              loadRewardedAd(); // Load the next rewarded ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('Rewarded ad failed to show: ${error.message}');
              ad.dispose();
              _isRewardedAdLoaded = false;
              loadRewardedAd(); // Try to load another one
            },
            onAdShowedFullScreenContent: (ad) {
              debugPrint('Rewarded ad showed successfully');
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Rewarded ad failed to load: ${error.message}');
          _isRewardedAdLoaded = false;
          _rewardedLoadAttempts += 1;
          _rewardedAd = null;

          if (_rewardedLoadAttempts < _maxRewardedLoadAttempts) {
            Future.delayed(const Duration(minutes: 1), () {
              loadRewardedAd();
            });
          }
        },
      ),
    );
  }

  // Show rewarded ad
  Future<bool> showRewardedAd(
      {required Function(RewardItem reward) onUserEarnedReward}) async {
    if (_rewardedAd == null) {
      debugPrint('Rewarded ad not loaded yet');
      return false;
    }

    try {
      await _rewardedAd!.show(
          onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        onUserEarnedReward(reward);
      });
      return true;
    } catch (e) {
      debugPrint('Error showing rewarded ad: $e');
      _rewardedAd!.dispose();
      _isRewardedAdLoaded = false;
      loadRewardedAd(); // Try to load another one
      return false;
    }
  }

  // Dispose ads
  void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    _rewardedAd = null;
    _isBannerAdLoaded = false;
    _isInterstitialAdLoaded = false;
    _isRewardedAdLoaded = false;
  }
}
