import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../models/pet_record_model.dart';

class BcsEvaluationScreen extends StatefulWidget {
  final PetRecord petRecord;

  const BcsEvaluationScreen({Key? key, required this.petRecord})
    : super(key: key);

  @override
  State<BcsEvaluationScreen> createState() => _BcsEvaluationScreenState();
}

class _BcsEvaluationScreenState extends State<BcsEvaluationScreen> {
  int _selectedIndex = 1;
  int _bcsScore = 5; // Default BCS score
  final TextEditingController _additionalNotesController =
      TextEditingController();

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
    // Initialize with existing BCS if available
    if (widget.petRecord.bcs != null) {
      _bcsScore = widget.petRecord.bcs!;
    }
  }

  @override
  void dispose() {
    _additionalNotesController.dispose();
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

    // Save additional notes if needed
    // If you want to save the additional notes, you would need to add a field to your PetRecord model
    // For example: widget.petRecord.additionalNotes = _additionalNotesController.text;

    // Navigate to the pet details screen
    Navigator.pushNamed(context, '/pet-details', arguments: widget.petRecord);
  }

  void _goBack() {
    // Save current state before going back
    widget.petRecord.bcs = _bcsScore;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Add Records at top
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

              // Line separator
              const SizedBox(height: 40),
              Container(height: 1, color: Colors.grey[300]),

              // Main Content
              const SizedBox(height: 27),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step Indicator
                    Text(
                      'Step 3 of 4',
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
                      'Evaluate your pet\'s Body Condition Score',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF333333),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // BCS Slider
                    Text(
                      'Body Condition Score',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF333333),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // BCS Value Display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Center(
                        child: Text(
                          '$_bcsScore',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                      ),
                    ),

                    // BCS Slider
                    Slider(
                      value: _bcsScore.toDouble(),
                      min: 1,
                      max: 9,
                      divisions: 8,
                      label: _bcsScore.toString(),
                      activeColor: Color(0xFF6B86C9),
                      onChanged: (double value) {
                        _updateBcsScore(value.round());
                      },
                    ),

                    const SizedBox(height: 16),

                    // BCS Description
                    Text(
                      'BCS Information for Rating $_bcsScore',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF333333),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // BCS Bullet Points
                    ..._bcsDescriptions[_bcsScore]!
                        .map(
                          (description) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    description,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      color: Color(0xFF333333),
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),

                    const SizedBox(height: 24),

                    // Additional Notes
                    Text(
                      'Additional',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF333333),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Additional Notes Text Field
                    TextField(
                      controller: _additionalNotesController,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Color(0xFF6B86C9)),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        hintText: 'Add additional observations...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      minLines: 3,
                      maxLines: 5,
                    ),

                    const SizedBox(height: 32),

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
                              padding: EdgeInsets.symmetric(vertical: 12),
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
                              padding: EdgeInsets.symmetric(vertical: 12),
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
              const SizedBox(height: 40),
            ],
          ),
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
