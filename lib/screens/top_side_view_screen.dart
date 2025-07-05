import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/photo_capture_section.dart';
import '../models/pet_record_model.dart';
import '../services/camera_service.dart';
import '../services/pet_detection_service.dart';

class TopSideViewScreen extends StatefulWidget {
  final PetRecord petRecord;

  const TopSideViewScreen({Key? key, required this.petRecord})
    : super(key: key);

  @override
  State<TopSideViewScreen> createState() => _TopSideViewScreenState();
}

class _TopSideViewScreenState extends State<TopSideViewScreen> {
  int _selectedIndex = 1;
  String? _topViewImagePath;
  String? _leftViewImagePath;
  String? _rightViewImagePath;
  String? _backViewImagePath; // Added back view

  // Loading state variables
  bool _isTopPhotoLoading = false;
  bool _isLeftPhotoLoading = false;
  bool _isRightPhotoLoading = false;
  bool _isBackPhotoLoading = false; // Added back view loading state

  // Classification state variables
  bool _isClassifying = false;
  Map<String, String> _viewClassifications = {};
  bool _classificationError = false;

  // Available test images for each view
  Map<String, String> _testImages = {
    'top': 'assets/images/dog_top.webp',
    'left': 'assets/images/dog_left.jpg', // Using available images
    'right': 'assets/images/dog_right.jpg',
    'back': 'assets/images/dog_back.webp',
  };

