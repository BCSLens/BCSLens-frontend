import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../models/pet_record_model.dart';
import '../services/camera_service.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import '../services/pet_detection_service.dart';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart'; // ✅ เพิ่ม import

class AddRecordScreen extends StatefulWidget {
  const AddRecordScreen({Key? key}) : super(key: key);
  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker(); // ✅ เพิ่ม ImagePicker instance
  
  int _selectedIndex = 1;
  String? _frontViewImagePath;
  bool _isPhotoLoading = false;
  bool _isPredicting = false;
  String? _predictedAnimal;
  double? _predictionConfidence;
  bool _predictionHandled = false;
  bool _apiError = false;

  late AnimationController _buttonAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _buttonAnimationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _buttonAnimationController.forward();

    // Reset all previous data when starting a new record
    PetRecord().reset();
    _frontViewImagePath = null;
    _predictedAnimal = null;
    _predictionConfidence = null;
    _predictionHandled = false;
    _apiError = false;
  }

  @override
  void dispose() {
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _goBack() {
    Navigator.pushReplacementNamed(context, '/records');
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/records', (route) => false);
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/special-care');
    }
  }

  // ✅ เพิ่ม method สำหรับแสดง dialog เลือก Camera หรือ Gallery
  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 24),
              
              // Title
              Text(
                'Add Front View Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 24),
              
              // Camera Button
              ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFF6B86C9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.camera_alt,
                    color: Color(0xFF6B86C9),
                  ),
                ),
                title: Text('Take Photo'),
                subtitle: Text('Use camera to capture new photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              
              // Gallery Button
              ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.photo_library,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
                title: Text('Choose from Gallery'),
                subtitle: Text('Select photo from your gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),
              
              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
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
        await _predictPetType(photoPath);
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

  // ✅ เพิ่ม method สำหรับเลือกจาก Gallery
  void _pickFromGallery() async {
    setState(() {
      _isPhotoLoading = true;
      _apiError = false;
      _predictionHandled = false;
      _predictedAnimal = null;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _frontViewImagePath = image.path;
        });

        // แสดงข้อความสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Photo selected from gallery'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // ทำการ predict pet type
        await _predictPetType(image.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPhotoLoading = false;
      });
    }
  }

  void _useTestImage() async {
    setState(() {
      _isPhotoLoading = true;
      _apiError = false;
      _predictionHandled = false;
      _predictedAnimal = null;
    });

    try {
      final directory = await getTemporaryDirectory();
      final tempPath = directory.path;
      final assetName = 'assets/images/dog.jpg';
      final tempFile = File('$tempPath/temp_test_image.jpg');

      final byteData = await rootBundle.load(assetName);
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      setState(() {
        _frontViewImagePath = tempFile.path;
      });

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

  Future<void> _predictPetType(String imagePath) async {
    setState(() {
      _isPredicting = true;
      _predictionHandled = false;
      _apiError = false;
    });

    try {
      print("Starting pet prediction...");

      var prediction = await AIService.predictPetType(imagePath);
      print("Prediction result: $prediction");

      if (prediction != null) {
        setState(() {
          _predictedAnimal = prediction['class_name'];
          _predictionConfidence = prediction['confidence'];
          _predictionHandled = true;
          _apiError = false;
        });

        Future.microtask(() => _showPetConfirmationDialog(false));
      } else {
        setState(() {
          _apiError = true;
          _predictionHandled = false;
        });
        Future.microtask(
          () => _showPetConfirmationDialog(
            true,
            errorMsg: "We couldn't detect the animal type",
          ),
        );
      }
    } catch (e) {
      print('Prediction error: $e');
      setState(() {
        _apiError = true;
        _predictionHandled = false;
      });
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: 24),
              Text(
                isError ? 'Something Went Wrong' : 'Pet Confirmation',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF1E293B),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 12),
              Text(
                isError
                    ? 'We couldn\'t detect the animal in your photo.\nPlease try again.'
                    : 'We need to confirm the animal\'s species\nfor accurate analysis.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF64748B),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 24),
              if (!isError) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Is this a $_predictedAnimal?',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showAnimalSelectionDialog();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Color(0xFF6B86C9),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: Text(
                            'No',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF6B86C9),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            final petRecord = PetRecord();
                            petRecord.frontViewImagePath = _frontViewImagePath;
                            petRecord.category =
                                _predictedAnimal == 'dog' ? 'Dogs' : 'Cats';
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6B86C9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 2,
                            shadowColor: Color(0xFF6B86C9).withOpacity(0.3),
                          ),
                          child: Text(
                            'Yes',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6B86C9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      shadowColor: Color(0xFF6B86C9).withOpacity(0.3),
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _showAnimalSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Pet Type',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 24),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _predictedAnimal = 'dog';
                      _predictionHandled = true;
                      _apiError = false;
                    });
                    final petRecord = PetRecord();
                    petRecord.frontViewImagePath = _frontViewImagePath;
                    petRecord.category = 'Dogs';
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pets, color: Color(0xFF6B86C9)),
                        SizedBox(width: 12),
                        Text(
                          'Dog',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 12),
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _predictedAnimal = 'cat';
                      _predictionHandled = true;
                      _apiError = false;
                    });
                    final petRecord = PetRecord();
                    petRecord.frontViewImagePath = _frontViewImagePath;
                    petRecord.category = 'Cats';
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.emoji_nature, color: Color(0xFF6B86C9)),
                        SizedBox(width: 12),
                        Text(
                          'Cat',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToNextStep() {
    if (_frontViewImagePath != null) {
      final petRecord = PetRecord(frontViewImagePath: _frontViewImagePath);

      if (_predictedAnimal != null) {
        petRecord.category = _predictedAnimal == 'dog' ? 'Dogs' : 'Cats';
        petRecord.predictedAnimal = _predictedAnimal;
        petRecord.predictionConfidence = _predictionConfidence;
      }

      Navigator.pushNamed(context, '/top-side-view', arguments: petRecord);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please take a front view photo'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    bool canProceed =
        _frontViewImagePath != null && _predictionHandled && !_apiError;

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(),
            Expanded(child: _buildPhotoContentWithAnimations()),
            _buildModernBottomSection(canProceed),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onAddRecordsTap: () {},
      ),
    );
  }

  Widget _buildModernHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          // Back arrow and title on same line
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _goBack,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      size: 18,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
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
                ),
                SizedBox(width: 40), // Spacer to balance the back button
              ],
            ),
          ),
          SizedBox(height: 20),
          Container(height: 1, color: Colors.grey[300]),
        ],
      ),
    );
  }

  Widget _buildPhotoContentWithAnimations() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildModernPhotoPreview(),
                  SizedBox(height: 32),
                  Center(child: _buildModernActionButtons()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernPhotoPreview() {
    return Expanded(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFF8FAFC)],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: Offset(0, 8),
            ),
            BoxShadow(
              color: Color(0xFF6B86C9).withOpacity(0.04),
              blurRadius: 40,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: _frontViewImagePath != null
              ? Stack(
                  children: [
                    Image.file(
                      File(_frontViewImagePath!),
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Front View',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // ✅ เอา loading overlay ออก - ไม่มี if (_isPredicting) แล้ว
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Color(0xFF6B86C9).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 32,
                        color: Color(0xFF6B86C9),
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Capture Front View',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Position the camera to show the front of your pet',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildModernActionButtons() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: Color(0xFF6B86C9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6B86C9).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0xFF6B86C9).withOpacity(0.1),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(40),
          // ✅ เปลี่ยนจาก _takePhoto เป็น _showImageOptions
          onTap: _isPhotoLoading ? null : _showImageOptions,
          child: Center(
            child: _isPhotoLoading
                ? SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : Icon(
                    Icons.camera_alt_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernBottomSection(bool canProceed) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status indicator
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _frontViewImagePath != null
                        ? Color(0xFF10B981)
                        : Color(0xFFCBD5E1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.camera_alt_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  _frontViewImagePath != null
                      ? (_predictionHandled ? 'Photo ready!' : 'Processing...')
                      : 'Take a photo to continue',
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

          // Next button
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: canProceed
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF8B5CF6), Color(0xFFAA7BF7)],
                    )
                  : null,
              color: canProceed ? null : Color(0xFFE2E8F0),
              boxShadow: canProceed
                  ? [
                      BoxShadow(
                        color: Color(0xFF8B5CF6).withOpacity(0.3),
                        blurRadius: 15,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(28),
                onTap: canProceed ? _goToNextStep : null,
                child: Center(
                  child: Text(
                    'Next Step',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: canProceed ? Colors.white : Color(0xFF94A3B8),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}