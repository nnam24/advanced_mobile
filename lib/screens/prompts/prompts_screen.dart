import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/prompt_provider.dart';
import '../../models/prompt.dart';
import '../../widgets/animated_background.dart';
import 'prompt_detail_screen.dart';
import 'prompt_create_screen.dart';

class PromptsScreen extends StatefulWidget {
  final int initialTabIndex;

  const PromptsScreen({
    super.key,
    this.initialTabIndex = 0, // Default to the Public tab (index 0)
  });

  @override
  State<PromptsScreen> createState() => _PromptsScreenState();
}

class _PromptsScreenState extends State<PromptsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  PromptCategory? _selectedCategory;
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;
  // Add this flag to track if we've already triggered a favorites fetch
  bool _favoritesFetchTriggered = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );

    _tabController.addListener(_onTabChanged);

    // Set up scroll controller for pagination
    _scrollController.addListener(_onScroll);

    // Set initial visibility filter and fetch data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  void _loadInitialData() {
    if (_isInitialized) return;

    final promptProvider = Provider.of<PromptProvider>(context, listen: false);

    // Load data based on the initial tab
    if (_tabController.index == 0) {
      // Public tab
      promptProvider.setVisibilityFilter(true);
      promptProvider.fetchPrompts(isPublic: true, refresh: true);
    } else if (_tabController.index == 1) {
      // My Prompts tab
      promptProvider.setVisibilityFilter(false);
      promptProvider.fetchPrompts(isPublic: false, refresh: true);
    } else if (_tabController.index == 2) {
      // Favorites tab
      promptProvider.fetchFavorites(refresh: true);
    }

    _isInitialized = true;
  }

