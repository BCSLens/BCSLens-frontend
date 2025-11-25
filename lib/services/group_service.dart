// lib/services/group_service.dart
import 'dart:convert';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;
import '../utils/app_logger.dart';

class GroupService {
  final AuthService _authService = AuthService();

  // Get all groups - CORRECTED VERSION
  Future<List<Map<String, dynamic>>> getGroups() async {
    try {
      AppLogger.log('🔍 Getting groups...');
      
      // AuthService.authenticatedGet now returns parsed JSON directly, not Response
      final data = await _authService.authenticatedGet('/groups');

      AppLogger.log('📥 Groups response type: ${data.runtimeType}');
      AppLogger.log('📥 Groups response data: $data');

      // Handle different possible response formats
      if (data is Map<String, dynamic>) {
        if (data.containsKey('groups')) {
          // Response format: {"groups": [...]}
          final groups = data['groups'] as List;
          final result = groups.map((group) => group as Map<String, dynamic>).toList();
          AppLogger.log('✅ Found ${result.length} groups (nested format)');
          return result;
        } else if (data.containsKey('data')) {
          // Response format: {"data": [...]}
          final groups = data['data'] as List;
          final result = groups.map((group) => group as Map<String, dynamic>).toList();
          AppLogger.log('✅ Found ${result.length} groups (data format)');
          return result;
        } else {
          // Response is a single group object, wrap in array
          AppLogger.log('✅ Found 1 group (single object)');
          return [data];
        }
      } else if (data is List) {
        // Response is directly an array of groups
        final result = data.map((group) => group as Map<String, dynamic>).toList();
        AppLogger.log('✅ Found ${result.length} groups (direct array)');
        return result;
      } else {
        AppLogger.log('❌ Unrecognized response format: $data');
        throw Exception('Unexpected response format: ${data.runtimeType}');
      }
    } catch (e) {
      AppLogger.log('❌ Error getting groups: $e');
      
      // Handle authentication errors specifically
      if (e.toString().contains('Authentication failed')) {
        throw Exception('Please log in again to access groups');
      }
      
      rethrow;
    }
  }

  // Create a new group - CORRECTED VERSION
  Future<Map<String, dynamic>> createGroup(String groupName) async {
    try {
      AppLogger.log('🆕 Creating group: $groupName');
      
      // AuthService.authenticatedPost returns parsed JSON directly
      final data = await _authService.authenticatedPost('/groups', {
        'group_name': groupName,
      });

      AppLogger.log('📥 Create group response type: ${data.runtimeType}');
      AppLogger.log('📥 Create group response data: $data');

      if (data is Map<String, dynamic>) {
        if (data.containsKey('group')) {
          // Response format: {"group": {...}}
          final groupData = data['group'] as Map<String, dynamic>;
          AppLogger.log('✅ Group created successfully (nested format)');
          return groupData;
        } else {
          // Response is the group data directly
          AppLogger.log('✅ Group created successfully (direct format)');
          return data;
        }
      } else {
        AppLogger.log('❌ Unrecognized create group response format: $data');
        throw Exception('Unexpected response format: ${data.runtimeType}');
      }
    } catch (e) {
      AppLogger.log('❌ Error creating group: $e');
      
      // Handle authentication errors specifically
      if (e.toString().contains('Authentication failed')) {
        throw Exception('Please log in again to create a group');
      }
      
      rethrow;
    }
  }

  // Update group
  Future<Map<String, dynamic>> updateGroup(String groupId, String groupName) async {
    try {
      AppLogger.log('📝 Updating group: $groupId with name: $groupName');
      
      final data = await _authService.authenticatedPost('/groups/$groupId', {
        'group_name': groupName,
      });

      if (data is Map<String, dynamic>) {
        AppLogger.log('✅ Group updated successfully');
        return data;
      } else {
        throw Exception('Unexpected response format: ${data.runtimeType}');
      }
    } catch (e) {
      AppLogger.log('❌ Error updating group: $e');
      rethrow;
    }
  }

  // Delete group
  Future<void> deleteGroup(String groupId) async {
    try {
      AppLogger.log('🗑️ Deleting group: $groupId');
      
      // Check token expiration first
      if (_authService.isTokenExpired()) {
        if (_authService.token != null) {
          // Try to refresh
          final refreshed = await _authService.refreshAccessToken();
          if (!refreshed) {
            throw Exception('Token expired and refresh failed');
          }
        } else {
        throw Exception('Not authenticated');
      }
      }
      
      // Use authenticated method with auto-refresh support
      final headers = _authService.getAuthHeaders();

      // Make HTTP DELETE request
      var response = await http.delete(
        Uri.parse('${AuthService.apiBaseUrl}/groups/$groupId'),
        headers: headers,
      );

      // Handle 401/403 with auto-refresh
      if (response.statusCode == 401 || response.statusCode == 403) {
        AppLogger.log('🔄 Authentication error, attempting token refresh...');
        // Note: We can't use authenticatedDelete here, so we handle refresh manually
        // This is a limitation - ideally we'd have authenticatedDelete method
        // For now, just throw the error and let the caller handle it
        final errorData = jsonDecode(response.body);
        throw Exception('Authentication failed: ${errorData['error'] ?? 'Unauthorized'}');
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        AppLogger.log('✅ Group deleted successfully');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to delete group: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      AppLogger.log('❌ Error deleting group: $e');
      rethrow;
    }
  }
}
