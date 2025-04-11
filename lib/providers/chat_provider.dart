import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/chat_history.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ChatProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  String _selectedAgent = 'Claude 3.5 Sonnet';
  bool _isLoading = false;
  bool _isFetchingConversations = false;
  String? _nextCursor;
  bool _hasMoreConversations = false;

  // For conversation history pagination
  Map<String, String?> _conversationCursors = {};
  Map<String, bool> _hasMoreMessages = {};
  Map<String, bool> _isFetchingMessages = {};

  // API configuration
  final String _baseUrl = 'https://api.dev.jarvis.cx';
  final String _apiPath = '/api/v1/ai-chat/messages';
  final String _conversationsPath = '/api/v1/ai-chat/conversations';

  // Token management
  final int _maxTokenLimit = 1000; // Maximum token limit
  int _availableTokens = 1000; // Available tokens (starts at max)
  int _totalTokensUsed = 0; // Total tokens used across all operations
  Timer? _tokenDecayTimer; // Timer for token decay

  // Getters
  List<Conversation> get conversations => _conversations;
  Conversation? get currentConversation => _currentConversation;
  String get selectedAgent => _selectedAgent;
  bool get isLoading => _isLoading;
  bool get isFetchingConversations => _isFetchingConversations;
  bool get hasMoreConversations => _hasMoreConversations;
  int get tokenLimit => _maxTokenLimit;
  int get availableTokens => _availableTokens;
  int get totalTokensUsed => _totalTokensUsed;
  double get tokenAvailabilityPercentage => _availableTokens / _maxTokenLimit;
  bool get hasTokens => _availableTokens > 0;

  bool isLoadingMessages(String conversationId) =>
      _isFetchingMessages[conversationId] ?? false;

  bool hasMoreMessages(String conversationId) =>
      _hasMoreMessages[conversationId] ?? false;

  final List<String> _availableAgents = [
    'Claude 3.5 Sonnet',
    'Claude 3 Opus',
    'GPT-4o',
    'Gemini Pro',
  ];

  // Map UI-friendly model names to API model IDs
  String _getModelId(String modelName) {
    switch (modelName) {
      case 'Claude 3.5 Sonnet':
        return 'claude-3-5-sonnet-20240620';
      case 'Claude 3 Opus':
        return 'claude-3-haiku-20240307';
      case 'GPT-4o':
        return 'gpt-4o';
      case 'Gemini Pro':
        return 'gemini-1.5-flash-latest';
      default:
        return 'gemini-1.5-flash-latest'; // Default model
    }
  }

  List<String> get availableAgents => _availableAgents;

  ChatProvider() {
    _initializeData();
    _startTokenDecayTimer();
  }

  @override
  void dispose() {
    _tokenDecayTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeData() async {
    // Try to fetch conversations from API first
    try {
      await fetchConversations();
    } catch (e) {
      print('Error fetching conversations: $e');
      // If API fetch fails, use sample data
      _loadSampleConversations();
    }
  }

  // Load sample conversations as fallback
  void _loadSampleConversations() {
    final now = DateTime.now();

    final conversation1 = Conversation(
      id: '1',
      title: 'Help with coding',
      agentName: 'Claude 3.5 Sonnet',
      messages: [
        Message(
          id: '1',
          content: 'How do I implement a binary search tree in Python?',
          type: MessageType.user,
          timestamp: now.subtract(const Duration(minutes: 5)),
          tokenCount: 12,
        ),
        Message(
          id: '2',
          content:
              'Here\'s how you can implement a binary search tree in Python:\n\n\`\`\`python\nclass Node:\n    def __init__(self, value):\n        self.value = value\n        self.left = None\n        self.right = None\n\nclass BinarySearchTree:\n    def __init__(self):\n        self.root = None\n    \n    def insert(self, value):\n        new_node = Node(value)\n        if self.root is None:\n            self.root = new_node\n            return\n        \n        current = self.root\n        while True:\n            if value < current.value:\n                if current.left is None:\n                    current.left = new_node\n                    return\n                current = current.left\n            else:\n                if current.right is None:\n                    current.right = new_node\n                    return\n                current = current.right\n\`\`\`\n\nThis is a basic implementation. You can add more methods like search, delete, traversal, etc.',
          type: MessageType.assistant,
          timestamp: now.subtract(const Duration(minutes: 4)),
          tokenCount: 35,
        ),
      ],
      createdAt: now.subtract(const Duration(minutes: 5)),
      updatedAt: now.subtract(const Duration(minutes: 4)),
    );

    final conversation2 = Conversation(
      id: '2',
      title: 'Travel recommendations',
      agentName: 'GPT-4o',
      messages: [
        Message(
          id: '3',
          content: 'What are some good places to visit in Japan?',
          type: MessageType.user,
          timestamp: now.subtract(const Duration(hours: 2)),
          tokenCount: 10,
        ),
        Message(
          id: '4',
          content:
              'Japan offers many incredible places to visit! Here are some recommendations:\n\n1. **Tokyo** - The capital city with a mix of ultramodern and traditional aspects\n2. **Kyoto** - Famous for its temples, shrines, and traditional gardens\n3. **Osaka** - Known for its modern architecture, nightlife, and street food\n4. **Hiroshima** - Historical site with the Peace Memorial Park\n5. **Mount Fuji** - Japan\'s highest mountain and an iconic landmark\n6. **Nara** - Home to friendly deer and ancient temples\n7. **Hokkaido** - Great for winter sports and natural hot springs\n8. **Okinawa** - Beautiful beaches and a unique culture\n\nThe best time to visit depends on what you want to see. Spring (March-May) is popular for cherry blossoms, fall (September-November) for autumn colors, and winter for snow activities in the north.',
          type: MessageType.assistant,
          timestamp: now.subtract(const Duration(hours: 2)),
          tokenCount: 42,
        ),
      ],
      createdAt: now.subtract(const Duration(hours: 2)),
      updatedAt: now.subtract(const Duration(hours: 2)),
    );

    _conversations = [conversation1, conversation2];
    _currentConversation = conversation1;

    // Calculate initial token usage
    _calculateInitialTokenUsage();
  }

  // Calculate initial token usage from all conversations
  void _calculateInitialTokenUsage() {
    int totalTokens = 0;

    for (final conversation in _conversations) {
      for (final message in conversation.messages) {
        totalTokens += message.tokenCount;
      }
    }

    // Update total tokens used
    _totalTokensUsed = totalTokens;

    // Update available tokens
    _availableTokens = _maxTokenLimit -
        (_totalTokensUsed ~/ 2); // Start with some tokens already used
    if (_availableTokens < 0) _availableTokens = 0;
  }

  // Start timer to simulate token decay over time
  void _startTokenDecayTimer() {
    // Decay tokens every 30 seconds
    _tokenDecayTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      // Decrease available tokens by a small amount (1-3 tokens)
      final decayAmount = (DateTime.now().second % 3) + 1;

      if (_availableTokens > decayAmount) {
        _availableTokens -= decayAmount;
        _totalTokensUsed += decayAmount;
        notifyListeners();
      } else if (_availableTokens > 0) {
        _totalTokensUsed += _availableTokens;
        _availableTokens = 0;
        notifyListeners();
      }
    });
  }

  // Fetch conversations from API
  Future<void> fetchConversations(
      {String? cursor, int limit = 20, String? assistantId}) async {
    if (_isFetchingConversations) return;

    _isFetchingConversations = true;
    if (cursor == null) {
      // If no cursor is provided, we're fetching the first page
      _isLoading = true;
    }
    notifyListeners();

    try {
      // Get authentication token
      final authToken = await _getAuthToken();
      if (authToken == null) {
        throw Exception('Authentication token not found');
      }

      // Build query parameters
      final queryParams = <String, String>{
        'limit': limit.toString(),
      };

      if (cursor != null) {
        queryParams['cursor'] = cursor;
      }

      if (assistantId != null) {
        queryParams['assistantId'] = assistantId;
      }

      // Always set assistantModel to 'dify'
      queryParams['assistantModel'] = 'dify';

      // Build URL with query parameters
      final uri = Uri.parse('$_baseUrl$_conversationsPath').replace(
        queryParameters: queryParams,
      );

      // Make API request
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      // Log the response for debugging
      print('API response status: ${response.statusCode}');
      print('API response body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse response
        final responseData = jsonDecode(response.body);

        // Extract cursor and has_more
        _nextCursor = responseData['cursor'] as String?;
        _hasMoreConversations = responseData['has_more'] as bool? ?? false;

        // Extract conversations
        final items = responseData['items'] as List<dynamic>;

        // Convert API response to Conversation objects
        final fetchedConversations = items.map((item) {
          return Conversation(
            id: item['id'] as String,
            title: item['title'] as String? ?? 'Untitled Conversation',
            agentName:
                'AI Assistant', // Default value since API doesn't provide this
            messages: [], // Empty messages since we don't have them yet
            createdAt: DateTime.parse(item['createdAt'] as String),
            updatedAt: DateTime.parse(item['createdAt'] as String),
          );
        }).toList();

        if (cursor == null) {
          // First page, replace existing conversations
          _conversations = fetchedConversations;
        } else {
          // Subsequent page, append to existing conversations
          _conversations.addAll(fetchedConversations);
        }

        // If we have conversations and no current conversation is selected, select the first one
        if (_conversations.isNotEmpty && _currentConversation == null) {
          _currentConversation = _conversations.first;
        }
      } else {
        // Handle error response
        throw Exception(
            'Failed to fetch conversations: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching conversations: $e');
      // If this is the first fetch and it failed, load sample data
      if (cursor == null && _conversations.isEmpty) {
        _loadSampleConversations();
      }
    } finally {
      _isFetchingConversations = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more conversations (pagination)
  Future<void> loadMoreConversations() async {
    if (_hasMoreConversations && _nextCursor != null) {
      await fetchConversations(cursor: _nextCursor);
    }
  }

  // Fetch conversation details (messages)
  Future<void> fetchConversationDetails(String conversationId,
      {String? cursor, int limit = 20}) async {
    // Find the conversation in our list
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index == -1) return;

    // If we're already fetching messages for this conversation, don't start another fetch
    if (_isFetchingMessages[conversationId] == true) return;

    // Set loading state
    _isFetchingMessages[conversationId] = true;
    if (cursor == null) {
      // If this is the first fetch for this conversation, set loading state
      _isLoading = true;
    }
    notifyListeners();

    try {
      // Get authentication token
      final authToken = await _getAuthToken();
      if (authToken == null) {
        throw Exception('Authentication token not found');
      }

      // Build query parameters
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'assistantModel': 'dify',
      };

      if (cursor != null) {
        queryParams['cursor'] = cursor;
      }

      // Build URL with query parameters
      final uri =
          Uri.parse('$_baseUrl$_conversationsPath/$conversationId/messages')
              .replace(
        queryParameters: queryParams,
      );

      // Make API request
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      );

      // Log the response for debugging
      print('API response status: ${response.statusCode}');
      print('API response body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse response
        final responseData = jsonDecode(response.body);

        // Extract cursor and has_more for this conversation
        _conversationCursors[conversationId] =
            responseData['cursor'] as String?;
        _hasMoreMessages[conversationId] =
            responseData['has_more'] as bool? ?? false;

        // Extract messages
        final items = responseData['items'] as List<dynamic>;

        // Convert API response to Message objects
        List<Message> fetchedMessages = [];

        for (final item in items) {
          // Parse createdAt timestamp
          DateTime timestamp;
          if (item['createdAt'] is int) {
            // If it's an integer timestamp
            timestamp = DateTime.fromMillisecondsSinceEpoch(
                (item['createdAt'] as int) * 1000);
          } else {
            // If it's a string timestamp
            timestamp = DateTime.parse(item['createdAt'] as String);
          }

          // Generate a unique ID for each message
          final baseId = item['id'] as String? ??
              DateTime.now().millisecondsSinceEpoch.toString();

          // Add user message if query exists
          if (item['query'] != null && (item['query'] as String).isNotEmpty) {
            fetchedMessages.add(Message(
              id: '${baseId}_user',
              content: item['query'] as String,
              type: MessageType.user,
              timestamp: timestamp,
              tokenCount: 0, // We don't have this information from the API
            ));
          }

          // Add assistant message if answer exists
          if (item['answer'] != null && (item['answer'] as String).isNotEmpty) {
            fetchedMessages.add(Message(
              id: '${baseId}_assistant',
              content: item['answer'] as String,
              type: MessageType.assistant,
              timestamp: timestamp.add(const Duration(
                  milliseconds: 500)), // Slightly later than user message
              tokenCount: 0, // We don't have this information from the API
            ));
          }
        }

        // Sort messages by timestamp (oldest first)
        fetchedMessages.sort((a, b) => a.timestamp!.compareTo(b.timestamp!));

        // If this is the first fetch, replace existing messages
        // Otherwise, append to existing messages
        if (cursor == null) {
          _conversations[index] = _conversations[index].copyWith(
            messages: fetchedMessages,
          );
        } else {
          final updatedMessages = [
            ...fetchedMessages,
            ..._conversations[index].messages,
          ];

          _conversations[index] = _conversations[index].copyWith(
            messages: updatedMessages,
          );
        }

        // If this is the current conversation, update it too
        if (_currentConversation?.id == conversationId) {
          _currentConversation = _conversations[index];
        }
      } else {
        // Handle error response
        throw Exception(
            'Failed to fetch conversation details: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      print('Error fetching conversation details: $e');
    } finally {
      _isFetchingMessages[conversationId] = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load more messages for a conversation (pagination)
  Future<void> loadMoreMessages(String conversationId) async {
    if (_hasMoreMessages[conversationId] == true &&
        _conversationCursors[conversationId] != null) {
      await fetchConversationDetails(
        conversationId,
        cursor: _conversationCursors[conversationId],
      );
    }
  }

  void createNewConversation() {
    final newConversation = Conversation.empty();
    _conversations.insert(0, newConversation);
    _currentConversation = newConversation;
    notifyListeners();
  }

  void selectConversation(String conversationId) {
    final selectedConversation = _conversations.firstWhere(
      (conversation) => conversation.id == conversationId,
    );
    _currentConversation = selectedConversation;

    // If the conversation doesn't have messages yet, fetch them
    if (selectedConversation.messages.isEmpty) {
      fetchConversationDetails(conversationId);
    }

    notifyListeners();
  }

  void changeAgent(String agent) {
    if (_availableAgents.contains(agent)) {
      _selectedAgent = agent;
      if (_currentConversation != null) {
        _currentConversation = _currentConversation!.copyWith(agentName: agent);
        final index = _conversations.indexWhere(
          (conversation) => conversation.id == _currentConversation!.id,
        );
        if (index != -1) {
          _conversations[index] = _currentConversation!;
        }
      }
      notifyListeners();
    }
  }

  // Get authentication token from SharedPreferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Send message to the API
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Check if we have enough tokens
    final estimatedUserTokens = _estimateTokenCount(content);
    if (estimatedUserTokens > _availableTokens) {
      // Not enough tokens
      notifyListeners();
      return;
    }

    if (_currentConversation == null) {
      createNewConversation();
    }

    // Create user message
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
      tokenCount: estimatedUserTokens,
    );

    // Add user message to conversation
    final updatedMessages = [
      ..._currentConversation!.messages,
      userMessage,
    ];

    _currentConversation = _currentConversation!.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    final index = _conversations.indexWhere(
      (conversation) => conversation.id == _currentConversation!.id,
    );

    if (index != -1) {
      _conversations[index] = _currentConversation!;
    }

    // Deduct user message tokens
    _availableTokens -= estimatedUserTokens;
    _totalTokensUsed += estimatedUserTokens;

    notifyListeners();

    // Set loading state
    _isLoading = true;
    notifyListeners();

    try {
      // Get authentication token
      final authToken = await _getAuthToken();
      if (authToken == null) {
        throw Exception('Authentication token not found');
      }

      // Prepare conversation history for API
      List<Map<String, dynamic>> messageHistory = [];

      // Only include previous messages if this is not a new conversation
      if (_currentConversation!.messages.length > 1) {
        for (final message in _currentConversation!.messages) {
          if (message.id != userMessage.id) {
            // Skip the message we just added
            messageHistory.add({
              'role': message.type == MessageType.user ? 'user' : 'assistant',
              'content': message.content,
            });
          }
        }
      }

      // Check if this is a new conversation or an existing one
      final bool isNewConversation =
          _isNewConversation(_currentConversation!.id);

      // Prepare request body according to API documentation
      Map<String, dynamic> requestBody;

      if (isNewConversation) {
        // First request - create a new conversation
        requestBody = {
          'content': content,
          'assistant': {
            'id': _getModelId(_selectedAgent),
            'model': 'dify',
            'files': [],
            'metadata': {
              'conversation': {
                'messages': messageHistory,
              },
            },
          },
        };
      } else {
        // Subsequent request - use existing conversation ID
        requestBody = {
          'content': content,
          'files': [],
          'metadata': {
            'conversation': {
              'id': _currentConversation!.id,
              'messages': [] // Empty messages array as per the example
            }
          },
          'assistant': {
            'id': _getModelId(_selectedAgent),
            'model': 'dify',
            'name': _selectedAgent
          }
        };
      }

      // Log the request for debugging
      print('Sending request to API: ${jsonEncode(requestBody)}');

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl$_apiPath'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode(requestBody),
      );

      // Log the response for debugging
      print('API response status: ${response.statusCode}');
      print('API response body: ${response.body}');

      if (response.statusCode == 200) {
        // Parse response
        final responseData = jsonDecode(response.body);
        final assistantMessage = responseData['message'] as String;
        final conversationId = responseData['conversationId'] as String;
        final remainingUsage = responseData['remainingUsage'] as int;

        // Update conversation ID if this is a new conversation
        if (isNewConversation) {
          _currentConversation = _currentConversation!.copyWith(
            id: conversationId,
          );

          // Update the conversation in the list
          if (index != -1) {
            _conversations[index] = _currentConversation!;
          }
        }

        // Create assistant message
        final message = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: assistantMessage,
          type: MessageType.assistant,
          timestamp: DateTime.now(),
          tokenCount: _estimateTokenCount(assistantMessage),
        );

        // Add assistant message to conversation
        final updatedMessagesWithResponse = [
          ..._currentConversation!.messages,
          message,
        ];

        _currentConversation = _currentConversation!.copyWith(
          messages: updatedMessagesWithResponse,
          updatedAt: DateTime.now(),
        );

        if (index != -1) {
          _conversations[index] = _currentConversation!;
        }

        // Update available tokens based on API response
        _availableTokens = remainingUsage;
      } else {
        // Handle error response
        throw Exception(
            'Failed to send message: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      // Add error message to conversation
      final errorMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content:
            'Error: Failed to get response from AI. Please try again later.',
        type: MessageType.assistant,
        timestamp: DateTime.now(),
        tokenCount: 10,
      );

      final updatedMessagesWithError = [
        ..._currentConversation!.messages,
        errorMessage,
      ];

      _currentConversation = _currentConversation!.copyWith(
        messages: updatedMessagesWithError,
        updatedAt: DateTime.now(),
      );

      if (index != -1) {
        _conversations[index] = _currentConversation!;
      }

      print('Error sending message: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // New method to send an image message
  Future<void> sendImageMessage(File imageFile, String caption) async {
    if (_currentConversation == null) {
      createNewConversation();
    }

    // Save the image to app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await imageFile.copy('${appDir.path}/$fileName}');
    final imageUrl = savedImage.path;

    // Create image message
    final imageMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: caption,
      type: MessageType.image,
      timestamp: DateTime.now(),
      tokenCount: _estimateTokenCount(caption) + 20, // Extra tokens for image
      imageUrl: imageUrl,
      imageCaption: caption,
    );

    final updatedMessages = [
      ..._currentConversation!.messages,
      imageMessage,
    ];

    _currentConversation = _currentConversation!.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );

    final index = _conversations.indexWhere(
      (conversation) => conversation.id == _currentConversation!.id,
    );

    if (index != -1) {
      _conversations[index] = _currentConversation!;
    }

    // Deduct tokens for image message
    final imageTokens = _estimateTokenCount(caption) + 20;
    _availableTokens -= imageTokens;
    _totalTokensUsed += imageTokens;

    notifyListeners();

    // Generate AI response to the image
    await _generateImageResponse(imageUrl, caption);
  }

  // Generate a response to an image
  Future<void> _generateImageResponse(String imageUrl, String caption) async {
    if (_currentConversation == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Get authentication token
      final authToken = await _getAuthToken();
      if (authToken == null) {
        throw Exception('Authentication token not found');
      }

      // TODO: Implement image upload to the API
      // For now, we'll use a placeholder response
      await Future.delayed(const Duration(seconds: 1));

      String response;
      if (caption.isEmpty) {
        response =
            "I can see the image you've shared. What would you like to know about it?";
      } else if (caption.toLowerCase().contains('what') ||
          caption.toLowerCase().contains('describe')) {
        response =
            "Based on the image you shared, I can see what appears to be a photograph. To provide a more detailed description, I'd need to analyze the specific content. The image quality looks good, and I can make out the main elements. Is there something specific about this image you'd like me to focus on?";
      } else {
        response =
            "Thanks for sharing this image with the caption: \"$caption\". I've analyzed what you've shared. Is there anything specific about this image you'd like me to explain or discuss?";
      }

      final assistantTokens = _estimateTokenCount(response);

      // Check if we have enough tokens
      if (assistantTokens > _availableTokens) {
        response =
            "I can see your image, but I don't have enough tokens to provide a detailed analysis. Please purchase more tokens.";
      }

      final assistantMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
        tokenCount: _estimateTokenCount(response),
      );

      final updatedMessages = [
        ..._currentConversation!.messages,
        assistantMessage,
      ];

      _currentConversation = _currentConversation!.copyWith(
        messages: updatedMessages,
        updatedAt: DateTime.now(),
      );

      final index = _conversations.indexWhere(
        (conversation) => conversation.id == _currentConversation!.id,
      );

      if (index != -1) {
        _conversations[index] = _currentConversation!;
      }

      // Deduct tokens
      _availableTokens -= assistantTokens;
      _totalTokensUsed += assistantTokens;
    } catch (e) {
      print('Error processing image: $e');

      // Add error message to conversation
      final errorMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Error: Failed to process image. Please try again later.',
        type: MessageType.assistant,
        timestamp: DateTime.now(),
        tokenCount: 10,
      );

      final updatedMessagesWithError = [
        ..._currentConversation!.messages,
        errorMessage,
      ];

      _currentConversation = _currentConversation!.copyWith(
        messages: updatedMessagesWithError,
        updatedAt: DateTime.now(),
      );

      final index = _conversations.indexWhere(
        (conversation) => conversation.id == _currentConversation!.id,
      );

      if (index != -1) {
        _conversations[index] = _currentConversation!;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Optimized method to load messages in batches
  Future<void> loadMessagesInBatches(String conversationId,
      {int batchSize = 20}) async {
    final conversation = _conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => Conversation.empty(),
    );

    if (conversation.id.isEmpty) return;

    // Simulate loading messages in batches from a database or API
    _isLoading = true;
    notifyListeners();

    final allMessages = conversation.messages;
    final batchCount = (allMessages.length / batchSize).ceil();

    List<Message> loadedMessages = [];

    for (int i = 0; i < batchCount; i++) {
      final start = i * batchSize;
      final end = (i + 1) * batchSize;
      final batch = allMessages.sublist(
        start,
        end > allMessages.length ? allMessages.length : end,
      );

      loadedMessages.addAll(batch);

      // Update the conversation with loaded messages
      _currentConversation = conversation.copyWith(
        messages: loadedMessages,
      );

      notifyListeners();

      // Add a small delay between batches to prevent UI freezing
      if (i < batchCount - 1) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Optimize token calculation by memoizing results
  final Map<String, int> _tokenCountCache = {};

  int _estimateTokenCount(String text) {
    // Check cache first
    if (_tokenCountCache.containsKey(text)) {
      return _tokenCountCache[text]!;
    }

    // A more accurate token estimator (roughly 4 characters per token)
    final count = (text.length / 4).ceil();

    // Cache the result
    _tokenCountCache[text] = count;

    return count;
  }

  void reduceTokenUsage() {
    if (_currentConversation == null ||
        _currentConversation!.messages.isEmpty) {
      return;
    }

    // Keep only the last 4 messages to reduce token usage
    if (_currentConversation!.messages.length > 4) {
      // Calculate tokens to be recovered
      int tokensToRecover = 0;
      final messagesToRemove = _currentConversation!.messages.sublist(
        0,
        _currentConversation!.messages.length - 4,
      );

      for (final message in messagesToRemove) {
        tokensToRecover += message.tokenCount;
      }

      // Keep only the last 4 messages
      final reducedMessages = _currentConversation!.messages.sublist(
        _currentConversation!.messages.length - 4,
      );

      _currentConversation = _currentConversation!.copyWith(
        messages: reducedMessages,
      );

      final index = _conversations.indexWhere(
        (conversation) => conversation.id == _currentConversation!.id,
      );

      if (index != -1) {
        _conversations[index] = _currentConversation!;
      }

      // Recover tokens (but don't reduce total tokens used)
      _availableTokens += tokensToRecover;
      if (_availableTokens > _maxTokenLimit) {
        _availableTokens = _maxTokenLimit;
      }

      notifyListeners();
    }
  }

  // Add tokens (could be used for purchasing more tokens)
  void addTokens(int amount) {
    _availableTokens += amount;
    if (_availableTokens > _maxTokenLimit) {
      _availableTokens = _maxTokenLimit;
    }
    notifyListeners();
  }

  // Reset tokens to maximum (for testing purposes)
  void resetTokens() {
    _availableTokens = _maxTokenLimit;
    notifyListeners();
  }

  // Get token usage statistics
  Map<String, dynamic> getTokenStats() {
    return {
      'availableTokens': _availableTokens,
      'totalTokensUsed': _totalTokensUsed,
      'maxTokenLimit': _maxTokenLimit,
      'availabilityPercentage': tokenAvailabilityPercentage,
    };
  }

  // Get AI model capabilities description
  String getAIModelCapabilities(String modelName) {
    switch (modelName) {
      case 'Claude 3.5 Sonnet':
        return 'Claude 3.5 Sonnet is optimized for speed and efficiency while maintaining high-quality responses. Best for everyday tasks, content creation, and quick answers.';
      case 'Claude 3 Opus':
        return 'Claude 3 Opus is Anthropic\'s most powerful model with enhanced reasoning, knowledge, and instruction-following capabilities. Ideal for complex tasks.';
      case 'GPT-4o':
        return 'GPT-4o is OpenAI\'s latest model with improved reasoning, broader knowledge, and better instruction following. Great for coding, creative writing, and problem-solving.';
      case 'Gemini Pro':
        return 'Gemini Pro is Google\'s advanced multimodal model that excels at understanding context across text, code, images, and more.';
      default:
        return 'AI assistant model designed to be helpful, harmless, and honest.';
    }
  }

  // Rename conversation
  void renameConversation(String conversationId, String newTitle) {
    final index = _conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );

    if (index != -1) {
      final updatedConversation = _conversations[index].copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );

      _conversations[index] = updatedConversation;

      if (_currentConversation?.id == conversationId) {
        _currentConversation = updatedConversation;
      }

      notifyListeners();
    }
  }

  // Delete conversation
  void deleteConversation(String conversationId) {
    final index = _conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );

    if (index != -1) {
      _conversations.removeAt(index);

      if (_currentConversation?.id == conversationId) {
        _currentConversation =
            _conversations.isNotEmpty ? _conversations[0] : null;
      }

      notifyListeners();
    }
  }

  // Export conversation to text
  String exportConversationToText(String conversationId) {
    final conversation = _conversations.firstWhere(
      (c) => c.id == conversationId,
      orElse: () => Conversation.empty(),
    );

    if (conversation.id.isEmpty) return '';

    final buffer = StringBuffer();
    buffer.writeln('# ${conversation.title}');
    buffer.writeln('Agent: ${conversation.agentName}');
    buffer.writeln('Date: ${conversation.createdAt.toString()}');
    buffer.writeln('');

    for (final message in conversation.messages) {
      final sender =
          message.type == MessageType.user ? 'You' : conversation.agentName;
      buffer.writeln('$sender: ${message.content}');
      buffer.writeln('');
    }

    return buffer.toString();
  }

  // Helper method to check if a conversation is new (hasn't been saved to the server yet)
  bool _isNewConversation(String conversationId) {
    return conversationId.startsWith('temp_') || !conversationId.contains('-');
  }
}
