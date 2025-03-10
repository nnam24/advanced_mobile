import 'package:flutter/material.dart';
import 'package:final_application/models/user_subscription.dart';
import 'package:final_application/services/subscription_service.dart';

class TokenDisplay extends StatelessWidget {
  final bool showSubscriptionStatus;

  const TokenDisplay({Key? key, this.showSubscriptionStatus = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserSubscription>(
      stream: SubscriptionService.instance.subscriptionStream,
      initialData: SubscriptionService.instance.subscription,
      builder: (context, snapshot) {
        final subscription = snapshot.data ?? const UserSubscription();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color:
                subscription.isProActive
                    ? Colors.amber.shade100
                    : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color:
                  subscription.isProActive
                      ? Colors.amber.shade300
                      : Colors.grey.shade300,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.token,
                color:
                    subscription.isProActive
                        ? Colors.amber.shade700
                        : Colors.grey.shade700,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                'Tokens: ${subscription.displayTokens}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      subscription.isProActive
                          ? Colors.amber.shade700
                          : Colors.grey.shade700,
                ),
              ),
              if (showSubscriptionStatus && subscription.isProActive) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade700,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
