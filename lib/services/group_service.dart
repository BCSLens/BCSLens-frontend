// lib/services/group_service.dart
import 'dart:convert';
import '../services/auth_service.dart';

class GroupService {
  final AuthService _authService = AuthService();

  // Get all groups
  Future<List<Map<String, dynamic>>> getGroups() async {
    try {
      // The problem is here. Your updated AuthService.authenticatedGet
      // already decodes the JSON, but your GroupService is trying to decode it again
      final data = await _authService.authenticatedGet('/groups');

      print('Response data type: ${data.runtimeType}');

      if (data is Map && data.containsKey('groups')) {
        final groups = data['groups'] as List;
        return groups.map((group) => group as Map<String, dynamic>).toList();
      } else {
        print('Unrecognized response format: $data');
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      print('Error getting groups: $e');
      rethrow;
    }
  }

  // Create a new group
  Future<Map<String, dynamic>> createGroup(String groupName) async {
    try {
      // Again, your AuthService already decodes the JSON
      final data = await _authService.authenticatedPost('/groups', {
        'group_name': groupName,
      });

      if (data is Map && data.containsKey('group')) {
        return data['group'] as Map<String, dynamic>;
      } else if (data is Map) {
        // If it's a map without a 'group' key, assume it's the group data
        return data as Map<String, dynamic>;
      } else {
        print('Unrecognized create group response format: $data');
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      print('Error creating group: $e');
      rethrow;
    }
  }
}
