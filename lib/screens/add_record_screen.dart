import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/frosted_glass_header.dart';
import '../widgets/gradient_background.dart';
import '../models/pet_record_model.dart';
import '../services/camera_service.dart';
import '../services/pet_detection_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AddRecordScreen extends StatefulWidget {
  final PetRecord?
  existingPetRecord; // ✅ เพิ่ม parameter สำหรับรับข้อมูลจากภายนอก

  const AddRecordScreen({Key? key, this.existingPetRecord}) : super(key: key);

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();

  int _selectedIndex = 1;
  String? _frontViewImagePath;
  bool _isPhotoLoading = false;
  String? _predictedAnimal;
  double? _predictionConfidence;
  bool _predictionHandled = false;
  bool _apiError = false;

  // ✅ เพิ่มตัวแปรสำหรับเก็บข้อมูลสัตว์ที่มีอยู่แล้ว
  late PetRecord _petRecord;
  bool _isExistingPet = false;

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

    print('🔍 AddRecordScreen initState');
    print('🔍 existingPetRecord: ${widget.existingPetRecord}');
    print(
      '🔍 isNewRecordForExistingPet: ${widget.existingPetRecord?.isNewRecordForExistingPet}',
    );

    // ตรวจสอบว่ามีข้อมูลสัตว์ที่ส่งเข้ามาหรือไม่
    if (widget.existingPetRecord != null &&
        widget.existingPetRecord!.isNewRecordForExistingPet) {
      // กรณีเพิ่มข้อมูลใหม่ให้สัตว์ที่มีอยู่แล้ว
      _petRecord = widget.existingPetRecord!;
      _isExistingPet = true;
      _predictedAnimal = _petRecord.category == 'Dogs' ? 'dog' : 'cat';
      _predictionHandled = true;

      print('✅ Setting up for existing pet: ${_petRecord.name}');
      print('✅ Pet ID: ${_petRecord.existingPetId}');
    } else {
      // กรณีเพิ่มสัตว์ใหม่
      _petRecord = PetRecord();
      _isExistingPet = false;
      _petRecord.reset();
      print('✅ Setting up for new pet');
    }

    // Reset image states
    _frontViewImagePath = null;
    if (!_isExistingPet) {
      _predictedAnimal = null;
      _predictionConfidence = null;
      _predictionHandled = false;
    }
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
                'Add Front View Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              SizedBox(height: 24),

              ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFF6B86C9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.camera_alt, color: Color(0xFF6B86C9)),
                ),
                title: Text('Take Photo'),
                subtitle: Text('Use camera to capture new photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),

              ListTile(
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFF8B5CF6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.photo_library, color: Color(0xFF8B5CF6)),
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
      if (!_isExistingPet) {
        _predictionHandled = false;
        _predictedAnimal = null;
      }
    });

    try {
      final photoPath = await CameraService.takePhoto();
      if (photoPath != null) {
        setState(() {
          _frontViewImagePath = photoPath;
        });

        // ✅ ถ้าเป็นสัตว์ใหม่ ให้ทำ prediction
        // ถ้าเป็นสัตว์เก่า จะข้าม prediction เพราะรู้ประเภทแล้ว
        if (!_isExistingPet) {
          await _predictPetType(photoPath);
        }
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

  void _pickFromGallery() async {
    setState(() {
      _isPhotoLoading = true;
      _apiError = false;
      if (!_isExistingPet) {
        _predictionHandled = false;
        _predictedAnimal = null;
      }
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo selected from gallery'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // ✅ ถ้าเป็นสัตว์ใหม่ ให้ทำ prediction
        if (!_isExistingPet) {
          await _predictPetType(image.path);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPhotoLoading = false;
      });
    }
  }


  Future<void> _predictPetType(String imagePath) async {
    // ✅ ข้าม prediction ถ้าเป็นสัตว์ที่มีอยู่แล้ว
    if (_isExistingPet) {
      return;
    }

    setState(() {
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
      // Prediction completed
    }
  }

  void _showPetConfirmationDialog(bool isError, {String? errorMsg}) {
    // ถ้าเป็นสัตว์ที่มีอยู่แล้ว ไม่ต้องแสดง dialog
    if (_isExistingPet) return;

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
                            _petRecord.frontViewImagePath = _frontViewImagePath;
                            _petRecord.category =
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
                    _petRecord.frontViewImagePath = _frontViewImagePath;
                    _petRecord.category = 'Dogs';
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
                    _petRecord.frontViewImagePath = _frontViewImagePath;
                    _petRecord.category = 'Cats';
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
      _petRecord.frontViewImagePath = _frontViewImagePath;

      if (_predictedAnimal != null) {
        _petRecord.category = _predictedAnimal == 'dog' ? 'Dogs' : 'Cats';
        _petRecord.predictedAnimal = _predictedAnimal;
        _petRecord.predictionConfidence = _predictionConfidence;
      }

      Navigator.pushNamed(context, '/top-side-view', arguments: _petRecord);
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

  // Helper method to check if user has unsaved data
  bool _hasUnsavedData() {
    return _frontViewImagePath != null || _predictedAnimal != null;
  }

  // Show confirmation dialog
  Future<bool> _showExitConfirmation() async {
    if (!_hasUnsavedData()) return true;
    
    return await _showModernConfirmDialog(
      context: context,
      title: 'Leave without saving?',
      message: 'You have unsaved changes. Are you sure you want to leave?',
      confirmText: 'Leave',
    ) ?? false;
  }
  
  // Helper function for modern confirmation dialog
  Future<bool?> _showModernConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF6B86C9).withOpacity(0.2),
                    blurRadius: 30,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Warning Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFFB84D),
                          Color(0xFFFF9500),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFF9500).withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Title
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  
                  // Content
                  Text(
                    message,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      color: Color(0xFF64748B),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Color(0xFF6B86C9),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: Colors.white,
                          ),
                          child: Text(
                            cancelText,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B86C9),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      
                      // Confirm Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: confirmColor != null
                                  ? [confirmColor, confirmColor.withOpacity(0.8)]
                                  : [
                                      Color(0xFFEF4444),
                                      Color(0xFFDC2626),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (confirmColor ?? Color(0xFFEF4444)).withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              confirmText,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ถ้าเป็นสัตว์เก่า ถือว่า prediction handled แล้ว
    bool canProceed =
        _frontViewImagePath != null &&
        (_predictionHandled || _isExistingPet) &&
        !_apiError;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _showExitConfirmation();
          if (shouldPop) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Color(0xFFD0E3F5), // สีฟ้าอ่อนมาก (ล่างสุด) เพื่อให้ตรงกับ gradient
        body: GradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                FrostedGlassHeader(
                  title: 'Add Record',
                  subtitle: 'Step 1: Take Photo',
                  leadingWidget: HeaderBackButton(
                    onPressed: () async {
                      final shouldPop = await _showExitConfirmation();
                      if (shouldPop) {
                        Navigator.pushReplacementNamed(context, '/records');
                      }
                    },
                  ),
                ),
                SizedBox(height: 20),
                _buildProgressIndicator(),
                Expanded(child: _buildPhotoContentWithAnimations()),
                _buildModernBottomSection(canProceed),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: _selectedIndex,
          onItemTapped: (index) async {
            if (_hasUnsavedData()) {
              final shouldLeave = await _showExitConfirmation();
              if (shouldLeave) {
                _onItemTapped(index);
              }
            } else {
              _onItemTapped(index);
            }
          },
          onAddRecordsTap: () {},
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6B86C9), Color(0xFF8BA3E7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Step 1 of 4',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.25, // 1/4 progress
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6B86C9), Color(0xFF8BA3E7)],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Take Front View Photo',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Capture a clear front view photo of your pet for identification',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B86C9),
            Color(0xFF8BA3E7),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6B86C9).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 30),
        child: Row(
          children: [
            GestureDetector(
              onTap: _goBack,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    Text(
                      'Add Records',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    // แสดงชื่อสัตว์ถ้าเป็นการเพิ่มข้อมูลให้สัตว์เก่า
                    if (_isExistingPet) ...[
                      SizedBox(height: 4),
                      Text(
                        'for ${_petRecord.name}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(width: 44), // Balance the back button
          ],
        ),
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
          child:
              _frontViewImagePath != null
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
                      // แสดง pet type ถ้าทราบแล้ว
                      if (_predictedAnimal != null)
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  _isExistingPet
                                      ? Colors.blue.withOpacity(0.9)
                                      : Colors.green.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _predictedAnimal!.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
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
                        'Capture Front Viewr',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _isExistingPet
                            ? 'Take a new photo of ${_petRecord.name}'
                            : 'Position the camera to show the front of your pet',
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
          onTap: _isPhotoLoading ? null : _showImageOptions,
          child: Center(
            child:
                _isPhotoLoading
                    ? SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
        // Gradient สีฟ้าอ่อนแทนสีขาว
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFA8C5E8).withOpacity(0.95), // สีฟ้าอ่อน
            Color(0xFFD0E3F5).withOpacity(0.98), // สีฟ้าอ่อนมาก
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF5B8CC9).withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6), // แก้วใสๆ ให้เข้ากับธีม
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color:
                        _frontViewImagePath != null
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
                      ? (_isExistingPet || _predictionHandled
                          ? 'Photo ready!'
                          : 'Processing...')
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

          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient:
                  canProceed
                      ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF8B5CF6), Color(0xFFAA7BF7)],
                      )
                      : null,
              color: canProceed ? null : Color(0xFFE2E8F0),
              boxShadow:
                  canProceed
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