// Modify the _onTabChanged method to be more efficient and reliable
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final promptProvider =
          Provider.of<PromptProvider>(context, listen: false);

      // Reset search and category filters when changing tabs
      _searchController.clear();
      setState(() {
        _selectedCategory = null;
      });

      // Load data based on the selected tab
      if (_tabController.index == 0) {
        // Public tab
        promptProvider.setSearchQuery('');
        promptProvider.setCategory(null);
        promptProvider.setVisibilityFilter(true);
        // Explicitly fetch data for this tab
        promptProvider.fetchPrompts(isPublic: true, refresh: true);
      } else if (_tabController.index == 1) {
        // My Prompts tab
        promptProvider.setSearchQuery('');
        promptProvider.setCategory(null);
        promptProvider.setVisibilityFilter(false);
        // Explicitly fetch data for this tab
        promptProvider.fetchPrompts(isPublic: false, refresh: true);
      } else if (_tabController.index == 2) {
        // Favorites tab
        promptProvider.setSearchQuery('');
        promptProvider.setCategory(null);
        // Explicitly fetch favorites
        promptProvider.fetchFavorites(refresh: true);
      }
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // Load more data when we're near the end of the list
      final promptProvider =
          Provider.of<PromptProvider>(context, listen: false);
      if (!promptProvider.isLoading) {
        if (_tabController.index == 2) {
          // Favorites tab
          if (promptProvider.hasMoreFavorites) {
            promptProvider.fetchFavorites();
          }
        } else {
          // Public or My Prompts tabs
          if (promptProvider.hasNext) {
            promptProvider.loadMore();
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prompt Library'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Public'),
            Tab(text: 'My Prompts'),
            Tab(text: 'Favorites'),
          ],
        ),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          Column(
            children: [
              // Search and filter
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Search bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search prompts...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  Provider.of<PromptProvider>(context,
                                          listen: false)
                                      .setSearchQuery('');
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        Provider.of<PromptProvider>(context, listen: false)
                            .setSearchQuery(value);
                      },
                    ),

                    const SizedBox(height: 12),

                    // Category filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: const Text('All'),
                              selected: _selectedCategory == null,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedCategory = null;
                                  });
                                  Provider.of<PromptProvider>(context,
                                          listen: false)
                                      .setCategory(null);
                                }
                              },
                            ),
                          ),
                          ...PromptCategory.values.map((category) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: FilterChip(
                                label: Text(Prompt.getCategoryName(category)),
                                selected: _selectedCategory == category,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory =
                                        selected ? category : null;
                                  });
                                  Provider.of<PromptProvider>(context,
                                          listen: false)
                                      .setCategory(selected ? category : null);
                                },
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Tab content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Public prompts tab
                    _buildPromptList(context, true),

                    // My prompts tab
                    _buildPromptList(context, false),

                    // Favorites tab
                    _buildFavoritesList(context),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to create screen and wait for result
          final result = await Navigator.push<int>(
            context,
            MaterialPageRoute(
              builder: (context) => const PromptCreateScreen(),
            ),
          );

          // If we got a result (tab index), switch to that tab
          if (result != null && mounted) {
            _tabController.animateTo(result);

            // Refresh the prompts list to show the newly created prompt
            final promptProvider =
                Provider.of<PromptProvider>(context, listen: false);
            if (result == 0) {
              // Public tab
              promptProvider.fetchPrompts(isPublic: true, refresh: true);
            } else if (result == 1) {
              // My Prompts tab
              promptProvider.fetchPrompts(isPublic: false, refresh: true);
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

// Modify the _buildPromptList method to handle loading states better
  Widget _buildPromptList(BuildContext context, bool isPublic) {
    return Consumer<PromptProvider>(
      builder: (context, promptProvider, child) {
        // Add debug print to track what's happening
        print(
            'Building prompt list for isPublic=$isPublic, current filter=${promptProvider.isPublicFilter}, prompts count=${promptProvider.prompts.length}');

        // Make sure we're showing the right prompts based on the tab
        if (promptProvider.isPublicFilter != isPublic) {
          // If the filter doesn't match the isPublic parameter, update the filter and fetch data
          print('Filter mismatch, updating to isPublic=$isPublic');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            promptProvider.setVisibilityFilter(isPublic);
            promptProvider.fetchPrompts(isPublic: isPublic, refresh: true);
          });

          // Show a loading indicator while we're switching filters
          return const Center(child: CircularProgressIndicator());
        }

        if (promptProvider.isLoading && promptProvider.prompts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final prompts = promptProvider.prompts;
        if (prompts.isEmpty) {
          return _buildEmptyState(context, isPublic);
        }

        return RefreshIndicator(
          onRefresh: () async {
            print('Manual refresh triggered for isPublic=$isPublic');
            await promptProvider.fetchPrompts(
                isPublic: isPublic, refresh: true);
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: prompts.length +
                (promptProvider.isLoading && prompts.isNotEmpty ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == prompts.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final prompt = prompts[index];
              return _buildPromptCard(context, prompt);
            },
          ),
        );
      },
    );
  }

// Modify the _buildFavoritesList method to prevent infinite loading when there are no favorites
  Widget _buildFavoritesList(BuildContext context) {
    return Consumer<PromptProvider>(
      builder: (context, promptProvider, child) {
        // Add debug print to track what's happening
        print(
            'Building favorites list, favorites count=${promptProvider.favoritePrompts.length}, isLoading=${promptProvider.isLoading}');

        // Check if we need to load favorites (only once)
        if (_tabController.index == 2 && !_favoritesFetchTriggered) {
          // Only trigger a fetch if we're not already loading
          if (!promptProvider.isLoading) {
            print('Favorites tab selected, triggering one-time fetch');
            _favoritesFetchTriggered = true;

            // Use a post-frame callback to avoid build-during-build errors
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                promptProvider.fetchFavorites(refresh: true);
              }
            });
          }
        } else if (_tabController.index != 2) {
          // Reset the flag when we're not on the favorites tab
          _favoritesFetchTriggered = false;
        }

        // Show loading indicator only during the initial load
        if (promptProvider.isLoading &&
            promptProvider.favoritePrompts.isEmpty &&
            _favoritesFetchTriggered) {
          return const Center(child: CircularProgressIndicator());
        }

        // Show empty state if we've completed loading and have no favorites
        if (promptProvider.favoritePrompts.isEmpty &&
            (!promptProvider.isLoading || !_favoritesFetchTriggered)) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No Favorite Prompts',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add prompts to your favorites to see them here',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Show the list of favorites
        return RefreshIndicator(
          onRefresh: () {
            print('Manual refresh triggered for favorites');
            return promptProvider.fetchFavorites(refresh: true);
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: promptProvider.favoritePrompts.length +
                (promptProvider.isLoading &&
                        promptProvider.favoritePrompts.isNotEmpty
                    ? 1
                    : 0),
            itemBuilder: (context, index) {
              if (index == promptProvider.favoritePrompts.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final prompt = promptProvider.favoritePrompts[index];
              return _buildPromptCard(context, prompt);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isPublic) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPublic ? Icons.public : Icons.lock,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            isPublic ? 'No Public Prompts Found' : 'No Private Prompts Found',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPublic
                ? 'Try a different search or category filter'
                : 'Create your first prompt to get started',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          if (!isPublic)
            ElevatedButton.icon(
              onPressed: () async {
                // Navigate to create screen and wait for result
                final result = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PromptCreateScreen(),
                  ),
                );

                // If we got a result (tab index), switch to that tab
                if (result != null && mounted) {
                  _tabController.animateTo(result);
                  // Refresh the prompts list to show the newly created prompt
                  Provider.of<PromptProvider>(context, listen: false)
                      .refreshPrompts();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Prompt'),
            ),
        ],
      ),
    );
  }

  Widget _buildPromptCard(BuildContext context, Prompt prompt) {
    final promptProvider = Provider.of<PromptProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: InkWell(
        onTap: () {
          // Verify that the prompt has a valid ID before navigating
          if (prompt.id.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Error: This prompt has no ID and cannot be viewed in detail'),
                behavior: SnackBarBehavior.floating,
              ),
            );
            return;
          }

          // Pass the entire prompt object to the detail screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PromptDetailScreen(
                promptId: prompt.id,
                prompt: prompt, // Pass the prompt object directly
              ),
            ),
          ).then((_) {
            // Refresh the current tab when returning from detail screen
            if (_tabController.index == 0) {
              promptProvider.fetchPrompts(isPublic: true, refresh: true);
            } else if (_tabController.index == 1) {
              promptProvider.fetchPrompts(isPublic: false, refresh: true);
            } else if (_tabController.index == 2) {
              promptProvider.fetchFavorites(refresh: true);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Prompt.getCategoryIcon(prompt.category),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prompt.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${Prompt.getCategoryName(prompt.category)} • ${prompt.usageCount} uses',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      prompt.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: prompt.isFavorite ? Colors.red : null,
                    ),
                    onPressed: () {
                      // Check if the prompt has a valid ID before toggling favorite
                      if (prompt.id.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Cannot favorite: Prompt has no valid ID'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      promptProvider.toggleFavorite(prompt.id);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                prompt.content.length > 100
                    ? '${prompt.content.substring(0, 100)}...'
                    : prompt.content,
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'By ${prompt.userName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Check if the prompt has a valid ID before incrementing usage count
                      if (prompt.id.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Cannot use: Prompt has no valid ID'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      // Use the prompt in chat
                      promptProvider.incrementUsageCount(prompt.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Prompt added to chat'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                      Navigator.pop(context, prompt);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                    child: const Text('Use'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
