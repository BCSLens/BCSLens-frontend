import 'package:flutter/material.dart';
import 'dart:io';
import '../widgets/bottom_nav_bar.dart';
import '../models/pet_record_model.dart';
import '../services/pet_service.dart';

class BcsReviewScreen extends StatefulWidget {
  final PetRecord petRecord;

  const BcsReviewScreen({
    Key? key,
    required this.petRecord,
  }) : super(key: key);

  @override
  State<BcsReviewScreen> createState() => _BcsReviewScreenState();
}

class _BcsReviewScreenState extends State<BcsReviewScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isFavorite = true;
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late AnimationController _scoreAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;

  // BCS descriptions based on score (1-9)
  final Map<int, List<String>> _bcsDescriptions = {
    1: [
      "Ribs, lumbar vertebrae, pelvic bones and all bony prominences evident from a distance",
      "No discernible body fat",
      "Obvious loss of muscle mass",
      "Severely emaciated",
    ],
    2: [
      "Ribs, lumbar vertebrae and pelvic bones easily visible",
      "Minimal muscle mass",
      "No palpable fat",
      "Obvious waist and abdominal tuck",
    ],
    3: [
      "Ribs easily palpable with minimal fat covering",
      "Waist easily observed when viewed from above",
      "Abdominal tuck evident",
      "Vertebrae and pelvic bones visible",
    ],
    4: [
      "Ribs easily palpable with minimal fat covering",
      "Waist easily observed from above",
      "Abdominal tuck present",
      "No excess fat covering",
    ],
    5: [
      "Ribs palpable without excess fat covering",
      "Waist is visible behind the ribs when viewed from above",
      "Minimal abdominal fat pad",
      "Proportionate body shape",
    ],
    6: [
      "Ribs palpable with slight excess fat covering",
      "Waist is discernible viewed from above but not prominent",
      "Slight abdominal tuck",
      "Small fat pad present",
    ],
    7: [
      "Ribs palpable with difficulty with moderate fat covering",
      "Waist barely visible",
      "Abdominal tuck absent",
      "Obvious fat deposits over lumbar area",
    ],
    8: [
      "Ribs not palpable under heavy fat cover",
      "No waist, abdominal distention present",
      "Fat deposits on lumbar area and tail base",
      "Abdomen rounded",
    ],
    9: [
      "Massive fat deposits over chest, spine and tail base",
      "Waist and abdominal tuck absent",
      "Fat deposits on neck and limbs",
      "Obvious abdominal distention",
    ],
  };

  // Enhanced suggestions based on BCS score and animal type
  Map<String, Map<int, Map<String, List<String>>>> _bcsSuggestions = {
    'dog': {
      1: {
        'Nutrition & Management': [
          "Increase energy in food",
          "Use high-quality food with sufficient protein and fat",
          "Divide food into smaller, more frequent meals"
        ],
        'Basic Care': [
          "Control internal and external parasites",
          "Maintain overall cleanliness"
        ],
        'Exercise & Rehabilitation': [
          "Engage in light exercise, such as short walks",
          "Stimulate muscle growth"
        ],
        'Additional Advice': [
          "Continuously observe eating habits, defecation, and weight"
        ],
        'Vet Visit': [
          "Consult a veterinarian to identify the cause of being underweight",
          "Check for gastrointestinal disease or parasites"
        ]
      },
      2: {
        'Nutrition & Management': [
          "Increase energy in food",
          "Use high-quality food with sufficient protein and fat",
          "Divide food into smaller, more frequent meals"
        ],
        'Basic Care': [
          "Control internal and external parasites",
          "Maintain overall cleanliness"
        ],
        'Exercise & Rehabilitation': [
          "Engage in light exercise, such as short walks",
          "Stimulate muscle growth"
        ],
        'Additional Advice': [
          "Continuously observe eating habits, defecation, and weight"
        ],
        'Vet Visit': [
          "Consult a veterinarian to identify the cause of being underweight",
          "Check for gastrointestinal disease or parasites"
        ]
      },
      3: {
        'Nutrition & Management': [
          "Increase energy in food",
          "Use high-quality food with sufficient protein and fat",
          "Divide food into smaller, more frequent meals"
        ],
        'Basic Care': [
          "Control internal and external parasites",
          "Maintain overall cleanliness"
        ],
        'Exercise & Rehabilitation': [
          "Engage in light exercise, such as short walks",
          "Stimulate muscle growth"
        ],
        'Additional Advice': [
          "Continuously observe eating habits, defecation, and weight"
        ],
        'Vet Visit': [
          "Consult a veterinarian to identify the cause of being underweight",
          "Check for gastrointestinal disease or parasites"
        ]
      },
      4: {
        'Nutrition & Management': [
          "Provide a balanced food formula appropriate for the pet's age",
          "Control the quantity to avoid overfeeding or underfeeding"
        ],
        'Basic Care': [
          "Ensure regular vaccinations and deworming",
          "Maintain consistent oral health"
        ],
        'Exercise & Rehabilitation': [
          "Engage in walking or playing for 30-60 minutes per day"
        ],
        'Additional Advice': [
          "Promote good behavior, such as socialization"
        ],
        'Vet Visit': [
          "Schedule an annual health check-up"
        ]
      },
      5: {
        'Nutrition & Management': [
          "Provide a balanced food formula appropriate for the pet's age",
          "Control the quantity to avoid overfeeding or underfeeding"
        ],
        'Basic Care': [
          "Ensure regular vaccinations and deworming",
          "Maintain consistent oral health"
        ],
        'Exercise & Rehabilitation': [
          "Engage in walking or playing for 30-60 minutes per day"
        ],
        'Additional Advice': [
          "Promote good behavior, such as socialization"
        ],
        'Vet Visit': [
          "Schedule an annual health check-up"
        ]
      },
      6: {
        'Nutrition & Management': [
          "Provide a balanced food formula appropriate for the pet's age",
          "Control the quantity to avoid overfeeding or underfeeding"
        ],
        'Basic Care': [
          "Ensure regular vaccinations and deworming",
          "Maintain consistent oral health"
        ],
        'Exercise & Rehabilitation': [
          "Engage in walking or playing for 30-60 minutes per day"
        ],
        'Additional Advice': [
          "Promote good behavior, such as socialization"
        ],
        'Vet Visit': [
          "Schedule an annual health check-up"
        ]
      },
      7: {
        'Nutrition & Management': [
          "Restrict energy intake",
          "Use a weight control food formula",
          "Reduce snacks"
        ],
        'Basic Care': [
          "Weigh the pet regularly",
          "Check for abnormalities in joints and skin"
        ],
        'Exercise & Rehabilitation': [
          "Increase non-strenuous activities",
          "Slow walking, swimming, or using a treadmill"
        ],
        'Additional Advice': [
          "Establish a clear feeding schedule",
          "Avoid leaving food out all the time",
          "Monitor for a monthly weight loss of 1-2% of body weight"
        ],
        'Vet Visit': [
          "Consult a veterinarian to plan a weight loss strategy",
          "Check for complications such as diabetes or heart disease"
        ]
      },
      8: {
        'Nutrition & Management': [
          "Restrict energy intake",
          "Use a weight control food formula",
          "Reduce snacks"
        ],
        'Basic Care': [
          "Weigh the pet regularly",
          "Check for abnormalities in joints and skin"
        ],
        'Exercise & Rehabilitation': [
          "Increase non-strenuous activities",
          "Slow walking, swimming, or using a treadmill"
        ],
        'Additional Advice': [
          "Establish a clear feeding schedule",
          "Avoid leaving food out all the time",
          "Monitor for a monthly weight loss of 1-2% of body weight"
        ],
        'Vet Visit': [
          "Consult a veterinarian to plan a weight loss strategy",
          "Check for complications such as diabetes or heart disease"
        ]
      },
      9: {
        'Nutrition & Management': [
          "Restrict energy intake",
          "Use a weight control food formula",
          "Reduce snacks"
        ],
        'Basic Care': [
          "Weigh the pet regularly",
          "Check for abnormalities in joints and skin"
        ],
        'Exercise & Rehabilitation': [
          "Increase non-strenuous activities",
          "Slow walking, swimming, or using a treadmill"
        ],
        'Additional Advice': [
          "Establish a clear feeding schedule",
          "Avoid leaving food out all the time",
          "Monitor for a monthly weight loss of 1-2% of body weight"
        ],
        'Vet Visit': [
          "Consult a veterinarian to plan a weight loss strategy",
          "Check for complications such as diabetes or heart disease"
        ]
      }
    },
    'cat': {
      1: {
        'Nutrition & Management': [
          "Provide high-energy and high-protein food",
          "Consider using wet food or a prescription diet",
          "Aid in weight gain"
        ],
        'Basic Care': [
          "Ensure a warm and comfortable resting corner",
          "Reduce stress",
          "Control internal and external parasites"
        ],
        'Exercise & Rehabilitation': [
          "Stimulate movement through play",
          "Hunting games, but avoid excessive exertion"
        ],
        'Additional Advice': [
          "Continuously observe eating habits, defecation, and weight"
        ],
        'Vet Visit': [
          "Consult a veterinarian to check for chronic diseases",
          "Check for kidney or liver disease or parasites"
        ]
      },
      2: {
        'Nutrition & Management': [
          "Provide high-energy and high-protein food",
          "Consider using wet food or a prescription diet",
          "Aid in weight gain"
        ],
        'Basic Care': [
          "Ensure a warm and comfortable resting corner",
          "Reduce stress",
          "Control internal and external parasites"
        ],
        'Exercise & Rehabilitation': [
          "Stimulate movement through play",
          "Hunting games, but avoid excessive exertion"
        ],
        'Additional Advice': [
          "Continuously observe eating habits, defecation, and weight"
        ],
        'Vet Visit': [
          "Consult a veterinarian to check for chronic diseases",
          "Check for kidney or liver disease or parasites"
        ]
      },
      3: {
        'Nutrition & Management': [
          "Provide high-energy and high-protein food",
          "Consider using wet food or a prescription diet",
          "Aid in weight gain"
        ],
        'Basic Care': [
          "Ensure a warm and comfortable resting corner",
          "Reduce stress",
          "Control internal and external parasites"
        ],
        'Exercise & Rehabilitation': [
          "Stimulate movement through play",
          "Hunting games, but avoid excessive exertion"
        ],
        'Additional Advice': [
          "Continuously observe eating habits, defecation, and weight"
        ],
        'Vet Visit': [
          "Consult a veterinarian to check for chronic diseases",
          "Check for kidney or liver disease or parasites"
        ]
      },
      4: {
        'Nutrition & Management': [
          "Control food quantity to prevent excess",
          "Include both dry and wet food",
          "Maintain proper water balance in the body"
        ],
        'Basic Care': [
          "Maintain a clean litter box",
          "Follow the vaccination schedule"
        ],
        'Exercise & Rehabilitation': [
          "Stimulate play for 15-20 minutes per day",
          "Chasing toys"
        ],
        'Additional Advice': [
          "Arrange an environment that allows for climbing",
          "Provide hiding spots"
        ],
        'Vet Visit': [
          "Schedule an annual health check-up",
          "Dental cleaning"
        ]
      },
      5: {
        'Nutrition & Management': [
          "Control food quantity to prevent excess",
          "Include both dry and wet food",
          "Maintain proper water balance in the body"
        ],
        'Basic Care': [
          "Maintain a clean litter box",
          "Follow the vaccination schedule"
        ],
        'Exercise & Rehabilitation': [
          "Stimulate play for 15-20 minutes per day",
          "Chasing toys"
        ],
        'Additional Advice': [
          "Arrange an environment that allows for climbing",
          "Provide hiding spots"
        ],
        'Vet Visit': [
          "Schedule an annual health check-up",
          "Dental cleaning"
        ]
      },
      6: {
        'Nutrition & Management': [
          "Control food quantity to prevent excess",
          "Include both dry and wet food",
          "Maintain proper water balance in the body"
        ],
        'Basic Care': [
          "Maintain a clean litter box",
          "Follow the vaccination schedule"
        ],
        'Exercise & Rehabilitation': [
          "Stimulate play for 15-20 minutes per day",
          "Chasing toys"
        ],
        'Additional Advice': [
          "Arrange an environment that allows for climbing",
          "Provide hiding spots"
        ],
        'Vet Visit': [
          "Schedule an annual health check-up",
          "Dental cleaning"
        ]
      },
      7: {
        'Nutrition & Management': [
          "Gradually reduce food quantity",
          "Use a weight loss food formula",
          "High in protein and low in fat"
        ],
        'Basic Care': [
          "Avoid excessive supplements or snacks"
        ],
        'Exercise & Rehabilitation': [
          "Stimulate movement through interactive toys",
          "Laser pointer"
        ],
        'Additional Advice': [
          "Monitor for a monthly weight loss of 1-2% of body weight"
        ],
        'Vet Visit': [
          "Consult a veterinarian to check for metabolic diseases",
          "Check for diabetes or fatty liver"
        ]
      },
      8: {
        'Nutrition & Management': [
          "Gradually reduce food quantity",
          "Use a weight loss food formula",
          "High in protein and low in fat"
        ],
        'Basic Care': [
          "Avoid excessive supplements or snacks"
        ],
        'Exercise & Rehabilitation': [
          "Stimulate movement through interactive toys",
          "Laser pointer"
        ],
        'Additional Advice': [
          "Monitor for a monthly weight loss of 1-2% of body weight"
        ],
        'Vet Visit': [
          "Consult a veterinarian to check for metabolic diseases",
          "Check for diabetes or fatty liver"
        ]
      },
      9: {
        'Nutrition & Management': [
          "Gradually reduce food quantity",
          "Use a weight loss food formula",
          "High in protein and low in fat"
        ],
        'Basic Care': [
          "Avoid excessive supplements or snacks"
        ],
        'Exercise & Rehabilitation': [
          "Stimulate movement through interactive toys",
          "Laser pointer"
        ],
        'Additional Advice': [
          "Monitor for a monthly weight loss of 1-2% of body weight"
        ],
        'Vet Visit': [
          "Consult a veterinarian to check for metabolic diseases",
          "Check for diabetes or fatty liver"
        ]
      }
    }
  };

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _scoreAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scoreAnimationController, curve: Curves.elasticOut),
    );

    _animationController.forward();
    Future.delayed(Duration(milliseconds: 300), () {
      _scoreAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scoreAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/records', (route) => false);
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/add-record');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/special-care');
    }
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  // Helper method to check if user has unsaved data
  bool _hasUnsavedData() {
    // Check if there's any data from add_record page (image, prediction)
    return widget.petRecord.frontViewImagePath != null ||
           widget.petRecord.predictedAnimal != null ||
           widget.petRecord.predictionConfidence != null;
  }

  // Show confirmation dialog
  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text(
              'Leave without saving?',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Text(
          'Your pet data will be lost. Are you sure you want to leave?',
          style: TextStyle(
            fontFamily: 'Inter',
            color: Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Leave',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _navigateToRecords() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final petService = PetService();

      if (widget.petRecord.isNewRecordForExistingPet &&
          widget.petRecord.existingPetId != null) {
        // Add record to existing pet
        await petService.addRecordToExistingPet(
          widget.petRecord.existingPetId!,
          widget.petRecord,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New record added for ${widget.petRecord.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // Create new pet
        await petService.createPet(widget.petRecord);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pet ${widget.petRecord.name} created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Navigate to records screen
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/records',
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Prefer single bcs score; fallback derive from range (supports new and old buckets)
    int bcsScore = widget.petRecord.bcs ?? 5;
    final String? bcsRangeRaw = widget.petRecord.bcsRange;
    if (widget.petRecord.bcs == null && bcsRangeRaw != null) {
      if (bcsRangeRaw == '1-3') bcsScore = 2;
      else if (bcsRangeRaw == '4-5') bcsScore = 5;
      else if (bcsRangeRaw == '6-9') bcsScore = 8;
      // Backward compatibility with old ranges
      else if (bcsRangeRaw == '4-6') bcsScore = 5;
      else if (bcsRangeRaw == '7-9') bcsScore = 8;
    }
    final List<String> bcsInfo = _bcsDescriptions[bcsScore] ?? [];
    final String animalType = widget.petRecord.category?.toLowerCase() == 'cats' ? 'cat' : 'dog';
    final Map<String, List<String>> suggestions = _bcsSuggestions[animalType]?[bcsScore] ?? {};
    
    // Debug print
    print('🔍 Debug - BCS Score: $bcsScore');
    print('🔍 Debug - Animal Type: $animalType');
    print('🔍 Debug - Category: ${widget.petRecord.category}');
    print('🔍 Debug - Suggestions: $suggestions');

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
        backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            _buildModernHeader(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: AnimatedBuilder(
                  animation: _fadeAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _slideAnimation.value),
                      child: Opacity(
                        opacity: _fadeAnimation.value,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Pet Profile Card
                              _buildPetProfileCard(bcsScore),
                              SizedBox(height: 24),
                              
                              // BCS Score Card (single score)
                              _buildBcsScoreCard(bcsScore),
                              SizedBox(height: 24),
                              
                              // Information Card
                              _buildInformationCard(bcsInfo),
                              SizedBox(height: 24),
                              
                              // Suggestions Card
                                _buildSuggestionsCard(suggestions),
                              
                              SizedBox(height: 100), // Space for bottom button
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      
      // Floating Done Button
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 80), // Above bottom nav
        child: FloatingActionButton.extended(
          onPressed: _isLoading ? null : _navigateToRecords,
          backgroundColor: Color(0xFF6B86C9),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          label: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      widget.petRecord.isNewRecordForExistingPet ? 'Add Record' : 'Create Pet',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      
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
        onAddRecordsTap: () {
          Navigator.pushReplacementNamed(context, '/add-record');
        },
      ),
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
              onTap: () => Navigator.pushReplacementNamed(
                context,
                '/pet-details',
                arguments: widget.petRecord,
              ),
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
                  '${widget.petRecord.name}\'s Health Report',
                  style: TextStyle(
                    fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                    SizedBox(height: 4),
                    Text(
                      'BCS Score Analysis',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                // Implement share functionality
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.share_outlined,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetProfileCard(int bcsScore) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Color(0xFFF8FAFC),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // Pet Image with enhanced styling
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF6B86C9).withOpacity(0.1),
                        Color(0xFF8B5CF6).withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      image: widget.petRecord.frontViewImagePath != null
                          ? FileImage(File(widget.petRecord.frontViewImagePath!))
                          : AssetImage('assets/images/default_pet.png') as ImageProvider,
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Pet name with favorite
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.petRecord.name ?? 'Pet',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(width: 12),
                GestureDetector(
                  onTap: _toggleFavorite,
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _isFavorite ? Colors.amber.withOpacity(0.1) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: _isFavorite ? Colors.amber : Color(0xFF94A3B8),
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Pet details with modern pills
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildModernInfoPill(
                  'Age', 
                  '${widget.petRecord.age ?? "Unknown"}',
                  Icons.cake_rounded,
                  Color(0xFF10B981),
                ),
                _buildModernInfoPill(
                  'Breed', 
                  widget.petRecord.breed ?? 'Unknown',
                  Icons.pets_rounded,
                  Color(0xFF6B86C9),
                ),
                _buildModernInfoPill(
                  'Gender', 
                  widget.petRecord.gender ?? 'Unknown',
                  Icons.male_rounded,
                  Color(0xFF8B5CF6),
                ),
                _buildModernInfoPill(
                  'Weight', 
                  widget.petRecord.weight ?? 'Unknown',
                  Icons.monitor_weight_rounded,
                  Color(0xFFEF4444),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBcsScoreCard(int bcsScore) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: _getBcsGradientColors(bcsScore),
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: _getBcsScoreColor(bcsScore).withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.analytics_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'BCS Score Analysis',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Large BCS Score Display (single score)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: Center(
                      child: Text(
                        bcsScore.toString(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  Text(
                    _getBcsScoreLabel(bcsScore),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  Text(
                    'Body Condition Score',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.8),
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

  Widget _buildInformationCard(List<String> bcsInfo) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Assessment Details',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            ...bcsInfo.asMap().entries.map((entry) {
              int index = entry.key;
              String info = entry.value;
              return _buildAnimatedBulletPoint(info, index);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(Map<String, List<String>> suggestions) {
    if (suggestions.isEmpty) {
    return Container(
      width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
                        colors: [Color(0xFF6B86C9), Color(0xFF8BA3E7)],
                      ),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Health Recommendations',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Personalized care guidance',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFF64748B),
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No specific recommendations available for this BCS score and animal type.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6B86C9), Color(0xFF8BA3E7)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Text(
                  'Health Recommendations',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Personalized care guidance',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            ...suggestions.entries.map((entry) {
              String category = entry.key;
              List<String> items = entry.value;
              return _buildCategorySection(category, items);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<String> items) {
    // Get category icon and color
    IconData categoryIcon;
    Color categoryColor;
    
    switch (category) {
      case 'Nutrition & Management':
        categoryIcon = Icons.restaurant;
        categoryColor = Color(0xFFEF4444);
        break;
      case 'Basic Care':
        categoryIcon = Icons.shield;
        categoryColor = Color(0xFF3B82F6);
        break;
      case 'Exercise & Rehabilitation':
        categoryIcon = Icons.directions_run;
        categoryColor = Color(0xFFF59E0B);
        break;
      case 'Additional Advice':
        categoryIcon = Icons.lightbulb;
        categoryColor = Color(0xFF8B5CF6);
        break;
      case 'Vet Visit':
        categoryIcon = Icons.calendar_today;
        categoryColor = Color(0xFF10B981);
        break;
      default:
        categoryIcon = Icons.info;
        categoryColor = Color(0xFF6B86C9);
    }

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: categoryColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Colored bar at the top
          Container(
            width: double.infinity,
            height: 4,
            decoration: BoxDecoration(
              color: categoryColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        categoryIcon,
                        color: categoryColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      category,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                // Items
                ...items.asMap().entries.map((entry) {
              int index = entry.key;
                  String item = entry.value;
                  return _buildRecommendationItem(item, index, categoryColor);
            }).toList(),
          ],
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationItem(String text, int index, Color categoryColor) {
    // Get specific icon based on text content
    IconData icon;
    
    // Determine icon based on text content
    if (text.toLowerCase().contains('balanced') || text.toLowerCase().contains('diet') || text.toLowerCase().contains('food')) {
      icon = Icons.apple; // Apple icon for nutrition
    } else if (text.toLowerCase().contains('portion') || text.toLowerCase().contains('control')) {
      icon = Icons.balance; // Scale icon for portion control
    } else if (text.toLowerCase().contains('vaccination') || text.toLowerCase().contains('vaccine')) {
      icon = Icons.medical_services; // Medical icon
    } else if (text.toLowerCase().contains('oral') || text.toLowerCase().contains('dental')) {
      icon = Icons.health_and_safety; // Health icon
    } else if (text.toLowerCase().contains('exercise') || text.toLowerCase().contains('walking') || text.toLowerCase().contains('play')) {
      icon = Icons.directions_run; // Running icon
    } else if (text.toLowerCase().contains('vet') || text.toLowerCase().contains('check') || text.toLowerCase().contains('consult')) {
      icon = Icons.local_hospital; // Hospital icon
    } else {
      icon = Icons.info; // Default info icon
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Single icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: categoryColor,
              size: 18,
            ),
          ),
          SizedBox(width: 12),
          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getRecommendationTitle(text),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  text,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRecommendationTitle(String text) {
    // Extract key words to create a title
    if (text.toLowerCase().contains('balanced') || text.toLowerCase().contains('diet')) {
      return 'Balanced Diet';
    } else if (text.toLowerCase().contains('portion') || text.toLowerCase().contains('control')) {
      return 'Portion Control';
    } else if (text.toLowerCase().contains('vaccination') || text.toLowerCase().contains('vaccine')) {
      return 'Vaccination Schedule';
    } else if (text.toLowerCase().contains('oral') || text.toLowerCase().contains('dental')) {
      return 'Oral Health';
    } else if (text.toLowerCase().contains('exercise') || text.toLowerCase().contains('walking')) {
      return 'Daily Activity';
    } else if (text.toLowerCase().contains('social') || text.toLowerCase().contains('behavior')) {
      return 'Socialization';
    } else if (text.toLowerCase().contains('check') || text.toLowerCase().contains('annual')) {
      return 'Routine Check-up';
    } else if (text.toLowerCase().contains('weight') || text.toLowerCase().contains('monitor')) {
      return 'Weight Management';
    } else {
      return 'Health Tip';
    }
  }

  Widget _buildModernInfoPill(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF1E293B),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBulletPoint(String text, int index, {bool isGreen = false}) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(20 * (1 - value), 0),
          child: Opacity(
            opacity: value,
            child: Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isGreen 
                    ? Color(0xFF10B981).withOpacity(0.05)
                    : Color(0xFF3B82F6).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isGreen 
                      ? Color(0xFF10B981).withOpacity(0.1)
                      : Color(0xFF3B82F6).withOpacity(0.1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: EdgeInsets.only(top: 6, right: 12),
                    decoration: BoxDecoration(
                      color: isGreen ? Color(0xFF10B981) : Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
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

  Color _getBcsScoreColor(int score) {
    if (score <= 3) return Color(0xFFEF4444); // Red - Underweight
    if (score <= 5) return Color(0xFF10B981); // Green - Ideal
    return Color(0xFFFF8C00); // Orange - Overweight
  }

  List<Color> _getBcsGradientColors(int score) {
    if (score <= 3) {
      return [Color(0xFFEF4444), Color(0xFFDC2626)]; // Red gradient
    } else if (score <= 5) {
      return [Color(0xFF10B981), Color(0xFF059669)]; // Green gradient
    }
    return [Color(0xFFFF8C00), Color(0xFFEA580C)]; // Orange gradient
  }

  String _getBcsScoreLabel(int score) {
    if (score <= 3) return 'Underweight';
    if (score <= 5) return 'Ideal Weight';
    return 'Overweight';
  }
}