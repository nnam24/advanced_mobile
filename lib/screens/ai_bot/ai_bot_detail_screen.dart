import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_bot_service.dart';
import '../../models/ai_bot.dart';
import '../../models/knowledge_item.dart';
import '../../widgets/animated_background.dart';
import 'ai_bot_edit_screen.dart';
import 'ai_bot_chat_screen.dart';
import 'ai_bot_knowledge_screen.dart';
import 'ai_bot_publish_screen.dart';

class AIBotDetailScreen extends StatefulWidget {
  final String botId;

  const AIBotDetailScreen({super.key, required this.botId});

  @override
  State<AIBotDetailScreen> createState() => _AIBotDetailScreenState();
}

class _AIBotDetailScreenState extends State<AIBotDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Select the bot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiBotService = Provider.of<AIBotService>(context, listen: false);
      aiBotService.selectBot(widget.botId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiBotService = Provider.of<AIBotService>(context);
    final bot = aiBotService.selectedBot;

    if (aiBotService.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Bot Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (bot == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Bot Details')),
        body: const Center(child: Text('Bot not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(bot.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AIBotEditScreen(bot: bot),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                _showDeleteConfirmation(context, bot);
              } else if (value == 'publish') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIBotPublishScreen(bot: bot),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'publish',
                child: Row(
                  children: [
                    Icon(Icons.share, size: 20),
                    SizedBox(width: 8),
                    Text('Publish'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          Column(
            children: [
              // Bot info card
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          child: Icon(
                            Icons.smart_toy,
                            size: 30,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bot.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                bot.description,
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
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildInfoItem(
                          context,
                          Icons.description_outlined,
                          '${bot.knowledgeIds.length}',
                          'Knowledge Sources',
                        ),
                        _buildInfoItem(
                          context,
                          Icons.calendar_today_outlined,
                          _formatDate(bot.createdAt),
                          'Created',
                        ),
                        _buildInfoItem(
                          context,
                          bot.isPublished ? Icons.public : Icons.public_off,
                          bot.isPublished ? 'Yes' : 'No',
                          'Published',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Tab bar
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Instructions'),
                  Tab(text: 'Knowledge'),
                  Tab(text: 'Preview'),
                ],
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Instructions tab
                    _buildInstructionsTab(context, bot),

                    // Knowledge tab
                    _buildKnowledgeTab(context, bot, aiBotService),

                    // Preview tab
                    _buildPreviewTab(context, bot),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AIBotChatScreen(bot: bot),
            ),
          );
        },
        icon: const Icon(Icons.chat),
        label: const Text('Chat with Bot'),
      ),
    );
  }

  Widget _buildInfoItem(
      BuildContext context, IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsTab(BuildContext context, AIBot bot) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Instructions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'These instructions define how your bot behaves and responds to user queries.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Text(
              bot.instructions,
              style: const TextStyle(height: 1.5),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AIBotEditScreen(bot: bot),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Instructions'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeTab(
      BuildContext context, AIBot bot, AIBotService aiBotService) {
    final knowledgeItems = aiBotService.getBotKnowledgeItems(bot.id);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Knowledge Sources (${knowledgeItems.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AIBotKnowledgeScreen(bot: bot),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Add Knowledge'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: knowledgeItems.isEmpty
                ? _buildEmptyKnowledge(context)
                : ListView.builder(
                    itemCount: knowledgeItems.length,
                    itemBuilder: (context, index) {
                      final item = knowledgeItems[index];
                      return _buildKnowledgeItem(
                          context, item, bot, aiBotService);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyKnowledge(BuildContext context) {
    final bot = Provider.of<AIBotService>(context).selectedBot!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Knowledge Sources',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add knowledge sources to improve your bot\'s responses',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AIBotKnowledgeScreen(bot: bot),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Knowledge'),
          ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeItem(BuildContext context, KnowledgeItem item,
      AIBot bot, AIBotService aiBotService) {
    IconData fileIcon;
    switch (item.fileType) {
      case 'pdf':
        fileIcon = Icons.picture_as_pdf;
        break;
      case 'doc':
      case 'docx':
        fileIcon = Icons.description;
        break;
      case 'txt':
        fileIcon = Icons.text_snippet;
        break;
      case 'url':
        fileIcon = Icons.link;
        break;
      default:
        fileIcon = Icons.insert_drive_file;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Icon(
            fileIcon,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(item.title),
        subtitle: Text(
          item.fileType.isNotEmpty
              ? 'Type: ${item.fileType.toUpperCase()}'
              : 'Text content',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            _showRemoveKnowledgeConfirmation(context, bot, item, aiBotService);
          },
        ),
        onTap: () {
          // Show knowledge item details
          _showKnowledgeDetails(context, item);
        },
      ),
    );
  }

  Widget _buildPreviewTab(BuildContext context, AIBot bot) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'See how your bot will appear to users and test its responses.',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.smart_toy,
                      size: 40,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    bot.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    bot.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AIBotChatScreen(bot: bot),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Start Chatting'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AIBot bot) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete AI Bot'),
        content: Text(
            'Are you sure you want to delete "${bot.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final aiBotService =
                  Provider.of<AIBotService>(context, listen: false);
              final success = await aiBotService.deleteBot(bot.id);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('AI Bot deleted successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.of(context).pop(); // Go back to list screen
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('Failed to delete AI Bot: ${aiBotService.error}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showRemoveKnowledgeConfirmation(BuildContext context, AIBot bot,
      KnowledgeItem item, AIBotService aiBotService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Knowledge Source'),
        content: Text(
            'Are you sure you want to remove "${item.title}" from this bot?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success =
                  await aiBotService.removeKnowledgeFromBot(bot.id, item.id);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Knowledge source removed successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                setState(() {}); // Refresh the UI
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Failed to remove knowledge source: ${aiBotService.error}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showKnowledgeDetails(BuildContext context, KnowledgeItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Type: ${item.fileType.toUpperCase()}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Created: ${_formatDate(item.createdAt)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Content Preview:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    item.content.length > 300
                        ? '${item.content.substring(0, 300)}...'
                        : item.content,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }
}
