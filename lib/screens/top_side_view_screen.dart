import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/photo_capture_section.dart';
import '../models/pet_record_model.dart';
import '../services/camera_service.dart';

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

  // Loading state variables
  bool _isTopPhotoLoading = false;
  bool _isLeftPhotoLoading = false;
  bool _isRightPhotoLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize view image paths from the pet record
    setState(() {
      _topViewImagePath = widget.petRecord.topViewImagePath;
      _leftViewImagePath = widget.petRecord.leftViewImagePath;
      _rightViewImagePath = widget.petRecord.rightViewImagePath;
    });
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/records');
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

  void _goToNextStep() {
    // Validate that all views are captured
    if (_topViewImagePath != null &&
        _leftViewImagePath != null &&
        _rightViewImagePath != null) {
      // Update the pet record with new image paths
      widget.petRecord.topViewImagePath = _topViewImagePath;
      widget.petRecord.leftViewImagePath = _leftViewImagePath;
      widget.petRecord.rightViewImagePath = _rightViewImagePath;

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
                    ),

                    const SizedBox(height: 24),

                    PhotoCaptureSection(
                      label: 'Left View Photo',
                      imagePath: _leftViewImagePath,
                      onTakePhoto: _takeLeftViewPhoto,
                      isLoading: _isLeftPhotoLoading,
                    ),

                    const SizedBox(height: 24),

                    PhotoCaptureSection(
                      label: 'Right View Photo',
                      imagePath: _rightViewImagePath,
                      onTakePhoto: _takeRightViewPhoto,
                      isLoading: _isRightPhotoLoading,
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