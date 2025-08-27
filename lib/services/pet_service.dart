// lib/services/pet_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/auth_service.dart';
import '../models/pet_record_model.dart';

class PetService {
  final AuthService _authService = AuthService();

  // Use environment variable or fallback to production URL
  static String get baseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    // Fallback to production URL
    return 'http://35.240.210.10:3000/api';
  }

  static String get uploadBaseUrl {
    final envUrl = dotenv.env['UPLOAD_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    // Fallback to production URL
    return 'http://34.142.243.161';
  }

  // Create a new pet - FIXED VERSION
  Future<Map<String, dynamic>> createPet(PetRecord pet) async {
    try {
      print('🐕 Creating pet with data...');

      // Validate required fields
      if (pet.name == null || pet.name!.isEmpty) {
        throw Exception('Pet name is required');
      }

      if (pet.groupId == null || pet.groupId!.isEmpty) {
        throw Exception('Group ID is required');
      }

      // Parse age to years and months
      int ageYears = _parseAgeYears(pet.age ?? '0');
      int ageMonths = _parseAgeMonths(pet.age ?? '0');
      int totalMonths = (ageYears * 12) + ageMonths;

      // Convert weight string to number (remove 'kg' and parse)
      double weightInKg = _parseWeight(pet.weight ?? '0');

      // Convert boolean to boolean (not string) ✅ แก้ไขแล้ว
      bool spayNeuterStatus = pet.isSterilized ?? false;

      // Map category/predictedAnimal to species
      String species = pet.predictedAnimal ?? 'dog';

      final requestBody = {
        'name': pet.name!,
        'breed': pet.breed ?? 'Mixed',
        'age': totalMonths, // Total months for backward compatibility
        'age_years': ageYears, // ✅ เพิ่มใหม่
        'age_months': ageMonths, // ✅ เพิ่มใหม่
        'gender': pet.gender ?? 'Male',
        'spay_neuter_status': spayNeuterStatus, // ✅ เป็น boolean แล้ว
        'group_id': pet.groupId!,
        'species': species,
      };

      print('📤 Request body: $requestBody');
      print('🔗 URL: $baseUrl/pets');

      // Create pet in database
      final responseData = await _authService.authenticatedPost(
        '/pets',
        requestBody,
      );

      print('📥 Response data: $responseData');

      if (responseData != null) {
        if (responseData is Map<String, dynamic>) {
          print('✅ Pet created successfully');

          // Extract pet ID for creating initial record
          String? petId;
          if (responseData.containsKey('pet') && responseData['pet'] is Map) {
            petId = responseData['pet']['_id'];
          } else if (responseData.containsKey('_id')) {
            petId = responseData['_id'];
          }

          if (petId != null) {
            print('✅ Pet created with ID: $petId');

            // ✅ สร้าง record แรกพร้อมรูป (แทนที่การอัพโหลดรูปใน Pet)
            await _createInitialRecord(petId, pet);
          }

          return responseData;
        } else {
          throw Exception('Unexpected response format');
        }
      } else {
        throw Exception('No response data received');
      }
    } catch (e) {
      print('❌ Error creating pet: $e');
      if (e.toString().contains('Authentication failed')) {
        throw Exception('Please log in again to create a pet');
      }
      rethrow;
    }
  }

  // ✅ ฟังก์ชันใหม่: สร้าง record แรกพร้อมรูป
  Future<void> _createInitialRecord(String petId, PetRecord pet) async {
    try {
      print('📸 Creating initial record with images for pet: $petId');

      // ✅ เพิ่ม debug ตรวจสอบ paths
      print('🔍 Debug image paths:');
      print('  Front: ${pet.frontViewImagePath}');
      print('  Back: ${pet.backViewImagePath}');
      print('  Left: ${pet.leftViewImagePath}');
      print('  Right: ${pet.rightViewImagePath}');
      print('  Top: ${pet.topViewImagePath}');

      // ตรวจสอบไฟล์มีอยู่จริงไหม
      if (pet.frontViewImagePath != null) {
        print(
          '  Front file exists: ${File(pet.frontViewImagePath!).existsSync()}',
        );
      }

      // อัพโหลดรูปทั้งหมด
      final imageUrls = await _uploadPetImages(pet);

      print('🔍 Upload results: $imageUrls');
      print('🔍 Number of uploaded images: ${imageUrls.length}');

      // สร้าง record data
      final recordData = {
        'date': DateTime.now().toIso8601String(),
        'score': pet.bcs ?? 5,
        'weight': _parseWeight(pet.weight ?? '0'),
        ...imageUrls, // รูปทั้งหมดไปใน record
        'notes': pet.additionalNotes ?? '',
      };

      print('🔍 Record data to send: $recordData');

      // สร้าง record แรกพร้อมรูป
      final recordResponse = await _authService.authenticatedPost(
        '/pets/$petId/records',
        recordData,
      );

      print('✅ Initial record created successfully');
      print('📥 Record response: $recordResponse');

      if (imageUrls.isNotEmpty) {
        print('✅ Images included: ${imageUrls.keys.join(', ')}');
      } else {
        print('⚠️ No images were uploaded');
      }
    } catch (e) {
      print('❌ Error creating initial record: $e');
      print('❌ Error details: ${e.toString()}');
      // ไม่ throw error - pet ถูกสร้างแล้ว
    }
  }

  // ✅ Helper functions สำหรับ parse age - FIXED VERSION
  int _parseAgeYears(String ageString) {
    try {
      print('🔍 Parsing age years from: "$ageString"');

      if (ageString.contains('years') && ageString.contains('months')) {
        // Format: "2 years 6 months"
        final yearsPart = ageString.split(' years')[0];
        final result = int.tryParse(yearsPart) ?? 0;
        print('✅ Parsed years: $result');
        return result;
      } else if (ageString.contains('year')) {
        // Format: "2 years" or "1 year"
        final yearsPart = ageString.split(' ')[0];
        final result = int.tryParse(yearsPart) ?? 0;
        print('✅ Parsed years: $result');
        return result;
      }
      print('⚠️ No years found in age string');
      return 0;
    } catch (e) {
      print('❌ Error parsing years: $e');
      return 0;
    }
  }

  int _parseAgeMonths(String ageString) {
    try {
      print('🔍 Parsing age months from: "$ageString"');

      if (ageString.contains('months')) {
        if (ageString.contains('years') || ageString.contains('year')) {
          // Format: "2 years 6 months" or "1 year 0 months"
          final parts = ageString.split(RegExp(r'years? '));
          if (parts.length > 1) {
            final monthsPart = parts[1].split(' months')[0];
            final result = int.tryParse(monthsPart) ?? 0;
            print('✅ Parsed months: $result');
            return result;
          }
        } else {
          // Format: "6 months"
          final monthsPart = ageString.split(' ')[0];
          final result = int.tryParse(monthsPart) ?? 0;
          print('✅ Parsed months: $result');
          return result;
        }
      }
      print('⚠️ No months found in age string');
      return 0;
    } catch (e) {
      print('❌ Error parsing months: $e');
      return 0;
    }
  }

  // Helper method to parse weight string to double
  double _parseWeight(String weightString) {
    try {
      // Remove 'kg' and other text, keep only numbers and decimal point
      String numericPart = weightString.replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(numericPart) ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Helper method to map category to species
  String _mapToSpecies(String? category) {
    if (category == null) return 'dog';

    switch (category.toLowerCase()) {
      case 'cats':
      case 'cat':
        return 'cat';
      case 'dogs':
      case 'dog':
        return 'dog';
      default:
        return 'dog';
    }
  }

  // Upload images for a pet
  Future<Map<String, String>> _uploadPetImages(PetRecord pet) async {
    Map<String, String> imageUrls = {};

    try {
      print('🔍 Starting image upload process...');

      if (pet.frontViewImagePath != null) {
        print('📤 Uploading front image: ${pet.frontViewImagePath}');
        final url = await _uploadImage(pet.frontViewImagePath!);
        if (url.isNotEmpty) {
          imageUrls['front_image_url'] = url;
          print('✅ Front image uploaded: $url');
        } else {
          print('❌ Front image upload failed');
        }
      } else {
        print('⚠️ No front image path provided');
      }

      if (pet.backViewImagePath != null) {
        print('📤 Uploading back image: ${pet.backViewImagePath}');
        final url = await _uploadImage(pet.backViewImagePath!);
        if (url.isNotEmpty) {
          imageUrls['back_image_url'] = url;
          print('✅ Back image uploaded: $url');
        }
      }

      if (pet.leftViewImagePath != null) {
        print('📤 Uploading left image: ${pet.leftViewImagePath}');
        final url = await _uploadImage(pet.leftViewImagePath!);
        if (url.isNotEmpty) {
          imageUrls['left_image_url'] = url;
          print('✅ Left image uploaded: $url');
        }
      }

      if (pet.rightViewImagePath != null) {
        print('📤 Uploading right image: ${pet.rightViewImagePath}');
        final url = await _uploadImage(pet.rightViewImagePath!);
        if (url.isNotEmpty) {
          imageUrls['right_image_url'] = url;
          print('✅ Right image uploaded: $url');
        }
      }

      if (pet.topViewImagePath != null) {
        print('📤 Uploading top image: ${pet.topViewImagePath}');
        final url = await _uploadImage(pet.topViewImagePath!);
        if (url.isNotEmpty) {
          imageUrls['top_image_url'] = url;
          print('✅ Top image uploaded: $url');
        }
      }

      print('🔍 Final image URLs: $imageUrls');
      return imageUrls;
    } catch (e) {
      print('❌ Error uploading images: $e');
      return {};
    }
  }

  // Upload a single image
  Future<String> _uploadImage(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (!file.existsSync()) {
        print('❌ File not found: $imagePath');
        return '';
      }

      final token = _authService.token;
      if (token == null) {
        print('❌ Not authenticated for image upload');
        return '';
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$uploadBaseUrl/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      String? mimeType = lookupMimeType(imagePath);

      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // Make sure this matches backend expectation
          imagePath,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      );

      print('📤 Uploading image: $imagePath');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Upload response: ${response.statusCode}');
      print('📥 Upload body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // ✅ แก้ไขการดึง URL ตาม response format ของ backend
        String url = '';

        if (data['url'] != null) {
          url = data['url'];
        } else if (data['file_url'] != null) {
          url = data['file_url'];
        } else if (data['filename'] != null) {
          // ✅ สร้าง URL จาก filename
          url = '$uploadBaseUrl/uploads/${data['filename']}';
        } else {
          print('❌ No URL found in response: $data');
          return '';
        }

        print('✅ Image uploaded successfully: $url');
        return url;
      } else {
        print('❌ Upload failed: ${response.statusCode} - ${response.body}');
        return '';
      }
    } catch (e) {
      print('❌ Error uploading image: $e');
      return '';
    }
  }

  // Get all pets - CORRECTED VERSION
  Future<List<Map<String, dynamic>>> getPets() async {
    try {
      // AuthService returns parsed JSON directly
      final data = await _authService.authenticatedGet('/groups');

      print('📥 Groups data type: ${data.runtimeType}');
      print('📥 Groups data: $data');

      List<Map<String, dynamic>> allPets = [];

      if (data is Map<String, dynamic> && data.containsKey('groups')) {
        final List<dynamic> groups = data['groups'] as List;

        for (var group in groups) {
          if (group is Map<String, dynamic> && group.containsKey('pets')) {
            final List<dynamic> pets = group['pets'] as List;
            for (var pet in pets) {
              if (pet is Map<String, dynamic>) {
                allPets.add(pet);
              }
            }
          }
        }
      } else if (data is List) {
        // If response is directly a list of groups
        for (var group in data) {
          if (group is Map<String, dynamic> && group.containsKey('pets')) {
            final List<dynamic> pets = group['pets'] as List;
            for (var pet in pets) {
              if (pet is Map<String, dynamic>) {
                allPets.add(pet);
              }
            }
          }
        }
      }

      print('✅ Found ${allPets.length} pets');
      return allPets;
    } catch (e) {
      print('❌ Error getting pets: $e');
      rethrow;
    }
  }

  // Add BCS record - CORRECTED VERSION
  Future<Map<String, dynamic>> addBcsRecord(String petId, PetRecord pet) async {
    try {
      // Upload images first
      final imageUrls = await _uploadPetImages(pet);

      // AuthService returns parsed JSON directly
      final responseData = await _authService
          .authenticatedPost('/pets/$petId/records', {
            'score': pet.bcs ?? 5,
            'date': DateTime.now().toIso8601String(),
            'weight': _parseWeight(pet.weight ?? '0'),
            ...imageUrls,
            'notes': pet.additionalNotes ?? '',
          });

      if (responseData != null && responseData is Map<String, dynamic>) {
        return responseData;
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      print('❌ Error adding BCS record: $e');
      rethrow;
    }
  }
  // เพิ่ม method นี้ใน PetService class

  // Method สำหรับเพิ่ม record ให้สัตว์ที่มีอยู่แล้ว
  Future<Map<String, dynamic>> addRecordToExistingPet(
    String petId,
    PetRecord petRecord,
  ) async {
    try {
      print('Adding record to existing pet: $petId');

      // อัพโหลดรูปทั้งหมด
      final imageUrls = await _uploadPetImages(petRecord);

      // สร้าง record data
      final recordData = {
        'date': DateTime.now().toIso8601String(),
        'score': petRecord.bcs ?? 5,
        'weight': _parseWeight(petRecord.weight ?? '0'),
        ...imageUrls, // รูปทั้งหมด
        'notes': petRecord.additionalNotes ?? '',
      };

      print('Sending record data: $recordData');

      // ส่งข้อมูลไปยัง API
      final responseData = await _authService.authenticatedPost(
        '/pets/$petId/records',
        recordData,
      );

      if (responseData != null && responseData is Map<String, dynamic>) {
        print('Record added successfully to pet: $petId');
        return responseData;
      } else {
        throw Exception('Unexpected response format');
      }
    } catch (e) {
      print('Error adding record to existing pet: $e');
      rethrow;
    }
  }
}
