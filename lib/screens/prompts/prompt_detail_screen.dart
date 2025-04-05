import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../../providers/prompt_provider.dart';
import '../../models/prompt.dart';
import '../../widgets/animated_background.dart';
import 'prompt_edit_screen.dart';
import 'prompts_screen.dart'; // Import for navigation

class PromptDetailScreen extends StatefulWidget {
  final String promptId;
  final Prompt? prompt; // Add optional prompt parameter

  const PromptDetailScreen({
    super.key,
    required this.promptId,
    this.prompt, // Make it optional
  });

  @override
  State<PromptDetailScreen> createState() => _PromptDetailScreenState();
}

class _PromptDetailScreenState extends State<PromptDetailScreen> {
  bool _isLoading = false;
  Prompt? _prompt; // Store the prompt locally
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Log the promptId for debugging
    print('PromptDetailScreen - promptId: ${widget.promptId}');

    // Check if we have a valid promptId
    if (widget.promptId.isEmpty) {
      _errorMessage = 'Invalid prompt ID provided';
      print('PromptDetailScreen - Error: $_errorMessage');
    }

    // If prompt was passed directly, use it
    if (widget.prompt != null) {
      // Log the prompt ID for debugging
      print('PromptDetailScreen - prompt.id: ${widget.prompt!.id}');

      // Check if the prompt has a valid ID
      if (widget.prompt!.id.isEmpty) {
        print('PromptDetailScreen - Warning: Prompt object has empty ID');

        // If the promptId from the widget is valid, try to use that
        if (widget.promptId.isNotEmpty) {
          // Create a new prompt with the valid ID
          _prompt = widget.prompt!.copyWith(id: widget.promptId);
          print(
              'PromptDetailScreen - Using promptId from widget: ${_prompt!.id}');
        } else {
          _errorMessage = 'Prompt has no valid ID';
        }
      } else {
        _prompt = widget.prompt;
      }
    } else if (widget.promptId.isNotEmpty) {
      // If we only have a promptId, try to find the prompt in the provider
      _loadPromptFromProvider();
    }
  }

  void _loadPromptFromProvider() {
    if (widget.promptId.isEmpty) {
      setState(() {
        _errorMessage = 'Cannot load prompt: Invalid ID';
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final promptProvider =
          Provider.of<PromptProvider>(context, listen: false);

      // Try to get the prompt from the provider
      Prompt? prompt = promptProvider.getPromptById(widget.promptId);

      if (prompt != null) {
        print('PromptDetailScreen - Found prompt in provider: ${prompt.id}');
      } else {
        print('PromptDetailScreen - Prompt not found in provider');
      }

      if (mounted) {
        setState(() {
          _prompt = prompt;
          _isLoading = false;
          if (prompt == null) {
            _errorMessage = 'Prompt not found';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading prompt: $e';
        });
        print('PromptDetailScreen - Error: $_errorMessage');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_prompt?.title ?? 'Prompt Details'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView(context)
              : _buildPromptDetails(context),
    );
  }

  Widget _buildErrorView(BuildContext context) {
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
          const Text(
            'Error Loading Prompt',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage ?? 'Unknown error occurred',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
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
    );
  }

  Widget _buildPromptDetails(BuildContext context) {
    // Use the local prompt variable instead of getting it from the provider
    final prompt = _prompt;
    final promptProvider = Provider.of<PromptProvider>(context, listen: false);

    if (prompt == null) {
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
            const Text(
              'Prompt not found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The prompt you\'re looking for could not be found',
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
      );
    }

    final isPrivate = !prompt.isPublic;
    final isCurrentUser = true; // Replace with actual user check

    return Stack(
      children: [
        const AnimatedBackground(),
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Debug info for ID (can be removed in production)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Prompt ID: ${prompt.id.isEmpty ? "No ID" : prompt.id}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // Prompt header
              Container(
                padding: const EdgeInsets.all(16),
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
                          radius: 24,
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                          child: Icon(
                            Prompt.getCategoryIcon(prompt.category),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prompt.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${Prompt.getCategoryName(prompt.category)} • ${prompt.isPublic ? 'Public' : 'Private'}',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
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
                                  content: Text(
                                      'Cannot favorite: Prompt has no valid ID'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            promptProvider.toggleFavorite(prompt.id);
                            // Update local state to reflect the change
                            setState(() {
                              _prompt = _prompt?.copyWith(
                                isFavorite: !(_prompt?.isFavorite ?? false),
                              );
                            });
                          },
                        ),
                        if (isPrivate && isCurrentUser)
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'edit') {
                                // Check if the prompt has a valid ID before editing
                                if (prompt.id.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Cannot edit: Prompt has no valid ID'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        PromptEditScreen(prompt: prompt),
                                  ),
                                ).then((result) {
                                  // Refresh the prompt details if edit was successful
                                  if (result == true) {
                                    _loadPromptFromProvider();
                                  }
                                });
                              } else if (value == 'delete') {
                                // Check if the prompt has a valid ID before deleting
                                if (prompt.id.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Cannot delete: Prompt has no valid ID'),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }

                                _showDeleteConfirmation(context, prompt);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 8),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            context,
                            'Author',
                            prompt.userName,
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            context,
                            'Created',
                            _formatDate(prompt.createdAt),
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem(
                            context,
                            'Uses',
                            prompt.usageCount.toString(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Prompt content
              Text(
                'Prompt',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      prompt.content,
                      style: const TextStyle(height: 1.5),
                    ),
                    if (prompt.description != null &&
                        prompt.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Description',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(prompt.description!),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: prompt.content));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Prompt copied to clipboard'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Use prompt button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Check if the prompt has a valid ID before incrementing usage count
                    if (prompt.id.isNotEmpty) {
                      promptProvider.incrementUsageCount(prompt.id);
                    }
                    Navigator.pop(context, prompt);
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Use in Chat'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
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

  void _showDeleteConfirmation(BuildContext context, Prompt prompt) {
    // Get the provider reference before any async operations
    final promptProvider = Provider.of<PromptProvider>(context, listen: false);
    final int tabIndex = prompt.isPublic ? 0 : 1;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Prompt'),
        content: Text(
            'Are you sure you want to delete "${prompt.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Close the dialog first
              Navigator.of(dialogContext).pop();

              // Check if the prompt has a valid ID before deleting
              if (prompt.id.isEmpty) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cannot delete: Prompt has no valid ID'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return;
              }

              // Show loading indicator
              if (context.mounted) {
                setState(() {
                  _isLoading = true;
                });
              }

              // Delete the prompt
              final success = await promptProvider.deletePrompt(prompt.id);

              // Only proceed if the widget is still mounted
              if (!context.mounted) return;

              // Hide loading indicator
              setState(() {
                _isLoading = false;
              });

              if (success) {
                // Show success notification
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Prompt deleted successfully'),
                    behavior: SnackBarBehavior.floating,
                    duration: Duration(seconds: 2),
                  ),
                );

                // Wait a moment to ensure the snackbar is visible
                await Future.delayed(const Duration(milliseconds: 300));

                // Only navigate if still mounted
                if (context.mounted) {
                  // Navigate to the PromptsScreen and replace the current screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => PromptsScreen(
                        initialTabIndex: tabIndex,
                      ),
                    ),
                    (route) => false, // Remove all previous routes
                  );
                }
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Failed to delete prompt: ${promptProvider.error ?? "Unknown error"}'),
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
}
