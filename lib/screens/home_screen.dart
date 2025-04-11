import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/prompt_provider.dart';
import '../models/prompt.dart';
import '../widgets/animated_background.dart';
import '../widgets/message_bubble.dart';
import '../widgets/chat_history_drawer.dart';
import 'profile/profile_screen.dart';
import 'auth/login_screen.dart';
import 'ai_bot/ai_bot_list_screen.dart';
import 'knowledge/knowledge_list_screen.dart';
import 'prompts/prompts_screen.dart';
import 'email/email_compose_screen.dart';
import 'chat/chat_history_screen.dart';
import 'prompts/prompt_create_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  bool _showScrollToBottom = false;
  bool _showPromptSuggestions = false;
  String _promptSearchQuery = '';
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final ImagePicker _imagePicker = ImagePicker();

  // For bottom sheet
  bool _showAttachmentOptions = false;

  // For tab controller
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _messageController.addListener(_handleTextChange);
    _tabController = TabController(length: 2, vsync: this);

    // Check authentication status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.isAuthenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }

      // Fetch prompts when the screen loads
      final promptProvider =
          Provider.of<PromptProvider>(context, listen: false);
      if (promptProvider.prompts.isEmpty) {
        promptProvider.fetchPrompts(isPublic: true, refresh: true);
      }
    });

    // Set up session expiration handler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Set callback for session expiration
      authProvider.onSessionExpired = (String reason) {
        // Navigate to login screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );

        // Show error message as a snackbar after navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(reason),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        });
      };
    });
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleTextChange);
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _tabController.dispose();
    _removeOverlay();
    super.dispose();
  }

  // Optimize the _handleTextChange method to be more efficient
  void _handleTextChange() {
    // Debounce the text processing to avoid excessive UI updates
    Future.microtask(() {
      final text = _messageController.text;

      // Check if text contains a slash command
      if (text.contains('/')) {
        final lastSlashIndex = text.lastIndexOf('/');
        final isAtStart =
            lastSlashIndex == 0 || text[lastSlashIndex - 1] == ' ';
        final hasTextAfterSlash = lastSlashIndex < text.length - 1;

        if (isAtStart) {
          // Extract the query after the slash
          final newQuery = hasTextAfterSlash
              ? text.substring(lastSlashIndex + 1).trim()
              : '';

          // Only update state if the query has changed
          if (newQuery != _promptSearchQuery || !_showPromptSuggestions) {
            setState(() {
              _promptSearchQuery = newQuery;
              _showPromptSuggestions = true;
            });

            // Use a microtask to show the overlay to avoid blocking the UI thread
            Future.microtask(() {
              if (mounted) {
                _showPromptOverlay();
              }
            });
          }
          return;
        }
      }

      // If we get here, we should hide the overlay
      if (_showPromptSuggestions) {
        setState(() {
          _showPromptSuggestions = false;
        });
        _removeOverlay();
      }
    });
  }

  // Optimize the overlay creation to be more efficient
  void _showPromptOverlay() {
    _removeOverlay(); // Remove any existing overlay

    // Use a microtask to avoid blocking the UI thread
    Future.microtask(() {
      if (!mounted) return;

      _overlayEntry = OverlayEntry(
        builder: (context) => _buildPromptSuggestionsOverlay(),
      );

      if (mounted) {
        Overlay.of(context).insert(_overlayEntry!);
      }
    });
  }

  void _updateOverlay() {
    _removeOverlay();
    _showPromptOverlay();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // Optimize the _buildPromptSuggestionsOverlay method
  Widget _buildPromptSuggestionsOverlay() {
    final promptProvider = Provider.of<PromptProvider>(context, listen: false);
    final size = MediaQuery.of(context).size;

    // If prompts are empty and not already loading, fetch them
    if (promptProvider.prompts.isEmpty && !promptProvider.isLoading) {
      promptProvider.fetchPrompts(isPublic: true, refresh: true);
    }

    // Filter prompts based on the query
    final filteredPrompts = promptProvider.prompts
        .where((prompt) =>
            _promptSearchQuery.isEmpty ||
            prompt.title
                .toLowerCase()
                .contains(_promptSearchQuery.toLowerCase()))
        .take(5) // Limit to 5 suggestions
        .toList();

    return Positioned(
      width: size.width * 0.9,
      child: CompositedTransformFollower(
        link: _layerLink,
        showWhenUnlinked: false,
        offset: const Offset(0, -250), // Position above the text field
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Prompt Suggestions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          setState(() {
                            _showPromptSuggestions = false;
                          });
                          _removeOverlay();
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: promptProvider.isLoading && filteredPrompts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Loading prompts...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      : filteredPrompts.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'No prompts found. Try a different search or browse all prompts.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              padding: EdgeInsets.zero,
                              itemCount: filteredPrompts.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final prompt = filteredPrompts[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    prompt.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  subtitle: Text(
                                    prompt.content.length > 60
                                        ? '${prompt.content.substring(0, 60)}...'
                                        : prompt.content,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    child: Icon(
                                      Prompt.getCategoryIcon(prompt.category),
                                      size: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                  trailing: prompt.isFavorite
                                      ? Icon(
                                          Icons.favorite,
                                          size: 16,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .error,
                                        )
                                      : null,
                                  onTap: () => _insertPrompt(prompt),
                                );
                              },
                            ),
                ),
                const Divider(height: 1),
                InkWell(
                  onTap: () {
                    _removeOverlay();
                    setState(() {
                      _showPromptSuggestions = false;
                    });
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PromptsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    alignment: Alignment.center,
                    child: Text(
                      'Browse all prompts',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _insertPrompt(Prompt prompt) {
    // Increment usage count
    final promptProvider = Provider.of<PromptProvider>(context, listen: false);
    promptProvider.incrementUsageCount(prompt.id);

    // Find the position of the slash command
    final text = _messageController.text;
    final lastSlashIndex = text.lastIndexOf('/');

    // Replace the slash command with the prompt content
    final beforeSlash =
        lastSlashIndex > 0 ? text.substring(0, lastSlashIndex) : '';
    _messageController.text = beforeSlash + prompt.content;

    // Position cursor at the end
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );

    // Hide the overlay
    setState(() {
      _showPromptSuggestions = false;
    });
    _removeOverlay();

    // Keep focus on the text field
    _messageFocusNode.requestFocus();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      setState(() {
        _showScrollToBottom = currentScroll < maxScroll - 200;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      await chatProvider.sendMessage(message);

      // Scroll to bottom after sending message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      // Show error message if API call fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Method to pick image from gallery
  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image != null) {
      _showImageCaptionDialog(File(image.path));
    }
  }

  // Method to take a photo with camera
  Future<void> _takePhoto() async {
    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (photo != null) {
      _showImageCaptionDialog(File(photo.path));
    }
  }

  // Method to show dialog for adding caption to image
  void _showImageCaptionDialog(File imageFile) {
    final TextEditingController captionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Caption (Optional)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                imageFile,
                height: 140,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: captionController,
              decoration: const InputDecoration(
                hintText: 'What would you like to know about this image?',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendImageMessage(imageFile, captionController.text);
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  // Method to send image message
  Future<void> _sendImageMessage(File imageFile, String caption) async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.sendImageMessage(imageFile, caption);

    // Scroll to bottom after sending image
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _showPromptSelector() {
    final promptProvider = Provider.of<PromptProvider>(context, listen: false);

    // If prompts are empty and not already loading, fetch them
    if (promptProvider.prompts.isEmpty && !promptProvider.isLoading) {
      promptProvider.fetchPrompts(isPublic: true, refresh: true);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return _buildPromptSelector(scrollController);
        },
      ),
    );
  }

  Widget _buildPromptSelector(ScrollController scrollController) {
    return Consumer<PromptProvider>(
      builder: (context, promptProvider, _) {
        final prompts = promptProvider.prompts;

        // Show loading indicator if prompts are being loaded
        if (promptProvider.isLoading && prompts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading prompts...'),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Text(
                    'Select a Prompt',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search prompts...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  promptProvider.setSearchQuery(value);
                },
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: promptProvider.selectedCategory == null,
                    onSelected: (selected) {
                      if (selected) {
                        promptProvider.setCategory(null);
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  ...PromptCategory.values.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(Prompt.getCategoryName(category)),
                        selected: promptProvider.selectedCategory == category,
                        onSelected: (selected) {
                          promptProvider
                              .setCategory(selected ? category : null);
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: prompts.isEmpty
                  ? Center(
                      child: Text(
                        'No prompts found',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: prompts.length,
                      itemBuilder: (context, index) {
                        final prompt = prompts[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: ListTile(
                            title: Text(
                              prompt.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              prompt.content.length > 100
                                  ? '${prompt.content.substring(0, 100)}...'
                                  : prompt.content,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Icon(
                                Prompt.getCategoryIcon(prompt.category),
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    prompt.isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: prompt.isFavorite
                                        ? Theme.of(context).colorScheme.error
                                        : null,
                                  ),
                                  onPressed: () {
                                    promptProvider.toggleFavorite(prompt.id);
                                  },
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    // Use the prompt
                                    _usePrompt(prompt);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Use'),
                                ),
                              ],
                            ),
                            isThreeLine: true,
                            onTap: () {
                              // Use the prompt
                              _usePrompt(prompt);
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  void _usePrompt(Prompt prompt) {
    // Increment usage count
    final promptProvider = Provider.of<PromptProvider>(context, listen: false);
    promptProvider.incrementUsageCount(prompt.id);

    // Set the message text to the prompt content
    _messageController.text = prompt.content;

    // Position cursor at the end
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );

    // Focus the text field
    _messageFocusNode.requestFocus();

    // Show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Prompt "${prompt.title}" inserted'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Add this method to the _HomeScreenState class to navigate to the PromptCreateScreen
  void _navigateToCreatePrompt() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PromptCreateScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final currentConversation = chatProvider.currentConversation;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;

    return Scaffold(
      drawer: _buildDrawer(context),
      endDrawer: const ChatHistoryDrawer(),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          currentConversation?.title ?? 'New Conversation',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Chat history button
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Chat History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatHistoryScreen(),
                ),
              );
            },
          ),
          // AI Model selector as a dropdown in the AppBar
          DropdownButton<String>(
            value: chatProvider.selectedAgent,
            underline: Container(),
            icon: const Icon(Icons.arrow_drop_down),
            dropdownColor: Theme.of(context).colorScheme.surface,
            onChanged: (String? newValue) {
              if (newValue != null) {
                chatProvider.changeAgent(newValue);
              }
            },
            items: chatProvider.availableAgents
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.email),
            tooltip: 'Compose Email',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const EmailComposeScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'new') {
                chatProvider.createNewConversation();
              } else if (value == 'clear') {
                chatProvider.reduceTokenUsage();
              } else if (value == 'logout') {
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
                        Text('Logging out...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                try {
                  // Call the API logout method
                  await authProvider.logout();

                  // Navigate to login screen after successful logout
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const LoginScreen()),
                      (route) => false, // This removes all previous routes
                    );
                  }
                } catch (e) {
                  // Show error if logout fails
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logout failed: ${e.toString()}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new',
                child: Row(
                  children: [
                    Icon(Icons.add, size: 20),
                    SizedBox(width: 8),
                    Text('New Conversation'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services, size: 20),
                    SizedBox(width: 8),
                    Text('Clear History'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              )
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Chat'),
            Tab(text: 'Email'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Chat Tab
          SafeArea(
            bottom: false, // Don't add padding at the bottom
            child: GestureDetector(
              onTap: () {
                // Dismiss keyboard when tapping outside of text field
                FocusScope.of(context).unfocus();
              },
              child: Stack(
                children: [
                  const AnimatedBackground(),
                  Column(
                    children: [
                      // Token indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withOpacity(0.8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.token,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: chatProvider.tokenAvailabilityPercentage,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  chatProvider.tokenAvailabilityPercentage > 0.2
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.red,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${chatProvider.availableTokens} / ${chatProvider.tokenLimit}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // AI Model Selector
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        color: Theme.of(context)
                            .colorScheme
                            .surface
                            .withOpacity(0.5),
                        child: Row(
                          children: [
                            Text(
                              'Current AI:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                chatProvider.selectedAgent,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.info_outline, size: 18),
                              tooltip: 'Model Info',
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(chatProvider.selectedAgent),
                                    content: Text(
                                        chatProvider.getAIModelCapabilities(
                                            chatProvider.selectedAgent)),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Messages
                      Expanded(
                        child: currentConversation == null ||
                                currentConversation.messages.isEmpty
                            ? _buildEmptyState(context)
                            : Stack(
                                children: [
                                  ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.only(
                                      left: 16,
                                      right: 16,
                                      top: 16,
                                      bottom:
                                          80, // Add extra bottom padding for input field
                                    ),
                                    itemCount:
                                        currentConversation.messages.length,
                                    itemBuilder: (context, index) {
                                      final message =
                                          currentConversation.messages[index];
                                      return MessageBubble(
                                        key: ValueKey(message.id),
                                        message: message,
                                      );
                                    },
                                  ),
                                  if (_showScrollToBottom)
                                    Positioned(
                                      right: 16,
                                      bottom: 16,
                                      child: FloatingActionButton.small(
                                        onPressed: _scrollToBottom,
                                        child: const Icon(Icons.arrow_downward),
                                      ),
                                    ),
                                ],
                              ),
                      ),

                      // Loading indicator
                      if (chatProvider.isLoading)
                        Container(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Thinking...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Message input - fixed height container
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withOpacity(0.95),
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.2),
                            ),
                          ),
                        ),
                        child: CompositedTransformTarget(
                          link: _layerLink,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.attach_file, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  setState(() {
                                    _showAttachmentOptions =
                                        !_showAttachmentOptions;
                                  });
                                  if (_showAttachmentOptions) {
                                    _showAttachmentOptionsBottomSheet();
                                  }
                                },
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxHeight: 100, // Limit max height
                                  ),
                                  child: TextField(
                                    controller: _messageController,
                                    focusNode: _messageFocusNode,
                                    decoration: InputDecoration(
                                      hintText: chatProvider.hasTokens
                                          ? 'Type a message...'
                                          : 'Out of tokens',
                                      hintStyle: const TextStyle(fontSize: 14),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: isDarkMode
                                          ? Colors.grey.shade800
                                          : Colors.grey.shade200,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      isDense: true,
                                      suffixIcon: IconButton(
                                        icon: const Icon(Icons.auto_awesome,
                                            size: 20),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: _showPromptSelector,
                                      ),
                                    ),
                                    style: const TextStyle(fontSize: 14),
                                    maxLines: null,
                                    minLines: 1,
                                    textInputAction: TextInputAction.newline,
                                    keyboardType: TextInputType.multiline,
                                    enabled: chatProvider.hasTokens,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.send, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: chatProvider.hasTokens
                                    ? _sendMessage
                                    : null,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Email Tab
          const EmailComposeScreen(),
        ],
      ),
    );
  }

  void _showAttachmentOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Upload Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _takePhoto();
            },
          ),
          ListTile(
            leading: const Icon(Icons.screenshot),
            title: const Text('Take Screenshot'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Take a screenshot using your device\'s screenshot function, then upload it'),
                  duration: Duration(seconds: 3),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    user?.name.isNotEmpty == true
                        ? user!.name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? 'email@example.com',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.chat),
            title: const Text('Chat'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Email Composer'),
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Chat History'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatHistoryScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text('AI Bots'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AIBotListScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Knowledge'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const KnowledgeListScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Prompts'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PromptsScreen(),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              authProvider.logout().then((_) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type a message to begin chatting with Jarvis AI',
            style: TextStyle(
              color:
                  Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _messageController.text =
                      'Hello, Jarvis! How can you help me today?';
                },
                icon: const Icon(Icons.smart_toy),
                label: const Text('Try a sample message'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _showPromptSelector,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Browse prompts'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
