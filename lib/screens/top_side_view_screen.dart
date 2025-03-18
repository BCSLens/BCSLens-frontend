import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../models/pet_record_model.dart'; // Adjust import path as needed

class TopSideViewScreen extends StatefulWidget {
  final PetRecord petRecord;

  const TopSideViewScreen({
    Key? key, 
    required this.petRecord
  }) : super(key: key);

  @override
  State<TopSideViewScreen> createState() => _TopSideViewScreenState();
}

class _TopSideViewScreenState extends State<TopSideViewScreen> {
  int _selectedIndex = 1;
  String? _topViewImagePath;
  String? _leftViewImagePath;
  String? _rightViewImagePath;

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/records');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/special-care');
    }
  }

  void _takeTopViewPhoto() {
    setState(() {
      _topViewImagePath = 'assets/images/dog_top_view.png'; // TODO: Implement actual photo capture
    });
  }

  void _takeLeftViewPhoto() {
    setState(() {
      _leftViewImagePath = 'assets/images/dog_left_view.png'; // TODO: Implement actual photo capture
    });
  }

  void _takeRightViewPhoto() {
    setState(() {
      _rightViewImagePath = 'assets/images/dog_right_view.png'; // TODO: Implement actual photo capture
    });
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

      // Navigate to next screen
      // TODO: Replace with actual next screen navigation
      // Navigator.push(context, MaterialPageRoute(
      //   builder: (context) => NextScreen(petRecord: widget.petRecord)
      // ));
    } else {
      // Show error that all views must be captured
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please capture all view photos')),
      );
    }
  }

  void _goBack() {
    Navigator.pop(context);
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
            Container(
              height: 1,
              color: Colors.grey[300],
            ),
            
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
                  
                  // Top View Photo
                  _buildPhotoSection(
                    label: 'Top View Photo', 
                    imagePath: _topViewImagePath, 
                    onTakePhoto: _takeTopViewPhoto
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Left View Photo
                  _buildPhotoSection(
                    label: 'Left View Photo', 
                    imagePath: _leftViewImagePath, 
                    onTakePhoto: _takeLeftViewPhoto
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Right View Photo
                  _buildPhotoSection(
                    label: 'Right View Photo', 
                    imagePath: _rightViewImagePath, 
                    onTakePhoto: _takeRightViewPhoto
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
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onAddRecordsTap: () {
          // Do nothing, already on add record screen
        },
      ),
    );
  }

  Widget _buildPhotoSection({
    required String label, 
    String? imagePath, 
    required VoidCallback onTakePhoto
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF333333),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton(
              onPressed: onTakePhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0F2F1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF4CAF50),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Take Photo',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF4CAF50),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 202,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: imagePath == null
              ? Center(
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.grey[400],
                    size: 64,
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
        ),
      ],
    );
  }
}