import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/knowledge_item.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

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

  // Add this function to determine the MIME type based on file extension
  String getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    switch (extension) {
      case 'c':
        return 'text/x-c';
      case 'cpp':
        return 'text/x-c++';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'html':
        return 'text/html';
      case 'java':
        return 'text/x-java';
      case 'json':
        return 'application/json';
      case 'md':
        return 'text/markdown';
      case 'pdf':
        return 'application/pdf';
      case 'php':
        return 'text/x-php';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'py':
        return 'text/x-python'; // or 'text/x-script.python'
      case 'rb':
        return 'text/x-ruby';
      case 'tex':
        return 'text/x-tex';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream'; // Default binary data
    }
  }

  // Upload a file to a knowledge item - updated to match JavaScript approach
  Future<bool> uploadFileToKnowledge(String knowledgeId, File file) async {
    final token = await _getAuthToken();
    final userGuid = await _getUserGuid();

    if (token == null) {
      throw Exception('Authentication token not found. Please login again.');
    }

    if (userGuid == null) {
      throw Exception('User GUID not found.');
    }

    try {
      // Get the file name from the path
      final fileName = path.basename(file.path);
      final mimeType = getMimeType(fileName);

      print('Uploading file: $fileName with MIME type: $mimeType');

      // Create multipart request
      final uri = Uri.parse('$baseUrl$knowledgeEndpoint/$knowledgeId/local-file');
      print('Upload URI: $uri');

      // Create a multipart request
      final request = http.MultipartRequest('POST', uri);

      // Add headers
      request.headers['x-jarvis-guid'] = userGuid;
      request.headers['Authorization'] = 'Bearer $token';

      // Add file to the request
      final fileBytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      );
      request.files.add(multipartFile);

      print('Request headers: ${request.headers}');
      print('File name: $fileName, size: ${fileBytes.length} bytes, MIME type: $mimeType');

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        if (response.body.isNotEmpty) {
          try {
            final errorData = json.decode(response.body);
            throw Exception(errorData['message'] ?? 'Failed to upload file. Status: ${response.statusCode}');
          } catch (e) {
            throw Exception('Failed to upload file. Status: ${response.statusCode}, Body: ${response.body}');
          }
        }
        throw Exception('Failed to upload file. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Error uploading file: $e');
    }
  }

  // Add website knowledge to an existing knowledge item
  Future<Map<String, dynamic>> addWebsiteKnowledge(String knowledgeId, String unitName, String webUrl) async {
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

    final body = json.encode({
      'unitName': unitName,
      'webUrl': webUrl,
    });

    try {
      print('Adding website knowledge: $unitName, URL: $webUrl');
      final uri = Uri.parse('$baseUrl$knowledgeEndpoint/$knowledgeId/web');
      print('API endpoint: $uri');

      final response = await http.post(
        uri,
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          return json.decode(response.body);
        }
        return {'success': true};
      } else {
        if (response.body.isNotEmpty) {
          try {
            final errorData = json.decode(response.body);
            throw Exception(errorData['message'] ?? 'Failed to add website knowledge. Status: ${response.statusCode}');
          } catch (e) {
            throw Exception('Failed to add website knowledge. Status: ${response.statusCode}, Body: ${response.body}');
          }
        }
        throw Exception('Failed to add website knowledge. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding website knowledge: $e');
      throw Exception('Error adding website knowledge: $e');
    }
  }

  // Disable a knowledge item (if different from delete)
  Future<bool> disableKnowledgeItem(String id) async {
    // In this case, the API uses the same DELETE endpoint for both delete and disable
    // If in the future there's a separate endpoint for disabling, this method can be updated
    return deleteKnowledgeItem(id);
  }
}
