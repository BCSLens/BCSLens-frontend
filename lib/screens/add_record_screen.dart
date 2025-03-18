import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../models/pet_record_model.dart';

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({Key? key}) : super(key: key);

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  int _selectedIndex = 1;
  String? _frontViewImagePath;

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/records');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/special-care');
    }
  }

  void _takePhoto() {
    // TODO: Implement actual photo capture 
    setState(() {
      _frontViewImagePath = 'assets/images/dog_placeholder.png';
    });
  }

void _goToNextStep() {
  if (_frontViewImagePath != null) {
    // Create a new PetRecord and populate the front view image
    PetRecord petRecord = PetRecord(
      frontViewImagePath: _frontViewImagePath,
    );

    // Navigate to the Top Side View Screen
    Navigator.pushNamed(
      context, 
      '/top-side-view', 
      arguments: petRecord
    );
  } else {
    // Show an error if no front view photo is taken
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
            Container(
              height: 1,
              color: Colors.grey[300],
            ),
            
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
                  
                  // Front View Photo Label and Take Photo Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Front View Photo',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF333333),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _takePhoto,
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
                  
                  const SizedBox(height: 15),
                  
                  // Photo Container
                  Container(
                    height: 202,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: _frontViewImagePath == null
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
                              _frontViewImagePath!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
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