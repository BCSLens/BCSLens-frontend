import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:async';

class AIService {
  static String get baseUrl {
    final url = dotenv.env['AI_SERVICE_BASE_URL'];
    if (url == null || url.isEmpty) {
      throw Exception('AI_SERVICE_BASE_URL is not set in .env file');
    }
    return url;
  }
  
  /// Predict pet type (dog/cat)
  static Future<Map<String, dynamic>?> predictPetType(String imagePath) async {
    try {
      var uri = Uri.parse('$baseUrl/predict-animal');
      var request = http.MultipartRequest('POST', uri);

      File imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        throw Exception('File not found: $imagePath');
      }

      String? mimeType = lookupMimeType(imagePath);

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imagePath,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      );

      var streamedResponse = await request.send().timeout(
        Duration(seconds: 120),  // เพิ่มเป็น 120 วินาที (2 นาที) สำหรับ AI inference
        onTimeout: () {
          throw TimeoutException('Request timed out after 120 seconds');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Map<String, dynamic> predictionData = jsonDecode(response.body);
        
        // Handle Flask response format: {"prediction": "cat"} 
        if (predictionData['prediction'] != null) {
          String animalName = predictionData['prediction'].toString().toLowerCase();
          
          // Map animal name to class_id and class_name
          int classId;
          String className;
          
          if (animalName.contains('dog') || animalName.contains('canine')) {
            classId = 0;
            className = 'dog';
          } else if (animalName.contains('cat') || animalName.contains('feline')) {
            classId = 1;
            className = 'cat';
          } else {
            classId = -1;
            className = animalName;
          }
          
          return {
            'class_id': classId,
            'class_name': className,
            'confidence': 0.95,
          };
        }
        
        // Fallback: handle old format if exists
        if (predictionData['predictions'] != null && 
            predictionData['predictions'].isNotEmpty) {
          return predictionData['predictions'][0];
        }
      } else {
        throw Exception('Prediction failed: ${response.statusCode}');
      }
      
      return null;
    } catch (e) {
      print('Prediction error: $e');
      rethrow;
    }
  }

  /// Classify image view (top/left/right/back)
  static Future<Map<String, dynamic>?> classifyImageView(String imagePath) async {
    try {
      var uri = Uri.parse('$baseUrl/predict-view');
      var request = http.MultipartRequest('POST', uri);

      File imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        throw Exception('File not found: $imagePath');
      }

      String? mimeType = lookupMimeType(imagePath);

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imagePath,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      );

      var streamedResponse = await request.send().timeout(
        Duration(seconds: 120),  // เพิ่มเป็น 120 วินาที สำหรับ AI inference
        onTimeout: () {
          throw TimeoutException('Request timed out after 120 seconds');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Map<String, dynamic> classificationData = jsonDecode(response.body);
        
        // Handle Flask response format: {"direction": "front", ...}
        if (classificationData.containsKey('direction')) {
          // Convert "direction" to "group" for Flutter compatibility
          return {
            'group': classificationData['direction'],
            'direction': classificationData['direction'],
            if (classificationData.containsKey('raw_response')) 
              'raw_response': classificationData['raw_response'],
            if (classificationData.containsKey('debug_cleaned')) 
              'debug_cleaned': classificationData['debug_cleaned'],
          };
        }
        
        // Fallback: handle old format if exists
        if (classificationData.containsKey('group')) {
          return classificationData;
        }
      } else {
        throw Exception('Classification failed: ${response.statusCode}');
      }
      
      return null;
    } catch (e) {
      print('Classification error: $e');
      rethrow;
    }
  }

  /// Predict BCS (Body Condition Score) from 4 views: left, right, back, top
  static Future<Map<String, dynamic>?> predictBCS({
    required String? leftImagePath,
    required String? rightImagePath,
    required String? backImagePath,
    required String? topImagePath,
  }) async {
    try {
      // Validate that all required images are provided
      if (leftImagePath == null || rightImagePath == null || 
          backImagePath == null || topImagePath == null) {
        throw Exception('All 4 views (left, right, back, top) are required for BCS prediction');
      }

      // Validate files exist
      final leftFile = File(leftImagePath);
      final rightFile = File(rightImagePath);
      final backFile = File(backImagePath);
      final topFile = File(topImagePath);

      if (!leftFile.existsSync() || !rightFile.existsSync() || 
          !backFile.existsSync() || !topFile.existsSync()) {
        throw Exception('One or more image files not found');
      }

      var uri = Uri.parse('$baseUrl/predict-bcs');
      var request = http.MultipartRequest('POST', uri);

      // Add all 4 images to the request
      String? mimeType = lookupMimeType(leftImagePath);
      request.files.add(
        await http.MultipartFile.fromPath(
          'left',
          leftImagePath,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      );

      mimeType = lookupMimeType(rightImagePath);
      request.files.add(
        await http.MultipartFile.fromPath(
          'right',
          rightImagePath,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      );

      mimeType = lookupMimeType(backImagePath);
      request.files.add(
        await http.MultipartFile.fromPath(
          'back',
          backImagePath,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      );

      mimeType = lookupMimeType(topImagePath);
      request.files.add(
        await http.MultipartFile.fromPath(
          'top',
          topImagePath,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      );

      var streamedResponse = await request.send().timeout(
        Duration(seconds: 300),  // 3 minutes for BCS prediction (uses 4 images)
        onTimeout: () {
          throw TimeoutException('Request timed out after 180 seconds');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> bcsData = jsonDecode(response.body);
        print('📥 Raw BCS response: $bcsData');

        // Model sends only: {"bcs_score": <int>, "bcs_category": <str>}
        if (!bcsData.containsKey('bcs_score') || !bcsData.containsKey('bcs_category')) {
          throw Exception('Invalid response format from backend');
        }

        final int bcsScore = (bcsData['bcs_score'] as num).toInt();
        final String category = (bcsData['bcs_category'] ?? 'IDEAL').toString();

        return {
          'bcs_score': bcsScore,
          'bcs_category': category,
        };
      } else {
        throw Exception('BCS prediction failed: ${response.statusCode}');
      }
    } catch (e) {
      print('BCS prediction error: $e');
      rethrow;
    }
  }
}