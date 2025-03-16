import 'package:flutter/material.dart';
import '../models/prompt.dart';

class PromptProvider extends ChangeNotifier {
  List<Prompt> _prompts = [];
  List<Prompt> _favoritePrompts = [];
  bool _isLoading = false;
  String _error = '';
  PromptCategory? _selectedCategory;
  String _searchQuery = '';
  PromptVisibility _visibilityFilter = PromptVisibility.public;

  // Getters
  List<Prompt> get prompts => _getFilteredPrompts();
  List<Prompt> get favoritePrompts => _favoritePrompts;
  bool get isLoading => _isLoading;
  String get error => _error;
  PromptCategory? get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  PromptVisibility get visibilityFilter => _visibilityFilter;

  PromptProvider() {
    _initializeMockData();
  }

  void _initializeMockData() {
    final now = DateTime.now();

    _prompts = [
      Prompt(
        id: '1',
        title: 'Explain a Complex Topic',
        content:
            'Explain [topic] in simple terms as if I am a [profession/age].',
        category: PromptCategory.general,
        visibility: PromptVisibility.public,
        authorId: 'system',
        authorName: 'System',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 30)),
        usageCount: 1245,
        isFavorite: true,
      ),
      Prompt(
        id: '2',
        title: 'Code Review',
        content:
            'Review this code and suggest improvements:\n```[language]\n[code]\n```',
        category: PromptCategory.coding,
        visibility: PromptVisibility.public,
        authorId: 'system',
        authorName: 'System',
        createdAt: now.subtract(const Duration(days: 25)),
        updatedAt: now.subtract(const Duration(days: 25)),
        usageCount: 876,
        isFavorite: false,
      ),
      Prompt(
        id: '3',
        title: 'Email Draft',
        content:
            'Draft a professional email to [recipient] about [topic]. The tone should be [tone].',
        category: PromptCategory.business,
        visibility: PromptVisibility.public,
        authorId: 'system',
        authorName: 'System',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(days: 20)),
        usageCount: 1032,
        isFavorite: true,
      ),
      Prompt(
        id: '4',
        title: 'Creative Story',
        content:
            'Write a short story in the style of [author] about [topic/theme].',
        category: PromptCategory.creative,
        visibility: PromptVisibility.public,
        authorId: 'system',
        authorName: 'System',
        createdAt: now.subtract(const Duration(days: 15)),
        updatedAt: now.subtract(const Duration(days: 15)),
        usageCount: 543,
        isFavorite: false,
      ),
      Prompt(
        id: '5',
        title: 'Research Summary',
        content:
            'Summarize the key findings and implications of research on [topic].',
        category: PromptCategory.academic,
        visibility: PromptVisibility.public,
        authorId: 'system',
        authorName: 'System',
        createdAt: now.subtract(const Duration(days: 10)),
        updatedAt: now.subtract(const Duration(days: 10)),
        usageCount: 321,
        isFavorite: false,
      ),
      Prompt(
        id: '6',
        title: 'My Flutter Project Plan',
        content:
            'Create a detailed project plan for building a Flutter mobile app with the following features: [features].',
        category: PromptCategory.coding,
        visibility: PromptVisibility.private,
        authorId: '1', // Current user ID
        authorName: 'User',
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
        usageCount: 12,
        isFavorite: true,
      ),
      Prompt(
        id: '7',
        title: 'Personal Bio',
        content:
            'Help me write a professional bio for my [platform] profile that highlights my experience in [field].',
        category: PromptCategory.personal,
        visibility: PromptVisibility.private,
        authorId: '1', // Current user ID
        authorName: 'User',
        createdAt: now.subtract(const Duration(days: 3)),
        updatedAt: now.subtract(const Duration(days: 3)),
        usageCount: 5,
        isFavorite: true,
      ),
    ];

    // Initialize favorites
    _favoritePrompts = _prompts.where((prompt) => prompt.isFavorite).toList();
  }

  List<Prompt> _getFilteredPrompts() {
    return _prompts.where((prompt) {
      // Filter by visibility
      if (prompt.visibility != _visibilityFilter) {
        return false;
      }

      // Filter by category if selected
      if (_selectedCategory != null && prompt.category != _selectedCategory) {
        return false;
      }

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return prompt.title.toLowerCase().contains(query) ||
            prompt.content.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  void setCategory(PromptCategory? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setVisibilityFilter(PromptVisibility visibility) {
    _visibilityFilter = visibility;
    notifyListeners();
  }

  Future<bool> toggleFavorite(String promptId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 300));

      // Update prompt
      final index = _prompts.indexWhere((p) => p.id == promptId);
      if (index != -1) {
        final prompt = _prompts[index];
        final updatedPrompt = prompt.copyWith(
          isFavorite: !prompt.isFavorite,
        );

        _prompts[index] = updatedPrompt;

        // Update favorites list
        if (updatedPrompt.isFavorite) {
          _favoritePrompts.add(updatedPrompt);
        } else {
          _favoritePrompts.removeWhere((p) => p.id == promptId);
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

  Future<bool> createPrompt(Prompt prompt) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Create new prompt
      final newPrompt = prompt.copyWith(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _prompts.add(newPrompt);

      // Add to favorites if marked as favorite
      if (newPrompt.isFavorite) {
        _favoritePrompts.add(newPrompt);
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

  Future<bool> updatePrompt(Prompt prompt) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Update prompt
      final index = _prompts.indexWhere((p) => p.id == prompt.id);
      if (index != -1) {
        final updatedPrompt = prompt.copyWith(
          updatedAt: DateTime.now(),
        );

        _prompts[index] = updatedPrompt;

        // Update in favorites if needed
        final favoriteIndex =
            _favoritePrompts.indexWhere((p) => p.id == prompt.id);
        if (favoriteIndex != -1) {
          if (updatedPrompt.isFavorite) {
            _favoritePrompts[favoriteIndex] = updatedPrompt;
          } else {
            _favoritePrompts.removeAt(favoriteIndex);
          }
        } else if (updatedPrompt.isFavorite) {
          _favoritePrompts.add(updatedPrompt);
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

  Future<bool> deletePrompt(String promptId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Delete prompt
      _prompts.removeWhere((p) => p.id == promptId);
      _favoritePrompts.removeWhere((p) => p.id == promptId);

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

  Future<bool> incrementUsageCount(String promptId) async {
    try {
      // Find prompt
      final index = _prompts.indexWhere((p) => p.id == promptId);
      if (index != -1) {
        final prompt = _prompts[index];
        final updatedPrompt = prompt.copyWith(
          usageCount: prompt.usageCount + 1,
        );

        _prompts[index] = updatedPrompt;

        // Update in favorites if needed
        final favoriteIndex =
            _favoritePrompts.indexWhere((p) => p.id == promptId);
        if (favoriteIndex != -1) {
          _favoritePrompts[favoriteIndex] = updatedPrompt;
        }

        notifyListeners();
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get prompt by ID
  Prompt? getPromptById(String id) {
    try {
      return _prompts.firstWhere((p) => p.id == id);
    } catch (e) {
      return null;
    }
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }
}
