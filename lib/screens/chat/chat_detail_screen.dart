import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../providers/chat_provider.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/message_bubble.dart';

class ChatDetailScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    // Add scroll listener for pagination
    _scrollController.addListener(_scrollListener);

    // Fetch conversation messages if they're not already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (widget.conversation.messages.isEmpty) {
        chatProvider.fetchConversationDetails(widget.conversation.id);
      }
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels <=
            _scrollController.position.minScrollExtent + 50 &&
        !_isLoadingMore) {
      _loadMoreMessages();
    }
  }

  Future<void> _loadMoreMessages() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    if (chatProvider.hasMoreMessages(widget.conversation.id) &&
        !chatProvider.isLoadingMessages(widget.conversation.id)) {
      setState(() {
        _isLoadingMore = true;
      });
      await chatProvider.loadMoreMessages(widget.conversation.id);
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _refreshConversation() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    await chatProvider.fetchConversationDetails(widget.conversation.id);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.conversation.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _refreshConversation,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Export Conversation',
            onPressed: () => _exportConversation(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'rename') {
                _showRenameDialog(context);
              } else if (value == 'delete') {
                _showDeleteConfirmation(context);
              } else if (value == 'continue') {
                _continueConversation(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'continue',
                child: Row(
                  children: [
                    Icon(Icons.chat, size: 20),
                    SizedBox(width: 8),
                    Text('Continue Chat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rename',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Rename'),
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
              // Conversation info
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI Agent: ${widget.conversation.agentName}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Created: ${_formatDate(widget.conversation.createdAt)}',
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Consumer<ChatProvider>(
                        builder: (context, chatProvider, child) {
                          final conversation =
                              chatProvider.conversations.firstWhere(
                            (c) => c.id == widget.conversation.id,
                            orElse: () => widget.conversation,
                          );
                          return Text(
                            '${conversation.messages.length} messages',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Messages
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    final conversation = chatProvider.conversations.firstWhere(
                      (c) => c.id == widget.conversation.id,
                      orElse: () => widget.conversation,
                    );

                    if (chatProvider.isLoading &&
                        conversation.messages.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (conversation.messages.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return RefreshIndicator(
                      onRefresh: _refreshConversation,
                      child: ListView.builder(
                        controller: _scrollController,
                        reverse: true, // Display messages from bottom to top
                        padding: const EdgeInsets.all(16),
                        itemCount: conversation.messages.length +
                            (chatProvider.hasMoreMessages(conversation.id)
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          if (index == conversation.messages.length) {
                            // This is the loading indicator at the top
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          // Reverse the index to display messages from bottom to top
                          final messageIndex =
                              conversation.messages.length - 1 - index;
                          final message = conversation.messages[messageIndex];
                          final currentTimestamp =
                              message.timestamp ?? DateTime.now();

                          // Check if we need to show a date divider
                          bool showDateDivider = false;
                          if (messageIndex == 0) {
                            showDateDivider = true;
                          } else if (messageIndex > 0) {
                            final prevTimestamp = conversation
                                    .messages[messageIndex - 1].timestamp ??
                                DateTime.now();
                            showDateDivider =
                                !_isSameDay(currentTimestamp, prevTimestamp);
                          }

                          return Column(
                            children: [
                              MessageBubble(
                                key: ValueKey(message.id),
                                message: message,
                              ),
                              if (showDateDivider)
                                _buildDateDivider(context, currentTimestamp),
                            ],
                          );
                        },
                      ),
                    );
                  },
                ),
              ),

              // Continue chat button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.2),
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _continueConversation(context),
                    icon: const Icon(Icons.chat),
                    label: const Text('Continue this Conversation'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
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
          const Text(
            'No Messages',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This conversation has no messages yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _continueConversation(context),
            icon: const Icon(Icons.chat),
            label: const Text('Start Chatting'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(BuildContext context, DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider()),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _formatDateForDivider(timestamp),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Expanded(child: Divider()),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDateForDivider(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    if (_isSameDay(date, now)) {
      return 'Today';
    } else if (_isSameDay(date, yesterday)) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showRenameDialog(BuildContext context) {
    final TextEditingController titleController =
        TextEditingController(text: widget.conversation.title);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Conversation'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Conversation Title',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = titleController.text.trim();
              if (newTitle.isNotEmpty) {
                chatProvider.renameConversation(
                    widget.conversation.id, newTitle);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Conversation renamed successfully'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text(
            'Are you sure you want to delete this conversation? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              chatProvider.deleteConversation(widget.conversation.id);
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conversation deleted'),
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

  void _exportConversation(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final text = chatProvider.exportConversationToText(widget.conversation.id);

    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Conversation copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _continueConversation(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.selectConversation(widget.conversation.id);
    Navigator.of(context).pop();
  }
}
