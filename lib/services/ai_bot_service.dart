import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/ai_bot.dart';
import '../models/knowledge_item.dart';
import '../models/message.dart';

class AIBotService extends ChangeNotifier {
  List<AIBot> _bots = [];
  AIBot? _selectedBot;
  List<KnowledgeItem> _knowledgeItems = [];
  bool _isLoading = false;
  String _error = '';

  // Getters
  List<AIBot> get bots => _bots;
  AIBot? get selectedBot => _selectedBot;
  List<KnowledgeItem> get knowledgeItems => _knowledgeItems;
  bool get isLoading => _isLoading;
  String get error => _error;

  AIBotService() {
    _initializeMockData();
  }

  void _initializeMockData() {
    // Mock bots
    _bots = [
      AIBot(
        id: '1',
        name: 'Customer Support Bot',
        description: 'A bot that helps with customer inquiries',
        instructions:
            'You are a helpful customer support assistant. Be polite and concise.',
        avatarUrl: '',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
        knowledgeIds: ['1', '2'],
        isPublished: true,
        publishedChannels: {
          'slack': 'C123456',
          'telegram': '@customer_support_bot',
        },
      ),
      AIBot(
        id: '2',
        name: 'Marketing Assistant',
        description: 'Helps with marketing tasks and content creation',
        instructions:
            'You are a creative marketing assistant. Generate engaging content.',
        avatarUrl: '',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
        knowledgeIds: ['3'],
        isPublished: false,
        publishedChannels: {},
      ),
      AIBot(
        id: '3',
        name: 'Code Helper',
        description: 'Assists with programming and debugging',
        instructions:
            'You are a programming assistant. Provide code examples and explanations.',
        avatarUrl: '',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
        knowledgeIds: [],
        isPublished: false,
        publishedChannels: {},
      ),
    ];

    // Mock knowledge items
    _knowledgeItems = [
      KnowledgeItem(
        id: '1',
        title: 'Product FAQ',
        content: 'Frequently asked questions about our products...',
        fileUrl: '',
        fileType: 'text',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
      KnowledgeItem(
        id: '2',
        title: 'Return Policy',
        content: 'Our return policy details...',
        fileUrl: '',
        fileType: 'text',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        updatedAt: DateTime.now().subtract(const Duration(days: 14)),
      ),
      KnowledgeItem(
        id: '3',
        title: 'Marketing Guidelines',
        content: 'Brand voice and marketing guidelines...',
        fileUrl: '',
        fileType: 'text',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];
  }

  // Select a bot
  void selectBot(String botId) {
    _selectedBot = _bots.firstWhere((bot) => bot.id == botId);
    notifyListeners();
  }

  // Create a new bot
  Future<bool> createBot(AIBot bot) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // In a real app, you would call an API here
      final newBot = bot.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _bots.add(newBot);
      _selectedBot = newBot;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
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

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // In a real app, you would call an API here
      final index = _bots.indexWhere((b) => b.id == bot.id);
      if (index != -1) {
        final updatedBot = bot.copyWith(updatedAt: DateTime.now());
        _bots[index] = updatedBot;
        _selectedBot = updatedBot;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
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

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // In a real app, you would call an API here
      _bots.removeWhere((bot) => bot.id == botId);
      if (_selectedBot?.id == botId) {
        _selectedBot = null;
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update bot instructions
  Future<bool> updateBotInstructions(String botId, String instructions) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // In a real app, you would call an API here
      final index = _bots.indexWhere((b) => b.id == botId);
      if (index != -1) {
        final updatedBot = _bots[index].copyWith(
          instructions: instructions,
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
    } catch (e) {
      _error = e.toString();
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

      // Simulate API call with a shorter delay to prevent ANR
      await Future.delayed(const Duration(milliseconds: 500));

      // In a real app, you would call an API here
      final bot = _bots.firstWhere((b) => b.id == botId);

      // Generate a mock response based on the bot's instructions
      String response = '';
      if (bot.name.contains('Customer')) {
        response =
            'As a customer support bot, I can help you with your inquiry. What specific product or service do you need assistance with?';
      } else if (bot.name.contains('Marketing')) {
        response =
            'As your marketing assistant, I can help create engaging content. Would you like me to suggest some marketing ideas for your business?';
      } else if (bot.name.contains('Code')) {
        response =
            'I can help with your coding questions. What programming language are you working with?';
      } else {
        response =
            'I\'m here to assist you with your question. How can I help you today?';
      }

      _isLoading = false;
      notifyListeners();

      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
        tokenCount: (response.length / 4).ceil(),
      );
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();

      return Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: 'Sorry, I encountered an error: $_error',
        type: MessageType.assistant,
        timestamp: DateTime.now(),
        tokenCount: 10,
      );
    }
  }

  // Import knowledge to bot
  Future<bool> importKnowledgeToBot(
      String botId, List<String> knowledgeIds) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate API call with a shorter delay
      await Future.delayed(const Duration(milliseconds: 500));

      // In a real app, you would call an API here
      final index = _bots.indexWhere((b) => b.id == botId);
      if (index != -1) {
        final currentKnowledgeIds = Set<String>.from(_bots[index].knowledgeIds);
        currentKnowledgeIds.addAll(knowledgeIds);

        final updatedBot = _bots[index].copyWith(
          knowledgeIds: currentKnowledgeIds.toList(),
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
    } catch (e) {
      _error = e.toString();
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

      // Simulate API call with a shorter delay
      await Future.delayed(const Duration(milliseconds: 500));

      // In a real app, you would call an API here
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
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Publish bot to channels
  Future<bool> publishBot(String botId, Map<String, String> channels) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate API call with a shorter delay
      await Future.delayed(const Duration(milliseconds: 500));

      // In a real app, you would call an API here
      final index = _bots.indexWhere((b) => b.id == botId);
      if (index != -1) {
        final updatedBot = _bots[index].copyWith(
          isPublished: true,
          publishedChannels: channels,
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
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Get knowledge items for a bot
  List<KnowledgeItem> getBotKnowledgeItems(String botId) {
    final bot =
        _bots.firstWhere((b) => b.id == botId, orElse: () => AIBot.empty());
    return _knowledgeItems
        .where((item) => bot.knowledgeIds.contains(item.id))
        .toList();
  }

  // Get available knowledge items (not already added to the bot)
  List<KnowledgeItem> getAvailableKnowledgeItems(String botId) {
    final bot =
        _bots.firstWhere((b) => b.id == botId, orElse: () => AIBot.empty());
    return _knowledgeItems
        .where((item) => !bot.knowledgeIds.contains(item.id))
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

  // Add a knowledge item
  void addKnowledgeItem(KnowledgeItem item) {
    _knowledgeItems.add(item);
    notifyListeners();
  }

  // Delete a knowledge item
  void deleteKnowledgeItem(String itemId) {
    _knowledgeItems.removeWhere((item) => item.id == itemId);

    // Also remove this knowledge item from any bots that use it
    for (int i = 0; i < _bots.length; i++) {
      if (_bots[i].knowledgeIds.contains(itemId)) {
        final updatedKnowledgeIds = List<String>.from(_bots[i].knowledgeIds)
          ..remove(itemId);

        _bots[i] = _bots[i].copyWith(
          knowledgeIds: updatedKnowledgeIds,
          updatedAt: DateTime.now(),
        );
      }
    }

    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }
}
