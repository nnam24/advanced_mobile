import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/ai_bot.dart';
import '../../services/bot_integration_service.dart';
import '../../utils/ui_utils.dart';

class AIBotPublishScreen extends StatefulWidget {
  final AIBot bot;

  const AIBotPublishScreen({super.key, required this.bot});

  @override
  State<AIBotPublishScreen> createState() => _AIBotPublishScreenState();
}

class _AIBotPublishScreenState extends State<AIBotPublishScreen> {
  final _telegramTokenController = TextEditingController();
  final _slackTokenController = TextEditingController();
  final _messengerTokenController = TextEditingController();

  bool _isTelegramVerified = false;
  bool _isSlackVerified = false;
  bool _isMessengerVerified = false;

  bool _isTelegramPublished = false;
  bool _isSlackPublished = false;
  bool _isMessengerPublished = false;

  bool _isVerifyingTelegram = false;
  bool _isVerifyingSlack = false;
  bool _isVerifyingMessenger = false;

  bool _isPublishingTelegram = false;
  bool _isPublishingSlack = false;
  bool _isPublishingMessenger = false;

  String? _telegramBotUrl;

  @override
  void initState() {
    super.initState();
    // Check if the bot is already published to any platform
    _checkPublishedStatus();
  }

  void _checkPublishedStatus() {
    // Check if the bot is already published to Telegram
    if (widget.bot.publishedChannels.containsKey('telegram')) {
      setState(() {
        _isTelegramPublished = true;
        // If we have a stored URL for the Telegram bot, use it
        _telegramBotUrl = widget.bot.publishedChannels['telegram'];
      });
    }

    // Check if the bot is already published to Slack
    if (widget.bot.publishedChannels.containsKey('slack')) {
      setState(() {
        _isSlackPublished = true;
      });
    }

    // Check if the bot is already published to Messenger
    if (widget.bot.publishedChannels.containsKey('messenger')) {
      setState(() {
        _isMessengerPublished = true;
      });
    }
  }

  @override
  void dispose() {
    _telegramTokenController.dispose();
    _slackTokenController.dispose();
    _messengerTokenController.dispose();
    super.dispose();
  }

  Future<void> _verifyTelegramBot() async {
    if (_telegramTokenController.text.isEmpty) {
      UIUtils.showSnackBar(
        context,
        message: 'Please enter a Telegram bot token',
      );
      return;
    }

    setState(() {
      _isVerifyingTelegram = true;
    });

    try {
      final botIntegrationService =
          Provider.of<BotIntegrationService>(context, listen: false);
      final response = await botIntegrationService
          .verifyTelegramBot(_telegramTokenController.text);

      if (mounted) {
        setState(() {
          _isVerifyingTelegram = false;
          _isTelegramVerified = response.success;
        });

        if (response.success) {
          UIUtils.showSnackBar(
            context,
            message: 'Telegram bot verified successfully',
          );
        } else {
          UIUtils.showSnackBar(
            context,
            message: response.message ?? 'Failed to verify Telegram bot',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingTelegram = false;
        });
        UIUtils.showSnackBar(
          context,
          message: 'Error verifying Telegram bot: $e',
        );
      }
    }
  }

  Future<void> _publishToTelegram() async {
    if (!_isTelegramVerified) {
      UIUtils.showSnackBar(
        context,
        message: 'Please verify your Telegram bot first',
      );
      return;
    }

    setState(() {
      _isPublishingTelegram = true;
    });

    try {
      final botIntegrationService =
          Provider.of<BotIntegrationService>(context, listen: false);
      final response = await botIntegrationService.publishToTelegram(
        widget.bot.id,
        _telegramTokenController.text,
      );

      if (mounted) {
        setState(() {
          _isPublishingTelegram = false;
          _isTelegramPublished = response.success;
          _telegramBotUrl = response.redirectUrl;
        });

        if (response.success) {
          String successMessage = 'AI bot published to Telegram successfully';
          if (response.redirectUrl != null) {
            successMessage +=
                '. Your bot is available at ${response.redirectUrl}';
          }

          UIUtils.showSnackBar(
            context,
            message: successMessage,
            duration: const Duration(seconds: 5),
          );
        } else {
          UIUtils.showSnackBar(
            context,
            message: response.message ?? 'Failed to publish to Telegram',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPublishingTelegram = false;
        });
        UIUtils.showSnackBar(
          context,
          message: 'Error publishing to Telegram: $e',
        );
      }
    }
  }

  Future<void> _openTelegramBot() async {
    if (_telegramBotUrl == null || _telegramBotUrl!.isEmpty) {
      UIUtils.showSnackBar(
        context,
        message: 'Telegram bot URL is not available',
      );
      return;
    }

    final Uri url = Uri.parse(_telegramBotUrl!);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          UIUtils.showSnackBar(
            context,
            message: 'Could not open: $_telegramBotUrl',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        UIUtils.showSnackBar(
          context,
          message: 'Error opening URL: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish AI Bot'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bot info card
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      child: Icon(
                        Icons.smart_toy,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.bot.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.bot.description,
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Publish to Telegram section
            _buildSectionTitle(context, 'Publish to Telegram'),
            _buildInfoText(
              'To publish your AI bot to Telegram, you need to create a bot using BotFather and get a bot token.',
            ),
            _buildHowToSteps([
              'Open Telegram and search for "BotFather"',
              'Start a chat with BotFather and use the /newbot command',
              'Follow the instructions to name your bot',
              'Copy the token provided by BotFather',
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _telegramTokenController,
              decoration: InputDecoration(
                labelText: 'Telegram Bot Token',
                hintText: 'Enter your Telegram bot token',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.vpn_key),
                suffixIcon: _isTelegramVerified
                    ? Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      )
                    : null,
              ),
              obscureText: true,
              enabled: !_isTelegramPublished,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTelegramPublished || _isVerifyingTelegram
                        ? null
                        : _verifyTelegramBot,
                    icon: _isVerifyingTelegram
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Verify Bot Token'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTelegramPublished ||
                            !_isTelegramVerified ||
                            _isPublishingTelegram
                        ? null
                        : _publishToTelegram,
                    icon: _isPublishingTelegram
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.publish),
                    label: const Text('Publish to Telegram'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (_isTelegramPublished)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Published to Telegram',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your AI bot is now available on Telegram. Users can interact with it by searching for your bot or using the link below.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (_telegramBotUrl != null &&
                        _telegramBotUrl!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _telegramBotUrl!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _openTelegramBot,
                            icon: const Icon(Icons.open_in_new),
                            tooltip: 'Open in Telegram',
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Publish to Slack section (placeholder for future implementation)
            _buildSectionTitle(context, 'Publish to Slack'),
            _buildInfoText(
              'Coming soon! You will be able to publish your AI bot to Slack in a future update.',
            ),

            const SizedBox(height: 32),

            // Publish to Messenger section (placeholder for future implementation)
            _buildSectionTitle(context, 'Publish to Messenger'),
            _buildInfoText(
              'Coming soon! You will be able to publish your AI bot to Facebook Messenger in a future update.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildHowToSteps(List<String> steps) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to get a bot token:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step,
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
