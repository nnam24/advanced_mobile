import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/knowledge_item.dart';

class KnowledgeService {
  // Base URL for knowledge API
  static const String baseUrl = 'https://knowledge-api.dev.jarvis.cx';
  static const String knowledgeEndpoint = '/kb-core/v1/knowledge';

  // Get auth token from shared preferences
  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  // Get user GUID from shared preferences or another source
  Future<String?> _getUserGuid() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_guid') ?? 'a153d8df-ee7d-4ac3-943e-882726700f9b'; // Default for testing
  }

  // Create a new knowledge item
  Future<KnowledgeItem> createKnowledge({
    required String knowledgeName,
    required String description,
  }) async {
    final token = await _getAuthToken();
    final userGuid = await _getUserGuid();

    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }

    if (userGuid == null) {
      throw Exception('User GUID not found.');
    }

    final headers = {
      'x-jarvis-guid': userGuid,
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    };

    final body = json.encode({
      'knowledgeName': knowledgeName,
      'description': description,
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl$knowledgeEndpoint'),
        headers: headers,
        body: body,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);

        // Create a KnowledgeItem from the response
        return KnowledgeItem(
          id: responseData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          title: responseData['knowledgeName'],
          content: responseData['description'],
          fileUrl: '',
          fileType: 'text',
          createdAt: responseData['createdAt'] != null
              ? DateTime.parse(responseData['createdAt'])
              : DateTime.now(),
          updatedAt: responseData['updatedAt'] != null
              ? DateTime.parse(responseData['updatedAt'])
              : DateTime.now(),
          userId: responseData['userId'],
        );
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create knowledge. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating knowledge: $e');
    }
  }

  // Get knowledge items with pagination and search
  Future<Map<String, dynamic>> getKnowledgeItems({
    String? searchQuery,
    int offset = 0,
    int limit = 20,
    String orderField = 'createdAt',
    String order = 'DESC',
  }) async {
    final token = await _getAuthToken();
    final userGuid = await _getUserGuid();

    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }

    if (userGuid == null) {
      throw Exception('User GUID not found.');
    }

    final headers = {
      'x-jarvis-guid': userGuid,
      'Authorization': 'Bearer $token',
    };

    // Build query parameters
    final queryParams = {
      'q': searchQuery,
      'order': order,
      'order_field': orderField,
      'offset': offset.toString(),
      'limit': limit.toString(),
    };

    // Remove null values from query parameters
    queryParams.removeWhere((key, value) => value == null);

    final uri = Uri.parse('$baseUrl$knowledgeEndpoint').replace(
      queryParameters: queryParams,
    );

    try {
      final response = await http.get(uri, headers: headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);

        // Parse knowledge items
        final List<KnowledgeItem> items = [];
        if (responseData['data'] != null) {
          for (var item in responseData['data']) {
            items.add(KnowledgeItem(
              id: item['id'] ?? item['userId'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
              title: item['knowledgeName'] ?? '',
              content: item['description'] ?? '',
              fileUrl: '',
              fileType: 'text',
              createdAt: item['createdAt'] != null
                  ? DateTime.parse(item['createdAt'])
                  : DateTime.now(),
              updatedAt: item['updatedAt'] != null
                  ? DateTime.parse(item['updatedAt'])
                  : DateTime.now(),
              userId: item['userId'],
            ));
          }
        }

        // Parse pagination metadata
        final meta = responseData['meta'] ?? {
          'limit': limit,
          'total': items.length,
          'offset': offset,
          'hasNext': false,
        };

        return {
          'items': items,
          'meta': meta,
        };
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to fetch knowledge items. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching knowledge items: $e');
    }
  }

  // Delete a knowledge item
  Future<bool> deleteKnowledgeItem(String id) async {
    final token = await _getAuthToken();
    final userGuid = await _getUserGuid();

    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }

    if (userGuid == null) {
      throw Exception('User GUID not found.');
    }

    final headers = {
      'x-jarvis-guid': userGuid,
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$knowledgeEndpoint/$id'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // API returns a boolean value indicating success
        if (response.body.isNotEmpty) {
          final result = json.decode(response.body);
          return result == true;
        }
        return true; // If body is empty but status code is success
      } else {
        if (response.body.isNotEmpty) {
          final errorData = json.decode(response.body);
          throw Exception(errorData['message'] ?? 'Failed to delete knowledge item. Status: ${response.statusCode}');
        }
        throw Exception('Failed to delete knowledge item. Status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting knowledge item: $e');
    }
  }

  // Disable a knowledge item (if different from delete)
  Future<bool> disableKnowledgeItem(String id) async {
    // In this case, the API uses the same DELETE endpoint for both delete and disable
    // If in the future there's a separate endpoint for disabling, this method can be updated
    return deleteKnowledgeItem(id);
  }
}

