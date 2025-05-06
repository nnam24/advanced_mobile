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
  // Telegram controllers
  final _telegramTokenController = TextEditingController();

  // Slack controllers
  final _slackBotTokenController = TextEditingController();
  final _slackClientIdController = TextEditingController();
  final _slackClientSecretController = TextEditingController();
  final _slackSigningSecretController = TextEditingController();

  // Messenger controllers
  final _messengerBotTokenController = TextEditingController();
  final _messengerPageIdController = TextEditingController();
  final _messengerAppSecretController = TextEditingController();

  // Verification states
  bool _isTelegramVerified = false;
  bool _isSlackVerified = false;
  bool _isMessengerVerified = false;

  // Publication states
  bool _isTelegramPublished = false;
  bool _isSlackPublished = false;
  bool _isMessengerPublished = false;

  // Loading states for verification
  bool _isVerifyingTelegram = false;
  bool _isVerifyingSlack = false;
  bool _isVerifyingMessenger = false;

  // Loading states for publication
  bool _isPublishingTelegram = false;
  bool _isPublishingSlack = false;
  bool _isPublishingMessenger = false;

  // Redirect URLs
  String? _telegramBotUrl;
  String? _slackBotUrl;
  String? _messengerBotUrl;

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
        // If we have a stored URL for the Slack bot, use it
        _slackBotUrl = widget.bot.publishedChannels['slack'];
      });
    }

    // Check if the bot is already published to Messenger
    if (widget.bot.publishedChannels.containsKey('messenger')) {
      setState(() {
        _isMessengerPublished = true;
        // If we have a stored URL for the Messenger bot, use it
        _messengerBotUrl = widget.bot.publishedChannels['messenger'];
      });
    }
  }

  @override
  void dispose() {
    // Dispose Telegram controllers
    _telegramTokenController.dispose();

    // Dispose Slack controllers
    _slackBotTokenController.dispose();
    _slackClientIdController.dispose();
    _slackClientSecretController.dispose();
    _slackSigningSecretController.dispose();

    // Dispose Messenger controllers
    _messengerBotTokenController.dispose();
    _messengerPageIdController.dispose();
    _messengerAppSecretController.dispose();

    super.dispose();
  }

  // TELEGRAM METHODS

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

  // SLACK METHODS

  Future<void> _verifySlackBot() async {
    // Validate all required fields
    if (_slackBotTokenController.text.isEmpty ||
        _slackClientIdController.text.isEmpty ||
        _slackClientSecretController.text.isEmpty ||
        _slackSigningSecretController.text.isEmpty) {
      UIUtils.showSnackBar(
        context,
        message: 'Please fill in all Slack bot fields',
      );
      return;
    }

    setState(() {
      _isVerifyingSlack = true;
    });

    try {
      final botIntegrationService =
          Provider.of<BotIntegrationService>(context, listen: false);
      final response = await botIntegrationService.verifySlackBot(
        botToken: _slackBotTokenController.text,
        clientId: _slackClientIdController.text,
        clientSecret: _slackClientSecretController.text,
        signingSecret: _slackSigningSecretController.text,
      );

      if (mounted) {
        setState(() {
          _isVerifyingSlack = false;
          _isSlackVerified = response.success;
        });

        if (response.success) {
          UIUtils.showSnackBar(
            context,
            message: 'Slack bot verified successfully',
          );
        } else {
          UIUtils.showSnackBar(
            context,
            message: response.message ?? 'Failed to verify Slack bot',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingSlack = false;
        });
        UIUtils.showSnackBar(
          context,
          message: 'Error verifying Slack bot: $e',
        );
      }
    }
  }

  Future<void> _publishToSlack() async {
    if (!_isSlackVerified) {
      UIUtils.showSnackBar(
        context,
        message: 'Please verify your Slack bot first',
      );
      return;
    }

    setState(() {
      _isPublishingSlack = true;
    });

    try {
      final botIntegrationService =
          Provider.of<BotIntegrationService>(context, listen: false);
      final response = await botIntegrationService.publishToSlack(
        assistantId: widget.bot.id,
        botToken: _slackBotTokenController.text,
        clientId: _slackClientIdController.text,
        clientSecret: _slackClientSecretController.text,
        signingSecret: _slackSigningSecretController.text,
      );

      if (mounted) {
        setState(() {
          _isPublishingSlack = false;
          _isSlackPublished = response.success;
          _slackBotUrl = response.redirectUrl;
        });

        if (response.success) {
          String successMessage = 'AI bot published to Slack successfully';
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
            message: response.message ?? 'Failed to publish to Slack',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPublishingSlack = false;
        });
        UIUtils.showSnackBar(
          context,
          message: 'Error publishing to Slack: $e',
        );
      }
    }
  }

  Future<void> _openSlackBot() async {
    if (_slackBotUrl == null || _slackBotUrl!.isEmpty) {
      UIUtils.showSnackBar(
        context,
        message: 'Slack bot URL is not available',
      );
      return;
    }

    final Uri url = Uri.parse(_slackBotUrl!);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          UIUtils.showSnackBar(
            context,
            message: 'Could not open: $_slackBotUrl',
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

  // MESSENGER METHODS

  Future<void> _verifyMessengerBot() async {
    // Validate all required fields
    if (_messengerBotTokenController.text.isEmpty ||
        _messengerPageIdController.text.isEmpty ||
        _messengerAppSecretController.text.isEmpty) {
      UIUtils.showSnackBar(
        context,
        message: 'Please fill in all Messenger bot fields',
      );
      return;
    }

    setState(() {
      _isVerifyingMessenger = true;
    });

    try {
      final botIntegrationService =
          Provider.of<BotIntegrationService>(context, listen: false);
      final response = await botIntegrationService.verifyMessengerBot(
        botToken: _messengerBotTokenController.text,
        pageId: _messengerPageIdController.text,
        appSecret: _messengerAppSecretController.text,
      );

      if (mounted) {
        setState(() {
          _isVerifyingMessenger = false;
          _isMessengerVerified = response.success;
        });

        if (response.success) {
          UIUtils.showSnackBar(
            context,
            message: 'Messenger bot verified successfully',
          );
        } else {
          UIUtils.showSnackBar(
            context,
            message: response.message ?? 'Failed to verify Messenger bot',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifyingMessenger = false;
        });
        UIUtils.showSnackBar(
          context,
          message: 'Error verifying Messenger bot: $e',
        );
      }
    }
  }

  Future<void> _publishToMessenger() async {
    if (!_isMessengerVerified) {
      UIUtils.showSnackBar(
        context,
        message: 'Please verify your Messenger bot first',
      );
      return;
    }

    setState(() {
      _isPublishingMessenger = true;
    });

    try {
      final botIntegrationService =
          Provider.of<BotIntegrationService>(context, listen: false);
      final response = await botIntegrationService.publishToMessenger(
        assistantId: widget.bot.id,
        botToken: _messengerBotTokenController.text,
        pageId: _messengerPageIdController.text,
        appSecret: _messengerAppSecretController.text,
      );

      if (mounted) {
        setState(() {
          _isPublishingMessenger = false;
          _isMessengerPublished = response.success;
          _messengerBotUrl = response.redirectUrl;
        });

        if (response.success) {
          String successMessage = 'AI bot published to Messenger successfully';
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
            message: response.message ?? 'Failed to publish to Messenger',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPublishingMessenger = false;
        });
        UIUtils.showSnackBar(
          context,
          message: 'Error publishing to Messenger: $e',
        );
      }
    }
  }

  Future<void> _openMessengerBot() async {
    if (_messengerBotUrl == null || _messengerBotUrl!.isEmpty) {
      UIUtils.showSnackBar(
        context,
        message: 'Messenger bot URL is not available',
      );
      return;
    }

    final Uri url = Uri.parse(_messengerBotUrl!);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          UIUtils.showSnackBar(
            context,
            message: 'Could not open: $_messengerBotUrl',
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
    final botIntegrationService = Provider.of<BotIntegrationService>(context);
    final isLoading = botIntegrationService.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish AI Bot'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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

                  // TELEGRAM SECTION
                  _buildSectionTitle(context, 'Publish to Telegram'),
                  _buildTelegramSection(),

                  const SizedBox(height: 32),

                  // SLACK SECTION
                  _buildSectionTitle(context, 'Publish to Slack'),
                  _buildSlackSection(),

                  const SizedBox(height: 32),

                  // MESSENGER SECTION
                  _buildSectionTitle(context, 'Publish to Messenger'),
                  _buildMessengerSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildTelegramSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              _buildSuccessBox(
                'Published to Telegram',
                'Your AI bot is now available on Telegram. Users can interact with it by searching for your bot or using the link below.',
                _telegramBotUrl,
                _openTelegramBot,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlackSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoText(
              'To publish your AI bot to Slack, you need to create a Slack app and configure it with the necessary permissions.',
            ),
            _buildHowToSteps([
              'Go to api.slack.com/apps and create a new app',
              'Under "OAuth & Permissions", add bot scopes: chat:write, im:history, im:read, im:write',
              'Install the app to your workspace',
              'Copy the Bot User OAuth Token, Client ID, Client Secret, and Signing Secret',
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _slackBotTokenController,
              decoration: InputDecoration(
                labelText: 'Bot User OAuth Token',
                hintText: 'xoxb-...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
              obscureText: true,
              enabled: !_isSlackPublished,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _slackClientIdController,
              decoration: InputDecoration(
                labelText: 'Client ID',
                hintText: 'Enter your Slack app Client ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.app_registration),
              ),
              enabled: !_isSlackPublished,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _slackClientSecretController,
              decoration: InputDecoration(
                labelText: 'Client Secret',
                hintText: 'Enter your Slack app Client Secret',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.security),
              ),
              obscureText: true,
              enabled: !_isSlackPublished,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _slackSigningSecretController,
              decoration: InputDecoration(
                labelText: 'Signing Secret',
                hintText: 'Enter your Slack app Signing Secret',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.verified_user),
                suffixIcon: _isSlackVerified
                    ? Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      )
                    : null,
              ),
              obscureText: true,
              enabled: !_isSlackPublished,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSlackPublished || _isVerifyingSlack
                        ? null
                        : _verifySlackBot,
                    icon: _isVerifyingSlack
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Verify Slack App'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSlackPublished ||
                            !_isSlackVerified ||
                            _isPublishingSlack
                        ? null
                        : _publishToSlack,
                    icon: _isPublishingSlack
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.publish),
                    label: const Text('Publish to Slack'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (_isSlackPublished)
              _buildSuccessBox(
                'Published to Slack',
                'Your AI bot is now available on Slack. Users can interact with it in your workspace.',
                _slackBotUrl,
                _openSlackBot,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessengerSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoText(
              'To publish your AI bot to Facebook Messenger, you need to create a Facebook app and configure a Messenger bot.',
            ),
            _buildHowToSteps([
              'Go to developers.facebook.com and create a new app',
              'Add the Messenger product to your app',
              'Set up webhooks for your Messenger bot',
              'Generate a Page Access Token for your Facebook Page',
              'Copy the Page Access Token, Page ID, and App Secret',
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _messengerBotTokenController,
              decoration: InputDecoration(
                labelText: 'Page Access Token',
                hintText: 'Enter your Facebook Page Access Token',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.vpn_key),
              ),
              obscureText: true,
              enabled: !_isMessengerPublished,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messengerPageIdController,
              decoration: InputDecoration(
                labelText: 'Page ID',
                hintText: 'Enter your Facebook Page ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.pages),
              ),
              enabled: !_isMessengerPublished,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messengerAppSecretController,
              decoration: InputDecoration(
                labelText: 'App Secret',
                hintText: 'Enter your Facebook App Secret',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.security),
                suffixIcon: _isMessengerVerified
                    ? Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      )
                    : null,
              ),
              obscureText: true,
              enabled: !_isMessengerPublished,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isMessengerPublished || _isVerifyingMessenger
                        ? null
                        : _verifyMessengerBot,
                    icon: _isVerifyingMessenger
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Verify Messenger Bot'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isMessengerPublished ||
                            !_isMessengerVerified ||
                            _isPublishingMessenger
                        ? null
                        : _publishToMessenger,
                    icon: _isPublishingMessenger
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.publish),
                    label: const Text('Publish to Messenger'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (_isMessengerPublished)
              _buildSuccessBox(
                'Published to Messenger',
                'Your AI bot is now available on Facebook Messenger. Users can interact with it through your Facebook Page.',
                _messengerBotUrl,
                _openMessengerBot,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessBox(
      String title, String description, String? url, VoidCallback onOpen) {
    return Container(
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
                  title,
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
            description,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (url != null && url.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      url,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onOpen,
                  icon: const Icon(Icons.open_in_new),
                  tooltip: 'Open',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ],
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
            'How to set up:',
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
