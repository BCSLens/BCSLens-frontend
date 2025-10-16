import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/group_service.dart';

class SpecialCareScreen extends StatefulWidget {
  const SpecialCareScreen({Key? key}) : super(key: key);

  @override
  State<SpecialCareScreen> createState() => _SpecialCareScreenState();
}

class _SpecialCareScreenState extends State<SpecialCareScreen> with TickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  List<Map<String, dynamic>> _specialCarePets = [];
  List<Map<String, dynamic>> _allPets = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'All';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _loadSpecialCarePets();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecialCarePets() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get groups data (same as records_screen)
      final groupsData = await _groupService.getGroups();
      _allPets.clear();

      print('🔍 Special Care API Response: $groupsData');

      // Process groups and extract pets (exactly like records_screen)
      for (final group in groupsData) {
        final String groupId = group['_id'];
        final String groupName = group['group_name'] ?? 'Unknown Group';
        
        // Extract pets from group data if they exist
        List<Map<String, dynamic>> pets = [];
        if (group.containsKey('pets') && group['pets'] is List) {
          pets = (group['pets'] as List).cast<Map<String, dynamic>>();
        }

        for (final pet in pets) {
          print('🐾 Processing pet: ${pet['name']} with records: ${pet['records']}');
          
          // Get latest record for BCS score (exactly like records_screen)
          int bcsScore = 5; // default
          String weightDisplay = 'N/A';
          
          if (pet['records'] != null && (pet['records'] as List).isNotEmpty) {
            final latestRecord = (pet['records'] as List).last;
            
            if (latestRecord['score'] != null) {
              bcsScore = int.tryParse(latestRecord['score'].toString()) ?? 5;
            }
            
            if (latestRecord['weight'] != null) {
              weightDisplay = '${latestRecord['weight']}';
            }
          }

          // For testing: add some demo BCS scores if no records exist
          if (pet['records'] == null || (pet['records'] as List).isEmpty) {
            // Demo data: assign some test BCS scores for special care demonstration
            if (pet['name'] == 'hallo') {
              // Assign different BCS scores for demo based on pet ID
              if (pet['_id'].toString().endsWith('5483')) {
                bcsScore = 2; // Underweight
                weightDisplay = '12';
              }
              if (pet['_id'].toString().endsWith('5486')) {
                bcsScore = 8; // Overweight  
                weightDisplay = '35';
              }
              if (pet['_id'].toString().endsWith('5489')) {
                bcsScore = 3; // Underweight
                weightDisplay = '15';
              }
              if (pet['_id'].toString().endsWith('548c')) {
                bcsScore = 9; // Severely overweight
                weightDisplay = '40';
              }
            }
          }

          _allPets.add({
            'id': pet['_id'] ?? '',
            'name': pet['name'] ?? 'Unknown',
            'breed': pet['breed'] ?? 'Mixed',
            'age_years': pet['age_years'] ?? 0,
            'age_months': pet['age_months'] ?? 0,
            'gender': pet['gender'] ?? 'Unknown',
            'weight': weightDisplay,
            'bcs': bcsScore,
            'species': pet['species'] ?? 'dog',
            'groupName': groupName,
            'groupId': groupId,
            'image_url': pet['image_url'],
            'records': pet['records'] ?? [],
          });
          
          print('✅ Added pet: ${pet['name']} with BCS: $bcsScore');
        }
      }

      print('📊 Total pets loaded: ${_allPets.length}');
      
      // Filter pets that need special care (BCS <= 3 or BCS >= 8)
      _filterSpecialCarePets();
      
      print('🚨 Special care pets found: ${_specialCarePets.length}');

      setState(() {
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      print('Error loading special care pets: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load pets data. Please try again.';
      });
    }
  }

  void _filterSpecialCarePets() {
    _specialCarePets = _allPets.where((pet) {
      int bcs = pet['bcs'] as int;
      
      switch (_selectedFilter) {
        case 'Underweight':
          return bcs <= 3;
        case 'Overweight':
          return bcs >= 7; // เปลี่ยนจาก 8 เป็น 7
        case 'All':
        default:
          return bcs <= 3 || bcs >= 7; // เปลี่ยนจาก 8 เป็น 7
      }
    }).toList();

    // Sort by severity (extreme scores first)
    _specialCarePets.sort((a, b) {
      int bcsA = a['bcs'] as int;
      int bcsB = b['bcs'] as int;
      
      // Calculate distance from ideal weight (5)
      int severityA = (bcsA - 5).abs();
      int severityB = (bcsB - 5).abs();
      
      return severityB.compareTo(severityA);
    });
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
      Navigator.pushReplacementNamed(context, '/records');
        break;
      case 1:
        // History - for now do nothing, already on special care
        break;
      case 2:
        // Already on Special Care screen
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
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
            SizedBox(height: 20),
            _buildFilterTabs(),
            SizedBox(height: 16),
            _buildStatsCards(),
            SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _specialCarePets.isEmpty
                          ? _buildEmptyState()
                          : _buildPetsList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2,
        onItemTapped: _onItemTapped,
        onAddRecordsTap: () {
          Navigator.pushReplacementNamed(context, '/add-record');
        },
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
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                Expanded(
                  child: Text(
                    'Special Care',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: _loadSpecialCarePets,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Pets that need special attention',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: ['All', 'Underweight', 'Overweight'].map((filter) {
          bool isSelected = _selectedFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                  _filterSpecialCarePets();
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? Color(0xFF6B86C9) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  filter,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsCards() {
    int underweightCount = _allPets.where((pet) => (pet['bcs'] as int) <= 3).length;
    int overweightCount = _allPets.where((pet) => (pet['bcs'] as int) >= 7).length; // เปลี่ยนจาก 8 เป็น 7
    int totalSpecialCare = underweightCount + overweightCount;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Alert',
              totalSpecialCare.toString(),
              Icons.warning_amber_rounded,
              Color(0xFFEF4444),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Underweight',
              underweightCount.toString(),
              Icons.trending_down,
              Color(0xFF3B82F6),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Overweight',
              overweightCount.toString(),
              Icons.trending_up,
              Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF6B86C9)),
          SizedBox(height: 16),
          Text(
            'Loading special care pets...',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Color(0xFFEF4444),
            ),
            SizedBox(height: 16),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Please try again later',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadSpecialCarePets,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6B86C9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.pets,
                size: 64,
                color: Color(0xFF10B981),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'All pets are healthy! 🎉',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'No pets currently need special care.\nAll BCS scores are in the healthy range.',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetsList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 24),
        itemCount: _specialCarePets.length,
        itemBuilder: (context, index) {
          return _buildSpecialCarePetCard(_specialCarePets[index], index);
        },
      ),
    );
  }

  Widget _buildSpecialCarePetCard(Map<String, dynamic> pet, int index) {
    int bcs = pet['bcs'] as int;
    bool isUnderweight = bcs <= 3;
    
    Color statusColor = isUnderweight ? Color(0xFF3B82F6) : Color(0xFFF59E0B);
    String statusText = isUnderweight ? 'Underweight' : 'Overweight';
    IconData statusIcon = isUnderweight ? Icons.trending_down : Icons.trending_up;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status badge
            Row(
              children: [
                // Pet avatar
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6B86C9), Color(0xFF8BA3E7)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    pet['species'] == 'cat' ? Icons.pets : Icons.pets,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pet['name'],
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        '${pet['breed']} • ${pet['groupName']}',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Pet details
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem('Weight', '${pet['weight']} kg'),
                ),
                Expanded(
                  child: _buildDetailItem('Age', '${pet['age_years']}y ${pet['age_months']}m'),
                ),
                Expanded(
                  child: _buildDetailItem('BCS Score', bcs.toString()),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Care recommendations
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, size: 16, color: statusColor),
                      SizedBox(width: 6),
                      Text(
                        'Care Recommendations',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    _getCareRecommendation(bcs),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/history',
                        arguments: {
                          'pet': pet,
                          'groupName': pet['groupName'],
                        },
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: statusColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'View History',
                      style: TextStyle(color: statusColor),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate to add record for this pet
                      Navigator.pushNamed(context, '/add-record');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Add Record',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  String _getCareRecommendation(int bcs) {
    if (bcs <= 2) {
      return 'Severely underweight. Consult veterinarian immediately. Increase caloric intake and monitor closely.';
    } else if (bcs == 3) {
      return 'Underweight. Increase food portions and consider high-calorie diet. Regular vet check-ups recommended.';
    } else if (bcs == 7) {
      return 'Slightly overweight. Monitor food intake, increase exercise, and consider portion control.';
    } else if (bcs == 8) {
      return 'Overweight. Reduce portions, increase exercise, and consider weight management diet.';
    } else if (bcs >= 9) {
      return 'Severely overweight. Urgent veterinary consultation needed. Strict diet and exercise plan required.';
    }
    return 'Monitor weight regularly and maintain current care routine.';
  }
}