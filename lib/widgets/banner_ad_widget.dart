import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';

class BannerAdWidget extends StatelessWidget {
  const BannerAdWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adProvider = Provider.of<AdProvider>(context);

    if (!adProvider.showBannerAd) {
      return const SizedBox.shrink();
    }

    if (!adProvider.isBannerAdLoaded || adProvider.bannerAd == null) {
      return Container(
        height: 50,
        color: Colors.grey.withOpacity(0.2),
        child: const Center(
          child: Text('Ad is loading...'),
        ),
      );
    }

    return Container(
      height: adProvider.bannerAd!.size.height.toDouble(),
      width: adProvider.bannerAd!.size.width.toDouble(),
      child: AdWidget(ad: adProvider.bannerAd!),
    );
  }
}
