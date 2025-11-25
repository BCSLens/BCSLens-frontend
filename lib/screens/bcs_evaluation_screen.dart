// lib/screens/bcs_evaluation_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/frosted_glass_header.dart';
import '../widgets/gradient_background.dart';
import '../models/pet_record_model.dart';
import '../services/auth_service.dart';
import '../services/pet_detection_service.dart';
import '../utils/app_logger.dart';

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
  String _bcsRange = '4-6'; // BCS range from AI (1-3, 4-6, 7-9)
  String? _bcsReason; // AI analysis reason
  String? _bcsCategory; // BCS category from AI
  final TextEditingController _additionalNotesController =
      TextEditingController();
  bool _isExpert = false;
  bool _isAnalyzing = false;
  late AnimationController _scoreAnimationController;
  late Animation<double> _scoreAnimation;

  // BCS descriptions based on score (1-9) - Official BCS Chart
  final Map<int, List<String>> _bcsDescriptions = {
    1: [
      "Ribs, lumbar vertebrae, pelvic bones and all bony prominences evident from a distance",
      "No discernible body fat",
      "Obvious loss of muscle mass",
    ],
    2: [
      "Ribs, lumbar vertebrae, pelvic bones easily visible",
      "No palpable fat",
      "Some evidence of other bony prominence",
      "Minimal loss of muscle mass",
    ],
    3: [
      "Ribs easily palpated and may be visible with no palpable fat",
      "Tops of lumbar vertebrae visible",
      "Pelvic bones becoming prominent",
      "Obvious waist and abdominal tuck",
    ],
    4: [
      "Ribs easily palpable, with minimal fat covering",
      "Waist easily noted when viewed from above",
      "Abdominal tuck evident",
    ],
    5: [
      "Ribs palpable without excess fat covering",
      "Waist observed behind ribs when viewed from above",
      "Abdomen tucked up when viewed from the side",
    ],
    6: [
      "Ribs palpable with slight excess fat covering",
      "Waist is discernible viewed from above, but is not prominent",
      "Abdominal tuck apparent",
    ],
    7: [
      "Ribs palpable with difficulty",
      "Heavy fat cover",
      "Noticeable fat deposits over lumbar area and base of tail",
      "Waist absent or barely visible",
      "Abdominal tuck may be present",
    ],
    8: [
      "Ribs not palpable under very heavy fat cover, or palpable only with significant pressure",
      "Heavy fat deposits over lumbar area and base of tail",
      "Waist absent",
      "No abdominal tuck",
      "Obvious abdominal distention may be present",
    ],
    9: [
      "Massive fat deposits over thorax, spine and base of tail",
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
      AppLogger.log('🔍 Starting BCS prediction with AI...');
      
      // Get image paths from pet record
      final leftImage = widget.petRecord.leftViewImagePath;
      final rightImage = widget.petRecord.rightViewImagePath;
      final backImage = widget.petRecord.backViewImagePath;
      final topImage = widget.petRecord.topViewImagePath;

      // Validate all required images are present
      if (leftImage == null || rightImage == null || 
          backImage == null || topImage == null) {
        throw Exception('Missing required images. Please capture all 4 views (left, right, back, top)');
      }

      AppLogger.log('📸 Image paths:');
      AppLogger.log('  Left: $leftImage');
      AppLogger.log('  Right: $rightImage');
      AppLogger.log('  Back: $backImage');
      AppLogger.log('  Top: $topImage');

      // Call AI service for BCS prediction
      final bcsResult = await AIService.predictBCS(
        leftImagePath: leftImage,
        rightImagePath: rightImage,
        backImagePath: backImage,
        topImagePath: topImage,
      );

      if (bcsResult != null) {
        final bcsCategory = bcsResult['bcs_category'] as String? ?? 'IDEAL';
        final bcsRange = bcsResult['bcs_range'] as String?; // may be null
        final bcsScore = bcsResult['bcs_score'] as int? ?? 5; // for internal use
        
        AppLogger.log('✅ BCS prediction successful!');
        AppLogger.log('📊 BCS Category: $bcsCategory');
        AppLogger.log('📊 BCS Range: ${bcsRange ?? '(derived)'}');
        AppLogger.log('📊 Mapped Score: $bcsScore (internal)');

      setState(() {
          _bcsScore = bcsScore;
          _bcsRange = bcsRange ?? _scoreToRange(bcsScore); // Store explicit or derived range
          _bcsReason = null; // Flask doesn't send reason
          _bcsCategory = bcsCategory.toLowerCase();
          widget.petRecord.bcs = bcsScore; // For internal use
          widget.petRecord.bcsRange = _bcsRange; // Store range (explicit or derived)
        _isAnalyzing = false;
      });

      // Start animation after AI analysis
      _scoreAnimationController.forward();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('BCS Range: ${_scoreToRange(bcsScore)} - $bcsCategory'),
            backgroundColor: Colors.green[400],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception('Failed to get BCS prediction from AI');
      }
    } catch (e) {
      AppLogger.log('❌ AI analysis error: $e');
      setState(() {
        _isAnalyzing = false;
      });

      // Show error to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error analyzing images: ${e.toString()}'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 5),
        ),
      );

      // Fallback to default score if prediction fails
      setState(() {
        _bcsScore = 5;
        widget.petRecord.bcs = 5;
      });
      
      _scoreAnimationController.forward();
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


  void _goToNextStep() {
    // Update pet record with BCS score and range
    widget.petRecord.bcs = _bcsScore; // For internal use
    widget.petRecord.bcsRange = _bcsRange; // Store range for backend

    // Only save additional notes if user is expert
    if (_isExpert && _additionalNotesController.text.isNotEmpty) {
      widget.petRecord.additionalNotes = _additionalNotesController.text;
    }

    // Navigate to the pet details screen
    Navigator.pushNamed(context, '/pet-details', arguments: widget.petRecord);
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
    // Color based on score (new ranges: 1-3, 4-5, 6-9)
    Color getScoreColor(int score) {
      if (score <= 3) return Color(0xFF3B82F6); // Blue for underweight
      if (score <= 5) return Color(0xFF10B981); // Green for ideal
      return Color(0xFFEF4444); // Red for overweight
    }

    // Category from backend if present; fallback from score
    String getCategoryText() {
      if (_bcsCategory != null && _bcsCategory!.isNotEmpty) {
        return _bcsCategory![0].toUpperCase() + _bcsCategory!.substring(1);
      }
      if (_bcsScore <= 3) return 'Too Thin';
      if (_bcsScore <= 5) return 'Ideal';
      return 'Obese';
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
          
          // Score Display Card - Show single score from AI
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
                      // Show single score
                      Text(
                        _bcsScore.toString(),
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
                          getCategoryText(),
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
              'Adjust Score',
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

  Widget _buildAIReasonCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFF6B86C9).withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
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
                  color: Color(0xFF6B86C9).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.psychology,
                  color: Color(0xFF6B86C9),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Analysis',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF1E293B),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_bcsCategory != null && _bcsCategory != 'unknown')
                      Text(
                        _bcsCategory!.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF6B86C9),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _bcsReason ?? 'No analysis available',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF475569),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Get list of BCS scores from range string
  List<int> _getBCSScoresFromRange(String range) {
    if (range == '1-3') return [1, 2, 3];
    if (range == '4-5') return [4, 5];
    if (range == '6-9') return [6, 7, 8, 9];
    // Backward compatibility (old ranges)
    if (range == '4-6') return [4, 5, 6];
    if (range == '7-9') return [7, 8, 9];
    return [5]; // default
  }

  // Map a single score to its range bucket string
  String _scoreToRange(int score) {
    if (score <= 3) return '1-3';
    if (score <= 5) return '4-5';
    return '6-9';
  }

  Widget _buildBCSInfoCard() {
    // Derive range from the single BCS score
    final String rangeFromScore = _scoreToRange(_bcsScore);
    // Get all scores in that derived range
    List<int> scoresInRange = _getBCSScoresFromRange(rangeFromScore);
    
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
                  'BCS Information for Range $rangeFromScore',
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
          
          // Display descriptions for all scores in the range
          ...scoresInRange.map((score) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFF6B86C9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'BCS $score',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF6B86C9),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Descriptions for this score
                ..._bcsDescriptions[score]!
              .map((description) => _buildBulletPoint(description))
              .toList(),
                
                // Add spacing between scores (except last one)
                if (score != scoresInRange.last) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 16),
                ],
              ],
            );
          }).toList(),
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

  // Helper method to check if user has unsaved data
  bool _hasUnsavedData() {
    // Check if there's any data from add_record page (image, prediction)
    return widget.petRecord.frontViewImagePath != null ||
           widget.petRecord.predictedAnimal != null ||
           widget.petRecord.predictionConfidence != null;
  }

  // Show confirmation dialog
  Future<bool> _showExitConfirmation() async {
    if (!_hasUnsavedData()) return true;
    
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
                    'Leave without saving?',
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
                    'You have unsaved BCS evaluation. Are you sure you want to leave?',
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
                            'Cancel',
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
                      
                      // Leave Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFEF4444),
                                Color(0xFFDC2626),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFFEF4444).withOpacity(0.3),
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
                              'Leave',
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
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFD0E3F5), // สีฟ้าอ่อนมาก (ล่างสุด) เพื่อให้ตรงกับ gradient
        body: GradientBackground(
          child: SafeArea(
          child: Column(
            children: [
              // Modern Header
                FrostedGlassHeader(
                  title: 'BCS Evaluation',
                  subtitle: 'Step 3: Body Condition Assessment',
                  leadingWidget: HeaderBackButton(
                    onPressed: () {
                      // Pop ไปหน้าก่อนหน้าโดยไม่ต้องแสดง modal confirm
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              
              SizedBox(height: 20),
              
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
                      
                      // AI Analysis Reason Card (if available)
                      if (_bcsReason != null && _bcsReason!.isNotEmpty) ...[
                        _buildAIReasonCard(),
                        const SizedBox(height: 24),
                      ],
                      
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
        onAddRecordsTap: () {
          // Do nothing, already on add record screen
        },
      ),
    );
  }
}
