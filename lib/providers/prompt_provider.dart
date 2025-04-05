import 'package:flutter/foundation.dart';
import '../models/prompt.dart';
import '../models/prompt_response.dart';
import '../services/prompt_service.dart';

class PromptProvider with ChangeNotifier {
  final PromptService _promptService;

  List<Prompt> _prompts = [];
  List<Prompt> _favoritePrompts = [];
  List<Prompt> _myPrompts = [];
  bool _isLoading = false;
  bool _hasNext = true;
  bool _hasMoreFavorites = true;
  bool _hasMoreMyPrompts = true;
  String? _error;
  int _offset = 0;
  int _favoriteOffset = 0;
  int _myPromptsOffset = 0;
  PromptCategory? _selectedCategory;
  String? _searchQuery;
  bool _isPublicFilter = true;
  // Add a flag to track if we've attempted to fetch favorites
  bool _hasFetchedFavorites = false;

  PromptProvider({required PromptService promptService})
      : _promptService = promptService;

  List<Prompt> get prompts => _prompts;
  List<Prompt> get favoritePrompts => _favoritePrompts;
  List<Prompt> get myPrompts => _myPrompts;
  bool get isLoading => _isLoading;
  bool get hasNext => _hasNext;
  bool get hasMoreFavorites => _hasMoreFavorites;
  bool get hasMoreMyPrompts => _hasMoreMyPrompts;
  String? get error => _error;
  PromptCategory? get selectedCategory => _selectedCategory;
  String? get searchQuery => _searchQuery;
  bool get isPublicFilter => _isPublicFilter;
  // Add getter for the new flag
  bool get hasFetchedFavorites => _hasFetchedFavorites;

  // Helper method to check if a prompt has a valid ID
  // Using dynamic parameter to be compatible with where() method
  bool hasValidId(dynamic item) {
    if (item is Prompt) {
      return item.id.isNotEmpty;
    }
    return false;
  }

  // Helper method to log prompt IDs for debugging
  void _logPromptIds(List<Prompt> prompts, String source) {
    if (prompts.isEmpty) {
      print('$source: No prompts to log');
      return;
    }

    final validCount = prompts.where((p) => p.id.isNotEmpty).length;
    final invalidCount = prompts.length - validCount;

    print(
        '$source: ${prompts.length} prompts (Valid: $validCount, Invalid: $invalidCount)');

    if (invalidCount > 0) {
      print('$source: Found $invalidCount prompts with empty IDs');
    }

    // Log the first few prompts for debugging
    for (var i = 0; i < prompts.length && i < 3; i++) {
      print(
          '$source: Prompt $i - ID: ${prompts[i].id}, Title: ${prompts[i].title}');
    }
  }

  // Set the visibility filter (public/private)
  Future<void> setVisibilityFilter(bool isPublic) async {
    print(
        'Setting visibility filter to isPublic=$isPublic (current: $_isPublicFilter)');

    if (_isPublicFilter == isPublic) {
      print('Filter already set to $isPublic, skipping');
      return;
    }

    _isPublicFilter = isPublic;
    _offset = 0;
    _hasNext = true;
    _prompts = []; // Clear the current prompts list
    notifyListeners();

    print('Filter updated, fetching prompts with isPublic=$isPublic');
    await fetchPrompts(isPublic: isPublic, refresh: true);
  }

  // Set the category filter
  void setCategory(PromptCategory? category) {
    _selectedCategory = category;
    refreshPrompts();
  }

  // Set the search query
  void setSearchQuery(String query) {
    _searchQuery = query.isEmpty ? null : query;
    refreshPrompts();
  }

  // Refresh prompts with current filters
  Future<void> refreshPrompts() async {
    _offset = 0;
    _hasNext = true;
    await fetchPrompts(isPublic: _isPublicFilter);
  }

