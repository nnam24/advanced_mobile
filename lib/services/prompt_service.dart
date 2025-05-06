import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/prompt.dart';
import '../models/prompt_response.dart';

class PromptService {
  // Base URL for the API
  static const String baseUrl = 'https://api.dev.jarvis.cx';

  // API endpoints
  static const String promptsEndpoint = '/api/v1/prompts';

  // Headers
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

  // Get prompts with filtering and pagination
  Future<PromptResponse<Prompt>> getPrompts({
    String? query,
    int offset = 0,
    int limit = 20,
    String? category,
    String? search,
    bool? isPublic,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'offset': offset.toString(),
        'limit': limit.toString(),
      };

      // Use query parameter for search (prioritize query over search)
      if (query != null && query.isNotEmpty) {
        queryParams['query'] = query;
        print('Searching with query: $query');
      } else if (search != null && search.isNotEmpty) {
        // Fallback to search parameter for backward compatibility
        queryParams['query'] = search; // Use 'query' instead of 'search'
        print('Searching with search (converted to query): $search');
      }

      if (category != null) {
        queryParams['category'] = category;
      }

      // Only add isPublic parameter if it's not null
      if (isPublic != null) {
        queryParams['isPublic'] = isPublic.toString();
      }

      // Build URL with query parameters
      final uri = Uri.parse('$baseUrl$promptsEndpoint').replace(
        queryParameters: queryParams,
      );

      print('API request URL: ${uri.toString()}');

      // Get headers
      final headers = await _getHeaders();

      // Make API request
      final response = await http.get(uri, headers: headers);

      // Check if request was successful
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        // Debug log to check the structure of the first item
        if (jsonData['items'] != null && jsonData['items'].isNotEmpty) {
          print(
              'First prompt ID format: ${jsonData['items'][0].containsKey('id') ? 'id' : '_id'}');
          print(
              'First prompt ID value: ${jsonData['items'][0]['id'] ?? jsonData['items'][0]['_id'] ?? 'No ID found'}');
        }

        return PromptResponse.fromJson(
          jsonData,
          (item) => Prompt.fromJson(item),
        );
      } else {
        throw Exception('Failed to load prompts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching prompts: $e');
    }
  }

  // Get favorite prompts
  Future<PromptResponse<Prompt>> getFavoritePrompts({
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      // Build query parameters
      final queryParams = <String, String>{
        'offset': offset.toString(),
        'limit': limit.toString(),
        'isFavorite': 'true',
      };

      // Build URL with query parameters
      final uri = Uri.parse('$baseUrl$promptsEndpoint').replace(
        queryParameters: queryParams,
      );

      // Get headers
      final headers = await _getHeaders();

      // Make API request
      final response = await http.get(uri, headers: headers);

      // Check if request was successful
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return PromptResponse.fromJson(
          jsonData,
          (item) => Prompt.fromJson(item),
        );
      } else {
        throw Exception(
            'Failed to load favorite prompts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching favorite prompts: $e');
    }
  }

  // Add prompt to favorites
  Future<bool> addToFavorites(String promptId) async {
    try {
      // Validate the prompt ID
      if (promptId.isEmpty) {
        print('Cannot add to favorites: Empty prompt ID');
        return false;
      }

      // Build the URL for the favorite endpoint
      final uri = Uri.parse('$baseUrl$promptsEndpoint/$promptId/favorite');

      // Get headers
      final headers = await _getHeaders();

      // Make the POST request to add to favorites
      print('Adding prompt to favorites: $promptId');
      final response = await http.post(uri, headers: headers);

      // Check if request was successful (201 Created)
      if (response.statusCode == 201) {
        print('Successfully added prompt to favorites: $promptId');
        return true;
      } else {
        print(
            'Failed to add prompt to favorites: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error adding prompt to favorites: $e');
      return false;
    }
  }

  // Remove prompt from favorites
  Future<bool> removeFromFavorites(String promptId) async {
    try {
      // Validate the prompt ID
      if (promptId.isEmpty) {
        print('Cannot remove from favorites: Empty prompt ID');
        return false;
      }

      // Build the URL for the favorite endpoint
      final uri = Uri.parse('$baseUrl$promptsEndpoint/$promptId/favorite');

      // Get headers
      final headers = await _getHeaders();

      // Make the DELETE request to remove from favorites
      print('Removing prompt from favorites: $promptId');
      final response = await http.delete(uri, headers: headers);

      // Check if request was successful (200 OK)
      if (response.statusCode == 200) {
        print('Successfully removed prompt from favorites: $promptId');
        return true;
      } else {
        print(
            'Failed to remove prompt from favorites: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error removing prompt from favorites: $e');
      return false;
    }
  }

  // Toggle favorite status for a prompt
  Future<bool> toggleFavorite(String promptId) async {
    try {
      // First, get the current prompt to check its favorite status
      final prompt = await getPromptById(promptId);

      if (prompt == null) {
        print('Cannot toggle favorite: Prompt not found');
        return false;
      }

      // Toggle based on current favorite status
      if (prompt.isFavorite) {
        return await removeFromFavorites(promptId);
      } else {
        return await addToFavorites(promptId);
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      return false;
    }
  }

  // Get a prompt by ID
  Future<Prompt?> getPromptById(String promptId) async {
    try {
      if (promptId.isEmpty) {
        print('Cannot get prompt: Empty ID');
        return null;
      }

      final uri = Uri.parse('$baseUrl$promptsEndpoint/$promptId');
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Prompt.fromJson(jsonData);
      } else {
        print('Failed to get prompt: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting prompt: $e');
      return null;
    }
  }

  // Increment usage count for a prompt
  Future<bool> incrementUsageCount(String promptId) async {
    try {
      final uri = Uri.parse('$baseUrl$promptsEndpoint/$promptId/use');
      final headers = await _getHeaders();

      final response = await http.post(
        uri,
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error incrementing usage count: $e');
    }
  }

  // Create a new prompt
  Future<Prompt> createPrompt(Prompt prompt) async {
    try {
      final uri = Uri.parse('$baseUrl$promptsEndpoint');
      final headers = await _getHeaders();

      // Create request body according to API documentation
      final requestBody = {
        'title': prompt.title,
        'content': prompt.content,
        'description': prompt.description ?? '',
        'category': prompt.category.toString().split('.').last.toLowerCase(),
        'isPublic': prompt.isPublic,
        'language': prompt.language,
      };

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return Prompt.fromJson(jsonData);
      } else {
        throw Exception(
            'Failed to create prompt: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating prompt: $e');
    }
  }

  // Update an existing prompt
  Future<Prompt> updatePrompt(Prompt prompt) async {
    try {
      final uri = Uri.parse('$baseUrl$promptsEndpoint/${prompt.id}');
      final headers = await _getHeaders();

      // Create request body according to API documentation
      final requestBody = {
        'title': prompt.title,
        'content': prompt.content,
        'description': prompt.description ?? '',
        'category': prompt.category.toString().split('.').last.toLowerCase(),
        'isPublic': prompt.isPublic,
        'language': prompt.language,
      };

      final response = await http.patch(
        uri,
        headers: headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        // If the API returns the updated prompt, use that
        if (response.body.isNotEmpty) {
          try {
            final jsonData = json.decode(response.body);
            return Prompt.fromJson(jsonData);
          } catch (e) {
            print('Warning: Could not parse response body: $e');
          }
        }

        // Otherwise, return the prompt we sent with updated timestamp
        return prompt.copyWith(updatedAt: DateTime.now());
      } else {
        throw Exception(
            'Failed to update prompt: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating prompt: $e');
    }
  }

  // Delete a prompt by ID
  Future<bool> deletePrompt(String promptId) async {
    try {
      final uri = Uri.parse('$baseUrl$promptsEndpoint/$promptId');
      final headers = await _getHeaders();

      // Log the request details for debugging
      print('Deleting prompt with ID: $promptId');
      print('DELETE request to: ${uri.toString()}');

      final response = await http.delete(uri, headers: headers);

      // Log the response for debugging
      print('Delete response status code: ${response.statusCode}');
      print('Delete response body: ${response.body}');

      // According to the API documentation, a successful delete returns 200 OK
      return response.statusCode == 200;
    } catch (e) {
      print('Error in deletePrompt: $e');
      throw Exception('Error deleting prompt: $e');
    }
  }
}
