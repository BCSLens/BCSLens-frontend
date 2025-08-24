// lib/services/group_service.dart
import 'dart:convert';
import '../services/auth_service.dart';
import 'package:http/http.dart' as http;

class GroupService {
  final AuthService _authService = AuthService();

  // Get all groups - CORRECTED VERSION
  Future<List<Map<String, dynamic>>> getGroups() async {
    try {
      print('🔍 Getting groups...');
      
      // AuthService.authenticatedGet now returns parsed JSON directly, not Response
      final data = await _authService.authenticatedGet('/groups');

      print('📥 Groups response type: ${data.runtimeType}');
      print('📥 Groups response data: $data');

      // Handle different possible response formats
      if (data is Map<String, dynamic>) {
        if (data.containsKey('groups')) {
          // Response format: {"groups": [...]}
          final groups = data['groups'] as List;
          final result = groups.map((group) => group as Map<String, dynamic>).toList();
          print('✅ Found ${result.length} groups (nested format)');
          return result;
        } else if (data.containsKey('data')) {
          // Response format: {"data": [...]}
          final groups = data['data'] as List;
          final result = groups.map((group) => group as Map<String, dynamic>).toList();
          print('✅ Found ${result.length} groups (data format)');
          return result;
        } else {
          // Response is a single group object, wrap in array
          print('✅ Found 1 group (single object)');
          return [data];
        }
      } else if (data is List) {
        // Response is directly an array of groups
        final result = data.map((group) => group as Map<String, dynamic>).toList();
        print('✅ Found ${result.length} groups (direct array)');
        return result;
      } else {
        print('❌ Unrecognized response format: $data');
        throw Exception('Unexpected response format: ${data.runtimeType}');
      }
    } catch (e) {
      print('❌ Error getting groups: $e');
      
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
      print('🆕 Creating group: $groupName');
      
      // AuthService.authenticatedPost returns parsed JSON directly
      final data = await _authService.authenticatedPost('/groups', {
        'group_name': groupName,
      });

      print('📥 Create group response type: ${data.runtimeType}');
      print('📥 Create group response data: $data');

      if (data is Map<String, dynamic>) {
        if (data.containsKey('group')) {
          // Response format: {"group": {...}}
          final groupData = data['group'] as Map<String, dynamic>;
          print('✅ Group created successfully (nested format)');
          return groupData;
        } else {
          // Response is the group data directly
          print('✅ Group created successfully (direct format)');
          return data;
        }
      } else {
        print('❌ Unrecognized create group response format: $data');
        throw Exception('Unexpected response format: ${data.runtimeType}');
      }
    } catch (e) {
      print('❌ Error creating group: $e');
      
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
      print('📝 Updating group: $groupId with name: $groupName');
      
      final data = await _authService.authenticatedPost('/groups/$groupId', {
        'group_name': groupName,
      });

      if (data is Map<String, dynamic>) {
        print('✅ Group updated successfully');
        return data;
      } else {
        throw Exception('Unexpected response format: ${data.runtimeType}');
      }
    } catch (e) {
      print('❌ Error updating group: $e');
      rethrow;
    }
  }

  // Delete group
  Future<void> deleteGroup(String groupId) async {
    try {
      print('🗑️ Deleting group: $groupId');
      
      // For DELETE requests, you might need to use a different method
      // since authenticatedPost is for POST requests
      final token = _authService.token;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Make direct HTTP DELETE request
      final response = await http.delete(
        Uri.parse('${AuthService.apiBaseUrl}/groups/$groupId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Group deleted successfully');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Failed to delete group: ${errorData['error'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ Error deleting group: $e');
      rethrow;
    }
  }
}