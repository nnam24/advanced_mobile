import 'package:flutter/material.dart';

class EmailComposeScreen extends StatefulWidget {
  const EmailComposeScreen({super.key});

  @override
  State<EmailComposeScreen> createState() => _EmailComposeScreenState();
}

class _EmailComposeScreenState extends State<EmailComposeScreen> {
  final TextEditingController _toController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  bool _isGenerating = false;

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _applyTemplate(String type) {
    if (!mounted) return;

    setState(() {
      _isGenerating = true;
    });

    // Simulate AI generating email content
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      String subject = '';
      String body = '';
      String recipient = _toController.text.isNotEmpty
          ? _toController.text.split('@')[0]
          : "Recipient";

      switch (type) {
        case 'thanks':
          subject = 'Thank You';
          body =
              'Dear $recipient,\n\nI wanted to express my sincere gratitude for your help and support.\n\nBest regards,\n[Your Name]';
          break;
        case 'sorry':
          subject = 'My Apologies';
          body =
              'Dear $recipient,\n\nI wanted to sincerely apologize for the inconvenience caused.\n\nSincerely,\n[Your Name]';
          break;
        case 'yes':
          subject = 'Confirming: Yes';
          body =
              'Dear $recipient,\n\nI am writing to confirm that I agree with the proposal.\n\nBest regards,\n[Your Name]';
          break;
        case 'no':
          subject = 'Response: Unable to Proceed';
          body =
              'Dear $recipient,\n\nAfter careful consideration, I regret to inform you that I won\'t be able to proceed at this time.\n\nKind regards,\n[Your Name]';
          break;
        default:
          subject = 'New Message';
          body =
              'Dear $recipient,\n\n[Your message here]\n\nBest regards,\n[Your Name]';
      }

      setState(() {
        _subjectController.text = subject;
        _bodyController.text = body;
        _isGenerating = false;
      });

      // Show a confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type template applied'),
          duration: const Duration(seconds: 1),
        ),
      );
    });
  }

  void _sendEmail() {
    if (!mounted) return;

    // In a real app, this would send the email
    // For now, just show a success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email draft created successfully'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Clear the form
    _toController.clear();
    _subjectController.clear();
    _bodyController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Define colors based on theme
    final backgroundColor = isDark ? Colors.grey[900] : Colors.grey[50];
    final cardColor = isDark ? Colors.grey[850] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: backgroundColor,
      // This is important to handle keyboard appearance
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        // Use LayoutBuilder to get available height
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  // Make sure content can scroll when keyboard appears
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      // Ensure the content takes at least the full height
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment
                              .stretch, // Make all children stretch to full width
                          children: [
                            // Email header
                            Card(
                              elevation: 2,
                              color: cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // To field
                                    const Text(
                                      'To:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextField(
                                      controller: _toController,
                                      style: TextStyle(color: textColor),
                                      decoration: InputDecoration(
                                        hintText: 'Recipients',
                                        hintStyle: TextStyle(color: hintColor),
                                        border: InputBorder.none,
                                      ),
                                    ),

                                    const SizedBox(height: 16),

                                    // Subject field
                                    const Text(
                                      'Subject:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    TextField(
                                      controller: _subjectController,
                                      style: TextStyle(color: textColor),
                                      decoration: InputDecoration(
                                        hintText: 'Subject',
                                        hintStyle: TextStyle(color: hintColor),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Email templates - now with full width
                            Card(
                              elevation: 2,
                              color: cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Email Templates',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),

                                    const SizedBox(height: 12),

                                    // Template buttons in a wrap to handle overflow
                                    // Using SizedBox.expand to ensure it takes full width
                                    SizedBox(
                                      width:
                                          double.infinity, // Force full width
                                      child: Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        alignment: WrapAlignment
                                            .start, // Align to start
                                        children: [
                                          _buildTemplateButton(
                                              'Thanks', Colors.blue),
                                          _buildTemplateButton(
                                              'Sorry', Colors.orange),
                                          _buildTemplateButton(
                                              'Yes', Colors.green),
                                          _buildTemplateButton(
                                              'No', Colors.red),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Email body - using a fixed height to avoid overflow
                            Card(
                              elevation: 2,
                              color: cardColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Message:',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),

                                    const SizedBox(height: 8),

                                    // Fixed height text field
                                    SizedBox(
                                      height: 200, // Fixed height
                                      child: TextField(
                                        controller: _bodyController,
                                        style: TextStyle(color: textColor),
                                        maxLines: null,
                                        expands: true,
                                        textAlignVertical:
                                            TextAlignVertical.top,
                                        decoration: InputDecoration(
                                          hintText: 'Compose email...',
                                          hintStyle:
                                              TextStyle(color: hintColor),
                                          border: InputBorder.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Action buttons - now in a full-width container
                            SizedBox(
                              width: double.infinity, // Force full width
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton(
                                    onPressed: () {
                                      // Clear the form
                                      _toController.clear();
                                      _subjectController.clear();
                                      _bodyController.clear();
                                    },
                                    child: const Text('Discard'),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton(
                                    onPressed: _sendEmail,
                                    child: const Text('Create Draft'),
                                  ),
                                ],
                              ),
                            ),

                            // Add extra space at the bottom to ensure scrollability
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // Loading overlay
            if (_isGenerating)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                theme.colorScheme.primary),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Generating email...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateButton(String label, Color color) {
    return ElevatedButton(
      onPressed: () => _applyTemplate(label.toLowerCase()),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }
}
