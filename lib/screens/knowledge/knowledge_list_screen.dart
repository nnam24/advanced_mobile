import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_bot_service.dart';
import '../../models/knowledge_item.dart';
import '../../widgets/animated_background.dart';
import 'knowledge_create_screen.dart';
import 'knowledge_detail_screen.dart';

class KnowledgeListScreen extends StatefulWidget {
  const KnowledgeListScreen({super.key});

  @override
  State<KnowledgeListScreen> createState() => _KnowledgeListScreenState();
}

class _KnowledgeListScreenState extends State<KnowledgeListScreen> {
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
    final knowledgeItems = _searchQuery.isEmpty
        ? aiBotService.knowledgeItems
        : aiBotService.knowledgeItems
            .where((item) =>
                item.title.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Sources'),
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
                    : knowledgeItems.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: knowledgeItems.length,
                            itemBuilder: (context, index) {
                              final item = knowledgeItems[index];
                              return _buildKnowledgeItem(context, item);
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
            _searchQuery.isEmpty ? 'No Knowledge Sources' : 'No Results Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? 'Create your first knowledge source to get started'
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

  Widget _buildKnowledgeItem(BuildContext context, KnowledgeItem item) {
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
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteConfirmation(context, item);
            } else if (value == 'disable') {
              _toggleKnowledgeStatus(context, item);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'disable',
              child: Row(
                children: [
                  Icon(Icons.visibility_off, size: 20),
                  SizedBox(width: 8),
                  Text('Disable'),
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KnowledgeDetailScreen(item: item),
            ),
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, KnowledgeItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Knowledge Source'),
        content: Text(
            'Are you sure you want to delete "${item.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Delete knowledge item
              // In a real app, this would call an API
              final aiBotService =
                  Provider.of<AIBotService>(context, listen: false);
              aiBotService.deleteKnowledgeItem(item.id);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Knowledge source deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
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

  void _toggleKnowledgeStatus(BuildContext context, KnowledgeItem item) {
    // In a real app, this would update the item's status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${item.title} has been disabled'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
