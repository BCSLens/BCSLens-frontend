import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

class PetDetectionService {
  static const String baseUrl = 'http://10.0.2.2:5000';
  
  /// Predicts the pet type from an image
  /// Returns a Map with 'class_name' and 'confidence'
  static Future<Map<String, dynamic>?> predictPetType(String imagePath) async {
    try {
      var uri = Uri.parse('$baseUrl/yolo');
      var request = http.MultipartRequest('POST', uri);

      File imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        throw Exception('File not found: $imagePath');
      }

      // Detect MIME type
      String? mimeType = lookupMimeType(imagePath);

      // Attach file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imagePath,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      );

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        // Parse the JSON response
        Map<String, dynamic> predictionData = jsonDecode(response.body);
        
        // Check if there are predictions
        if (predictionData['predictions'] != null && 
            predictionData['predictions'].isNotEmpty) {
          
          // Return the first prediction
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
}