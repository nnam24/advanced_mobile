import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ad_provider.dart';
import '../providers/subscription_provider.dart';

class EarnTokensWidget extends StatelessWidget {
  const EarnTokensWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final adProvider = Provider.of<AdProvider>(context);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Earn Free Tokens',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Watch a short video ad to earn 10 free tokens!',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: adProvider.isRewardedAdLoaded
                    ? () async {
                        final result = await adProvider.showRewardedAd(
                          onUserEarnedReward: (reward) async {
                            // Add tokens to user's account
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Congratulations! You earned ${reward.amount} tokens!'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            
                            // Refresh token usage data
                            await subscriptionProvider.fetchTokenUsage();
                          },
                        );
                        
                        if (!result) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to load ad. Please try again later.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    : null,
                icon: const Icon(Icons.videocam),
                label: Text(
                  adProvider.isRewardedAdLoaded
                      ? 'Watch Ad to Earn Tokens'
                      : 'Loading Ad...',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
