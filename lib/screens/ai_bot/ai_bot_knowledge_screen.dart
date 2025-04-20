import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_bot_service.dart';
import '../../services/knowledge_service.dart';
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

class _AIBotKnowledgeScreenState extends State<AIBotKnowledgeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late TabController _tabController;
  bool _isLoading = false;
  List<KnowledgeItem> _availableKnowledge = [];
  List<KnowledgeItem> _attachedKnowledge = [];
  String _errorMessage = '';
  final KnowledgeService _knowledgeService = KnowledgeService();

  // Pagination variables
  int _attachedOffset = 0;
  int _availableOffset = 0;
  final int _limit = 20;
  bool _hasMoreAttached = true;
  bool _hasMoreAvailable = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final aiBotService = Provider.of<AIBotService>(context, listen: false);

      // Fetch imported knowledge directly from the API
      final attachedKnowledge = await aiBotService.getImportedKnowledge(
        widget.bot.id,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        offset: _attachedOffset,
        limit: _limit,
      );

      // Fetch all available knowledge
      final knowledgeResult = await _knowledgeService.getKnowledgeItems(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        offset: _availableOffset,
        limit: _limit,
      );

      final allKnowledge = knowledgeResult['items'] as List<KnowledgeItem>;
      final meta = knowledgeResult['meta'] as Map<String, dynamic>;

      // Filter out knowledge already attached to the bot
      final attachedIds = attachedKnowledge.map((k) => k.id).toSet();
      final availableKnowledge =
          allKnowledge.where((item) => !attachedIds.contains(item.id)).toList();

      setState(() {
        if (_attachedOffset == 0) {
          _attachedKnowledge = attachedKnowledge;
        } else {
          _attachedKnowledge = [..._attachedKnowledge, ...attachedKnowledge];
        }

        if (_availableOffset == 0) {
          _availableKnowledge = availableKnowledge;
        } else {
          _availableKnowledge = [..._availableKnowledge, ...availableKnowledge];
        }

        // Update pagination flags
        _hasMoreAttached = attachedKnowledge.length >= _limit;
        _hasMoreAvailable = meta['hasNext'] ?? false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load knowledge items: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Load more attached knowledge
  Future<void> _loadMoreAttached() async {
    if (!_hasMoreAttached || _isLoading) return;

    setState(() {
      _attachedOffset += _limit;
    });

    await _loadData();
  }

  // Load more available knowledge
  Future<void> _loadMoreAvailable() async {
    if (!_hasMoreAvailable || _isLoading) return;

    setState(() {
      _availableOffset += _limit;
    });

    await _loadData();
  }

  // Refresh data
  Future<void> _refreshData() async {
    setState(() {
      _attachedOffset = 0;
      _availableOffset = 0;
      _hasMoreAttached = true;
      _hasMoreAvailable = true;
      _attachedKnowledge = [];
      _availableKnowledge = [];
    });

    await _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bot Knowledge'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Attached Knowledge'),
            Tab(text: 'Available Knowledge'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: 'Refresh',
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
                                _refreshData();
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
                      _refreshData();
                    });
                  },
                ),
              ),

              // Error message if any
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              _errorMessage = '';
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Attached Knowledge Tab
                    _isLoading && _attachedOffset == 0
                        ? const Center(child: CircularProgressIndicator())
                        : _buildKnowledgeList(
                            _attachedKnowledge,
                            isAttached: true,
                            onLoadMore: _loadMoreAttached,
                            hasMore: _hasMoreAttached,
                          ),

                    // Available Knowledge Tab
                    _isLoading && _availableOffset == 0
                        ? const Center(child: CircularProgressIndicator())
                        : _buildKnowledgeList(
                            _availableKnowledge,
                            isAttached: false,
                            onLoadMore: _loadMoreAvailable,
                            hasMore: _hasMoreAvailable,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const KnowledgeCreateScreen(),
            ),
          );

          if (result == true) {
            // Refresh the knowledge list if a new knowledge item was created
            _refreshData();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Knowledge'),
      ),
    );
  }

  Widget _buildKnowledgeList(
    List<KnowledgeItem> items, {
    required bool isAttached,
    required Function onLoadMore,
    required bool hasMore,
  }) {
    if (items.isEmpty) {
      return _buildEmptyState(isAttached);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent &&
            hasMore) {
          onLoadMore();
        }
        return true;
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == items.length) {
            return _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : const SizedBox.shrink();
          }

          final item = items[index];
          return _buildKnowledgeItem(context, item, isAttached);
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isAttached) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAttached ? Icons.folder_off : Icons.description_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isAttached
                ? _searchQuery.isEmpty
                    ? 'No Knowledge Sources Attached'
                    : 'No Matching Attached Knowledge'
                : _searchQuery.isEmpty
                    ? 'No Available Knowledge Sources'
                    : 'No Matching Available Knowledge',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAttached
                ? _searchQuery.isEmpty
                    ? 'Add knowledge sources to enhance your bot'
                    : 'Try a different search term'
                : _searchQuery.isEmpty
                    ? 'Create a new knowledge source to add to your bot'
                    : 'Try a different search term',
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (!isAttached && _searchQuery.isEmpty)
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KnowledgeCreateScreen(),
                  ),
                );

                if (result == true) {
                  // Refresh the knowledge list if a new knowledge item was created
                  _refreshData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Knowledge'),
            ),
        ],
      ),
    );
  }

  Widget _buildKnowledgeItem(
      BuildContext context, KnowledgeItem item, bool isAttached) {
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
        trailing: isAttached
            ? IconButton(
                icon:
                    const Icon(Icons.remove_circle_outline, color: Colors.red),
                tooltip: 'Remove from bot',
                onPressed: () => _removeKnowledgeFromBot(item),
              )
            : IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                tooltip: 'Add to bot',
                onPressed: () => _addKnowledgeToBot(item),
              ),
        onTap: () {
          // Show knowledge item details
          _showKnowledgeDetails(context, item, isAttached);
        },
      ),
    );
  }

  Future<void> _addKnowledgeToBot(KnowledgeItem item) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final aiBotService = Provider.of<AIBotService>(context, listen: false);
      final success = await aiBotService.importKnowledgeToBot(
        widget.bot.id,
        item.id,
      );

      if (success) {
        // Refresh the data
        await _refreshData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Knowledge "${item.title}" added successfully'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to add knowledge: ${aiBotService.error}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error adding knowledge: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeKnowledgeFromBot(KnowledgeItem item) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final aiBotService = Provider.of<AIBotService>(context, listen: false);
      final success = await aiBotService.removeKnowledgeFromBot(
        widget.bot.id,
        item.id,
      );

      if (success) {
        // Refresh the data
        await _refreshData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Knowledge "${item.title}" removed successfully'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Failed to remove knowledge: ${aiBotService.error}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error removing knowledge: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showKnowledgeDetails(
      BuildContext context, KnowledgeItem item, bool isAttached) {
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
          if (isAttached)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _removeKnowledgeFromBot(item);
              },
              icon:
                  const Icon(Icons.remove_circle_outline, color: Colors.white),
              label: const Text('Remove from Bot'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _addKnowledgeToBot(item);
              },
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('Add to Bot'),
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
