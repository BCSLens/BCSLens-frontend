import 'package:flutter/material.dart';
import 'dart:io';
import '../widgets/bottom_nav_bar.dart';
import '../models/pet_record_model.dart';

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

  // Enhanced suggestions based on BCS score
  final Map<int, List<String>> _bcsSuggestions = {
    1: [
      "Immediate veterinary consultation required",
      "Increase caloric intake with high-quality food",
      "Monitor weight gain progress weekly",
    ],
    2: [
      "Consult veterinarian for feeding plan",
      "Increase portion sizes gradually",
      "Regular health monitoring needed",
    ],
    3: [
      "Slight increase in food portions",
      "Monitor body condition weekly",
      "Maintain regular exercise routine",
    ],
    4: [
      "Continue current feeding routine",
      "Regular exercise is beneficial",
      "Monitor weight stability",
    ],
    5: [
      "Maintain current diet & exercise routine",
      "Feed high-quality food with proper portion control",
      "Provide daily interactive play sessions",
    ],
    6: [
      "Slight reduction in daily food portions",
      "Increase exercise frequency",
      "Monitor weight weekly",
    ],
    7: [
      "Reduce daily caloric intake by 10-15%",
      "Increase exercise duration and intensity",
      "Consider veterinary weight management plan",
    ],
    8: [
      "Veterinary consultation for weight loss plan",
      "Significant caloric restriction needed",
      "Supervised exercise program recommended",
    ],
    9: [
      "Immediate veterinary intervention required",
      "Strict weight management program essential",
      "Regular health monitoring critical",
    ],
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

  void _navigateToRecords() {
    Navigator.pushReplacementNamed(context, '/records');
  }

  @override
  Widget build(BuildContext context) {
    final int bcsScore = widget.petRecord.bcs ?? 5;
    final List<String> bcsInfo = _bcsDescriptions[bcsScore] ?? [];
    final List<String> suggestions = _bcsSuggestions[bcsScore] ?? [];

    return Scaffold(
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
                              
                              // BCS Score Card
                              _buildBcsScoreCard(bcsScore),
                              SizedBox(height: 24),
                              
                              // Information Card
                              _buildInformationCard(bcsInfo),
                              SizedBox(height: 24),
                              
                              // Suggestions Card
                              if (suggestions.isNotEmpty)
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
          onPressed: _navigateToRecords,
          backgroundColor: Color(0xFF6B86C9),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          label: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Done',
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
        onItemTapped: _onItemTapped,
        onAddRecordsTap: () {
          Navigator.pushReplacementNamed(context, '/add-record');
        },
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFFE2E8F0)),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            
            // Title
            Expanded(
              child: Center(
                child: Text(
                  '${widget.petRecord.name}\'s Health Report',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF7B8EB5),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            
            // Share button
            GestureDetector(
              onTap: () {
                // Implement share functionality
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFFE2E8F0)),
                ),
                child: Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: Color(0xFF64748B),
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
                  
                  // Large BCS Score Display
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
                        '$bcsScore',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 48,
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

  Widget _buildSuggestionsCard(List<String> suggestions) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10B981).withOpacity(0.05),
            Color(0xFF059669).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Color(0xFF10B981).withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF10B981).withOpacity(0.1),
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
                    color: Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lightbulb_outline_rounded,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Health Recommendations',
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
            
            ...suggestions.asMap().entries.map((entry) {
              int index = entry.key;
              String suggestion = entry.value;
              return _buildAnimatedBulletPoint(suggestion, index, isGreen: true);
            }).toList(),
          ],
        ),
      ),
    );
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
    if (score >= 4 && score <= 6) return Color(0xFF10B981); // Green - Ideal
    return Color(0xFFFF8C00); // Orange - Overweight
  }

  List<Color> _getBcsGradientColors(int score) {
    if (score <= 3) {
      return [Color(0xFFEF4444), Color(0xFFDC2626)]; // Red gradient
    } else if (score >= 4 && score <= 6) {
      return [Color(0xFF10B981), Color(0xFF059669)]; // Green gradient
    }
    return [Color(0xFFFF8C00), Color(0xFFEA580C)]; // Orange gradient
  }

  String _getBcsScoreLabel(int score) {
    if (score <= 3) return 'Underweight';
    if (score >= 4 && score <= 6) return 'Ideal Weight';
    return 'Overweight';
  }
}