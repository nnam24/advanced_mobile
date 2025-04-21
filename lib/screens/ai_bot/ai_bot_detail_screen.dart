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
  bool _isLoading = false;
  bool _isDeleting = false;
  bool _isLoadingKnowledge = false;
  List<KnowledgeItem> _knowledgeItems = [];
  bool _hasMoreKnowledge = true;
  int _knowledgeOffset = 0;
  final int _knowledgeLimit = 10;
  String _knowledgeError = '';
  final ScrollController _knowledgeScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _knowledgeScrollController.addListener(_handleKnowledgeScroll);

    // Select the bot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBotDetails();
    });
  }

  void _handleKnowledgeScroll() {
    if (_knowledgeScrollController.position.pixels >=
        _knowledgeScrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingKnowledge && _hasMoreKnowledge) {
        _loadMoreKnowledgeItems();
      }
    }
  }

  Future<void> _loadBotDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final aiBotService = Provider.of<AIBotService>(context, listen: false);
      await aiBotService.selectBot(widget.botId);

      // After bot is loaded, fetch knowledge items
      await _loadKnowledgeItems(refresh: true);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading bot details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load bot details: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Add this method to load knowledge items
  Future<void> _loadKnowledgeItems({bool refresh = false}) async {
    if (!mounted) return;

    final aiBotService = Provider.of<AIBotService>(context, listen: false);
    if (aiBotService.selectedBot == null) return;

    setState(() {
      _isLoadingKnowledge = true;
      if (refresh) {
        _knowledgeOffset = 0;
        _hasMoreKnowledge = true;
        _knowledgeItems = [];
      }
    });

    try {
      // Use updateLoadingState: false to prevent notifyListeners during build
      final items = await aiBotService.getImportedKnowledge(
        aiBotService.selectedBot!.id,
        offset: _knowledgeOffset,
        limit: _knowledgeLimit,
        updateLoadingState: false,
      );

      if (mounted) {
        setState(() {
          if (refresh) {
            _knowledgeItems = items;
          } else {
            _knowledgeItems = [..._knowledgeItems, ...items];
          }
          _knowledgeOffset = _knowledgeItems.length;
          _hasMoreKnowledge = items.length >= _knowledgeLimit;
          _isLoadingKnowledge = false;
          _knowledgeError = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _knowledgeError = 'Failed to load knowledge items: $e';
          _isLoadingKnowledge = false;
        });
      }
    }
  }

  Future<void> _loadMoreKnowledgeItems() async {
    if (_hasMoreKnowledge && !_isLoadingKnowledge) {
      await _loadKnowledgeItems();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _knowledgeScrollController.removeListener(_handleKnowledgeScroll);
    _knowledgeScrollController.dispose();
    super.dispose();
  }

  // Create a method to navigate to the knowledge screen without using the provider directly
  void _navigateToKnowledgeScreen(AIBot bot) {
    // Create a copy of the bot to avoid direct provider access during navigation
    final botCopy = AIBot(
      id: bot.id,
      name: bot.name,
      description: bot.description,
      instructions: bot.instructions,
      avatarUrl: bot.avatarUrl,
      createdAt: bot.createdAt,
      updatedAt: bot.updatedAt,
      knowledgeIds: List.from(bot.knowledgeIds),
      isPublished: bot.isPublished,
      publishedChannels: Map.from(bot.publishedChannels),
      openAiAssistantId: bot.openAiAssistantId,
      openAiThreadIdPlay: bot.openAiThreadIdPlay,
      createdBy: bot.createdBy,
      updatedBy: bot.updatedBy,
    );

    // Use Future.microtask to ensure navigation happens outside of the build phase
    Future.microtask(() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIBotKnowledgeScreen(bot: botCopy),
        ),
      ).then((_) {
        // Refresh bot details when returning from knowledge screen
        _loadBotDetails();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiBotService = Provider.of<AIBotService>(context);
    final bot = aiBotService.selectedBot;

    if (_isLoading || aiBotService.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Bot Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (bot == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('AI Bot Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                'Bot Not Found',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The AI bot you\'re looking for could not be found',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Go Back'),
              ),
            ],
          ),
        ),
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
              ).then((_) {
                // Refresh bot details when returning from edit screen
                _loadBotDetails();
              });
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
                ).then((_) {
                  // Refresh bot details when returning from publish screen
                  _loadBotDetails();
                });
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
                          '${_knowledgeItems.length}',
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
                    _buildKnowledgeTab(context, bot),

                    // Preview tab
                    _buildPreviewTab(context, bot),
                  ],
                ),
              ),
            ],
          ),

          // Show loading overlay when deleting
          if (_isDeleting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Deleting bot...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
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
                ).then((_) {
                  // Refresh bot details when returning from edit screen
                  _loadBotDetails();
                });
              },
              icon: const Icon(Icons.edit),
              label: const Text('Edit Instructions'),
            ),
          ),
        ],
      ),
    );
  }

  // Update the _buildKnowledgeTab method to use the local state
  Widget _buildKnowledgeTab(BuildContext context, AIBot bot) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Knowledge Sources (${_knowledgeItems.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _navigateToKnowledgeScreen(bot),
                icon: const Icon(Icons.settings, size: 16),
                label: const Text('Manage'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _knowledgeError.isNotEmpty
                ? _buildErrorState(context)
                : _isLoadingKnowledge && _knowledgeItems.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : _knowledgeItems.isEmpty
                        ? _buildEmptyKnowledge(context, bot)
                        : RefreshIndicator(
                            onRefresh: () => _loadKnowledgeItems(refresh: true),
                            child: ListView.builder(
                              controller: _knowledgeScrollController,
                              itemCount: _knowledgeItems.length +
                                  (_hasMoreKnowledge ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _knowledgeItems.length) {
                                  // Load more when reaching the end
                                  if (!_isLoadingKnowledge) {
                                    _loadMoreKnowledgeItems();
                                  }
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final item = _knowledgeItems[index];
                                return _buildKnowledgeItem(context, item);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  // Add this method to show error state
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Error Loading Knowledge',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _knowledgeError,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _loadKnowledgeItems(refresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyKnowledge(BuildContext context, AIBot bot) {
    // Use a ListView to make the RefreshIndicator work
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
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
                  onPressed: () => _navigateToKnowledgeScreen(bot),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Knowledge'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Update the knowledge item builder to remove the delete button
  Widget _buildKnowledgeItem(BuildContext context, KnowledgeItem item) {
    IconData fileIcon;
    switch (item.fileType.toLowerCase()) {
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
      case 'web':
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
    // Get the provider reference before any async operations
    final aiBotService = Provider.of<AIBotService>(context, listen: false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete AI Bot'),
        content: Text(
            'Are you sure you want to delete "${bot.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close the dialog first
              Navigator.of(dialogContext).pop();

              // Only proceed if the main widget is still mounted
              if (!mounted) return;

              // Set deleting state
              setState(() {
                _isDeleting = true;
              });

              try {
                final success = await aiBotService.deleteBot(bot.id);

                // Only proceed if the widget is still mounted
                if (!mounted) return;

                // Reset deleting state
                setState(() {
                  _isDeleting = false;
                });

                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('AI Bot deleted successfully'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  Navigator.of(context)
                      .pop(true); // Go back to list screen with result
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Failed to delete AI Bot: ${aiBotService.error}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                // Handle any exceptions
                if (mounted) {
                  setState(() {
                    _isDeleting = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error deleting AI Bot: $e'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
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
