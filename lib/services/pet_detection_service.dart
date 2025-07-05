import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'dart:async';

class AIService {
  static String get baseUrl => dotenv.env['AI_SERVICE_BASE_URL'] ?? 'http://10.0.2.2:5000';
  
  /// Predict pet type (dog/cat)
  static Future<Map<String, dynamic>?> predictPetType(String imagePath) async {
    try {
      var uri = Uri.parse('$baseUrl/yolo');
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
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Map<String, dynamic> predictionData = jsonDecode(response.body);
        
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
      var uri = Uri.parse('$baseUrl/classify-view');
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
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        Map<String, dynamic> classificationData = jsonDecode(response.body);
        
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
}