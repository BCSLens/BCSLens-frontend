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

class _BcsReviewScreenState extends State<BcsReviewScreen> {
  int _selectedIndex = 0; // Records tab should be selected
  bool _isFavorite = true;

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

  // Suggestions based on BCS score
  final Map<int, List<String>> _bcsSuggestions = {
    5: [
      "Maintain current diet & exercise routine",
      "Feed high-quality cat food with proper portion control",
      "Provide daily interactive play (e.g., wand toys, laser pointer)",
    ],
    // Add other BCS suggestions as needed
  };

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
    // Get appropriate BCS information
    final int bcsScore = widget.petRecord.bcs ?? 5;
    final List<String> bcsInfo = _bcsDescriptions[bcsScore] ?? [];
    final List<String> suggestions = _bcsSuggestions[bcsScore] ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7B8EB5)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          '${widget.petRecord.name}\'s BCS Score',
          style: const TextStyle(
            color: Color(0xFF7B8EB5),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Color(0xFF7B8EB5)),
            onPressed: () {
              // Implement share functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pet profile image (circular)
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        margin: const EdgeInsets.only(top: 16, bottom: 20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: widget.petRecord.frontViewImagePath != null
                                ? FileImage(File(widget.petRecord.frontViewImagePath!))
                                : const AssetImage('assets/images/default_pet.png') as ImageProvider,
                            fit: BoxFit.cover,
                          ),
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Pet name and favorite star
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.petRecord.name ?? 'Pet',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _toggleFavorite,
                          child: Icon(
                            _isFavorite ? Icons.star : Icons.star_border,
                            color: _isFavorite ? Colors.amber : Colors.grey,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Pet details in horizontal scrollable row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildInfoPill('Age', '${widget.petRecord.age ?? "Unknown"}'),
                          const SizedBox(width: 10),
                          _buildInfoPill('Breed', widget.petRecord.breed ?? 'Unknown'),
                          const SizedBox(width: 10),
                          _buildInfoPill('Gender', widget.petRecord.gender ?? 'Unknown'),
                          const SizedBox(width: 10),
                          _buildInfoPill('Weight', widget.petRecord.weight ?? 'Unknown'),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // BCS Score display
                    Row(
                      children: [
                        const Text(
                          'BCS Score',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getBcsScoreColor(bcsScore),
                          ),
                          child: Center(
                            child: Text(
                              '$bcsScore',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Information section
                    const Text(
                      'Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // BCS description bullet points
                    ...bcsInfo.map((info) => _buildBulletPoint(info)).toList(),
                    
                    const SizedBox(height: 24),
                    
                    // Suggestions section
                    if (suggestions.isNotEmpty) ...[
                      const Text(
                        'Suggestions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      ...suggestions.map((suggestion) => _buildBulletPoint(suggestion)).toList(),
                      
                      const SizedBox(height: 24),
                    ],
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          // Done button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: _navigateToRecords,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B86C9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onAddRecordsTap: () {
          Navigator.pushReplacementNamed(context, '/add-record');
        },
      ),
    );
  }
  
  Widget _buildInfoPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getBcsScoreColor(int score) {
    if (score <= 3) return Colors.orange;
    if (score >= 4 && score <= 6) return const Color(0xFF7BC67E); // Green color matching Figma
    return Colors.orange; // 7-9 is also concerning (overweight)
  }
}