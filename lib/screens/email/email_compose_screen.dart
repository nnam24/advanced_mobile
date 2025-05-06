import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/email_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/ai_action_button.dart';

class EmailComposeScreen extends StatefulWidget {
  const EmailComposeScreen({Key? key}) : super(key: key);

  @override
  State<EmailComposeScreen> createState() => _EmailComposeScreenState();
}

class _EmailComposeScreenState extends State<EmailComposeScreen> {
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final FocusNode _bodyFocusNode = FocusNode();
  bool _showAIActions = false;
  bool _showReplyIdeas = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final emailProvider = Provider.of<EmailProvider>(context, listen: false);
      _subjectController.text = emailProvider.subject;
      _recipientController.text = emailProvider.recipient;
      _bodyController.text = emailProvider.emailContent;
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _recipientController.dispose();
    _bodyController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  void _updateProviderState() {
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);
    emailProvider.setSubject(_subjectController.text);
    emailProvider.setRecipient(_recipientController.text);
    emailProvider.setEmailContent(_bodyController.text);
  }

  void _generateEmailWithIntent(String intent) async {
    _updateProviderState();
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);
    
    await emailProvider.generateEmailWithIntent(intent: intent);
    
    if (emailProvider.error.isEmpty && emailProvider.generatedResponse.isNotEmpty) {
      setState(() {
        _bodyController.text = emailProvider.generatedResponse;
      });
    } else if (emailProvider.error.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${emailProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _getReplyIdeas() async {
    _updateProviderState();
    final emailProvider = Provider.of<EmailProvider>(context, listen: false);
    
    await emailProvider.getReplyIdeas();
    
    if (emailProvider.error.isEmpty && emailProvider.replyIdeas.isNotEmpty) {
      setState(() {
        _showReplyIdeas = true;
      });
    } else if (emailProvider.error.isNotEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${emailProvider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _useReplyIdea(String idea) {
    setState(() {
      _bodyController.text = idea;
      _showReplyIdeas = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<EmailProvider, SubscriptionProvider>(
      builder: (context, emailProvider, subscriptionProvider, _) {
        final hasEnoughTokens = subscriptionProvider.hasUnlimitedTokens || 
                               subscriptionProvider.availableTokens >= 10;
        
        return Scaffold(
          body: Column(
            children: [
              // Token indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                child: Row(
                  children: [
                    Icon(
                      Icons.token,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: subscriptionProvider.isLoadingTokens
                          ? LinearProgressIndicator(
                              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            )
                          : LinearProgressIndicator(
                              value: subscriptionProvider.tokenAvailabilityPercentage,
                              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                subscriptionProvider.tokenAvailabilityPercentage > 0.2
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.red,
                              ),
                            ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      subscriptionProvider.hasUnlimitedTokens
                          ? 'Unlimited'
                          : '${subscriptionProvider.availableTokens} / ${subscriptionProvider.totalTokens}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Email remaining usage
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                child: Row(
                  children: [
                    Icon(
                      Icons.email,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Email AI Usage: ${emailProvider.remainingUsage} remaining',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: Icon(
                        _showAIActions ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                      ),
                      label: Text(
                        _showAIActions ? 'Hide AI Actions' : 'Show AI Actions',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          _showAIActions = !_showAIActions;
                          _showReplyIdeas = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              // AI Actions
              if (_showAIActions)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          'AI Email Actions',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            AIActionButton(
                              icon: Icons.thumb_up,
                              label: 'Thanks',
                              onPressed: hasEnoughTokens 
                                ? () => _generateEmailWithIntent('thanks')
                                : null,
                              isLoading: emailProvider.isGenerating,
                            ),
                            AIActionButton(
                              icon: Icons.sentiment_dissatisfied,
                              label: 'Sorry',
                              onPressed: hasEnoughTokens 
                                ? () => _generateEmailWithIntent('sorry')
                                : null,
                              isLoading: emailProvider.isGenerating,
                            ),
                            AIActionButton(
                              icon: Icons.check_circle,
                              label: 'Yes',
                              onPressed: hasEnoughTokens 
                                ? () => _generateEmailWithIntent('yes')
                                : null,
                              isLoading: emailProvider.isGenerating,
                            ),
                            AIActionButton(
                              icon: Icons.cancel,
                              label: 'No',
                              onPressed: hasEnoughTokens 
                                ? () => _generateEmailWithIntent('no')
                                : null,
                              isLoading: emailProvider.isGenerating,
                            ),
                            AIActionButton(
                              icon: Icons.update,
                              label: 'Follow Up',
                              onPressed: hasEnoughTokens 
                                ? () => _generateEmailWithIntent('followup')
                                : null,
                              isLoading: emailProvider.isGenerating,
                            ),
                            AIActionButton(
                              icon: Icons.help,
                              label: 'More Info',
                              onPressed: hasEnoughTokens 
                                ? () => _generateEmailWithIntent('moreinfo')
                                : null,
                              isLoading: emailProvider.isGenerating,
                            ),
                            AIActionButton(
                              icon: Icons.lightbulb,
                              label: 'Ideas',
                              onPressed: hasEnoughTokens 
                                ? _getReplyIdeas
                                : null,
                              isLoading: emailProvider.isGenerating,
                            ),
                          ],
                        ),
                      ),
                      
                      // Reply Ideas
                      if (_showReplyIdeas && emailProvider.replyIdeas.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Reply Ideas',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    onPressed: () {
                                      setState(() {
                                        _showReplyIdeas = false;
                                      });
                                    },
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const Divider(),
                              ...emailProvider.replyIdeas.map((idea) => 
                                InkWell(
                                  onTap: () => _useReplyIdea(idea),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    child: Text(idea),
                                  ),
                                ),
                              ).toList(),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              
              // Email form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _recipientController,
                        decoration: const InputDecoration(
                          labelText: 'To',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        onChanged: (value) {
                          emailProvider.setRecipient(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.subject),
                        ),
                        onChanged: (value) {
                          emailProvider.setSubject(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _bodyController,
                        focusNode: _bodyFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Email Body',
                          alignLabelWithHint: true,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.email),
                          suffixIcon: emailProvider.isGenerating
                            ? Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: _bodyController.text.isEmpty
                                  ? null
                                  : () {
                                      setState(() {
                                        _bodyController.clear();
                                      });
                                      emailProvider.setEmailContent('');
                                    },
                              ),
                        ),
                        maxLines: 15,
                        minLines: 10,
                        onChanged: (value) {
                          emailProvider.setEmailContent(value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom actions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.delete),
                        label: const Text('Discard'),
                        onPressed: () {
                          setState(() {
                            _subjectController.clear();
                            _recipientController.clear();
                            _bodyController.clear();
                          });
                          emailProvider.setSubject('');
                          emailProvider.setRecipient('');
                          emailProvider.setEmailContent('');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.send),
                        label: const Text('Send'),
                        onPressed: () {
                          // Implement send functionality
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Email sent successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          setState(() {
                            _subjectController.clear();
                            _recipientController.clear();
                            _bodyController.clear();
                          });
                          emailProvider.setSubject('');
                          emailProvider.setRecipient('');
                          emailProvider.setEmailContent('');
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
