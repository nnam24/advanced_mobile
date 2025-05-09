import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/email_suggestion_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/email_action_button.dart';

class EmailTabScreen extends StatefulWidget {
  const EmailTabScreen({Key? key}) : super(key: key);

  @override
  State<EmailTabScreen> createState() => _EmailTabScreenState();
}

class _EmailTabScreenState extends State<EmailTabScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showActions = true;
  bool _showReplyIdeas = false;
  bool _showGeneratedResponse = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final emailProvider = Provider.of<EmailSuggestionProvider>(context, listen: false);
      _emailController.text = emailProvider.emailContent;
      _subjectController.text = emailProvider.subject;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _updateProviderState() {
    final emailProvider = Provider.of<EmailSuggestionProvider>(context, listen: false);
    emailProvider.setEmailContent(_emailController.text);
    emailProvider.setSubject(_subjectController.text);
    // Mặc định sender và receiver
    emailProvider.setSender('TT Hỗ trợ sinh viên Trường ĐH Khoa học Tự nhiên, ĐHQG-HCM');
    emailProvider.setReceiver('haonamviettel2003@gmail.com');
  }

  void _generateEmailWithIntent(String intent) async {
    _updateProviderState();
    final emailProvider = Provider.of<EmailSuggestionProvider>(context, listen: false);
    
    await emailProvider.generateEmailWithIntent(intent: intent);
    
    if (emailProvider.error.isEmpty && emailProvider.generatedResponse.isNotEmpty) {
      setState(() {
        _showGeneratedResponse = true;
        _showReplyIdeas = false;
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

  void _getReplyIdeas() async {
    _updateProviderState();
    final emailProvider = Provider.of<EmailSuggestionProvider>(context, listen: false);
    
    await emailProvider.getReplyIdeas();
    
    if (emailProvider.error.isEmpty && emailProvider.replyIdeas.isNotEmpty) {
      setState(() {
        _showReplyIdeas = true;
        _showGeneratedResponse = false;
      });
      
      // Scroll to bottom to show reply ideas
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
    // Implement clipboard functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép vào clipboard'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<EmailSuggestionProvider, SubscriptionProvider>(
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
                          ? 'Không giới hạn'
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
                      'Email AI: còn ${emailProvider.remainingUsage} lượt sử dụng',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      icon: Icon(
                        _showActions ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                      ),
                      label: Text(
                        _showActions ? 'Ẩn hành động AI' : 'Hiện hành động AI',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () {
                        setState(() {
                          _showActions = !_showActions;
                        });
                      },
                    ),
                  ],
                ),
              ),
              
              // AI Actions
              if (_showActions)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          'Hành động AI Email',
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
                            EmailActionButton(
                              icon: Icons.thumb_up,
                              label: 'Cảm ơn',
                              onPressed: hasEnoughTokens && _emailController.text.isNotEmpty
                                ? () => _generateEmailWithIntent('thanks')
                                : null,
                              isLoading: emailProvider.isGenerating,
                            ),
                            EmailActionButton(
                              icon: Icons.sentiment_dissatisfied,
                              label: 'Xin lỗi',
                              onPressed: hasEnoughTokens && _emailController.text.isNotEmpty
                                ? () => _generateEmailWithIntent('sorry')
                                : null,
                              isLoading: emailProvider.isGenerating,
                            ),
                            EmailActionButton(
                              icon: Icons.check_circle,
                              label: 'Đồng ý',
                              onPressed: hasEnoughTokens && _emailController.text.isNotEmpty
                                ? () => _generateEmailWithIntent('yes')
                                : null,
                              isLoading: emailProvider.isGenerating,
                            ),
                            EmailActionButton(
                              icon: Icons.cancel,
                              label: 'Từ chối',
                              onPressed: hasEnoughTokens && _emailController.text.isNotEmpty
                                ? () => _generateEmailWithIntent('no')
                                : null,
                              isLoading: emailProvider.isGenerating,
                            ),
                            EmailActionButton(
                              icon: Icons.update,
                              label: 'Theo dõi',
                              onPressed: hasEnoughTokens && _emailController.text.isNotEmpty
                                ? () => _generateEmailWithIntent('followup')
                                : null,
                              isLoading: emailProvider.isGenerating,
                            ),
                            EmailActionButton(
                              icon: Icons.help,
                              label: 'Thêm thông tin',
                              onPressed: hasEnoughTokens && _emailController.text.isNotEmpty
                                ? () => _generateEmailWithIntent('moreinfo')
                                : null,
                              isLoading: emailProvider.isGenerating,
                            ),
                            EmailActionButton(
                              icon: Icons.lightbulb,
                              label: 'Gợi ý',
                              onPressed: hasEnoughTokens && _emailController.text.isNotEmpty
                                ? _getReplyIdeas
                                : null,
                              isLoading: emailProvider.isGenerating,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Email content
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject field
                      TextField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          labelText: 'Tiêu đề email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.subject),
                        ),
                        onChanged: (value) {
                          emailProvider.setSubject(value);
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Email content field
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Nội dung email',
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
                                onPressed: _emailController.text.isEmpty
                                  ? null
                                  : () {
                                      setState(() {
                                        _emailController.clear();
                                        _showReplyIdeas = false;
                                        _showGeneratedResponse = false;
                                      });
                                      emailProvider.setEmailContent('');
                                    },
                              ),
                        ),
                        maxLines: 10,
                        minLines: 5,
                        onChanged: (value) {
                          emailProvider.setEmailContent(value);
                        },
                      ),
                      
                      // Reply Ideas
                      if (_showReplyIdeas && emailProvider.replyIdeas.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Gợi ý trả lời',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _showReplyIdeas = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const Divider(),
                              ...emailProvider.replyIdeas.map((idea) => 
                                Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(idea),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.content_copy),
                                      onPressed: () => _copyToClipboard(idea),
                                    ),
                                    onTap: () {
                                      // Generate full response based on this idea
                                      _emailController.text = idea;
                                      emailProvider.setEmailContent(idea);
                                      _generateEmailWithIntent('default');
                                    },
                                  ),
                                ),
                              ).toList(),
                            ],
                          ),
                        ),
                      
                      // Generated Response
                      if (_showGeneratedResponse && emailProvider.generatedResponse.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.email,
                                    size: 20,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Email được tạo',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Theme.of(context).colorScheme.primary,
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
                                  ),
                                ],
                              ),
                              const Divider(),
                              SelectableText(
                                emailProvider.generatedResponse,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    icon: const Icon(Icons.edit),
                                    label: const Text('Chỉnh sửa'),
                                    onPressed: () {
                                      setState(() {
                                        _emailController.text = emailProvider.generatedResponse;
                                        _showGeneratedResponse = false;
                                      });
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.content_copy),
                                    label: const Text('Sao chép'),
                                    onPressed: () => _copyToClipboard(emailProvider.generatedResponse),
                                  ),
                                ],
                              ),
                              
                              // Improved Actions if available
                              if (emailProvider.improvedActions.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 16),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Hành động được cải thiện:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: emailProvider.improvedActions.map((action) => 
                                          Chip(
                                            label: Text(action),
                                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                            labelStyle: TextStyle(
                                              color: Theme.of(context).colorScheme.onPrimaryContainer,
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
              ),
            ],
          ),
        );
      },
    );
  }
}
