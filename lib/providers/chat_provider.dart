import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ChatProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  String _selectedAgent = 'Claude 3.5 Sonnet';
  bool _isLoading = false;

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
  int get tokenLimit => _maxTokenLimit;
  int get availableTokens => _availableTokens;
  int get totalTokensUsed => _totalTokensUsed;
  double get tokenAvailabilityPercentage => _availableTokens / _maxTokenLimit;
  bool get hasTokens => _availableTokens > 0;

  final List<String> _availableAgents = [
    'Claude 3.5 Sonnet',
    'Claude 3 Opus',
    'GPT-4o',
    'Gemini Pro',
  ];

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

  void _initializeData() {
    // Create some sample conversations
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

  // Optimize the sendMessage method to prevent UI blocking
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Check if we have enough tokens
    final estimatedUserTokens = _estimateTokenCount(content);
    final estimatedResponseTokens =
        estimatedUserTokens * 2; // Rough estimate for response
    final totalEstimatedTokens = estimatedUserTokens + estimatedResponseTokens;

    if (totalEstimatedTokens > _availableTokens) {
      // Not enough tokens
      notifyListeners();
      return;
    }

    if (_currentConversation == null) {
      createNewConversation();
    }

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
      tokenCount: estimatedUserTokens,
    );

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

    // Simulate AI response in a separate isolate or at least a microtask
    _isLoading = true;
    notifyListeners();

    // Use a microtask to avoid blocking the UI thread
    await Future.microtask(() async {
      // Add a small delay to simulate processing
      await Future.delayed(const Duration(milliseconds: 300));

      final assistantResponse = _generateResponse(content);
      final assistantTokens = _estimateTokenCount(assistantResponse);

      // Check if we have enough tokens for the response
      if (assistantTokens > _availableTokens) {
        // Not enough tokens for full response
        final shortenedResponse =
            "I apologize, but you don't have enough tokens for a complete response. Please reduce token usage or purchase more tokens.";
        final shortenedTokens = _estimateTokenCount(shortenedResponse);

        final assistantMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: shortenedResponse,
          type: MessageType.assistant,
          timestamp: DateTime.now(),
          tokenCount: shortenedTokens,
        );

        final updatedMessagesWithResponse = [
          ...updatedMessages,
          assistantMessage,
        ];

        _currentConversation = _currentConversation!.copyWith(
          messages: updatedMessagesWithResponse,
          updatedAt: DateTime.now(),
        );

        if (index != -1) {
          _conversations[index] = _currentConversation!;
        }

        // Deduct shortened response tokens
        _availableTokens -= shortenedTokens;
        _totalTokensUsed += shortenedTokens;
      } else {
        // Enough tokens for full response
        final assistantMessage = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: assistantResponse,
          type: MessageType.assistant,
          timestamp: DateTime.now(),
          tokenCount: assistantTokens,
        );

        final updatedMessagesWithResponse = [
          ...updatedMessages,
          assistantMessage,
        ];

        _currentConversation = _currentConversation!.copyWith(
          messages: updatedMessagesWithResponse,
          updatedAt: DateTime.now(),
        );

        if (index != -1) {
          _conversations[index] = _currentConversation!;
        }

        // Deduct assistant response tokens
        _availableTokens -= assistantTokens;
        _totalTokensUsed += assistantTokens;
      }

      _isLoading = false;
      notifyListeners();
    });
  }

  // New method to send an image message
  Future<void> sendImageMessage(File imageFile, String caption) async {
    if (_currentConversation == null) {
      createNewConversation();
    }

    // Save the image to app documents directory
    final appDir = await getApplicationDocumentsDirectory();
    final fileName = 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await imageFile.copy('${appDir.path}/$fileName');
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

    await Future.delayed(const Duration(seconds: 1));

    // Simulate AI analyzing the image
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

    _isLoading = false;
    notifyListeners();
  }

  String _generateResponse(String userMessage) {
    // This is a mock response generator
    if (userMessage.toLowerCase().contains('hello') ||
        userMessage.toLowerCase().contains('hi')) {
      return 'Hey there! How can I assist you today?';
    } else if (userMessage.toLowerCase().contains('help')) {
      return 'I\'m here to help! What do you need assistance with?';
    } else if (userMessage.toLowerCase().contains('thanks') ||
        userMessage.toLowerCase().contains('thank you')) {
      return 'You\'re welcome! Is there anything else I can help you with?';
    } else if (userMessage.toLowerCase().contains('token')) {
      return 'I see you\'re asking about tokens. You currently have $_availableTokens tokens available out of a total limit of $_maxTokenLimit. Your total token usage across all operations is $_totalTokensUsed. Tokens are consumed over time and with each interaction.';
    } else {
      return 'I understand you\'re asking about "${userMessage.substring(0, userMessage.length > 20 ? 20 : userMessage.length)}...". Could you provide more details so I can better assist you?';
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
}
