// lib/services/pet_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../services/auth_service.dart';
import '../models/pet_record_model.dart';

class PetService {
  final AuthService _authService = AuthService();
  static const String baseUrl =
      'http://10.0.2.2:3000/api'; // For Android emulator

  // Get all pets
  Future<List<Map<String, dynamic>>> getPets() async {
    try {
      // Instead of trying to directly get pets, we'll get groups which contain pets
      final response = await _authService.authenticatedGet('/groups');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> groups = data['groups'] as List;

        // Extract all pets from all groups
        List<Map<String, dynamic>> allPets = [];

        for (var group in groups) {
          final List<dynamic> pets = group['pets'] as List;
          for (var pet in pets) {
            allPets.add(pet as Map<String, dynamic>);
          }
        }

        return allPets;
      } else {
        throw Exception('Failed to load pets: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting pets: $e');
      rethrow;
    }
  }

  // Create a new pet
  Future<Map<String, dynamic>> createPet(PetRecord pet) async {
    try {
      // First upload images
      final imageUrls = await _uploadPetImages(pet);

      // Create pet with image URLs
      final response = await _authService.authenticatedPost('/pets', {
        'name': pet.name,
        'breed': pet.breed,
        'age': int.tryParse(pet.age ?? '0') ?? 0,
        'weight': double.tryParse(pet.weight ?? '0') ?? 0.0,
        'gender': pet.gender,
        'spay_neuter_status': pet.isSterilized ?? false,
        'species': pet.category == 'Cats' ? 'Cat' : 'Dog',
        'group_id':
            pet.groupId, // Make sure this is set from the selected group
        'front_image_url': imageUrls['front'],
        'back_image_url': imageUrls['back'],
        'left_image_url': imageUrls['left'],
        'right_image_url': imageUrls['right'],
        'top_image_url': imageUrls['top'],
        'image_url': imageUrls['front'], // Use front as default image
      });

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Failed to create pet: ${error['error']}');
      }
    } catch (e) {
      print('Error creating pet: $e');
      rethrow;
    }
  }

  // Upload images for a pet
  Future<Map<String, String>> _uploadPetImages(PetRecord pet) async {
    Map<String, String> imageUrls = {
      'front': '',
      'back': '',
      'left': '',
      'right': '',
      'top': '',
    };

    try {
      if (pet.frontViewImagePath != null) {
        imageUrls['front'] = await _uploadImage(pet.frontViewImagePath!);
      }

      if (pet.backViewImagePath != null) {
        imageUrls['back'] = await _uploadImage(pet.backViewImagePath!);
      }

      if (pet.leftViewImagePath != null) {
        imageUrls['left'] = await _uploadImage(pet.leftViewImagePath!);
      }

      if (pet.rightViewImagePath != null) {
        imageUrls['right'] = await _uploadImage(pet.rightViewImagePath!);
      }

      if (pet.topViewImagePath != null) {
        imageUrls['top'] = await _uploadImage(pet.topViewImagePath!);
      }

      return imageUrls;
    } catch (e) {
      print('Error uploading images: $e');
      rethrow;
    }
  }

  // In pet_service.dart, add this method
  Future<Map<String, dynamic>> addBcsRecord(String petId, PetRecord pet) async {
    try {
      final response = await _authService
          .authenticatedPost('/pets/$petId/records', {
            'score': pet.bcs ?? 5,
            'date': DateTime.now().toIso8601String(),
            'weight': double.tryParse(pet.weight ?? '0') ?? 0.0,
            'front_image_url':
                pet.frontViewImagePath != null
                    ? await _uploadImage(pet.frontViewImagePath!)
                    : '',
            'back_image_url':
                pet.backViewImagePath != null
                    ? await _uploadImage(pet.backViewImagePath!)
                    : '',
            'left_image_url':
                pet.leftViewImagePath != null
                    ? await _uploadImage(pet.leftViewImagePath!)
                    : '',
            'right_image_url':
                pet.rightViewImagePath != null
                    ? await _uploadImage(pet.rightViewImagePath!)
                    : '',
            'top_image_url':
                pet.topViewImagePath != null
                    ? await _uploadImage(pet.topViewImagePath!)
                    : '',
            'notes': pet.additionalNotes ?? '',
          });

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Failed to add BCS record: ${error['error']}');
      }
    } catch (e) {
      print('Error adding BCS record: $e');
      rethrow;
    }
  }

  // Upload a single image
  Future<String> _uploadImage(String imagePath) async {
    try {
      // Check if file exists
      final File file = File(imagePath);
      if (!file.existsSync()) {
        throw Exception('File not found: $imagePath');
      }

      // Get token from auth service
      final token = _authService.token;
      if (token == null) {
        throw Exception('Not authenticated');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      // Add auth header
      request.headers['Authorization'] = 'Bearer $token';

      // Detect mime type
      String? mimeType = lookupMimeType(imagePath);

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imagePath,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      );

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['url'] ?? '';
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      // Return empty string if upload fails
      return '';
    }
  }
}
