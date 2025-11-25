import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/bottom_nav_bar.dart';
import '../services/group_service.dart';
import '../services/pet_service.dart';
import '../utils/app_logger.dart';

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

      AppLogger.log('🔍 Special Care API Response: $groupsData');

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
          AppLogger.log('🐾 Processing pet: ${pet['name']} with records: ${pet['records']}');
          
        // Get latest record for BCS score (require backend bcs_score)
        int? bcsScore; // only set if present
          String weightDisplay = 'N/A';
          
          if (pet['records'] != null && (pet['records'] as List).isNotEmpty) {
            final latestRecord = (pet['records'] as List).last;
            
            // Prefer bcs_score from backend
            final dynamic rawScore = latestRecord['bcs_score'];
            if (rawScore != null) {
            if (rawScore is num) bcsScore = rawScore.toInt();
            else if (rawScore is String) bcsScore = int.tryParse(rawScore);
            }
            
            if (latestRecord['weight'] != null) {
              weightDisplay = '${latestRecord['weight']}';
            }
          }

        // Skip pets without a valid bcs_score
        if (bcsScore == null) {
          continue;
          }

          _allPets.add({
            'id': pet['_id'] ?? '',
            'name': pet['name'] ?? 'Unknown',
            'breed': pet['breed'] ?? 'Mixed',
            'age_years': pet['age_years'] ?? 0,
            'age_months': pet['age_months'] ?? 0,
            'gender': pet['gender'] ?? 'Unknown',
            'weight': weightDisplay,
          'bcs': bcsScore, // score from backend only
          'species': (pet['species'] ?? 'dog').toString().toLowerCase(),
            'groupName': groupName,
            'groupId': groupId,
            'image_url': pet['image_url'],
            'records': pet['records'] ?? [],
          });
          
          AppLogger.log('✅ Added pet: ${pet['name']} with BCS: $bcsScore');
        }
      }

      AppLogger.log('📊 Total pets loaded: ${_allPets.length}');
      
      // Filter pets that need special care (BCS <= 3 or BCS >= 8)
      _filterSpecialCarePets();
      
      AppLogger.log('🚨 Special care pets found: ${_specialCarePets.length}');

      setState(() {
        _isLoading = false;
      });

      _animationController.forward();
    } catch (e) {
      AppLogger.log('Error loading special care pets: $e');
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
          return bcs >= 6; // use new bucket 6-9
        case 'All':
        default:
          return bcs <= 3 || bcs >= 6; // new bucket 6-9
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
      backgroundColor: Color(0xFFD0E3F5), // สีฟ้าอ่อนมาก (ล่างสุด) เพื่อให้ตรงกับ gradient
      body: Container(
        // Soft blue gradient - อ่อนๆสวยๆ
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5B8CC9), // สีฟ้าเข้ม (บน)
              Color(0xFF7CA6DB), // สีฟ้ากลาง
              Color(0xFFA8C5E8), // สีฟ้าอ่อน
              Color(0xFFD0E3F5), // สีฟ้าอ่อนมาก (ล่าง)
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(),
            SizedBox(height: 20),
            _buildFilterTabs(),
            SizedBox(height: 16),
            _buildStatsCards(),
            SizedBox(height: 20),
            Expanded(
                child: RefreshIndicator(
                  onRefresh: _loadSpecialCarePets,
                  color: Color(0xFF6B86C9),
              child: _isLoading
                  ? _buildLoadingState()
                  : _errorMessage != null
                      ? _buildErrorState()
                      : _specialCarePets.isEmpty
                          ? _buildEmptyState()
                          : _buildPetsList(),
                ),
            ),
          ],
          ),
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
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
              decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3), // แก้วใสๆ
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 25,
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
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 10,
                            ),
                          ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Pets that need special attention',
              style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF475569),
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
            ),
          ),
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
    int underweightCount = _allPets.where((pet) {
      final bcs = pet['bcs'];
      if (bcs is! int) return false;
      return bcs <= 3;
    }).length;
    int overweightCount = _allPets.where((pet) {
      final bcs = pet['bcs'];
      if (bcs is! int) return false;
      return bcs >= 6; // 6-9 bucket
    }).length;
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
    return ListView(
      physics: AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 200),
        Center(
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
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return ListView(
      physics: AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 150),
        Padding(
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
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: 150),
        Padding(
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
      ],
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
    String species = pet['species'] ?? 'dog'; // ต้องตรงกับ default ใน _loadSpecialCarePets
    
    // Debug: ตรวจสอบ species
    AppLogger.log('🐾 Special Care - Pet: ${pet['name']}, Species: $species, BCS: $bcs');
    
    Color statusColor = isUnderweight ? Color(0xFF3B82F6) : Color(0xFFF59E0B);

    // Get image URL
    String imageUrl = _getPetImageUrl(pet);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/history',
          arguments: {
            'pet': pet,
            'groupName': pet['groupName'] ?? 'Group',
          },
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Color(0xFFF8FAFC),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.15),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Top: Image and Info with BCS Badge
            Stack(
              children: [
            Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                    // Pet Image
                Container(
                      width: 140,
                      height: 140,
                  decoration: BoxDecoration(
                        color: Color(0xFFE8B349), // สีเหลืองทอง
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                    ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildPlaceholderImage(species);
                                },
                              )
                            : _buildPlaceholderImage(species),
                  ),
                ),
                    SizedBox(width: 20),
                    
                    // Pet Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                          // Pet Name
                      Text(
                        pet['name'],
                        style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                          SizedBox(height: 16),
                          
                          // Weight
                          _buildInfoRow(
                            Icons.monitor_weight,
                            'Weight',
                            '${pet['weight'] ?? 0}',
                            Colors.grey[700]!,
                          ),
                          SizedBox(height: 12),
                          
                          // Age
                          _buildInfoRow(
                            Icons.calendar_today,
                            'Age',
                            '${pet['age_years'] ?? 0} years old',
                            Colors.grey[700]!,
                      ),
                    ],
                  ),
                ),
                  ],
                ),
                
                // BCS Badge (ตรงมุมขวาบน)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          statusColor,
                          statusColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                        Icon(Icons.favorite, color: Colors.white, size: 18),
                        SizedBox(width: 6),
                      Text(
                          'BCS Score ${pet['bcs'] != null ? pet['bcs'].toString() : 'N/A'}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // BCS Recommendation Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[300]!, width: 1.5),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                      ),
                    ),
                    child: Row(
                    children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            'BCS Level',
                        style: TextStyle(
                          fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                            textAlign: TextAlign.center,
                        ),
                      ),
                        Container(width: 1.5, height: 20, color: Colors.grey[300]),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Condition',
                    style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                    ),
                            textAlign: TextAlign.center,
              ),
            ),
                        Container(width: 1.5, height: 20, color: Colors.grey[300]),
                Expanded(
                          flex: 5,
                          child: Text(
                            'Feeding Recommendation',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                      ),
                            textAlign: TextAlign.center,
                    ),
                  ),
                      ],
                    ),
                  ),
                  // Rows
                  ..._buildBCSRecommendationRows(bcs, species, statusColor),
                ],
                    ),
            ),
          ],
                    ),
                  ),
                ),
    );
  }

  // Helper: Get pet image URL (robust, mirrors history_screen logic)
  String _getPetImageUrl(Map<String, dynamic> pet) {
    final List<dynamic> records = pet['records'] ?? [];
    if (records.isEmpty) return '';
    final latestRecord = records.last;

    // Check multiple possible image fields, prefer front
    final List<String> candidates = [
      'front_image_url',
      'back_image_url',
      'left_image_url',
      'right_image_url',
      'top_image_url',
    ];

    String originalUrl = '';
    for (final key in candidates) {
      final val = latestRecord[key];
      if (val != null && val.toString().trim().isNotEmpty) {
        originalUrl = val.toString().trim();
        break;
      }
    }

    if (originalUrl.isEmpty) return '';

    // If already full URL and not pointing to old hosts → use as is
    if (originalUrl.startsWith('http') &&
        !originalUrl.contains('172.20.10.3') &&
        !originalUrl.contains('localhost') &&
        !originalUrl.contains('127.0.0.1')) {
      return originalUrl;
    }

    // If full URL but old host → convert by filename
    if (originalUrl.startsWith('http')) {
      final filename = originalUrl.split('/').last;
      if (filename.isNotEmpty && filename.contains('.')) {
        return '${PetService.uploadBaseUrl}/upload/$filename';
      }
      return originalUrl;
    }

    // If relative path starting with /upload/ or /uploads/
    if (originalUrl.startsWith('/upload/') || originalUrl.startsWith('/uploads/')) {
      String correctedPath = originalUrl.startsWith('/uploads/') 
          ? originalUrl.replaceFirst('/uploads/', '/upload/')
          : originalUrl;
      return '${PetService.uploadBaseUrl}$correctedPath';
    }

    // If looks like a filename → build full URL
    if (originalUrl.contains('.')) {
      return '${PetService.uploadBaseUrl}/upload/$originalUrl';
    }

    // Fallback to original
    return originalUrl;
  }


  // Helper: Build placeholder image
  Widget _buildPlaceholderImage(String species) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE8B349), Color(0xFFD4A044)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          species == 'cat' ? Icons.pets : Icons.pets,
          color: Colors.white.withOpacity(0.7),
          size: 60,
        ),
      ),
    );
  }

  // Helper: Build info row (Weight, Age)
  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
        Text(
          value,
          style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
          ],
        ),
      ],
    );
  }

  // Helper: Build BCS recommendation rows
  List<Widget> _buildBCSRecommendationRows(int currentBCS, String species, Color highlightColor) {
    List<Map<String, dynamic>> recommendations = _getBCSRecommendations(species);
    
    return recommendations.map((rec) {
      bool isCurrentBCS = rec['bcsRange'].contains(currentBCS);
      
      return Container(
        decoration: BoxDecoration(
          color: isCurrentBCS ? highlightColor.withOpacity(0.08) : Colors.white,
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
        ),
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                rec['bcs'],
          style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrentBCS ? FontWeight.w800 : FontWeight.w600,
                  color: isCurrentBCS ? highlightColor : Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(width: 1.5, height: 40, color: Colors.grey[200]),
            Expanded(
              flex: 2,
              child: Text(
                rec['condition'],
                style: TextStyle(
            fontSize: 12,
                  fontWeight: isCurrentBCS ? FontWeight.w700 : FontWeight.w500,
                  color: isCurrentBCS ? highlightColor : Color(0xFF475569),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Container(width: 1.5, height: 40, color: Colors.grey[200]),
            Expanded(
              flex: 5,
              child: Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  rec['recommendation'],
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isCurrentBCS ? FontWeight.w600 : FontWeight.w400,
                    color: isCurrentBCS ? Color(0xFF1E293B) : Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
          ),
        ),
      ],
        ),
    );
    }).toList();
  }

  // Helper: Get BCS recommendations based on species
  List<Map<String, dynamic>> _getBCSRecommendations(String species) {
    // Normalize species to lowercase
    String normalizedSpecies = species.toLowerCase();
    
    AppLogger.log('📋 Getting BCS recommendations for species: $species (normalized: $normalizedSpecies)');
    
    if (normalizedSpecies == 'cat') {
      return [
        {
          'bcs': '1-3\n(Thin)',
          'condition': 'Underweight',
          'bcsRange': [1, 2, 3],
          'recommendation': 'Provide food with higher energy and protein. May use wet food or prescription diet to help gain weight.',
        },
        {
          'bcs': '4-5\n(Normal)',
          'condition': 'Normal',
          'bcsRange': [4, 5],
          'recommendation': 'Control food quantity to avoid excess. Should include both dry and wet food for body water balance.',
        },
        {
          'bcs': '6-9\n(Obese)',
          'condition': 'Overweight',
          'bcsRange': [6, 7, 8, 9],
          'recommendation': 'Gradually reduce food quantity. Use weight loss food formula with high protein and low fat.',
        },
      ];
    } else {
      // Dog
      return [
        {
          'bcs': '1-3\n(Thin)',
          'condition': 'Underweight',
          'bcsRange': [1, 2, 3],
          'recommendation': 'Increase energy in food. Use high-quality food with sufficient protein and fat. Divide meals into smaller portions.',
        },
        {
          'bcs': '4-5\n(Normal)',
          'condition': 'Normal',
          'bcsRange': [4, 5],
          'recommendation': 'Provide balanced food formula according to age. Control quantity to avoid excess or deficiency.',
        },
        {
          'bcs': '6-9\n(Obese)',
          'condition': 'Overweight',
          'bcsRange': [6, 7, 8, 9],
          'recommendation': 'Limit energy intake. Use weight control food formula. Reduce snacks.',
        },
      ];
  }
  }

}
