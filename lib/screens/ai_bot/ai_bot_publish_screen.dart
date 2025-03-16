import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_bot_service.dart';
import '../../models/ai_bot.dart';
import '../../widgets/animated_background.dart';

class AIBotPublishScreen extends StatefulWidget {
  final AIBot bot;

  const AIBotPublishScreen({super.key, required this.bot});

  @override
  State<AIBotPublishScreen> createState() => _AIBotPublishScreenState();
}

class _AIBotPublishScreenState extends State<AIBotPublishScreen> {
  final _formKey = GlobalKey<FormState>();
  late Map<String, TextEditingController> _channelControllers;
  late Map<String, bool> _selectedChannels;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers and selected channels
    _channelControllers = {
      'slack': TextEditingController(
          text: widget.bot.publishedChannels['slack'] ?? ''),
      'telegram': TextEditingController(
          text: widget.bot.publishedChannels['telegram'] ?? ''),
      'messenger': TextEditingController(
          text: widget.bot.publishedChannels['messenger'] ?? ''),
    };

    _selectedChannels = {
      'slack': widget.bot.publishedChannels.containsKey('slack'),
      'telegram': widget.bot.publishedChannels.containsKey('telegram'),
      'messenger': widget.bot.publishedChannels.containsKey('messenger'),
    };
  }

  @override
  void dispose() {
    _channelControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _publishBot() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Build the channels map
        final Map<String, String> channels = {};
        _selectedChannels.forEach((channel, isSelected) {
          if (isSelected) {
            channels[channel] = _channelControllers[channel]!.text.trim();
          }
        });

        // Publish the bot
        final aiBotService = Provider.of<AIBotService>(context, listen: false);
        final success = await aiBotService.publishBot(widget.bot.id, channels);

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bot published successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          Navigator.pop(context);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to publish bot: ${aiBotService.error}'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish Bot'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _publishBot,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Publish'),
          ),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bot info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surface
                          .withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.2),
                      ),
                    ),
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
                                  fontSize: 20,
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

                  const SizedBox(height: 24),

                  // Publish channels
                  Text(
                    'Publish Channels',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the platforms where you want to publish your bot.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Slack
                  _buildChannelSection(
                    context,
                    'slack',
                    'Slack',
                    Icons.chat_bubble_outline,
                    Colors.purple,
                    'Enter Slack workspace and channel (e.g., T123456/C789012)',
                  ),

                  const SizedBox(height: 16),

                  // Telegram
                  _buildChannelSection(
                    context,
                    'telegram',
                    'Telegram',
                    Icons.send,
                    Colors.blue,
                    'Enter Telegram bot token or channel username',
                  ),

                  const SizedBox(height: 16),

                  // Messenger
                  _buildChannelSection(
                    context,
                    'messenger',
                    'Facebook Messenger',
                    Icons.facebook,
                    Colors.indigo,
                    'Enter Messenger page ID',
                  ),

                  const SizedBox(height: 32),

                  // Publish button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _publishBot,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Publish Bot',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Note
                  Text(
                    'Note: Publishing your bot will make it available to users on the selected platforms. Make sure your bot is ready for public use.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelSection(
    BuildContext context,
    String channelKey,
    String channelName,
    IconData icon,
    Color color,
    String hint,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _selectedChannels[channelKey]!
              ? color.withOpacity(0.5)
              : Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
              ),
              const SizedBox(width: 8),
              Text(
                channelName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Switch(
                value: _selectedChannels[channelKey]!,
                onChanged: (value) {
                  setState(() {
                    _selectedChannels[channelKey] = value;
                  });
                },
                activeColor: color,
              ),
            ],
          ),
          if (_selectedChannels[channelKey]!) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _channelControllers[channelKey],
              decoration: InputDecoration(
                labelText: '$channelName ID/Token',
                hintText: hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (_selectedChannels[channelKey]! &&
                    (value == null || value.isEmpty)) {
                  return 'Please enter the $channelName ID or token';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                // This would open documentation or help
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$channelName integration documentation'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.help_outline, size: 16),
              label: const Text('How to get this?'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
