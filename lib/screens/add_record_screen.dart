import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/photo_capture_section.dart'; // Import the new widget
import '../models/pet_record_model.dart';
import '../services/camera_service.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({Key? key}) : super(key: key);
  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  int _selectedIndex = 1;
  String? _frontViewImagePath;
  bool _isPhotoLoading = false;

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/records');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/special-care');
    }
  }

  void _takePhoto() async {
    setState(() {
      _isPhotoLoading = true;
    });

    try {
      final photoPath = await CameraService.takePhoto();
      if (photoPath != null) {
        setState(() {
          _frontViewImagePath = photoPath;
        });
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

void _goToNextStep() {
  if (_frontViewImagePath != null) {
    // Update the shared PetRecord instance with front view
    final petRecord = PetRecord(frontViewImagePath: _frontViewImagePath);
    
    // Navigate to the next screen - no need to handle returns now
    Navigator.pushNamed(
      context, 
      '/top-side-view', 
      arguments: petRecord
    );
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
            // Step 1 of 4 at 133px from top
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

                  // Using the PhotoCaptureSection widget instead of the original code
                  PhotoCaptureSection(
                    label: 'Front View Photo',
                    imagePath: _frontViewImagePath,
                    onTakePhoto: _takePhoto,
                    isLoading: _isPhotoLoading,
                  ),

                  const SizedBox(height: 39),

                  // Next Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
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
