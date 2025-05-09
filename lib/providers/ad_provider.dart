import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_service.dart';

class AdProvider extends ChangeNotifier {
  final AdService _adService = AdService();
  bool _showBannerAd = true;
  int _interstitialAdCounter = 0;
  final int _interstitialAdThreshold = 5; // Show interstitial ad every 5 actions

  // Getters
  bool get showBannerAd => _showBannerAd;
  bool get isBannerAdLoaded => _adService.isBannerAdLoaded;
  bool get isInterstitialAdLoaded => _adService.isInterstitialAdLoaded;
  bool get isRewardedAdLoaded => _adService.isRewardedAdLoaded;
  BannerAd? get bannerAd => _adService.bannerAd;

  // Initialize ads
  Future<void> initialize() async {
    await _adService.initialize();
    notifyListeners();
  }

  // Toggle banner ad visibility
  void toggleBannerAd() {
    _showBannerAd = !_showBannerAd;
    notifyListeners();
  }

  // Increment counter and show interstitial ad if threshold is reached
  Future<bool> incrementCounterAndShowInterstitialAd() async {
    _interstitialAdCounter++;

    if (_interstitialAdCounter >= _interstitialAdThreshold) {
      _interstitialAdCounter = 0;
      return await showInterstitialAd();
    }

    return false;
  }

  // Show interstitial ad
  Future<bool> showInterstitialAd() async {
    final result = await _adService.showInterstitialAd();
    notifyListeners();
    return result;
  }

  // Show rewarded ad
  Future<bool> showRewardedAd({required Function(RewardItem reward) onUserEarnedReward}) async {
    final result = await _adService.showRewardedAd(onUserEarnedReward: onUserEarnedReward);
    notifyListeners();
    return result;
  }

  // Reload banner ad
  void reloadBannerAd() {
    _adService.loadBannerAd();
    notifyListeners();
  }

  // Dispose ads
  @override
  void dispose() {
    _adService.dispose();
    super.dispose();
  }
}
