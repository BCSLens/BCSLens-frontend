// lib/screens/bcs_evaluation_screen.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../models/pet_record_model.dart';
import '../services/auth_service.dart';

class BcsEvaluationScreen extends StatefulWidget {
  final PetRecord petRecord;

  const BcsEvaluationScreen({Key? key, required this.petRecord})
    : super(key: key);

  @override
  State<BcsEvaluationScreen> createState() => _BcsEvaluationScreenState();
}

class _BcsEvaluationScreenState extends State<BcsEvaluationScreen> with TickerProviderStateMixin {
  int _selectedIndex = 1;
  int _bcsScore = 5; // Default BCS score
  final TextEditingController _additionalNotesController =
      TextEditingController();
  bool _isExpert = false;
  bool _isLoading = false;
  bool _isAnalyzing = false;
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;

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

  @override
  void initState() {
    super.initState();
    // Initialize animation controller
    _scoreAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scoreAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scoreAnimationController,
      curve: Curves.elasticOut,
    ));

    // Check if user is expert
    _isExpert = AuthService().isExpert;

    // Initialize with existing BCS if available
    if (widget.petRecord.bcs != null) {
      _bcsScore = widget.petRecord.bcs!;
    }

    // If user is not an expert, trigger AI analysis
    if (!_isExpert) {
      _analyzeImagesWithAI();
    } else {
      _scoreAnimationController.forward();
    }
  }

  Future<void> _analyzeImagesWithAI() async {
    setState(() {
      _isAnalyzing = true;
    });

    try {
      // This will connect to your backend in the future
      // For now, simulate AI analysis
      await Future.delayed(const Duration(seconds: 2));

      // Simulate a BCS score from AI (random between 3-7)
      final aiScore = 3 + (DateTime.now().millisecond % 5);

      setState(() {
        _bcsScore = aiScore;
        widget.petRecord.bcs = aiScore;
        _isAnalyzing = false;
      });

      // Start animation after AI analysis
      _scoreAnimationController.forward();
    } catch (e) {
      print('AI analysis error: $e');
      setState(() {
        _isAnalyzing = false;
      });

      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing images: $e'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  void dispose() {
    _additionalNotesController.dispose();
    _scoreAnimationController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushNamedAndRemoveUntil(context, '/records', (route) => false);
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/special-care');
    }
  }

  void _updateBcsScore(int value) {
    setState(() {
      _bcsScore = value;
    });
  }

  void _goToNextStep() {
    // Update pet record with BCS score
    widget.petRecord.bcs = _bcsScore;

    // Only save additional notes if user is expert
    if (_isExpert && _additionalNotesController.text.isNotEmpty) {
      widget.petRecord.additionalNotes = _additionalNotesController.text;
    }

    // Navigate to the pet details screen
    Navigator.pushNamed(context, '/pet-details', arguments: widget.petRecord);
  }

  void _goBack() {
    // Save current state before going back
    widget.petRecord.bcs = _bcsScore;
    Navigator.pop(context);
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
                  'Step 3 of 4',
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
                    widthFactor: 0.75, // 3/4 progress
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
            'Evaluate your pet\'s Body Condition Score',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAnalysisCard() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6B86C9).withOpacity(0.05),
              Color(0xFF8BA3E7).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFF6B86C9).withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6B86C9), Color(0xFF8BA3E7)],
                ),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                  ),
                  Icon(
                    Icons.pets,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'AI is analyzing your pet images...',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This may take a few moments',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBCSScoreCard() {
    Color getScoreColor(int score) {
      if (score <= 3) return Color(0xFF3B82F6); // Blue for underweight
      if (score <= 6) return Color(0xFF10B981); // Green for ideal
      return Color(0xFFEF4444); // Red for overweight
    }

    String getScoreCategory(int score) {
      if (score <= 3) return 'Underweight';
      if (score <= 6) return 'Ideal Weight';
      return 'Overweight';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Body Condition Score',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF1E293B),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          
          // Score Display Card
          AnimatedBuilder(
            animation: _scoreAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * _scoreAnimation.value),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: getScoreColor(_bcsScore).withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: getScoreColor(_bcsScore).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$_bcsScore',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 48,
                          fontWeight: FontWeight.w800,
                          color: getScoreColor(_bcsScore),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: getScoreColor(_bcsScore).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          getScoreCategory(_bcsScore),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: getScoreColor(_bcsScore),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // BCS Slider - only enabled for expert users
          if (_isExpert) ...[
            Text(
              'Adjust Score (Expert Mode)',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF64748B),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Color(0xFF6B86C9),
                inactiveTrackColor: Colors.grey[300],
                trackHeight: 6,
                thumbColor: Color(0xFF6B86C9),
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12),
                overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
                valueIndicatorShape: PaddleSliderValueIndicatorShape(),
                valueIndicatorColor: Color(0xFF6B86C9),
                valueIndicatorTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Slider(
                value: _bcsScore.toDouble(),
                min: 1,
                max: 9,
                divisions: 8,
                label: _bcsScore.toString(),
                onChanged: (double value) {
                  setState(() {
                    _bcsScore = value.round();
                  });
                },
              ),
            ),
          ] else ...[
            // AI Evaluated label for normal users
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF6B86C9).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Color(0xFF6B86C9).withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.smart_toy,
                    size: 20,
                    color: Color(0xFF6B86C9),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'BCS automatically evaluated by AI',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontStyle: FontStyle.italic,
                      color: Color(0xFF6B86C9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 12),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Color(0xFF6B86C9),
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF475569),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBCSInfoCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF6B86C9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: Color(0xFF6B86C9),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'BCS Information for Rating $_bcsScore',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF1E293B),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._bcsDescriptions[_bcsScore]!
              .map((description) => _buildBulletPoint(description))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildAdditionalNotesCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_add,
                color: Color(0xFF6B86C9),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Additional Notes',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF1E293B),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _additionalNotesController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xFF6B86C9), width: 2),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.all(16),
                hintText: 'Add expert observations and detailed notes...',
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontFamily: 'Inter',
                ),
              ),
              minLines: 4,
              maxLines: 6,
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF475569),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isAnalyzing ? null : _goToNextStep,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isAnalyzing ? Colors.grey[300] : Color(0xFF6B86C9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: _isAnalyzing ? 0 : 4,
            shadowColor: Color(0xFF6B86C9).withOpacity(0.3),
          ),
          child: _isAnalyzing
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.grey[600]!),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Processing...',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                )
              : Text(
                  'Next Step',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Modern Header
            _buildModernHeader(),
            
            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    
                    // Progress Indicator
                    _buildProgressIndicator(),
                    
                    const SizedBox(height: 32),

                    // Show AI Analysis Card or BCS Score
                    if (_isAnalyzing) ...[
                      _buildAIAnalysisCard(),
                    ] else ...[
                      // BCS Score Card
                      _buildBCSScoreCard(),
                      
                      const SizedBox(height: 24),
                      
                      // BCS Information Card
                      _buildBCSInfoCard(),
                      
                      // Additional Notes - only for expert users
                      if (_isExpert) ...[
                        const SizedBox(height: 24),
                        _buildAdditionalNotesCard(),
                      ],
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Next Button
                    _buildNextButton(),
                    
                    const SizedBox(height: 40),
                  ],
                ),
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