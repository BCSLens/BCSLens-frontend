import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/photo_capture_section.dart';
import '../models/pet_record_model.dart';
import '../services/camera_service.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:mime/mime.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'dart:async';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({Key? key}) : super(key: key);
  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  int _selectedIndex = 1;
  String? _frontViewImagePath;
  bool _isPhotoLoading = false;
  bool _isPredicting = false;
  String? _predictedAnimal;
  double? _predictionConfidence;
  bool _predictionHandled = false;
  bool _apiError = false;

  @override
  void initState() {
    super.initState();
    // Reset all previous data when starting a new record
    PetRecord().reset();
    _frontViewImagePath = null;
    _predictedAnimal = null;
    _predictionConfidence = null;
    _predictionHandled = false;
    _apiError = false;
  }

  void _useTestImage() async {
    setState(() {
      _isPhotoLoading = true;
      _apiError = false;
      _predictionHandled = false;
      _predictedAnimal = null;
    });

    try {
      // Get temporary directory to save asset file
      final directory = await getTemporaryDirectory();
      final tempPath = directory.path;

      // Define which test image to use
      final assetName = 'assets/images/dog.jpg'; // or 'assets/images/cat.jpg'
      final tempFile = File('$tempPath/temp_test_image.jpg');

      // Load asset and save to temp file
      final byteData = await rootBundle.load(assetName);
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      setState(() {
        _frontViewImagePath = tempFile.path;
      });

      // Use the API with the temp file path
      await _predictPetType(tempFile.path);
    } catch (e) {
      print('Error using test image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error using test image: $e')));
    } finally {
      setState(() {
        _isPhotoLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/records', (route) => false);
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/special-care');
    }
  }

  void _takePhoto() async {
    setState(() {
      _isPhotoLoading = true;
      _apiError = false;
      _predictionHandled = false;
      _predictedAnimal = null;
    });

    try {
      final photoPath = await CameraService.takePhoto();
      if (photoPath != null) {
        setState(() {
          _frontViewImagePath = photoPath;
        });

        // After taking the photo, predict the pet type
        _predictPetType(photoPath);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
    } finally {
      setState(() {
        _isPhotoLoading = false;
      });
    }
  }

  Future<void> _predictPetType(String imagePath) async {
    setState(() {
      _isPredicting = true;
      _predictionHandled = false;
      _apiError = false;
    });

    // await Future.delayed(Duration(seconds: 2)); // Simulate network delay
    // setState(() {
    //   _predictedAnimal = 'dog'; // Simulate dog detection
    //   _predictionConfidence = 0.95;
    //   _predictionHandled = true;
    //   _apiError = false;
    //   _isPredicting = false;
    // });
    // Future.microtask(() => _showPetConfirmationDialog(false));
    // return;

    try {
      print("Starting pet prediction...");
      var uri = Uri.parse('http://10.0.2.2:5000/yolo');
      print("Using API endpoint: $uri");

      var request = http.MultipartRequest('POST', uri);

      // Check if the file exists
      File imageFile = File(imagePath);
      if (!imageFile.existsSync()) {
        print("File not found: $imagePath");
        throw Exception('File not found: $imagePath');
      }
      print("File exists: $imagePath");

      // Detect MIME type
      String? mimeType = lookupMimeType(imagePath);
      print("Detected MIME type: $mimeType");

      // Attach file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imagePath,
          contentType: mimeType != null ? MediaType.parse(mimeType) : null,
        ),
      );
      print("File attached to request");

      // Send the request
      print("Sending request...");

      // Add a timeout to the request to handle server connectivity issues
      var streamedResponse = await request.send().timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print("Request timed out");
          throw TimeoutException('Request timed out after 10 seconds');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);
      print("Response status code: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        // Parse the JSON response
        Map<String, dynamic> predictionData = jsonDecode(response.body);
        print("Prediction data: $predictionData");

        // Check if there are predictions
        if (predictionData['predictions'] != null &&
            predictionData['predictions'].isNotEmpty) {
          // Get the first prediction
          var prediction = predictionData['predictions'][0];
          print("First prediction: $prediction");

          setState(() {
            _predictedAnimal = prediction['class_name'];
            _predictionConfidence = prediction['confidence'];
            _predictionHandled = true;
            _apiError = false;
          });
          print(
            "Set predicted animal to: $_predictedAnimal with confidence $_predictionConfidence",
          );

          Future.microtask(() => _showPetConfirmationDialog(false));
        } else {
          print("No predictions found in response");
          // API worked but couldn't detect animal
          setState(() {
            _apiError = true;
            _predictionHandled = false;
          });
          // Show dialog with "Can't detect animal" message
          Future.microtask(
            () => _showPetConfirmationDialog(
              true,
              errorMsg: "We couldn't detect the animal type",
            ),
          );
        }
      } else {
        print("API call failed with status: ${response.statusCode}");
        // API error
        setState(() {
          _apiError = true;
          _predictionHandled = false;
        });
        // Show dialog with connection error message
        Future.microtask(
          () => _showPetConfirmationDialog(true, errorMsg: "Connection error"),
        );
      }
    } catch (e) {
      print('Prediction error: $e');
      // API error
      setState(() {
        _apiError = true;
        _predictionHandled = false;
      });
      // Show dialog with error message
      Future.microtask(
        () =>
            _showPetConfirmationDialog(true, errorMsg: "Error analyzing image"),
      );
    } finally {
      setState(() {
        _isPredicting = false;
      });
    }
  }

  void _showPetConfirmationDialog(bool isError, {String? errorMsg}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        if (isError) {
          // Error case - show only Retry button
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Something Went Wrong',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF7B8EB5),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'We couldn\'t detect the animal in your photo.\nPlease try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // Close the dialog and allow user to take a new photo
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B86C9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        } else {
          // Success case - show confirmation UI
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Text(
                  'Pet Confirmation',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF7B8EB5),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'We need to confirm the animal\'s species\nfor accurate analysis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Is this a ${_predictedAnimal}?',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.black,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // User says this is not the predicted animal
                          Navigator.pop(context);
                          // Show animal selection dialog
                          _showAnimalSelectionDialog();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Color(0xFF6B86C9)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'No',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF6B86C9),
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // User confirms this is the predicted animal
                          // Just close the dialog and stay on the same page
                          Navigator.pop(context);

                          // Update the pet record but don't navigate
                          final petRecord = PetRecord();
                          petRecord.frontViewImagePath = _frontViewImagePath;
                          petRecord.category =
                              _predictedAnimal == 'dog' ? 'Dogs' : 'Cats';

                          // Print debug info
                          print('Confirmed prediction: $_predictedAnimal');
                          print('Confidence: $_predictionConfidence');
                          print('Category set to: ${petRecord.category}');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B86C9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Yes',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      },
    );
  }

  void _showAnimalSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Pet Type'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Dog'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _predictedAnimal = 'dog';
                    _predictionHandled = true;
                    _apiError = false;
                  });

                  // Update the pet record but don't navigate
                  final petRecord = PetRecord();
                  petRecord.frontViewImagePath = _frontViewImagePath;
                  petRecord.category = 'Dogs';

                  // Print debug info
                  print('Manual selection: dog');
                  print('Category set to: ${petRecord.category}');
                },
              ),
              ListTile(
                title: Text('Cat'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _predictedAnimal = 'cat';
                    _predictionHandled = true;
                    _apiError = false;
                  });

                  // Update the pet record but don't navigate
                  final petRecord = PetRecord();
                  petRecord.frontViewImagePath = _frontViewImagePath;
                  petRecord.category = 'Cats';

                  // Print debug info
                  print('Manual selection: cat');
                  print('Category set to: ${petRecord.category}');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _goToNextStep() {
    if (_frontViewImagePath != null) {
      // Update the shared PetRecord instance with front view
      final petRecord = PetRecord(frontViewImagePath: _frontViewImagePath);

      // If we have a predicted animal type, set the category
      if (_predictedAnimal != null) {
        petRecord.category = _predictedAnimal == 'dog' ? 'Dogs' : 'Cats';
      }

      // Navigate to the next screen
      Navigator.pushNamed(context, '/top-side-view', arguments: petRecord);
    } else {
      // Show error if no front view photo is taken
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a front view photo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Add Records at top
            const SizedBox(height: 46),
            Center(
              child: Text(
                'Add Records',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF7B8EB5),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Line separator
            const SizedBox(height: 40),
            Container(height: 1, color: Colors.grey[300]),

            // Main Content
            const SizedBox(height: 27),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Step Indicator
                  Text(
                    'Step 1 of 4',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF7B8EB5),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Step Description
                  Text(
                    'Capture Your Pet\'s Front View',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF333333),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  // Photo capture section
                  PhotoCaptureSection(
                    label: 'Front View Photo',
                    imagePath: _frontViewImagePath,
                    onTakePhoto: _takePhoto,
                    isLoading: _isPhotoLoading,
                    isPredicting: _isPredicting,
                  ),

                  const SizedBox(height: 39),

                  // Add this just before the Next button
                  ElevatedButton(
                    onPressed: _useTestImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.amber, // Different color to distinguish
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('Use Test Image'),
                  ),
                  const SizedBox(height: 16), // Add spacing
                  
                  // Next Button - Only enabled if we have a photo and no API error
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed:
                          (_frontViewImagePath != null &&
                                  _predictionHandled &&
                                  !_apiError)
                              ? () {
                                _goToNextStep();
                              }
                              : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B86C9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: Text(
                        'Next',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onAddRecordsTap: () {
          // Do nothing, already on add record screen
        },
      ),
    );
  }
}
