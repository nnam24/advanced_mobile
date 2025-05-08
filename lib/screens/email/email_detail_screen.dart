import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/email_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/ai_action_button.dart';
import '../../models/email_model.dart';

class EmailDetailScreen extends StatefulWidget {
  final Function(EmailModel) onEditEmail;

  const EmailDetailScreen({
    Key? key,
    required this.onEditEmail,
  }) : super(key: key);

  @override
  State<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showActions = true;
  bool _showGeneratedResponse = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _generateEmailWithAction(String action) async {
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);

    // Chuyển đổi action thành text
    String actionText;
    switch (action) {
      case 'thanks':
        actionText = 'Write a thank you email';
        break;
      case 'sorry':
        actionText = 'Write an apology email';
        break;
      case 'yes':
        actionText = 'Write an email agreeing';
        break;
      case 'no':
        actionText = 'Write a polite rejection email';
        break;
      case 'followup':
        actionText = 'Write a follow-up email';
        break;
      case 'moreinfo':
        actionText = 'Write an email requesting more information';
        break;
      default:
        actionText = 'Write a comprehensive response email';
    }

    await emailProvider.generateEmailWithAction(action: actionText);

    if (emailProvider.error.isEmpty && emailProvider.generatedResponse.isNotEmpty) {
      setState(() {
        _showGeneratedResponse = true;
      });

      // Scroll to bottom to show generated response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else if (emailProvider.error.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${emailProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _saveGeneratedEmail() async {
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);

    try {
      await emailProvider.saveGeneratedEmail();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email saved'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          _showGeneratedResponse = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer2<EmailProvider, SubscriptionProvider>(
      builder: (context, emailProvider, subscriptionProvider, _) {
        final email = emailProvider.selectedEmail;

        if (email == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Email Details'),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            body: const Center(
              child: Text('No email selected'),
            ),
          );
        }

        final hasEnoughTokens = subscriptionProvider.hasUnlimitedTokens ||
            subscriptionProvider.availableTokens >= 10;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Email Details'),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                // Đảm bảo quay về email_list_screen
                Navigator.of(context).pop();
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => widget.onEditEmail(email),
                tooltip: 'Edit',
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  // Xác nhận xóa
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Confirm Delete'),
                      content: const Text('Are you sure you want to delete this email?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await emailProvider.deleteEmail(email.id);
                    if (mounted) {
                      Navigator.of(context).pop();
                    }
                  }
                },
                tooltip: 'Delete',
              ),
            ],
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email header
                Container(
                  padding: const EdgeInsets.all(16),
                  color: colorScheme.primary.withOpacity(0.1),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email.subject,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Color((email.sender.hashCode & 0xFFFFFF) | 0xFF000000),
                            radius: 20,
                            child: Text(
                              email.sender.isNotEmpty ? email.sender[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Từ: ${email.sender}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Đến: ${email.receiver}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: colorScheme.onSurface.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Email content
                Container(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    email.content,
                    style: TextStyle(
                      fontSize: 16,
                      color: colorScheme.onSurface,
                      height: 1.5,
                    ),
                  ),
                ),

                const Divider(),

                // Email remaining usage
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.primary.withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Email AI: ${emailProvider.remainingUsage} uses remaining',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _showActions = !_showActions;
                          });
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _showActions ? 'Hide' : 'Show',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'AI Actions',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Icon(
                                  _showActions ? Icons.expand_less : Icons.expand_more,
                                  size: 16,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // AI Actions
                if (_showActions)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email AI Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              AIActionButton(
                                icon: Icons.thumb_up,
                                label: 'Thanks',
                                onPressed: hasEnoughTokens
                                    ? () => _generateEmailWithAction('thanks')
                                    : null,
                                isLoading: emailProvider.isGenerating,
                                color: colorScheme.primary,
                              ),
                              AIActionButton(
                                icon: Icons.sentiment_dissatisfied,
                                label: 'Sorry',
                                onPressed: hasEnoughTokens
                                    ? () => _generateEmailWithAction('sorry')
                                    : null,
                                isLoading: emailProvider.isGenerating,
                                color: colorScheme.primary,
                              ),
                              AIActionButton(
                                icon: Icons.check_circle,
                                label: 'Agree',
                                onPressed: hasEnoughTokens
                                    ? () => _generateEmailWithAction('yes')
                                    : null,
                                isLoading: emailProvider.isGenerating,
                                color: colorScheme.primary,
                              ),
                              AIActionButton(
                                icon: Icons.cancel,
                                label: 'Decline',
                                onPressed: hasEnoughTokens
                                    ? () => _generateEmailWithAction('no')
                                    : null,
                                isLoading: emailProvider.isGenerating,
                                color: colorScheme.primary,
                              ),
                              AIActionButton(
                                icon: Icons.update,
                                label: 'Follow up',
                                onPressed: hasEnoughTokens
                                    ? () => _generateEmailWithAction('followup')
                                    : null,
                                isLoading: emailProvider.isGenerating,
                                color: colorScheme.primary,
                              ),
                              AIActionButton(
                                icon: Icons.help,
                                label: 'More Info',
                                onPressed: hasEnoughTokens
                                    ? () => _generateEmailWithAction('moreinfo')
                                    : null,
                                isLoading: emailProvider.isGenerating,
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Generated Response
                if (_showGeneratedResponse && emailProvider.generatedResponse.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.email,
                                size: 20,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Generated Email',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _showGeneratedResponse = false;
                                  });
                                },
                                tooltip: 'Close',
                                color: colorScheme.primary,
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SelectableText(
                            emailProvider.generatedResponse,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit'),
                                onPressed: () {
                                  // Tạo email mới với nội dung được tạo
                                  final newEmail = EmailModel(
                                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                                    subject: 'Re: ${email.subject}',
                                    content: emailProvider.generatedResponse,
                                    sender: email.receiver,
                                    receiver: email.sender,
                                    timestamp: DateTime.now(),
                                  );

                                  widget.onEditEmail(newEmail);
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: const Text('Save'),
                                onPressed: _saveGeneratedEmail,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                icon: const Icon(Icons.content_copy),
                                label: const Text('Copy'),
                                onPressed: () => _copyToClipboard(emailProvider.generatedResponse),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.secondary,
                                  foregroundColor: colorScheme.onSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Improved Actions if available
                        if (emailProvider.improvedActions.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Improved Actions:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: emailProvider.improvedActions.map((action) =>
                                      Chip(
                                        label: Text(action),
                                        backgroundColor: colorScheme.primaryContainer,
                                        labelStyle: TextStyle(
                                          color: colorScheme.onPrimaryContainer,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ).toList(),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