  Future<void> fetchPrompts({
    bool? isPublic,
    String? category,
    String? search,
    bool refresh = false,
  }) async {
    if (_isLoading) {
      print('Already loading prompts, skipping new request');
      return;
    }

    if (refresh) {
      print('Refreshing prompts list');
      _offset = 0;
      _hasNext = true;
      _prompts = []; // Clear the current prompts list when refreshing
      notifyListeners();
    }

    if (!_hasNext && !refresh) {
      print('No more prompts to load and not refreshing, skipping');
      return;
    }

    // Update filters if provided
    if (isPublic != null) {
      _isPublicFilter = isPublic;
    }

    print('Fetching prompts with isPublic: $_isPublicFilter, offset: $_offset');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final categoryValue = _selectedCategory?.toString().split('.').last;

      print(
          'API request: isPublic=$_isPublicFilter, category=$categoryValue, search=$_searchQuery, offset=$_offset');

      final response = await _promptService.getPrompts(
        offset: _offset,
        category: categoryValue,
        search: _searchQuery,
        isPublic: _isPublicFilter,
      );

      // Filter out prompts with empty IDs
      final validPrompts =
          response.items.where((p) => p.id.isNotEmpty).toList();

      // Log the prompts for debugging
      _logPromptIds(validPrompts, 'fetchPrompts');

      if (refresh || _offset == 0) {
        _prompts = validPrompts;
      } else {
        _prompts = [..._prompts, ...validPrompts];
      }

      _offset = _prompts.length;
      _hasNext = response.hasNext;
      _isLoading = false;

      print(
          'Fetch complete: ${validPrompts.length} prompts loaded, hasNext: $_hasNext');

      notifyListeners();
    } catch (e) {
      print('Error fetching prompts: $e');
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (!_hasNext || _isLoading) return;
    await fetchPrompts(isPublic: _isPublicFilter);
  }

// Modify the fetchFavorites method to better handle empty results
  Future<void> fetchFavorites({bool refresh = false}) async {
    if (_isLoading) {
      print('Already loading favorites, skipping new request');
      return;
    }

    if (refresh) {
      print('Refreshing favorites list');
      _favoriteOffset = 0;
      _hasMoreFavorites = true;
      _favoritePrompts = []; // Clear when refreshing
      notifyListeners();
    }

    if (!_hasMoreFavorites && !refresh) {
      print('No more favorites to load and not refreshing, skipping');
      return;
    }

    print('Fetching favorites with offset: $_favoriteOffset');

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _promptService.getFavoritePrompts(
        offset: _favoriteOffset,
      );

      // Filter out prompts with empty IDs
      final validPrompts =
          response.items.where((p) => p.id.isNotEmpty).toList();

      // Log the prompts for debugging
      _logPromptIds(validPrompts, 'fetchFavorites');

      if (refresh) {
        _favoritePrompts = validPrompts;
      } else {
        _favoritePrompts = [..._favoritePrompts, ...validPrompts];
      }

      _favoriteOffset = _favoritePrompts.length;
      _hasMoreFavorites = response.hasNext;
      _isLoading = false;
      _hasFetchedFavorites = true; // Mark that we've fetched favorites

      print(
          'Favorites fetch complete: ${validPrompts.length} prompts loaded, hasMore: $_hasMoreFavorites');

      notifyListeners();
    } catch (e) {
      print('Error fetching favorites: $e');
      _error = e.toString();
      _isLoading = false;
      _hasFetchedFavorites =
          true; // Mark that we've attempted to fetch favorites
      notifyListeners();
    }
  }

  Future<void> fetchMyPrompts({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _myPromptsOffset = 0;
      _hasMoreMyPrompts = true;
    }

    if (!_hasMoreMyPrompts && !refresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _promptService.getPrompts(
        offset: _myPromptsOffset,
        isPublic: false,
      );

      // Filter out prompts with empty IDs
      final validPrompts =
          response.items.where((p) => p.id.isNotEmpty).toList();

      // Log the prompts for debugging
      _logPromptIds(response.items, 'fetchMyPrompts');

      if (refresh) {
        _myPrompts = validPrompts;
      } else {
        _myPrompts = [..._myPrompts, ...validPrompts];
      }

      _myPromptsOffset = _myPrompts.length;
      _hasMoreMyPrompts = response.hasNext;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Updated toggleFavorite method to use the new API endpoints
  Future<bool> toggleFavorite(String promptId) async {
    // Validate the ID
    if (promptId.isEmpty) {
      _error = 'Cannot toggle favorite: Empty ID provided';
      notifyListeners();
      return false;
    }

    try {
      // Find the prompt in our lists to check its current favorite status
      Prompt? prompt = getPromptById(promptId);
      bool isFavorite = prompt?.isFavorite ?? false;
      bool success;

      // Show loading state
      _isLoading = true;
      notifyListeners();

      // Call the appropriate API method based on current favorite status
      if (isFavorite) {
        // If it's already a favorite, remove it
        success = await _promptService.removeFromFavorites(promptId);
      } else {
        // If it's not a favorite, add it
        success = await _promptService.addToFavorites(promptId);
      }

      if (success) {
        // Update the prompt in all lists
        _updatePromptInLists(
          promptId,
          (prompt) => prompt.copyWith(isFavorite: !isFavorite),
        );

        // If we're removing from favorites, also remove from the favorites list
        if (isFavorite) {
          _favoritePrompts.removeWhere((p) => p.id == promptId);
        } else {
          // If we're adding to favorites and we have the prompt in another list,
          // add it to the favorites list too
          if (prompt != null &&
              !_favoritePrompts.any((p) => p.id == promptId)) {
            _favoritePrompts.add(prompt.copyWith(isFavorite: true));
          }
        }

        _isLoading = false;
        notifyListeners();
      } else {
        _error = 'Failed to toggle favorite status';
        _isLoading = false;
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> incrementUsageCount(String promptId) async {
    // Validate the ID
    if (promptId.isEmpty) {
      _error = 'Cannot increment usage count: Empty ID provided';
      notifyListeners();
      return false;
    }

    try {
      final success = await _promptService.incrementUsageCount(promptId);

      if (success) {
        // Update the prompt in all lists
        _updatePromptInLists(
          promptId,
          (prompt) => prompt.copyWith(usageCount: prompt.usageCount + 1),
        );
        notifyListeners();
      }

      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _updatePromptInLists(String promptId, Prompt Function(Prompt) update) {
    // Validate the ID
    if (promptId.isEmpty) {
      print('Cannot update prompt in lists: Empty ID provided');
      return;
    }

    // Update in prompts list
    for (var i = 0; i < _prompts.length; i++) {
      if (_prompts[i].id == promptId) {
        _prompts[i] = update(_prompts[i]);
      }
    }

    // Update in favorite prompts list
    for (var i = 0; i < _favoritePrompts.length; i++) {
      if (_favoritePrompts[i].id == promptId) {
        _favoritePrompts[i] = update(_favoritePrompts[i]);
      }
    }

    // Update in my prompts list
    for (var i = 0; i < _myPrompts.length; i++) {
      if (_myPrompts[i].id == promptId) {
        _myPrompts[i] = update(_myPrompts[i]);
      }
    }
  }

  Prompt? getPromptById(String id) {
    // Validate the ID
    if (id.isEmpty) {
      print('Cannot get prompt by ID: Empty ID provided');
      return null;
    }

    // Check in prompts list
    for (var prompt in _prompts) {
      if (prompt.id == id) {
        return prompt;
      }
    }

    // Check in favorite prompts list
    for (var prompt in _favoritePrompts) {
      if (prompt.id == id) {
        return prompt;
      }
    }

    // Check in my prompts list
    for (var prompt in _myPrompts) {
      if (prompt.id == id) {
        return prompt;
      }
    }

    return null;
  }

  Future<bool> createPrompt(Prompt prompt) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final createdPrompt = await _promptService.createPrompt(prompt);

      // Verify that the created prompt has a valid ID
      if (createdPrompt.id.isEmpty) {
        _error = 'Created prompt has no valid ID';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Add to my prompts list if it's private
      if (!createdPrompt.isPublic) {
        _myPrompts = [createdPrompt, ..._myPrompts];
      } else {
        // Add to public prompts list if it's public
        _prompts = [createdPrompt, ..._prompts];
      }

      _isLoading = false;
      notifyListeners();

      print('Successfully created prompt: ${createdPrompt.id}');
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePrompt(Prompt updatedPrompt) async {
    // Validate the ID
    if (updatedPrompt.id.isEmpty) {
      _error = 'Cannot update prompt: Empty ID provided';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final prompt = await _promptService.updatePrompt(updatedPrompt);

      // Update the prompt in all lists
      _updatePromptInLists(
        updatedPrompt.id,
        (_) => prompt,
      );

      _isLoading = false;
      notifyListeners();

      print('Successfully updated prompt: ${updatedPrompt.id}');
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePrompt(String id) async {
    // Validate the ID
    if (id.isEmpty) {
      _error = 'Cannot delete prompt: Empty ID provided';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _promptService.deletePrompt(id);

      if (success) {
        // Remove the prompt from all lists
        _prompts.removeWhere((prompt) => prompt.id == id);
        _favoritePrompts.removeWhere((prompt) => prompt.id == id);
        _myPrompts.removeWhere((prompt) => prompt.id == id);

        print('Successfully deleted prompt: $id');
      } else {
        _error = 'Failed to delete prompt';
        print('Failed to delete prompt: $id');
      }

      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print('Error deleting prompt: $e');
      return false;
    }
  }
}
