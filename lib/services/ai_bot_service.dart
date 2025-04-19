import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_bot.dart';
import '../models/knowledge_item.dart';
import '../models/message.dart';
import '../models/ai_bot_response.dart';
import '../models/thread_response.dart';

class AIBotService extends ChangeNotifier {
  List<AIBot> _bots = [];
  AIBot? _selectedBot;
  List<KnowledgeItem> _knowledgeItems = [];
  bool _isLoading = false;
  String _error = '';
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  // Map to store thread IDs for each bot
  final Map<String, String> _threadIds = {};

  // Base URL for the API
  static const String baseUrl = 'https://knowledge-api.dev.jarvis.cx';

  // Getters
  List<AIBot> get bots => _bots;
  AIBot? get selectedBot => _selectedBot;
  List<KnowledgeItem> get knowledgeItems => _knowledgeItems;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasMore => _hasMore;
  Map<String, String> get threadIds => _threadIds;

  AIBotService() {
    // Load bots when service is initialized
    fetchBots();
    _loadThreadIds();
  }

  // Load thread IDs from SharedPreferences
  Future<void> _loadThreadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final threadIdsJson = prefs.getString('thread_ids');
      if (threadIdsJson != null) {
        final Map<String, dynamic> loadedThreadIds = json.decode(threadIdsJson);
        loadedThreadIds.forEach((key, value) {
          _threadIds[key] = value.toString();
        });
        print('Loaded thread IDs: $_threadIds');
      }
    } catch (e) {
      print('Error loading thread IDs: $e');
    }
  }

  // Save thread IDs to SharedPreferences
  Future<void> _saveThreadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('thread_ids', json.encode(_threadIds));
      print('Saved thread IDs: $_threadIds');
    } catch (e) {
      print('Error saving thread IDs: $e');
    }
  }

  // Get headers for API requests
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    final guid = prefs.getString('jarvis_guid') ?? '';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
      'x-jarvis-guid': guid,
    };
  }

  // Fetch bots from the API
  Future<void> fetchBots({bool refresh = false}) async {
    if (_isLoading) {
      print('Already loading bots, skipping fetch request');
      return;
    }

    if (refresh) {
      print('Refreshing bot list from scratch');
      _offset = 0;
      _hasMore = true;
      _bots = [];
    }

    if (!_hasMore && !refresh) {
      print('No more bots to load and not refreshing, skipping fetch');
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      // Build query parameters
      final queryParams = <String, String>{
        'offset': _offset.toString(),
        'limit': _limit.toString(),
        'order': 'DESC',
        'order_field': 'createdAt',
      };

      // Build URL with query parameters
      final uri = Uri.parse('$baseUrl/kb-core/v1/ai-assistant').replace(
        queryParameters: queryParams,
      );

      // Get headers
      final headers = await _getHeaders();

      // Make API request
      print('Fetching bots from: $uri');
      print('Headers: ${headers.toString()}');

      final response = await http.get(uri, headers: headers);

      // Check if request was successful
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('Response received: ${response.statusCode}');
        print('Response body length: ${response.body.length}');

        try {
          final botResponse = AIBotResponse.fromJson(jsonData);
          print('Parsed ${botResponse.data.length} bots');

          if (refresh) {
            _bots = botResponse.data;
          } else {
            _bots = [..._bots, ...botResponse.data];
          }

          _offset = _bots.length;
          _hasMore = botResponse.meta.hasNext;
          _error = '';
        } catch (parseError) {
          _error = 'Error parsing bot data: $parseError';
          print(_error);
          print('JSON data: $jsonData');
        }
      } else {
        _error = 'Failed to load bots: ${response.statusCode}';
        print(_error);
        print('Response body: ${response.body}');
      }
    } catch (e) {
      _error = 'Error fetching bots: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
      print('Fetch complete, bot count: ${_bots.length}');
    }
  }

  // Load more bots
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    await fetchBots();
  }

  // Select a bot
  Future<void> selectBot(String botId) async {
    try {
      _isLoading = true;
      notifyListeners();

      print('Selecting bot with ID: $botId');

      // First check if the bot is already in our list
      final existingBot = _bots.firstWhere(
        (bot) => bot.id == botId,
        orElse: () => AIBot.empty(),
      );

      if (existingBot.id.isNotEmpty) {
        print('Bot found in local list: ${existingBot.name}');
        _selectedBot = existingBot;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // If not found in our list, fetch it from the API
      final uri = Uri.parse('$baseUrl/kb-core/v1/ai-assistant/$botId');
      final headers = await _getHeaders();

      print('Fetching bot details from: $uri');
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print(
            'Bot details received: ${jsonData.toString().substring(0, min(200, jsonData.toString().length))}...');

        _selectedBot = AIBot.fromJson(jsonData);
        print('Bot selected: ${_selectedBot?.name}');
        _error = '';
      } else {
        _error = 'Failed to load bot details: ${response.statusCode}';
        print(_error);
        print('Response body: ${response.body}');
      }
    } catch (e) {
      _error = 'Error selecting bot: $e';
      print(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new bot
  Future<bool> createBot(AIBot bot) async {
    try {
      _isLoading = true;
      notifyListeners();

      final uri = Uri.parse('$baseUrl/kb-core/v1/ai-assistant');
      final headers = await _getHeaders();

      // Prepare request body according to API documentation
      final requestBody = {
        'assistantName': bot.name,
        'instructions': bot.instructions,
        'description': bot.description,
      };

      print('Creating bot with data: $requestBody');
      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('Bot created successfully: $jsonData');

        // Parse the response according to API documentation
        final newBot = AIBot(
          id: jsonData['id'] ?? '',
          name: jsonData['assistantName'] ?? bot.name,
          description: jsonData['description'] ?? bot.description,
          instructions: jsonData['instructions'] ?? bot.instructions,
          avatarUrl: jsonData['avatarUrl'] ?? '',
          createdAt: jsonData['createdAt'] != null
              ? DateTime.parse(jsonData['createdAt'])
              : DateTime.now(),
          updatedAt: jsonData['updatedAt'] != null
              ? DateTime.parse(jsonData['updatedAt'])
              : DateTime.now(),
          knowledgeIds: [],
          isPublished: false,
          publishedChannels: {},
          openAiAssistantId: jsonData['openAiAssistantId'],
          openAiThreadIdPlay: jsonData['openAiThreadIdPlay'],
          createdBy: jsonData['createdBy'],
          updatedBy: jsonData['updatedBy'],
        );

        _bots.add(newBot);
        _selectedBot = newBot;
        _error = '';

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to create bot: ${response.statusCode}';
        print('Error creating bot: ${response.body}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print('Exception creating bot: $_error');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update a bot
  Future<bool> updateBot(AIBot bot) async {
    try {
      _isLoading = true;
      notifyListeners();

      final uri = Uri.parse('$baseUrl/kb-core/v1/ai-assistant/${bot.id}');
      final headers = await _getHeaders();

      // Prepare request body according to API documentation
      final requestBody = {
        'assistantName': bot.name,
        'instructions': bot.instructions,
        'description': bot.description,
      };

      print('Updating bot with ID: ${bot.id}');
      print('Request body: $requestBody');

      // Use PATCH instead of PUT as per API documentation
      final response = await http.patch(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Bot updated successfully: ${response.statusCode}');
        final jsonData = json.decode(response.body);
        print(
            'Response data: ${jsonData.toString().substring(0, min(200, jsonData.toString().length))}...');

        final updatedBot = AIBot.fromJson(jsonData);

        // Update the bot in the local list
        final index = _bots.indexWhere((b) => b.id == bot.id);
        if (index != -1) {
          _bots[index] = updatedBot;
        }

        // Update the selected bot if it's the one being edited
        if (_selectedBot?.id == bot.id) {
          _selectedBot = updatedBot;
        }

        _error = '';
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update bot: ${response.statusCode}';
        print('Error updating bot: ${response.body}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Exception updating bot: $e';
      print(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Delete a bot
  Future<bool> deleteBot(String botId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final uri = Uri.parse('$baseUrl/kb-core/v1/ai-assistant/$botId');
      final headers = await _getHeaders();

      print('Deleting bot with ID: $botId');
      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200) {
        // Parse the response according to API documentation
        final jsonData = json.decode(response.body);
        final success = jsonData is bool ? jsonData : true;

        print('Bot deleted successfully: $success');

        if (success) {
          // Remove the bot from the local list
          _bots.removeWhere((bot) => bot.id == botId);

          // Clear selected bot if it's the one being deleted
          if (_selectedBot?.id == botId) {
            _selectedBot = null;
          }

          // Remove thread ID for this bot
          _threadIds.remove(botId);
          _saveThreadIds();

          _error = '';
        } else {
          _error = 'Failed to delete bot: API returned false';
          print(_error);
          _isLoading = false;
          notifyListeners();
          return false;
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to delete bot: ${response.statusCode}';
        print('Error deleting bot: ${response.body}');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Exception deleting bot: $e';
      print(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Create a thread for an assistant (first message)
  Future<ThreadResponse?> createThreadForAssistant(
      String botId, String firstMessage) async {
    try {
      _isLoading = true;
      notifyListeners();

      final uri = Uri.parse('$baseUrl/kb-core/v1/ai-assistant/thread');
      final headers = await _getHeaders();

      // Prepare request body according to API documentation
      final requestBody = {
        'assistantId': botId,
        'firstMessage': firstMessage,
      };

      print('Creating thread for bot ID: $botId');
      print('Request body: $requestBody');
      print('Sending first message: $firstMessage');

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        print('Thread created successfully: $jsonData');

        // Parse the response
        final threadResponse = ThreadResponse.fromJson(jsonData);

        // Print the thread ID to verify it's correct
        print('Created thread with ID: ${threadResponse.openAiThreadId}');

        // Verify the thread ID is not empty
        if (threadResponse.openAiThreadId.isEmpty) {
          print('ERROR: Thread ID is empty after parsing!');
          print('Raw JSON data: $jsonData');

          // Try to extract it directly as a fallback
          String threadId = '';
          if (jsonData.containsKey('openAiThreadId')) {
            threadId = jsonData['openAiThreadId'] ?? '';
          } else if (jsonData.containsKey('openAIThreadId')) {
            threadId = jsonData['openAIThreadId'] ?? '';
          }

          print('Directly extracted thread ID: $threadId');

          if (threadId.isNotEmpty) {
            // Use the directly extracted thread ID
            _threadIds[botId] = threadId;
            await _saveThreadIds();

            // Update the threadResponse object
            final updatedThreadResponse = ThreadResponse(
              id: threadResponse.id,
              assistantId: threadResponse.assistantId,
              openAiThreadId: threadId,
              threadName: threadResponse.threadName,
              createdBy: threadResponse.createdBy,
              updatedBy: threadResponse.updatedBy,
              createdAt: threadResponse.createdAt,
              updatedAt: threadResponse.updatedAt,
            );

            _isLoading = false;
            notifyListeners();

            return updatedThreadResponse;
          }
        }

        // Store the thread ID for this bot
        _threadIds[botId] = threadResponse.openAiThreadId;
        await _saveThreadIds();

        _isLoading = false;
        notifyListeners();

        return threadResponse;
      } else {
        _error = 'Failed to create thread: ${response.statusCode}';
        print(_error);
        print('Response body: ${response.body}');

        _isLoading = false;
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Exception creating thread: $e';
      print(_error);
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Ask a bot (for subsequent messages)
  Future<Message> askAssistant(
      String botId, String question, String threadId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final uri = Uri.parse('$baseUrl/kb-core/v1/ai-assistant/$botId/ask');
      final headers = await _getHeaders();

      // Prepare request body according to API documentation
      final requestBody = {
        'message': question,
        'openAiThreadId': threadId,
        'additionalInstruction': '', // Optional, can be empty
      };

      print('Asking assistant with ID: $botId');
      print('Using thread ID: $threadId');
      print('Request body: $requestBody');

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        // Print the raw response for debugging
        print('Raw response body: ${response.body}');

        String responseText;

        // Try to parse as JSON first
        try {
          final jsonData = json.decode(response.body);
          print('Successfully parsed response as JSON');
          responseText =
              jsonData['response'] ?? 'No response from the assistant';
        } catch (e) {
          // If JSON parsing fails, use the raw response body as plain text
          print('Response is not JSON, using as plain text: $e');
          responseText = response.body;
        }

        _isLoading = false;
        notifyListeners();

        return Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: responseText,
          type: MessageType.assistant,
          timestamp: DateTime.now(),
        );
      } else {
        _error = 'Failed to get response: ${response.statusCode}';
        print(_error);
        print('Response body: ${response.body}');

        _isLoading = false;
        notifyListeners();

        return Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'Sorry, I encountered an error: $_error',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      _error = e.toString();
      print('Exception asking assistant: $_error');
      _isLoading = false;
      notifyListeners();

      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I encountered an error: $_error',
        type: MessageType.assistant,
        timestamp: DateTime.now(),
      );
    }
  }

  // Combined method to handle both first message and subsequent messages
  Future<Message> sendMessage(String botId, String message) async {
    try {
      // Check if we already have a thread ID for this bot
      final existingThreadId = _threadIds[botId];

      print('Thread ID for bot $botId: $existingThreadId');

      if (existingThreadId == null || existingThreadId.isEmpty) {
        // First message - create a thread
        print(
            'No existing thread found for bot $botId. Creating a new thread...');
        final threadResponse = await createThreadForAssistant(botId, message);

        if (threadResponse == null) {
          // Failed to create thread
          return Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content:
                'Sorry, I encountered an error creating a conversation thread.',
            type: MessageType.assistant,
            timestamp: DateTime.now(),
          );
        }

        // Get the thread ID from the response
        String threadId = threadResponse.openAiThreadId;

        // If the thread ID is still empty, try to extract it directly from the raw response
        if (threadId.isEmpty) {
          print('ERROR: Thread ID is still empty after parsing!');
          return Message(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content:
                'Sorry, I encountered an error creating a conversation thread. Thread ID is empty.',
            type: MessageType.assistant,
            timestamp: DateTime.now(),
          );
        }

        // Store the thread ID immediately after creation to ensure it's available
        _threadIds[botId] = threadId;
        await _saveThreadIds();

        print('Thread created successfully with ID: $threadId');
        print('Thread IDs after creation: $_threadIds');

        // Now we need to use the Ask Assistant API to get the response to the first message
        return await askAssistant(botId, message, threadId);
      } else {
        // Subsequent message - use existing thread
        print('Using existing thread $existingThreadId for bot $botId');
        return await askAssistant(botId, message, existingThreadId);
      }
    } catch (e) {
      _error = e.toString();
      print('Exception in sendMessage: $_error');

      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I encountered an error: $_error',
        type: MessageType.assistant,
        timestamp: DateTime.now(),
      );
    }
  }

  // Import knowledge to bot
  Future<bool> importKnowledgeToBot(String botId, String knowledgeId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final uri = Uri.parse(
          '$baseUrl/kb-core/v1/ai-assistant/$botId/knowledges/$knowledgeId');
      final headers = await _getHeaders();

      final response = await http.post(uri, headers: headers);

      if (response.statusCode == 200) {
        // Update local bot data
        final index = _bots.indexWhere((b) => b.id == botId);
        if (index != -1) {
          final currentKnowledgeIds =
              List<String>.from(_bots[index].knowledgeIds);
          if (!currentKnowledgeIds.contains(knowledgeId)) {
            currentKnowledgeIds.add(knowledgeId);

            final updatedBot = _bots[index].copyWith(
              knowledgeIds: currentKnowledgeIds,
              updatedAt: DateTime.now(),
            );

            _bots[index] = updatedBot;
            if (_selectedBot?.id == botId) {
              _selectedBot = updatedBot;
            }
          }
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to import knowledge: ${response.statusCode}';
        print(_error);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Remove knowledge from bot
  Future<bool> removeKnowledgeFromBot(String botId, String knowledgeId) async {
    try {
      _isLoading = true;
      notifyListeners();

      final uri = Uri.parse(
          '$baseUrl/kb-core/v1/ai-assistant/$botId/knowledges/$knowledgeId');
      final headers = await _getHeaders();

      final response = await http.delete(uri, headers: headers);

      if (response.statusCode == 200) {
        // Update local bot data
        final index = _bots.indexWhere((b) => b.id == botId);
        if (index != -1) {
          final currentKnowledgeIds =
              List<String>.from(_bots[index].knowledgeIds);
          currentKnowledgeIds.remove(knowledgeId);

          final updatedBot = _bots[index].copyWith(
            knowledgeIds: currentKnowledgeIds,
            updatedAt: DateTime.now(),
          );

          _bots[index] = updatedBot;
          if (_selectedBot?.id == botId) {
            _selectedBot = updatedBot;
          }
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to remove knowledge: ${response.statusCode}';
        print(_error);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      print(_error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get knowledge items for a bot
  List<KnowledgeItem> getBotKnowledgeItems(String botId) {
    final bot = _bots.firstWhere(
      (b) => b.id == botId,
      orElse: () => AIBot.empty(),
    );
    return _knowledgeItems
        .where((item) => bot.knowledgeIds.contains(item.id))
        .toList();
  }

  // Search bots
  List<AIBot> searchBots(String query) {
    if (query.isEmpty) {
      return _bots;
    }

    final lowercaseQuery = query.toLowerCase();
    return _bots.where((bot) {
      return bot.name.toLowerCase().contains(lowercaseQuery) ||
          bot.description.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Helper function for string length
  int min(int a, int b) {
    return a < b ? a : b;
  }

  // Reset thread for a bot (for testing or when conversation needs to be restarted)
  void resetThread(String botId) {
    _threadIds.remove(botId);
    _saveThreadIds();
    notifyListeners();
  }
}
