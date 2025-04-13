import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_bot_service.dart';
import '../../services/knowledge_service.dart';
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
  final KnowledgeService _knowledgeService = KnowledgeService();
  String _searchQuery = '';
  List<KnowledgeItem> _knowledgeItems = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  bool _hasMoreItems = false;
  int _currentOffset = 0;
  int _totalItems = 0;
  final int _pageSize = 20;
  final ScrollController _scrollController = ScrollController();

  // Filter options
  String _sortOrder = 'DESC';
  String _sortField = 'createdAt';
  bool _showFilterOptions = false;

  @override
  void initState() {
    super.initState();
    _fetchKnowledgeItems();

    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent * 0.8 &&
        !_isLoading &&
        _hasMoreItems) {
      _loadMoreItems();
    }
  }

  Future<void> _fetchKnowledgeItems({bool refresh = true}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _errorMessage = '';
        _currentOffset = 0;
      });
    } else {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final result = await _knowledgeService.getKnowledgeItems(
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
        offset: _currentOffset,
        limit: _pageSize,
        order: _sortOrder,
        orderField: _sortField,
      );

      final List<KnowledgeItem> items = result['items'];
      final meta = result['meta'];

      setState(() {
        if (refresh) {
          _knowledgeItems = items;
        } else {
          _knowledgeItems.addAll(items);
        }

        _totalItems = meta['total'];
        _hasMoreItems = meta['hasNext'];
        _isLoading = false;
      });

      // Also update the AIBotService for consistency
      final aiBotService = Provider.of<AIBotService>(context, listen: false);
      aiBotService.setKnowledgeItems(_knowledgeItems);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreItems() async {
    if (!_hasMoreItems || _isLoading) return;

    _currentOffset += _pageSize;
    await _fetchKnowledgeItems(refresh: false);
  }

  Future<void> _refreshList() async {
    _currentOffset = 0;
    await _fetchKnowledgeItems();
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _refreshList();
  }

  void _applyFilters() {
    _refreshList();
    setState(() {
      _showFilterOptions = false;
    });
  }

  void _resetFilters() {
    setState(() {
      _sortOrder = 'DESC';
      _sortField = 'createdAt';
    });
    _refreshList();
    setState(() {
      _showFilterOptions = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Knowledge Sources'),
        actions: [
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilterOptions = !_showFilterOptions;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KnowledgeCreateScreen(),
                ),
              );

              // Refresh the list when returning from create screen
              if (result == true) {
                _refreshList();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          Column(
            children: [
              // Filter options panel
              if (_showFilterOptions) _buildFilterOptions(),

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
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: _performSearch,
                  onChanged: (value) {
                    // Optionally implement real-time search
                    // _performSearch(value);
                  },
                ),
              ),

              // Error message if any
              if (_hasError)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
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
                        icon: const Icon(Icons.refresh, color: Colors.red),
                        onPressed: _refreshList,
                      ),
                    ],
                  ),
                ),

              // Active filters indicator
              if (_sortOrder != 'DESC' || _sortField != 'createdAt')
                Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.filter_list, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Sorted by: ${_getSortFieldName(_sortField)} (${_sortOrder == 'ASC' ? 'Oldest first' : 'Newest first'})',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: _resetFilters,
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Knowledge list
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshList,
                  child: _isLoading && _knowledgeItems.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _knowledgeItems.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: _knowledgeItems.length +
                                  (_hasMoreItems ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _knowledgeItems.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(16.0),
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

          // Refresh the list when returning from create screen
          if (result == true) {
            _refreshList();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Create Knowledge'),
      ),
    );
  }

  Widget _buildFilterOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _showFilterOptions = false;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Sort Field
          Text(
            'Sort By',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildSortFieldChip('createdAt', 'Created Date'),
              _buildSortFieldChip('updatedAt', 'Updated Date'),
            ],
          ),

          const SizedBox(height: 16),

          // Sort Order
          Text(
            'Sort Order',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildSortOrderChip('DESC', 'Newest First'),
              _buildSortOrderChip('ASC', 'Oldest First'),
            ],
          ),

          const SizedBox(height: 16),

          // Apply and Reset buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _resetFilters,
                child: const Text('Reset'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _applyFilters,
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortFieldChip(String value, String label) {
    final isSelected = _sortField == value;

    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortField = value;
          });
        }
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  Widget _buildSortOrderChip(String value, String label) {
    final isSelected = _sortOrder == value;

    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortOrder = value;
          });
        }
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  String _getSortFieldName(String field) {
    switch (field) {
      case 'createdAt':
        return 'Created Date';
      case 'updatedAt':
        return 'Updated Date';
      default:
        return field;
    }
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
                : 'Try a different search term or filter',
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (_searchQuery.isEmpty &&
              _sortOrder == 'DESC' &&
              _sortField == 'createdAt')
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const KnowledgeCreateScreen(),
                  ),
                );

                // Refresh the list when returning from create screen
                if (result == true) {
                  _refreshList();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Knowledge'),
            ),
          if (_searchQuery.isNotEmpty ||
              _sortOrder != 'DESC' ||
              _sortField != 'createdAt')
            ElevatedButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Filters'),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.fileType.isNotEmpty
                  ? 'Type: ${item.fileType.toUpperCase()}'
                  : 'Text content',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Created: ${_formatDate(item.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Deleting knowledge source...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              try {
                // Delete knowledge item using the API
                final success =
                    await _knowledgeService.deleteKnowledgeItem(item.id);

                // Update local state
                setState(() {
                  _knowledgeItems.removeWhere((i) => i.id == item.id);
                  _totalItems--;
                });

                // Update AIBotService
                final aiBotService =
                    Provider.of<AIBotService>(context, listen: false);
                aiBotService.deleteKnowledgeItem(item.id);

                if (mounted) {
                  // Clear any existing snackbars
                  ScaffoldMessenger.of(context).clearSnackBars();

                  // Show success notification
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Success!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                    'Knowledge source "${item.title}" has been deleted'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'DISMISS',
                        textColor: Colors.white,
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  // Clear any existing snackbars
                  ScaffoldMessenger.of(context).clearSnackBars();

                  // Show error notification
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Error!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Failed to delete: ${e.toString()}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 6),
                      action: SnackBarAction(
                        label: 'DISMISS',
                        textColor: Colors.white,
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      ),
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

// Also update the _toggleKnowledgeStatus method for consistency
  void _toggleKnowledgeStatus(BuildContext context, KnowledgeItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disable Knowledge Source'),
        content: Text(
            'Are you sure you want to disable "${item.title}"? This will make it unavailable for use in bots.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 16),
                      Text('Disabling knowledge source...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );

              try {
                // Disable knowledge item using the API (same as delete in this case)
                final success =
                    await _knowledgeService.disableKnowledgeItem(item.id);

                // Update local state - remove the item from the list
                setState(() {
                  _knowledgeItems.removeWhere((i) => i.id == item.id);
                  _totalItems--;
                });

                // Update AIBotService
                final aiBotService =
                    Provider.of<AIBotService>(context, listen: false);
                aiBotService.deleteKnowledgeItem(item.id);

                if (mounted) {
                  // Clear any existing snackbars
                  ScaffoldMessenger.of(context).clearSnackBars();

                  // Show success notification
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.white),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Success!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                    'Knowledge source "${item.title}" has been disabled'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 4),
                      action: SnackBarAction(
                        label: 'DISMISS',
                        textColor: Colors.white,
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  // Clear any existing snackbars
                  ScaffoldMessenger.of(context).clearSnackBars();

                  // Show error notification
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Error!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('Failed to disable: ${e.toString()}'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 6),
                      action: SnackBarAction(
                        label: 'DISMISS',
                        textColor: Colors.white,
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        },
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }
}
