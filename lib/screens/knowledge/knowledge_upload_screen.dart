import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../services/knowledge_service.dart';
import '../../models/knowledge_item.dart';
import '../../widgets/animated_background.dart';

class KnowledgeUploadScreen extends StatefulWidget {
  final KnowledgeItem knowledgeItem;

  const KnowledgeUploadScreen({super.key, required this.knowledgeItem});

  @override
  State<KnowledgeUploadScreen> createState() => _KnowledgeUploadScreenState();
}

class _KnowledgeUploadScreenState extends State<KnowledgeUploadScreen> with SingleTickerProviderStateMixin {
  final _knowledgeService = KnowledgeService();
  late TabController _tabController;

  // File upload variables
  bool _isUploading = false;
  String? _uploadError;
  String? _uploadSuccess;
  File? _selectedFile;
  String? _selectedFileName;

  // Website knowledge variables
  final _websiteNameController = TextEditingController();
  final _websiteUrlController = TextEditingController();
  final _websiteFormKey = GlobalKey<FormState>();
  bool _isAddingWebsite = false;
  String? _websiteError;
  String? _websiteSuccess;

  // Slack knowledge variables
  final _slackNameController = TextEditingController();
  final _slackWorkspaceController = TextEditingController();
  final _slackBotTokenController = TextEditingController();
  final _slackFormKey = GlobalKey<FormState>();
  bool _isAddingSlack = false;
  String? _slackError;
  String? _slackSuccess;

  // Add Confluence knowledge variables
  final _confluenceNameController = TextEditingController();
  final _confluenceUrlController = TextEditingController();
  final _confluenceUsernameController = TextEditingController();
  final _confluenceTokenController = TextEditingController();
  final _confluenceFormKey = GlobalKey<FormState>();
  bool _isAddingConfluence = false;
  String? _confluenceError;
  String? _confluenceSuccess;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _websiteNameController.dispose();
    _websiteUrlController.dispose();
    _slackNameController.dispose();
    _slackWorkspaceController.dispose();
    _slackBotTokenController.dispose();
    _confluenceNameController.dispose();
    _confluenceUrlController.dispose();
    _confluenceUsernameController.dispose();
    _confluenceTokenController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadFile() async {
    try {
      // Pick file with supported extensions only
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'c', 'cpp', 'docx', 'html', 'java', 'json', 'md',
          'pdf', 'php', 'pptx', 'py', 'rb', 'tex', 'txt'
        ],
      );

      if (result == null || result.files.single.path == null) {
        return; // User canceled the picker
      }

      final filePath = result.files.single.path!;
      final fileName = result.files.single.name;
      final fileSize = result.files.single.size;
      final fileExtension = fileName.split('.').last.toLowerCase();

      print('Selected file: $fileName, path: $filePath, size: $fileSize bytes, extension: $fileExtension');

      // Validate file type
      final validExtensions = ['c', 'cpp', 'docx', 'html', 'java', 'json', 'md',
        'pdf', 'php', 'pptx', 'py', 'rb', 'tex', 'txt'];

      if (!validExtensions.contains(fileExtension)) {
        throw Exception('Unsupported file type. Please select one of the supported file types.');
      }

      setState(() {
        _isUploading = true;
        _uploadError = null;
        _uploadSuccess = null;
        _selectedFile = File(filePath);
        _selectedFileName = fileName;
      });

      // Check if file exists and is readable
      if (!await _selectedFile!.exists()) {
        throw Exception('File does not exist: $filePath');
      }

      print('File exists and is readable');

      // Upload file
      final success = await _knowledgeService.uploadFileToKnowledge(
          widget.knowledgeItem.id,
          _selectedFile!
      );

