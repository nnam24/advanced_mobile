import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ai_bot.dart';
import '../models/knowledge_item.dart';
import '../models/message.dart';
import '../models/ai_bot_response.dart';

class AIBotService extends ChangeNotifier {
  List<AIBot> _bots = [];
  AIBot? _selectedBot;
  List<KnowledgeItem> _knowledgeItems = [];
  bool _isLoading = false;
  String _error = '';
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  // Base URL for the API
  static const String baseUrl = 'https://knowledge-api.dev.jarvis.cx';

  // Getters
  List<AIBot> get bots => _bots;
  AIBot? get selectedBot => _selectedBot;
  List<KnowledgeItem> get knowledgeItems => _knowledgeItems;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get hasMore => _hasMore;

  AIBotService() {
    // Load bots when service is initialized
    fetchBots();
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

  // Ask a bot (chat)
  Future<Message> askBot(String botId, String question) async {
    try {
      _isLoading = true;
      notifyListeners();

      final uri = Uri.parse('$baseUrl/kb-core/v1/ai-assistant/$botId/chat');
      final headers = await _getHeaders();

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode({'message': question}),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final responseText = jsonData['response'] ?? 'No response from the bot';

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
}
