import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../widgets/bottom_nav_bar.dart';
import '../models/pet_record_model.dart';
import '../services/camera_service.dart';
import '../services/pet_detection_service.dart';
import 'package:image_picker/image_picker.dart';

class TopSideViewScreen extends StatefulWidget {
  final PetRecord petRecord;

  const TopSideViewScreen({Key? key, required this.petRecord})
    : super(key: key);

  @override
  State<TopSideViewScreen> createState() => _TopSideViewScreenState();
}

class _TopSideViewScreenState extends State<TopSideViewScreen>
    with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  int _selectedIndex = 1;
  int _selectedTabIndex = 0;

  String? _topViewImagePath;
  String? _leftViewImagePath;
  String? _rightViewImagePath;
  String? _backViewImagePath;

  Map<int, bool> _loadingStates = {0: false, 1: false, 2: false, 3: false};

  bool _isClassifying = false;
  Map<String, String> _viewClassifications = {};
  bool _classificationError = false;

  late AnimationController _tabAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _viewTabs = ['Top', 'Left', 'Right', 'Back'];
  final List<IconData> _viewIcons = [
    Icons.keyboard_arrow_up_rounded,
    Icons.keyboard_arrow_left_rounded,
    Icons.keyboard_arrow_right_rounded,
    Icons.keyboard_arrow_down_rounded,
  ];

  final List<String> _viewDescriptions = [
    'Position camera above the animal',
    'Capture from the left side',
    'Capture from the right side',
    'Position behind the animal',
  ];

  Map<String, String> _testImages = {
    'top': 'assets/images/dog_top.webp',
    'left': 'assets/images/dog_left.jpg',
    'right': 'assets/images/dog_right.jpg',
    'back': 'assets/images/dog_back.webp',
  };

  @override
  void initState() {
    super.initState();

    _tabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

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

    setState(() {
      _topViewImagePath = widget.petRecord.topViewImagePath;
      _leftViewImagePath = widget.petRecord.leftViewImagePath;
      _rightViewImagePath = widget.petRecord.rightViewImagePath;
      _backViewImagePath = widget.petRecord.backViewImagePath;
    });
  }

  @override
  void dispose() {
    _tabAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/records', (route) => false);
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/special-care');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(),
            _buildGlassmorphicTabs(),
            Expanded(child: _buildPhotoContentWithAnimations()),
            _buildModernBottomSection(),
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

  Widget _buildGlassmorphicTabs() {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_viewTabs.length, (index) {
          bool isSelected = _selectedTabIndex == index;
          bool hasImage = _getImagePathByIndex(index) != null;
          bool isLoading = _loadingStates[index] ?? false;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTabIndex = index;
                });
                _tabAnimationController.forward(from: 0);
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFF6B86C9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow:
                      isSelected
                          ? [
                            BoxShadow(
                              color: Color(0xFF6B86C9).withOpacity(0.3),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ]
                          : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : Colors.grey[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _viewIcons[index],
                            color:
                                isSelected ? Colors.white : Color(0xFF64748B),
                            size: 18,
                          ),
                        ),
                        if (isLoading)
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isSelected ? Colors.white : Color(0xFF6B86C9),
                              ),
                            ),
                          ),
                        if (hasImage && !isLoading)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF10B981).withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      _viewTabs[index],
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: isSelected ? Colors.white : Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPhotoContentWithAnimations() {
    String currentView = _viewTabs[_selectedTabIndex];
    String? currentImagePath = _getImagePathByIndex(_selectedTabIndex);
    bool isLoading = _loadingStates[_selectedTabIndex] ?? false;

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
                  _buildModernPhotoPreview(currentView, currentImagePath),
                  SizedBox(height: 32),
                  Center(
                    child: _buildModernActionButtons(
                      currentImagePath,
                      isLoading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernPhotoPreview(
    String currentView,
    String? currentImagePath,
  ) {
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
              currentImagePath != null
                  ? Stack(
                    children: [
                      Image.file(
                        File(currentImagePath),
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
                                _viewIcons[_selectedTabIndex],
                                color: Colors.white,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '$currentView View',
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
                          _viewIcons[_selectedTabIndex],
                          size: 32,
                          color: Color(0xFF6B86C9),
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Capture $currentView View',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _viewDescriptions[_selectedTabIndex],
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

  Widget _buildModernActionButtons(String? currentImagePath, bool isLoading) {
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
          onTap: isLoading ? null : () => _showImageOptions(_selectedTabIndex),
          child: Center(
            child:
                isLoading
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

  Widget _buildModernBottomSection() {
    int completedViews = _getCompletedViewsCount();
    bool canProceed = completedViews == 4;

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
                    color:
                        completedViews > 0
                            ? Color(0xFF10B981)
                            : Color(0xFFCBD5E1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.photo_camera_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  '$completedViews of 4 views captured',
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
          // Modern gradient button like in the image
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
                        colors: [
                          Color(0xFF8B5CF6), // Purple color like in image
                          Color(0xFFAA7BF7),
                        ],
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

  // Helper methods (same as before)
  String? _getImagePathByIndex(int index) {
    switch (index) {
      case 0:
        return _topViewImagePath;
      case 1:
        return _leftViewImagePath;
      case 2:
        return _rightViewImagePath;
      case 3:
        return _backViewImagePath;
      default:
        return null;
    }
  }

  void _setImagePathByIndex(int index, String? path) {
    setState(() {
      switch (index) {
        case 0:
          _topViewImagePath = path;
          widget.petRecord.topViewImagePath = path;
          break;
        case 1:
          _leftViewImagePath = path;
          widget.petRecord.leftViewImagePath = path;
          break;
        case 2:
          _rightViewImagePath = path;
          widget.petRecord.rightViewImagePath = path;
          break;
        case 3:
          _backViewImagePath = path;
          widget.petRecord.backViewImagePath = path;
          break;
      }
    });
  }

  int _getCompletedViewsCount() {
    int count = 0;
    if (_topViewImagePath != null) count++;
    if (_leftViewImagePath != null) count++;
    if (_rightViewImagePath != null) count++;
    if (_backViewImagePath != null) count++;
    return count;
  }

  void _takePhoto(int viewIndex) async {
    setState(() {
      _loadingStates[viewIndex] = true;
    });

    try {
      final photoPath = await CameraService.takePhoto();
      if (photoPath != null) {
        _setImagePathByIndex(viewIndex, photoPath);

        String viewName = _viewTabs[viewIndex].toLowerCase();
        await _classifyImageView(photoPath, viewName);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
    } finally {
      setState(() {
        _loadingStates[viewIndex] = false;
      });
    }
  }

  void _retakePhoto(int viewIndex) {
    _setImagePathByIndex(viewIndex, null);
  }

  void _useTestImage(int viewIndex) async {
    setState(() {
      _loadingStates[viewIndex] = true;
    });

    try {
      final directory = await getTemporaryDirectory();
      final tempPath = directory.path;

      String viewName = _viewTabs[viewIndex].toLowerCase();
      final assetName = _testImages[viewName]!;
      final tempFile = File('$tempPath/temp_${viewName}_image.jpg');

      final byteData = await rootBundle.load(assetName);
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      _setImagePathByIndex(viewIndex, tempFile.path);

      await _classifyImageView(tempFile.path, viewName);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error using test image: $e')));
    } finally {
      setState(() {
        _loadingStates[viewIndex] = false;
      });
    }
  }

  Future<void> _classifyImageView(String imagePath, String expectedView) async {
    setState(() {
      _isClassifying = true;
      _classificationError = false;
    });

    try {
      var classificationResult = await AIService.classifyImageView(imagePath);

      if (classificationResult != null &&
          classificationResult.containsKey('group')) {
        String detectedView = classificationResult['group'];
        setState(() {
          _viewClassifications[imagePath] = detectedView;
        });
        _showViewConfirmationDialog(imagePath, expectedView, detectedView);
      } else {
        setState(() {
          _classificationError = true;
        });
        _showViewConfirmationDialog(imagePath, expectedView, "unknown");
      }
    } catch (e) {
      setState(() {
        _classificationError = true;
      });
      _showViewConfirmationDialog(imagePath, expectedView, "unknown");
    } finally {
      setState(() {
        _isClassifying = false;
      });
    }
  }

  void _showViewConfirmationDialog(
    String imagePath,
    String expectedView,
    String detectedView,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false, // ✅ ป้องกันการปิดโดยกดพื้นที่ว่าง
      enableDrag: false, // ✅ ป้องกันการลากปิด
      builder: (context) {
        return WillPopScope(
          // ✅ ป้องกันการกดปุ่มย้อนกลับ
          onWillPop: () async => false,
          child: Container(
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
                  'Image Confirmation',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF1E293B),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 12),

                // Description
                Text(
                  'We need to ensure the correct angle for\naccurate analysis.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF64748B),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 24),

                // Question container
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Is this a ${detectedView.toLowerCase()} view of the animal?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    // No button
                    Expanded(
                      child: Container(
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _showViewSelectionDialog(imagePath, detectedView);
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
                            'No, Wrong View',
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

                    // Yes button
                    Expanded(
                      child: Container(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _viewClassifications[imagePath] = detectedView;
                            });

                            // Show success feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '${detectedView.toUpperCase()} view confirmed!',
                                    ),
                                  ],
                                ),
                                backgroundColor: Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
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
                            'Yes, Correct!',
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
                SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showImageOptions(int viewIndex) {
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
                'Add ${_viewTabs[viewIndex]} View Photo',
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
                  child: Icon(Icons.camera_alt, color: Color(0xFF6B86C9)),
                ),
                title: Text('Take Photo'),
                subtitle: Text('Use camera to capture new photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto(viewIndex);
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
                  child: Icon(Icons.photo_library, color: Color(0xFF8B5CF6)),
                ),
                title: Text('Choose from Gallery'),
                subtitle: Text('Select photo from your gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery(viewIndex);
                },
              ),

              SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ✅ Step 3: เพิ่ม method สำหรับเลือกจาก Gallery
  void _pickFromGallery(int viewIndex) async {
    setState(() {
      _loadingStates[viewIndex] = true;
    });

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        _setImagePathByIndex(viewIndex, image.path);

        // แสดงข้อความสำเร็จ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Photo selected from gallery'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // ทำการ classify รูป (ถ้าต้องการ)
        String viewName = _viewTabs[viewIndex].toLowerCase();
        await _classifyImageView(image.path, viewName);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _loadingStates[viewIndex] = false;
      });
    }
  }

  void _showViewSelectionDialog(String imagePath, String detectedView) {
    // Get available view options (exclude the incorrectly detected one)
    List<String> allViews = ['Top', 'Left', 'Right', 'Back'];
    List<String> availableViews =
        allViews
            .where((view) => view.toLowerCase() != detectedView.toLowerCase())
            .toList();

    List<IconData> viewIcons = [
      Icons.keyboard_arrow_up_rounded, // Top
      Icons.keyboard_arrow_left_rounded, // Left
      Icons.keyboard_arrow_right_rounded, // Right
      Icons.keyboard_arrow_down_rounded, // Back
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Container(
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

                // Title with icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rotate_right_rounded,
                      color: Color(0xFF6B86C9),
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Select Correct View',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF1E293B),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),

                Text(
                  'Which view does this image actually show?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF64748B),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 32),

                // View options grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: availableViews.length,
                  itemBuilder: (context, index) {
                    String viewName = availableViews[index];
                    IconData viewIcon = viewIcons[allViews.indexOf(viewName)];

                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          _viewClassifications[imagePath] = viewName;
                        });

                        // Show success feedback
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(
                                  Icons.swap_horiz_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Changed to ${viewName.toUpperCase()} view',
                                ),
                              ],
                            ),
                            backgroundColor: Color(0xFF8B5CF6),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Color(0xFF6B86C9).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                viewIcon,
                                size: 24,
                                color: Color(0xFF6B86C9),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              viewName,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'View',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 24),

                // Cancel button
                Container(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Remove the incorrectly classified image
                      int currentIndex = _selectedTabIndex;
                      _setImagePathByIndex(currentIndex, null);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Please retake the photo'),
                            ],
                          ),
                          backgroundColor: Color(0xFF64748B),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: Duration(seconds: 3),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: Text(
                      'Cancel & Retake Photo',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF64748B),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _goToNextStep() {
    if (_topViewImagePath != null &&
        _leftViewImagePath != null &&
        _rightViewImagePath != null &&
        _backViewImagePath != null) {
      Navigator.pushNamed(
        context,
        '/bcs-evaluation',
        arguments: widget.petRecord,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please capture all view photos'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _goBack() {
    Navigator.pop(context);
  }
}