      setState(() {
        _isUploading = false;
        if (success) {
          _uploadSuccess = 'File uploaded successfully';
          _selectedFile = null;
          _selectedFileName = null;
        }
      });

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Success!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('File "$_selectedFileName" has been uploaded to "${widget.knowledgeItem.title}"'),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error in _pickAndUploadFile: $e');
      setState(() {
        _isUploading = false;
        _uploadError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Failed to upload file: ${e.toString()}'),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _addWebsiteKnowledge() async {
    if (!_websiteFormKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isAddingWebsite = true;
        _websiteError = null;
        _websiteSuccess = null;
      });

      final unitName = _websiteNameController.text.trim();
      final webUrl = _websiteUrlController.text.trim();

      // Add website knowledge
      final result = await _knowledgeService.addWebsiteKnowledge(
          widget.knowledgeItem.id,
          unitName,
          webUrl
      );

      setState(() {
        _isAddingWebsite = false;
        _websiteSuccess = 'Website knowledge added successfully';
        // Clear the form
        _websiteNameController.clear();
        _websiteUrlController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Success!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Website "$unitName" has been added to "${widget.knowledgeItem.title}"'),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error in _addWebsiteKnowledge: $e');
      setState(() {
        _isAddingWebsite = false;
        _websiteError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Failed to add website knowledge: ${e.toString()}'),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _addSlackKnowledge() async {
    if (!_slackFormKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isAddingSlack = true;
        _slackError = null;
        _slackSuccess = null;
      });

      final unitName = _slackNameController.text.trim();
      final slackWorkspace = _slackWorkspaceController.text.trim();
      final slackBotToken = _slackBotTokenController.text.trim();

      // Add Slack knowledge
      final result = await _knowledgeService.addSlackKnowledge(
          widget.knowledgeItem.id,
          unitName,
          slackWorkspace,
          slackBotToken
      );

      setState(() {
        _isAddingSlack = false;
        _slackSuccess = 'Slack knowledge added successfully';
        // Clear the form
        _slackNameController.clear();
        _slackWorkspaceController.clear();
        _slackBotTokenController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Success!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Slack workspace "$unitName" has been added to "${widget.knowledgeItem.title}"'),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error in _addSlackKnowledge: $e');
      setState(() {
        _isAddingSlack = false;
        _slackError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Failed to add Slack knowledge: ${e.toString()}'),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 6),
          ),
        );
      }
    }
  }

  // Add the method to handle Confluence knowledge addition
  Future<void> _addConfluenceKnowledge() async {
    if (!_confluenceFormKey.currentState!.validate()) {
      return;
    }

    try {
      setState(() {
        _isAddingConfluence = true;
        _confluenceError = null;
        _confluenceSuccess = null;
      });

      final unitName = _confluenceNameController.text.trim();
      final wikiPageUrl = _confluenceUrlController.text.trim();
      final confluenceUsername = _confluenceUsernameController.text.trim();
      final confluenceAccessToken = _confluenceTokenController.text.trim();

      // Add Confluence knowledge
      final result = await _knowledgeService.addConfluenceKnowledge(
          widget.knowledgeItem.id,
          unitName,
          wikiPageUrl,
          confluenceUsername,
          confluenceAccessToken.isEmpty ? null : confluenceAccessToken
      );

      setState(() {
        _isAddingConfluence = false;
        _confluenceSuccess = 'Confluence knowledge added successfully';
        // Clear the form
        _confluenceNameController.clear();
        _confluenceUrlController.clear();
        _confluenceUsernameController.clear();
        _confluenceTokenController.clear();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Success!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Confluence wiki "$unitName" has been added to "${widget.knowledgeItem.title}"'),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error in _addConfluenceKnowledge: $e');
      setState(() {
        _isAddingConfluence = false;
        _confluenceError = e.toString();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Failed to add Confluence knowledge: ${e.toString()}'),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 6),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Data Source to ${widget.knowledgeItem.title}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.upload_file),
              text: 'File',
            ),
            Tab(
              icon: Icon(Icons.language),
              text: 'Website',
            ),
            Tab(
              icon: Icon(Icons.chat),
              text: 'Slack',
            ),
            Tab(
              icon: Icon(Icons.book_online),
              text: 'Confluence',
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          TabBarView(
            controller: _tabController,
            children: [
              // File Upload Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add a file to this knowledge source',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Upload a file to enhance your knowledge base. The file will be processed and its content will be made available for AI to learn from.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Supported file types: .c, .cpp, .docx, .html, .java, .json, .md, .pdf, .php, .pptx, .py, .rb, .tex, .txt',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Selected file info
                          if (_selectedFile != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.insert_drive_file,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedFileName ?? _selectedFile!.path.split('/').last,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '${(_selectedFile!.lengthSync() / 1024).toStringAsFixed(1)} KB',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _selectedFile = null;
                                        _selectedFileName = null;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Upload button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isUploading ? null : _pickAndUploadFile,
                              icon: _isUploading
                                  ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                                  : const Icon(Icons.upload_file),
                              label: Text(_isUploading ? 'Uploading...' : 'Select & Upload File'),
                            ),
                          ),

                          // Error message
                          if (_uploadError != null) ...[
                            const SizedBox(height: 16),
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
                                      _uploadError!,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          // Success message
                          if (_uploadSuccess != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.withOpacity(0.5)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _uploadSuccess!,
                                      style: const TextStyle(color: Colors.green),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Website Knowledge Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.2),
                        ),
                      ),
                      child: Form(
                        key: _websiteFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add a website to this knowledge source',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add a website URL to your knowledge base. The content of the website will be crawled and processed for AI to learn from.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Website Name field
                            TextFormField(
                              controller: _websiteNameController,
                              decoration: InputDecoration(
                                labelText: 'Website Name',
                                hintText: 'Enter a name for this website',
                                prefixIcon: Icon(Icons.web),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a website name';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Website URL field
                            TextFormField(
                              controller: _websiteUrlController,
                              decoration: InputDecoration(
                                labelText: 'Website URL',
                                hintText: 'Enter the website URL (e.g., https://example.com)',
                                prefixIcon: Icon(Icons.link),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a website URL';
                                }
                                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                                  return 'URL must start with http:// or https://';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Add Website button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isAddingWebsite ? null : _addWebsiteKnowledge,
                                icon: _isAddingWebsite
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                    : const Icon(Icons.add_link),
                                label: Text(_isAddingWebsite ? 'Adding...' : 'Add Website'),
                              ),
                            ),

                            // Error message
                            if (_websiteError != null) ...[
                              const SizedBox(height: 16),
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
                                        _websiteError!,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Success message
                            if (_websiteSuccess != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _websiteSuccess!,
                                        style: const TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Slack Knowledge Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.2),
                        ),
                      ),
                      child: Form(
                        key: _slackFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add a Slack workspace to this knowledge source',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Connect a Slack workspace to your knowledge base. Messages and content from the workspace will be processed for AI to learn from.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Slack Name field
                            TextFormField(
                              controller: _slackNameController,
                              decoration: InputDecoration(
                                labelText: 'Slack Integration Name',
                                hintText: 'Enter a name for this Slack integration',
                                prefixIcon: Icon(Icons.workspaces),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a name for the Slack integration';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Slack Workspace field
                            TextFormField(
                              controller: _slackWorkspaceController,
                              decoration: InputDecoration(
                                labelText: 'Slack Workspace',
                                hintText: 'Enter the Slack workspace name',
                                prefixIcon: Icon(Icons.chat),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a Slack workspace name';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Slack Bot Token field
                            TextFormField(
                              controller: _slackBotTokenController,
                              decoration: InputDecoration(
                                labelText: 'Slack Bot Token (Optional)',
                                hintText: 'Enter the Slack bot token or leave empty to use default',
                                prefixIcon: Icon(Icons.vpn_key),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                helperText: 'If left empty, a default token will be used',
                              ),
                              // No validator since this field is optional
                            ),

                            const SizedBox(height: 24),

                            // Add Slack button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isAddingSlack ? null : _addSlackKnowledge,
                                icon: _isAddingSlack
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                    : const Icon(Icons.add_comment),
                                label: Text(_isAddingSlack ? 'Adding...' : 'Add Slack Workspace'),
                              ),
                            ),

                            // Error message
                            if (_slackError != null) ...[
                              const SizedBox(height: 16),
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
                                        _slackError!,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Success message
                            if (_slackSuccess != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _slackSuccess!,
                                        style: const TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Confluence Knowledge Tab
              SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withOpacity(0.2),
                        ),
                      ),
                      child: Form(
                        key: _confluenceFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add a Confluence wiki to this knowledge source',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Connect a Confluence wiki to your knowledge base. Content from the wiki will be processed for AI to learn from.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Confluence Name field
                            TextFormField(
                              controller: _confluenceNameController,
                              decoration: InputDecoration(
                                labelText: 'Confluence Integration Name',
                                hintText: 'Enter a name for this Confluence integration',
                                prefixIcon: Icon(Icons.book),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a name for the Confluence integration';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Wiki Page URL field
                            TextFormField(
                              controller: _confluenceUrlController,
                              decoration: InputDecoration(
                                labelText: 'Wiki Page URL',
                                hintText: 'Enter the Confluence wiki page URL',
                                prefixIcon: Icon(Icons.link),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a wiki page URL';
                                }
                                if (!value.startsWith('http://') && !value.startsWith('https://')) {
                                  return 'URL must start with http:// or https://';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Confluence Username field
                            TextFormField(
                              controller: _confluenceUsernameController,
                              decoration: InputDecoration(
                                labelText: 'Confluence Username',
                                hintText: 'Enter your Confluence username or email',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your Confluence username';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Confluence Access Token field
                            TextFormField(
                              controller: _confluenceTokenController,
                              decoration: InputDecoration(
                                labelText: 'Confluence Access Token (Optional)',
                                hintText: 'Enter your Confluence access token or leave empty to use default',
                                prefixIcon: Icon(Icons.vpn_key),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                helperText: 'If left empty, a default token will be used',
                              ),
                              // No validator since this field is optional
                            ),

                            const SizedBox(height: 24),

                            // Add Confluence button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _isAddingConfluence ? null : _addConfluenceKnowledge,
                                icon: _isAddingConfluence
                                    ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                                    : const Icon(Icons.add_circle),
                                label: Text(_isAddingConfluence ? 'Adding...' : 'Add Confluence Wiki'),
                              ),
                            ),

                            // Error message
                            if (_confluenceError != null) ...[
                              const SizedBox(height: 16),
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
                                        _confluenceError!,
                                        style: const TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            // Success message
                            if (_confluenceSuccess != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _confluenceSuccess!,
                                        style: const TextStyle(color: Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
