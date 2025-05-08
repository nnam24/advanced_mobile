import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_bot_service.dart';
import '../../models/ai_bot.dart';
import '../../models/message.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/message_bubble.dart';
import '../../providers/prompt_provider.dart';
import '../../models/prompt.dart';

class AIBotChatScreen extends StatefulWidget {
  final AIBot bot;

  const AIBotChatScreen({super.key, required this.bot});

  @override
  State<AIBotChatScreen> createState() => _AIBotChatScreenState();
}

class _AIBotChatScreenState extends State<AIBotChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<Message> _messages = [];
  bool _isLoading = false;
  bool _showScrollToBottom = false;
  bool _isFirstMessage = true;

  // For streaming response
  String _currentResponse = '';
  String _pendingMessageId = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);

    // Check if we already have a thread for this bot
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final aiBotService = Provider.of<AIBotService>(context, listen: false);
      final hasThread = aiBotService.threadIds.containsKey(widget.bot.id) &&
          aiBotService.threadIds[widget.bot.id]!.isNotEmpty;

      setState(() {
        _isFirstMessage = !hasThread;
      });

      // Add a welcome message from the bot
      setState(() {
        _messages.add(
          Message(
            id: 'welcome',
            content:
                'Hello! I am ${widget.bot.name}. ${widget.bot.description} How can I help you today?',
            type: MessageType.assistant,
            timestamp: DateTime.now(),
          ),
        );
      });
    });
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _messages.add(
        Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: message,
          type: MessageType.user,
          timestamp: DateTime.now(),
        ),
      );
    });

    _messageController.clear();

    // Scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      final aiBotService = Provider.of<AIBotService>(context, listen: false);

      // Create a placeholder message for streaming updates
      final pendingMessageId = DateTime.now().millisecondsSinceEpoch.toString();
      setState(() {
        _pendingMessageId = pendingMessageId;
        _currentResponse = '';
        _messages.add(
          Message(
            id: pendingMessageId,
            content: '',
            type: MessageType.assistant,
            timestamp: DateTime.now(),
          ),
        );
      });

      // Use the streaming message method
      final response = await aiBotService.sendMessage(widget.bot.id, message,
          onChunkReceived: (chunk) {
        if (!mounted) return;

        setState(() {
          _currentResponse += chunk;

          // Update the pending message with the current accumulated response
          final index =
              _messages.indexWhere((msg) => msg.id == _pendingMessageId);
          if (index != -1) {
            _messages[index] =
                _messages[index].copyWith(content: _currentResponse);
          }
        });

        // Scroll to bottom as new content arrives
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      });

      if (!mounted) return;

      // Replace the streaming placeholder with the final message
      final index = _messages.indexWhere((msg) => msg.id == _pendingMessageId);
      if (index != -1) {
        setState(() {
          _messages[index] = response;
          _isLoading = false;
          _pendingMessageId = '';
          _currentResponse = '';

          // If this was the first message, now we're in subsequent message mode
          if (_isFirstMessage) {
            _isFirstMessage = false;
          }
        });
      }

      // Scroll to bottom after receiving full response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      if (!mounted) return;

      // If there was a pending message being streamed, update it with error
      if (_pendingMessageId.isNotEmpty) {
        final index =
            _messages.indexWhere((msg) => msg.id == _pendingMessageId);
        if (index != -1) {
          setState(() {
            _messages[index] = _messages[index].copyWith(
              content:
                  'Sorry, there was an error processing your request: ${e.toString()}',
            );
            _pendingMessageId = '';
            _currentResponse = '';
          });
        }
      } else {
        setState(() {
          _messages.add(
            Message(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              content:
                  'Sorry, there was an error processing your request: ${e.toString()}',
              type: MessageType.assistant,
              timestamp: DateTime.now(),
            ),
          );
        });
      }

      setState(() {
        _isLoading = false;
      });

      // Scroll to bottom to show error message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    }
  }

  void _usePrompt(Prompt prompt) {
    // Increment usage count
    final promptProvider = Provider.of<PromptProvider>(context, listen: false);
    promptProvider.incrementUsageCount(prompt.id);

    // Insert the prompt content into the message input
    _messageController.text = prompt.content;
    _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length));

    // Focus on the text field
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Icon(
                Icons.smart_toy,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.bot.name,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Prompts',
            onPressed: () {
              _showPromptsBottomSheet(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showBotInfo(context);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset_thread') {
                _showResetThreadConfirmation(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset_thread',
                child: Row(
                  children: [
                    Icon(Icons.refresh, size: 20),
                    SizedBox(width: 8),
                    Text('Reset Conversation'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages
            Expanded(
              child: Stack(
                children: [
                  const AnimatedBackground(),
                  _messages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
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
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      _pendingMessageId.isNotEmpty
                          ? 'Typing...'
                          : 'Thinking...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

            // Message input
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 3,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 40,
                        maxHeight: 120,
                      ),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor:
                              Theme.of(context).colorScheme.surfaceVariant,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.auto_awesome),
                            tooltip: 'Browse prompts',
                            onPressed: () {
                              _showPromptsBottomSheet(context);
                            },
                          ),
                          isDense: true,
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        keyboardType: TextInputType.multiline,
                        enabled: !_isLoading,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    onPressed: _isLoading ? null : _sendMessage,
                    mini: true,
                    elevation: 2,
                    highlightElevation: 4,
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetThreadConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Conversation'),
        content: const Text(
          'This will clear the current conversation history with the AI. '
          'The AI will not remember previous messages. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              final aiBotService =
                  Provider.of<AIBotService>(context, listen: false);
              aiBotService.resetThread(widget.bot.id);

              setState(() {
                // Clear all messages except the welcome message
                _messages.clear();
                _messages.add(
                  Message(
                    id: 'welcome_reset',
                    content:
                        'Conversation has been reset. How can I help you today?',
                    type: MessageType.assistant,
                    timestamp: DateTime.now(),
                  ),
                );
                _isFirstMessage = true;
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversation has been reset'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showPromptsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return _PromptSelector(
              scrollController: scrollController,
              onSelectPrompt: (prompt) {
                Navigator.pop(context);
                _usePrompt(prompt);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
              widget.bot.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.bot.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Start chatting with ${widget.bot.name} by sending a message below.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _messageController.text = 'Hello! How can you help me today?';
              },
              child: const Text('Try a sample message'),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Browse prompts'),
              onPressed: () {
                _showPromptsBottomSheet(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBotInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.bot.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.bot.description,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Instructions:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.bot.instructions,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Knowledge Sources: ${widget.bot.knowledgeIds.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
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
}

class _PromptSelector extends StatefulWidget {
  final ScrollController scrollController;
  final Function(Prompt) onSelectPrompt;

  const _PromptSelector({
    required this.scrollController,
    required this.onSelectPrompt,
  });

  @override
  State<_PromptSelector> createState() => _PromptSelectorState();
}

class _PromptSelectorState extends State<_PromptSelector>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  PromptCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Handle
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Prompt Library',
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

        // Search
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search prompts...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),

        // Tabs
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Favorites'),
            Tab(text: 'My Prompts'),
          ],
        ),

        // Category filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildCategoryChip(null, 'All'),
              ...PromptCategory.values.map((category) => _buildCategoryChip(
                  category, Prompt.getCategoryName(category))),
            ],
          ),
        ),

        // Prompt list
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              // All prompts
              _buildPromptList(context,
                  (promptProvider) => _filterPrompts(promptProvider.prompts)),

              // Favorites
              _buildPromptList(
                  context,
                  (promptProvider) =>
                      _filterPrompts(promptProvider.favoritePrompts)),

              // My prompts
              _buildPromptList(
                  context,
                  (promptProvider) => _filterPrompts(promptProvider.prompts
                      .where((p) => !p.isPublic)
                      .toList())),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(PromptCategory? category, String label) {
    final isSelected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        avatar: category != null
            ? Icon(
                Prompt.getCategoryIcon(category),
                size: 18,
              )
            : null,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = selected ? category : null;
          });
        },
      ),
    );
  }

  List<Prompt> _filterPrompts(List<Prompt> prompts) {
    return prompts.where((prompt) {
      // Filter by category
      if (_selectedCategory != null && prompt.category != _selectedCategory) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return prompt.title.toLowerCase().contains(query) ||
            prompt.content.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  Widget _buildPromptList(
    BuildContext context,
    List<Prompt> Function(PromptProvider) promptsSelector,
  ) {
    return Consumer<PromptProvider>(
      builder: (context, promptProvider, child) {
        final prompts = promptsSelector(promptProvider);

        if (prompts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_awesome,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No prompts found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: widget.scrollController,
          itemCount: prompts.length,
          itemBuilder: (context, index) {
            final prompt = prompts[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Prompt.getCategoryIcon(prompt.category),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  prompt.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  prompt.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (prompt.isFavorite)
                      Icon(
                        Icons.favorite,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ElevatedButton(
                      onPressed: () {
                        widget.onSelectPrompt(prompt);
                      },
                      child: const Text('Use'),
                    ),
                  ],
                ),
                onTap: () {
                  widget.onSelectPrompt(prompt);
                },
              ),
            );
          },
        );
      },
    );
  }
}