  @override
  void initState() {
    super.initState();

    // Initialize view image paths from the pet record
    setState(() {
      _topViewImagePath = widget.petRecord.topViewImagePath;
      _leftViewImagePath = widget.petRecord.leftViewImagePath;
      _rightViewImagePath = widget.petRecord.rightViewImagePath;
      _backViewImagePath = widget.petRecord.backViewImagePath;
    });
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/records', (route) => false);
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/special-care');
    }
  }

  void _takeTopViewPhoto() async {
    setState(() {
      _isTopPhotoLoading = true;
    });

    try {
      final photoPath = await CameraService.takePhoto();
      if (photoPath != null) {
        setState(() {
          _topViewImagePath = photoPath;
        });
        // Update the singleton instance
        widget.petRecord.topViewImagePath = photoPath;

        // After taking the photo, classify it
        await _classifyImageView(photoPath, 'top');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
    } finally {
      setState(() {
        _isTopPhotoLoading = false;
      });
    }
  }

  void _takeLeftViewPhoto() async {
    setState(() {
      _isLeftPhotoLoading = true;
    });

    try {
      final photoPath = await CameraService.takePhoto();
      if (photoPath != null) {
        setState(() {
          _leftViewImagePath = photoPath;
        });
        // Update the singleton instance
        widget.petRecord.leftViewImagePath = photoPath;

        // After taking the photo, classify it
        await _classifyImageView(photoPath, 'left');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
    } finally {
      setState(() {
        _isLeftPhotoLoading = false;
      });
    }
  }

  void _takeRightViewPhoto() async {
    setState(() {
      _isRightPhotoLoading = true;
    });

    try {
      final photoPath = await CameraService.takePhoto();
      if (photoPath != null) {
        setState(() {
          _rightViewImagePath = photoPath;
        });
        // Update the singleton instance
        widget.petRecord.rightViewImagePath = photoPath;

        // After taking the photo, classify it
        await _classifyImageView(photoPath, 'right');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
    } finally {
      setState(() {
        _isRightPhotoLoading = false;
      });
    }
  }

  // New method for back view photo
  void _takeBackViewPhoto() async {
    setState(() {
      _isBackPhotoLoading = true;
    });

    try {
      final photoPath = await CameraService.takePhoto();
      if (photoPath != null) {
        setState(() {
          _backViewImagePath = photoPath;
        });
        // Update the singleton instance
        widget.petRecord.backViewImagePath = photoPath;

        // After taking the photo, classify it
        await _classifyImageView(photoPath, 'back');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
    } finally {
      setState(() {
        _isBackPhotoLoading = false;
      });
    }
  }

  // ใช้ AIService แทน hardcode API calls
  Future<void> _classifyImageView(String imagePath, String expectedView) async {
    // Set loading state for the specific view
    setState(() {
      _isClassifying = true;
      _classificationError = false;
    });

    try {
      print("Starting view classification for $expectedView view...");
      
      // ใช้ AIService แทนการ hardcode API
      var classificationResult = await AIService.classifyImageView(imagePath);
      print("Classification result: $classificationResult");

      if (classificationResult != null && classificationResult.containsKey('group')) {
        String detectedView = classificationResult['group'];
        print("Detected view: $detectedView");

        setState(() {
          _viewClassifications[imagePath] = detectedView;
        });

        // Always show confirmation dialog for any view
        _showViewConfirmationDialog(imagePath, expectedView, detectedView);
      } else {
        print("No view classification found in response");
        setState(() {
          _classificationError = true;
        });
        // Show a generic confirmation dialog even if classification failed
        _showViewConfirmationDialog(imagePath, expectedView, "unknown");
      }
    } catch (e) {
      print('Classification error: $e');
      setState(() {
        _classificationError = true;
      });
      // Show a generic confirmation dialog even if there was an error
      _showViewConfirmationDialog(imagePath, expectedView, "unknown");
    } finally {
      setState(() {
        _isClassifying = false;
      });
    }
  }

  // New method for the view confirmation dialog
  void _showViewConfirmationDialog(
    String imagePath,
    String expectedView,
    String detectedView,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Text(
                'Image Confirmation',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF7B8EB5),
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'We need to ensure the correct angle for\naccurate analysis.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Is this a ${detectedView.toLowerCase()} view of the animal?',
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
                        // User says this is not the detected view
                        Navigator.pop(context);
                        // Let them retry taking the photo
                        // (Don't need to do anything else here)
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
                        // User confirms this is the detected view from API
                        Navigator.pop(context);
                        setState(() {
                          // Store the API's detected view classification
                          _viewClassifications[imagePath] = detectedView;
                        });
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
      },
    );
  }

  void _goToNextStep() {
    // Validate that all views are captured
    if (_topViewImagePath != null &&
        _leftViewImagePath != null &&
        _rightViewImagePath != null &&
        _backViewImagePath != null) {
      // Update the pet record with new image paths
      widget.petRecord.topViewImagePath = _topViewImagePath;
      widget.petRecord.leftViewImagePath = _leftViewImagePath;
      widget.petRecord.rightViewImagePath = _rightViewImagePath;
      widget.petRecord.backViewImagePath = _backViewImagePath; // Save back view

      // Navigate to BCS evaluation screen
      Navigator.pushNamed(
        context,
        '/bcs-evaluation',
        arguments: widget.petRecord,
      );
    } else {
      // Show error that all views must be captured
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture all view photos')),
      );
    }
  }

  void _goBack() {
    Navigator.pop(context); // No need to pass data back
  }

  // Methods to use test images for each specific view
  void _useTestTopImage() async {
    setState(() {
      _isTopPhotoLoading = true;
    });

    try {
      // Get temporary directory to save asset file
      final directory = await getTemporaryDirectory();
      final tempPath = directory.path;

      // Use the test image from the map
      final assetName = _testImages['top']!;
      final tempFile = File('$tempPath/temp_top_image.jpg');

      // Load asset and save to temp file
      final byteData = await rootBundle.load(assetName);
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      setState(() {
        _topViewImagePath = tempFile.path;
        widget.petRecord.topViewImagePath = tempFile.path;
      });

      // Classify just this image
      await _classifyImageView(tempFile.path, 'top');
    } catch (e) {
      print('Error using test image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error using test image: $e')));
    } finally {
      setState(() {
        _isTopPhotoLoading = false;
      });
    }
  }

  void _useTestLeftImage() async {
    setState(() {
      _isLeftPhotoLoading = true;
    });

    try {
      // Get temporary directory to save asset file
      final directory = await getTemporaryDirectory();
      final tempPath = directory.path;

      // Use the test image from the map
      final assetName = _testImages['left']!;
      final tempFile = File('$tempPath/temp_left_image.jpg');

      // Load asset and save to temp file
      final byteData = await rootBundle.load(assetName);
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      setState(() {
        _leftViewImagePath = tempFile.path;
        widget.petRecord.leftViewImagePath = tempFile.path;
      });

      // Classify just this image
      await _classifyImageView(tempFile.path, 'left');
    } catch (e) {
      print('Error using test image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error using test image: $e')));
    } finally {
      setState(() {
        _isLeftPhotoLoading = false;
      });
    }
  }

  void _useTestRightImage() async {
    setState(() {
      _isRightPhotoLoading = true;
    });

    try {
      // Get temporary directory to save asset file
      final directory = await getTemporaryDirectory();
      final tempPath = directory.path;

      // Use the test image from the map
      final assetName = _testImages['right']!;
      final tempFile = File('$tempPath/temp_right_image.jpg');

      // Load asset and save to temp file
      final byteData = await rootBundle.load(assetName);
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      setState(() {
        _rightViewImagePath = tempFile.path;
        widget.petRecord.rightViewImagePath = tempFile.path;
      });

      // Classify just this image
      await _classifyImageView(tempFile.path, 'right');
    } catch (e) {
      print('Error using test image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error using test image: $e')));
    } finally {
      setState(() {
        _isRightPhotoLoading = false;
      });
    }
  }

  void _useTestBackImage() async {
    setState(() {
      _isBackPhotoLoading = true;
    });

    try {
      // Get temporary directory to save asset file
      final directory = await getTemporaryDirectory();
      final tempPath = directory.path;

      // Use the test image from the map
      final assetName = _testImages['back']!;
      final tempFile = File('$tempPath/temp_back_image.jpg');

      // Load asset and save to temp file
      final byteData = await rootBundle.load(assetName);
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      setState(() {
        _backViewImagePath = tempFile.path;
        widget.petRecord.backViewImagePath = tempFile.path;
      });

      // Classify just this image
      await _classifyImageView(tempFile.path, 'back');
    } catch (e) {
      print('Error using test image: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error using test image: $e')));
    } finally {
      setState(() {
        _isBackPhotoLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Add Records at 66px from top
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

              // Line at 106px from top
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
                      'Step 2 of 4',
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
                      'Capture Top and Side Views',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF333333),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Using PhotoCaptureSection for each view with loading states
                    PhotoCaptureSection(
                      label: 'Top View Photo',
                      imagePath: _topViewImagePath,
                      onTakePhoto: _takeTopViewPhoto,
                      isLoading: _isTopPhotoLoading,
                      isPredicting: _topViewImagePath != null && _isClassifying,
                    ),

                    // Test image button for top view
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _useTestTopImage,
                        child: Text(
                          'Use Test Image',
                          style: TextStyle(
                            color: Colors.amber[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    PhotoCaptureSection(
                      label: 'Left View Photo',
                      imagePath: _leftViewImagePath,
                      onTakePhoto: _takeLeftViewPhoto,
                      isLoading: _isLeftPhotoLoading,
                      isPredicting:
                          _leftViewImagePath != null && _isClassifying,
                    ),

                    // Test image button for left view
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _useTestLeftImage,
                        child: Text(
                          'Use Test Image',
                          style: TextStyle(
                            color: Colors.amber[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    PhotoCaptureSection(
                      label: 'Right View Photo',
                      imagePath: _rightViewImagePath,
                      onTakePhoto: _takeRightViewPhoto,
                      isLoading: _isRightPhotoLoading,
                      isPredicting:
                          _rightViewImagePath != null && _isClassifying,
                    ),

                    // Test image button for right view
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _useTestRightImage,
                        child: Text(
                          'Use Test Image',
                          style: TextStyle(
                            color: Colors.amber[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Added Back View Photo section
                    PhotoCaptureSection(
                      label: 'Back View Photo',
                      imagePath: _backViewImagePath,
                      onTakePhoto: _takeBackViewPhoto,
                      isLoading: _isBackPhotoLoading,
                      isPredicting:
                          _backViewImagePath != null && _isClassifying,
                    ),

                    // Test image button for back view
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _useTestBackImage,
                        child: Text(
                          'Use Test Image',
                          style: TextStyle(
                            color: Colors.amber[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Navigation Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _goBack,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF6B86C9)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              'Back',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                color: const Color(0xFF6B86C9),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _goToNextStep,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B86C9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              'Next',
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
                  ],
                ),
              ),
              // Add some padding at the bottom for better scrolling
              const SizedBox(height: 40),
            ],
          ),
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