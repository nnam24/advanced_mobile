import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_bot_service.dart';
import '../../models/ai_bot.dart';
import '../../models/knowledge_item.dart';
import '../../widgets/animated_background.dart';
import '../knowledge/knowledge_create_screen.dart';

class AIBotKnowledgeScreen extends StatefulWidget {
  final AIBot bot;

  const AIBotKnowledgeScreen({super.key, required this.bot});

  @override
  State<AIBotKnowledgeScreen> createState() => _AIBotKnowledgeScreenState();
}

class _AIBotKnowledgeScreenState extends State<AIBotKnowledgeScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiBotService = Provider.of<AIBotService>(context);
    final availableKnowledge = _searchQuery.isEmpty
        ? aiBotService.getAvailableKnowledgeItems(widget.bot.id)
        : aiBotService
            .getAvailableKnowledgeItems(widget.bot.id)
            .where((item) =>
                item.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Knowledge'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KnowledgeCreateScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search knowledge sources...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              // Knowledge list
              Expanded(
                child: aiBotService.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : availableKnowledge.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: availableKnowledge.length,
                            itemBuilder: (context, index) {
                              final item = availableKnowledge[index];
                              return _buildKnowledgeItem(
                                  context, item, aiBotService);
                            },
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
              builder: (context) => const KnowledgeCreateScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Knowledge'),
      ),
    );
  }

  Widget _buildEmptyState() {
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
          Text(
            _searchQuery.isEmpty
                ? 'No Knowledge Sources Available'
                : 'No Results Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Create a new knowledge source to add to your bot'
                : 'Try a different search term',
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isEmpty)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KnowledgeCreateScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Knowledge'),
            ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeItem(
      BuildContext context, KnowledgeItem item, AIBotService aiBotService) {
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
          icon: const Icon(Icons.add_circle_outline, color: Colors.green),
          onPressed: () async {
            final success = await aiBotService.importKnowledgeToBot(
              widget.bot.id,
              [item.id],
            );

            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Knowledge source added successfully'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              setState(() {}); // Refresh the UI
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Failed to add knowledge source: ${aiBotService.error}'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        onTap: () {
          // Show knowledge item details
          _showKnowledgeDetails(context, item);
        },
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
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final aiBotService =
                  Provider.of<AIBotService>(context, listen: false);
              final success = await aiBotService.importKnowledgeToBot(
                widget.bot.id,
                [item.id],
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Knowledge source added successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                setState(() {}); // Refresh the UI
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Failed to add knowledge source: ${aiBotService.error}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Add to Bot'),
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
