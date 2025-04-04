import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_bot_service.dart';
import '../../services/knowledge_service.dart';
import '../../models/knowledge_item.dart';
import '../../widgets/animated_background.dart';

class KnowledgeCreateScreen extends StatefulWidget {
  const KnowledgeCreateScreen({super.key});

  @override
  State<KnowledgeCreateScreen> createState() => _KnowledgeCreateScreenState();
}

class _KnowledgeCreateScreenState extends State<KnowledgeCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();
  String _selectedSource =
      'text'; // 'text', 'file', 'url', 'drive', 'slack', 'confluence'
  String _selectedFileType = 'txt'; // 'txt', 'pdf', 'doc', 'docx'
  bool _isLoading = false;
  final _knowledgeService = KnowledgeService();
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _createKnowledge() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Call the actual API to create the knowledge item
        final newKnowledge = await _knowledgeService.createKnowledge(
          knowledgeName: _titleController.text.trim(),
          description: _selectedSource == 'text'
              ? _contentController.text.trim()
              : 'Content from ${_selectedSource}: ${_urlController.text}',
        );

        // Add to the service for local state management
        final aiBotService = Provider.of<AIBotService>(context, listen: false);
        aiBotService.addKnowledgeItem(newKnowledge);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Knowledge source created successfully'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Return true to indicate successful creation
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to create knowledge source: ${e.toString()}'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Knowledge Source'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _createKnowledge,
            child: _isLoading
                ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
                : const Text('Create'),
          ),
        ],
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Error message if any
                  if (_errorMessage != null) ...[
                    Container(
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
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter a title for this knowledge source',
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 24),

                  // Source type selector
                  Text(
                    'Source Type',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Source type options
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildSourceChip('text', 'Text', Icons.text_fields),
                      _buildSourceChip(
                          'file', 'File Upload', Icons.upload_file),
                      _buildSourceChip('url', 'Website URL', Icons.link),
                      _buildSourceChip('drive', 'Google Drive', Icons.cloud),
                      _buildSourceChip('slack', 'Slack', Icons.chat),
                      _buildSourceChip(
                          'confluence', 'Confluence', Icons.article),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Content fields based on selected source
                  if (_selectedSource == 'text') ...[
                    Text(
                      'Content',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.5),
                        ),
                      ),
                      child: TextFormField(
                        controller: _contentController,
                        decoration: const InputDecoration(
                          hintText: 'Enter the content...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16),
                        ),
                        maxLines: 10,
                        validator: (value) {
                          if (_selectedSource == 'text' &&
                              (value == null || value.isEmpty)) {
                            return 'Please enter some content';
                          }
                          return null;
                        },
                      ),
                    ),
                  ] else ...[
                    // File type selector (for file uploads)
                    if (_selectedSource == 'file') ...[
                      Text(
                        'File Type',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          _buildFileTypeChip('txt', 'TXT'),
                          _buildFileTypeChip('pdf', 'PDF'),
                          _buildFileTypeChip('doc', 'DOC'),
                          _buildFileTypeChip('docx', 'DOCX'),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // URL or file path field
                    TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: _getUrlFieldLabel(),
                        hintText: _getUrlFieldHint(),
                        prefixIcon: Icon(_getUrlFieldIcon()),
                      ),
                      validator: (value) {
                        if (_selectedSource != 'text' &&
                            (value == null || value.isEmpty)) {
                          return 'Please enter a ${_selectedSource == 'url' ? 'URL' : 'source'}';
                        }
                        if (_selectedSource == 'url' &&
                            value != null &&
                            !value.startsWith('http')) {
                          return 'Please enter a valid URL starting with http:// or https://';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    // Upload button for file
                    if (_selectedSource == 'file')
                      ElevatedButton.icon(
                        onPressed: () {
                          // File picker would be implemented here
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'File picker not implemented in this demo'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Choose File'),
                      ),

                    // Connect button for external services
                    if (['drive', 'slack', 'confluence']
                        .contains(_selectedSource))
                      ElevatedButton.icon(
                        onPressed: () {
                          // OAuth flow would be implemented here
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  '${_selectedSource.toUpperCase()} integration not implemented in this demo'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: Icon(_getConnectButtonIcon()),
                        label:
                        Text('Connect to ${_selectedSource.toUpperCase()}'),
                      ),
                  ],

                  const SizedBox(height: 32),

                  // Create button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createKnowledge,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Text(
                        'Create Knowledge Source',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceChip(String value, String label, IconData icon) {
    final isSelected = _selectedSource == value;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimary
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedSource = value;
        });
      },
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primary,
      checkmarkColor: Theme.of(context).colorScheme.onPrimary,
    );
  }

  Widget _buildFileTypeChip(String value, String label) {
    final isSelected = _selectedFileType == value;

    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFileType = value;
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

  String _getUrlFieldLabel() {
    switch (_selectedSource) {
      case 'file':
        return 'File Path';
      case 'url':
        return 'Website URL';
      case 'drive':
        return 'Google Drive URL';
      case 'slack':
        return 'Slack Channel/Message URL';
      case 'confluence':
        return 'Confluence Page URL';
      default:
        return 'Source';
    }
  }

  String _getUrlFieldHint() {
    switch (_selectedSource) {
      case 'file':
        return 'Select a file to upload';
      case 'url':
        return 'Enter the website URL';
      case 'drive':
        return 'Enter Google Drive document URL';
      case 'slack':
        return 'Enter Slack channel or message URL';
      case 'confluence':
        return 'Enter Confluence page URL';
      default:
        return 'Enter source location';
    }
  }

  IconData _getUrlFieldIcon() {
    switch (_selectedSource) {
      case 'file':
        return Icons.upload_file;
      case 'url':
        return Icons.link;
      case 'drive':
        return Icons.cloud;
      case 'slack':
        return Icons.chat;
      case 'confluence':
        return Icons.article;
      default:
        return Icons.link;
    }
  }

  IconData _getConnectButtonIcon() {
    switch (_selectedSource) {
      case 'drive':
        return Icons.cloud;
      case 'slack':
        return Icons.chat;
      case 'confluence':
        return Icons.article;
      default:
        return Icons.link;
    }
  }
}

