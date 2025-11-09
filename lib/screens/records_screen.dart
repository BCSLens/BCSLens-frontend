// lib/screens/records_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import '../widgets/bottom_nav_bar.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../services/pet_service.dart';
import '../models/pet_record_model.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({Key? key}) : super(key: key);

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _showAddGroupForm = false;
  bool _showAddPetForm = false;
  bool _showFilterOptions = false;
  String _selectedGroupId = '';
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // Animation controllers
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  // Search and filter variables
  String _searchQuery = '';
  int? _bcsScoreFilter; // null = All, otherwise exact BCS score 1-9

  // State variables for data loading
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _filteredGroups = [];
  Map<String, List<Map<String, dynamic>>> _groupPets = {};
  Map<String, List<Map<String, dynamic>>> _filteredGroupPets = {};

  // Expanded state for groups
  final Map<String, bool> _expandedGroups = {};
  

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _headerAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOut),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerAnimationController, curve: Curves.elasticOut));

    _loadData();
    _searchController.addListener(_onSearchChanged);
    
    // Start animations
    _headerAnimationController.forward();
    _cardAnimationController.forward();
    
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _petNameController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty && _bcsScoreFilter == null) {
      _filteredGroups = List.from(_groups);
      _filteredGroupPets = Map.from(_groupPets);
      return;
    }

    final Map<String, List<Map<String, dynamic>>> newFilteredGroupPets = {};
    final List<Map<String, dynamic>> newFilteredGroups = [];

    for (final group in _groups) {
      final String groupId = group['_id'];
      final String groupName = group['group_name'].toLowerCase();
      final List<Map<String, dynamic>> pets = _groupPets[groupId] ?? [];

      final List<Map<String, dynamic>> filteredPets = pets.where((pet) {
        final bool nameMatches = pet['name'] != null &&
                pet['name'].toString().toLowerCase().contains(_searchQuery);

        bool scoreMatches = true;
        final bool isFilteringActive = _bcsScoreFilter != null;
        if (isFilteringActive) {
          scoreMatches = false;
          if (pet['records'] != null && (pet['records'] as List).isNotEmpty) {
            final latestRecord = (pet['records'] as List).last;
            final dynamic rawScore = latestRecord['bcs_score'];
            int? score;
            if (rawScore is num) score = rawScore.toInt();
            else if (rawScore is String) score = int.tryParse(rawScore);

            if (score != null) {
              scoreMatches = score == _bcsScoreFilter;
            } else {
              scoreMatches = false;
            }
          }
        }

        return (_searchQuery.isEmpty || nameMatches) && scoreMatches;
      }).toList();

      if (filteredPets.isNotEmpty || 
          (_searchQuery.isNotEmpty && groupName.contains(_searchQuery))) {
        newFilteredGroups.add(group);
        newFilteredGroupPets[groupId] = filteredPets;
      }
    }

      _filteredGroups = newFilteredGroups;
      _filteredGroupPets = newFilteredGroupPets;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final groupService = GroupService();

      // Get groups data (which already includes pets from the API)
      final groupsData = await groupService.getGroups();
      final Map<String, List<Map<String, dynamic>>> groupPets = {};

      // Process groups and extract pets
      for (final group in groupsData) {
        final String groupId = group['_id'];
        
        // Extract pets from group data if they exist
        List<Map<String, dynamic>> pets = [];
        if (group.containsKey('pets') && group['pets'] is List) {
          pets = (group['pets'] as List)
              .map((pet) => pet as Map<String, dynamic>)
              .toList();
        }
        
        groupPets[groupId] = pets;

        // Initialize expanded state - default to closed
        _expandedGroups[groupId] = false;
      }

      setState(() {
        _groups = groupsData;
        _groupPets = groupPets;
        _isLoading = false;
        _applyFilters();
        
      });
    } catch (e) {
        setState(() {
        _errorMessage = 'Error loading data: $e';
          _isLoading = false;
        });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Already on Home/Records screen
        break;
      case 1:
        // History - for now redirect to special care
      Navigator.pushReplacementNamed(context, '/special-care');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/special-care');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profile');
        break;
    }
  }

  void _handleAddRecordsTap() {
    Navigator.pushNamed(context, '/add-record');
  }

  void _addNewRecordForPet(Map<String, dynamic> pet) {
  final PetRecord newRecord = PetRecord();
  
  newRecord.existingPetId = pet['_id'];
  newRecord.name = pet['name'];
  newRecord.breed = pet['breed'];
  // Build age string from age_years and age_months if available
  final int years = (pet['age_years'] is num) ? (pet['age_years'] as num).toInt() : int.tryParse(pet['age_years']?.toString() ?? '') ?? 0;
  final int months = (pet['age_months'] is num) ? (pet['age_months'] as num).toInt() : int.tryParse(pet['age_months']?.toString() ?? '') ?? 0;
  String ageString;
  if (years > 0 && months > 0) {
    ageString = '$years years $months months';
  } else if (years > 0) {
    ageString = years == 1 ? '1 year' : '$years years';
  } else if (months > 0) {
    ageString = months == 1 ? '1 month' : '$months months';
  } else {
    ageString = 'Unknown';
  }
  newRecord.age = ageString;
  newRecord.gender = pet['gender'];
  newRecord.isSterilized = pet['is_sterilized'];
  newRecord.category = pet['category'];
  newRecord.groupId = pet['group_id'];
    newRecord.isNewRecordForExistingPet = true;

    Navigator.pushNamed(context, '/add-record', arguments: newRecord);
  }

  void _showAddGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.create_new_folder, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text(
              'Add New Group',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: TextField(
            controller: _groupNameController,
            decoration: InputDecoration(
              hintText: 'Enter group name',
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF94A3B8),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF10B981)),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _groupNameController.clear();
            },
            child: Text(
              'Cancel',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _addNewGroup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Create',
              style: TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addNewGroup() async {
    if (_groupNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty')),
      );
      return;
    }

    setState(() {
      _showAddGroupForm = false;
    });

    try {
      final groupService = GroupService();
      await groupService.createGroup(_groupNameController.text);
      _groupNameController.clear();
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating group: $e')),
      );
    }
  }

  void _showAddPetDialog(String groupId, String groupName) {
    setState(() {
      _selectedGroupId = groupId;
      _showAddPetForm = true;
    });
  }

  void _signOut() async {
    await AuthService().signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Get dashboard statistics
  Map<String, int> _getDashboardStats() {
    int totalPets = 0;
    int healthyPets = 0;
    int concernPets = 0;
    int totalRecords = 0;

    for (final pets in _groupPets.values) {
      totalPets += pets.length;
      for (final pet in pets) {
        if (pet['records'] != null) {
          final records = pet['records'] as List;
          totalRecords += records.length;
          
          if (records.isNotEmpty) {
            final latestRecord = records.last;
            // Use bcs_range only - skip if null (N/A)
            String? bcsRange = latestRecord['bcs_range']?.toString();
            if (bcsRange != null) {
              // Convert range to score (middle value) for stats
              int score = 5; // default
              if (bcsRange == '1-3') {
                score = 2;
              } else if (bcsRange == '4-6') {
                score = 5;
              } else if (bcsRange == '7-9') {
                score = 8;
              }
              if (score >= 4 && score <= 6) {
                healthyPets++;
              } else {
                concernPets++;
              }
            }
            // If no bcs_range, don't count in stats (N/A)
          }
        }
      }
    }

    return {
      'totalPets': totalPets,
      'healthyPets': healthyPets,
      'concernPets': concernPets,
      'totalRecords': totalRecords,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              _buildDashboardStats(),
              _buildSearchAndFilter(),
              SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                        : _errorMessage != null
                        ? _buildErrorState()
                        : _filteredGroups.isEmpty
                            ? (_bcsScoreFilter != null || _searchQuery.isNotEmpty
                                ? _buildFilteredEmptyState()
                                : _buildEmptyState())
                            : _buildPetsList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onAddRecordsTap: _handleAddRecordsTap,
      ),
    );
  }

  Widget _buildModernHeader() {
    return SlideTransition(
      position: _headerSlideAnimation,
      child: FadeTransition(
        opacity: _headerFadeAnimation,
        child: ClipRRect(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back! 👋',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF475569),
                            shadows: [
                              Shadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Pet Health Records',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.white.withOpacity(0.8),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Info Button
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.info_outline, color: Color(0xFF6B86C9)),
                            onPressed: () {
                              _showAppGuideDialog();
                            },
                            tooltip: 'App Guide',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardStats() {
    final stats = _getDashboardStats();
    final totalGroups = _groups.length;
    
    return Container(
      margin: EdgeInsets.all(24),
                                child: Row(
                                  children: [
          Expanded(
            child: _buildStatCard(
              'Total Groups',
              totalGroups.toString(),
              Icons.groups,
              Color(0xFF6B86C9),
              Color(0xFF6B86C9).withOpacity(0.1),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Pets',
              stats['totalPets'].toString(),
              Icons.pets,
              Color(0xFF10B981),
              Color(0xFF10B981).withOpacity(0.1),
            ),
          ),
                                  ],
                                ),
    );
  }

  // Helper: Build small info row (for Age, Weight in pet card)
  Widget _buildInfoRowSmall(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: Color(0xFF6B86C9),
        ),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, Color bgColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
                                              children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
                              ),
                            ],
                          ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                                child: Container(
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
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search pets...',
                      hintStyle: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF94A3B8),
                      ),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF6B86C9)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF6B86C9),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF6B86C9).withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.tune, color: Colors.white),
                                                    onPressed: () {
                                                      setState(() {
                      _showFilterOptions = !_showFilterOptions;
                                                      });
                                                    },
                ),
              ),
              SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(Icons.create_new_folder, color: Colors.white),
                  onPressed: _showAddGroupDialog,
                  tooltip: 'Add Group',
                ),
              ),
            ],
          ),
          if (_showFilterOptions) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(20),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BCS Score',
                                                      style: TextStyle(
                      fontFamily: 'Inter',
                                                        fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: (_bcsScoreFilter ?? 5).toDouble(),
                          min: 1,
                          max: 9,
                          divisions: 8,
                          label: _bcsScoreFilter?.toString() ?? 'All',
                          activeColor: Color(0xFF6B86C9),
                          onChanged: (double v) {
                            setState(() {
                              _bcsScoreFilter = v.round();
                              _applyFilters();
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _bcsScoreFilter = null; // reset to All
                            _applyFilters();
                          });
                        },
                        child: Text('Reset'),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('1 (Underweight)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text('9 (Obese)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                              ],
                                            ),
                                          ],
                              ),
                            ),
                        ],
          SizedBox(height: 20),
        ],
      ),
    );
  }



  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B86C9)),
          ),
          SizedBox(height: 16),
          Text(
            'Loading your pets...',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
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
            _errorMessage ?? 'Unknown error',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6B86C9),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Color(0xFF6B86C9).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
                    Icons.pets,
              size: 64,
              color: Color(0xFF6B86C9),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No pets found',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start by adding your first pet to track their health!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _handleAddRecordsTap,
            icon: Icon(Icons.add),
            label: Text('Add Your First Pet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6B86C9),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
                  ),
                ),
              ],
            ),
    );
  }

  // Empty state when filters/search yield no pets
  Widget _buildFilteredEmptyState() {
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
                  color: Color(0xFF6B86C9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.search_off,
                  size: 64,
                  color: Color(0xFF6B86C9),
                ),
              ),
              SizedBox(height: 24),
              Text(
                _bcsScoreFilter != null
                    ? 'No pets found with BCS score ${_bcsScoreFilter}'
                    : 'No pets found for current filters',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Try adjusting your filters or clearing them to view all pets.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _bcsScoreFilter = null;
                    _searchQuery = '';
                    _searchController.clear();
                    _applyFilters();
                  });
                },
                icon: Icon(Icons.clear),
                label: Text('Clear Filters'),
                style: TextButton.styleFrom(
                  foregroundColor: Color(0xFF6B86C9),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPetsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24),
      itemCount: _filteredGroups.length,
      itemBuilder: (context, index) {
        final group = _filteredGroups[index];
        final groupId = group['_id'];
        final pets = _filteredGroupPets[groupId] ?? [];
        
        return _buildGroupCard(group, pets.length);
      },
    );
  }

  Widget _buildGroupCard(Map<String, dynamic> group, int petCount) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.7),  // ขาวโปร่งแสง
            Color(0xFFE8F2FC).withOpacity(0.8),  // ฟ้าอ่อนมาก
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF5B8CC9).withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showGroupBottomSheet(group, petCount),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(20),
            child: Row(
              children: [
              // Group Icon
                Container(
                padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                  color: Color(0xFF6B86C9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pets,
                  color: Color(0xFF6B86C9),
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              
              // Group Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      group['group_name'],
                        style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                      Text(
                      '$petCount ${petCount == 1 ? 'pet' : 'pets'}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
              
              // Arrow Icon
            Icon(
                Icons.keyboard_arrow_up,
                color: Color(0xFF64748B),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernPetCard(Map<String, dynamic> pet, String groupName) {
    String imageUrl = '';

    if (pet['records'] != null && (pet['records'] as List).isNotEmpty) {
      final latestRecord = (pet['records'] as List).last;
      final frontImageUrl = latestRecord['front_image_url'];

      if (frontImageUrl != null && frontImageUrl.toString().isNotEmpty) {
        String originalUrl = frontImageUrl.toString().trim();
        
        // ถ้าเป็น URL เต็มรูปแบบ และไม่ใช่ localhost/old IP → ใช้ตามเดิม
        if (originalUrl.startsWith('http') && 
            !originalUrl.contains('172.20.10.3') && 
            !originalUrl.contains('localhost') && 
            !originalUrl.contains('127.0.0.1')) {
          imageUrl = originalUrl;
        } 
        // ถ้าเป็น URL แบบเก่าหรือ localhost → แปลงเป็น URL ใหม่
        else if (originalUrl.startsWith('http')) {
          String filename = originalUrl.split('/').last;
          // เช็คว่า filename ไม่ว่างและมี extension
          if (filename.isNotEmpty && filename.contains('.')) {
            imageUrl = '${PetService.uploadBaseUrl}/uploads/$filename';
          } else {
            imageUrl = originalUrl;
          }
        } 
        // ถ้าเป็นแค่ filename → สร้าง URL เต็ม
        else {
          // เช็คว่าเป็น filename จริงๆ (มี extension)
          if (originalUrl.contains('.')) {
            imageUrl = '${PetService.uploadBaseUrl}/uploads/$originalUrl';
          } else {
            // ถ้าไม่ใช่ filename อาจเป็น path อื่น
            imageUrl = originalUrl;
          }
        }
      }
    }

    // Get latest record data
    String weightDisplay = 'N/A';
    int? bcsScore; // single score to display on badge

    if (pet['records'] != null && (pet['records'] as List).isNotEmpty) {
      final latestRecord = (pet['records'] as List).last;
      
      if (latestRecord['weight'] != null) {
        weightDisplay = '${latestRecord['weight']}';
      }
      
      // Prefer bcs_score if present; otherwise map from bcs_range
      if (latestRecord['bcs_score'] != null) {
        final dynamic raw = latestRecord['bcs_score'];
        if (raw is num) bcsScore = raw.toInt();
        else if (raw is String) bcsScore = int.tryParse(raw);
      } else if (latestRecord['bcs_range'] != null) {
        final String range = latestRecord['bcs_range'].toString();
        if (range == '1-3') bcsScore = 2;
        else if (range == '4-5') bcsScore = 5;
        else if (range == '6-9') bcsScore = 8;
        // Backward compatibility with old ranges
        else if (range == '4-6') bcsScore = 5;
        else if (range == '7-9') bcsScore = 8;
      }
    }

    // Determine BCS color based on score
    Color bcsColor = const Color(0xFF64748B); // Default gray for N/A
    if (bcsScore != null) {
      if (bcsScore! <= 3) {
        bcsColor = const Color(0xFF3B82F6); // Blue for underweight
      } else if (bcsScore! <= 5) {
        bcsColor = const Color(0xFF10B981); // Green for ideal
      } else {
        bcsColor = const Color(0xFFEF4444); // Red for overweight
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6B86C9).withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/history',
                arguments: {
                  'pet': pet,
                  'groupName': groupName,
                },
              );
            },
            child: Stack(
              children: [
                // Main Content
                Container(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Pet Image - Large
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: [Color(0xFFE8B349), Color(0xFFD4A044)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
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
                                    return Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFE8B349), Color(0xFFD4A044)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                      ),
                                      child: Icon(
                                        Icons.pets,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 50,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Color(0xFFE8B349), Color(0xFFD4A044)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.pets,
                                    color: Colors.white.withOpacity(0.7),
                                    size: 50,
                                  ),
                                ),
                        ),
                      ),
                      
                      SizedBox(width: 12),
                      
                      // Pet Info - Right Side (ความสูง 120 เท่ากับรูป)
                      Expanded(
                        child: Container(
                          height: 120,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Section: Name & Breed
                              Padding(
                                padding: EdgeInsets.only(right: 70), // เผื่อที่ให้ BCS Badge
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pet['name'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1E293B),
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      pet['breed'] ?? 'Unknown breed',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Middle Section: Age + Weight + Buttons
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.only(right: 70),
                                    child: _buildInfoRowSmall(
                                      Icons.calendar_today,
                                      '${pet['age_years'] ?? 0}y ${pet['age_months'] ?? 0}m',
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  
                                  // Weight + Action Buttons (same line - ชิดขวาเต็มที่)
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.monitor_weight,
                                        size: 15,
                                        color: Color(0xFF6B86C9),
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        '${weightDisplay} kg',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      
                                      Spacer(),
                                      
                                      // Analytics Button (ชิดขวา)
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF8B5CF6).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: InkWell(
                                          onTap: () {
                                            Navigator.pushNamed(
                                              context,
                                              '/history',
                                              arguments: {
                                                'pet': pet,
                                                'groupName': groupName,
                                              },
                                            );
                                          },
                                          child: Icon(
                                            Icons.analytics,
                                            color: Color(0xFF8B5CF6),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      
                                      SizedBox(width: 6),
                                      
                                      // Add Record Button (ชิดขวา)
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF6B86C9).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: InkWell(
                                          onTap: () => _addNewRecordForPet(pet),
                                          child: Icon(
                                            Icons.add,
                                            color: Color(0xFF6B86C9),
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // BCS Badge (ขวาบน) - Positioned
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          bcsColor,
                          bcsColor.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: bcsColor.withOpacity(0.4),
                          blurRadius: 15,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      bcsScore != null ? 'BCS $bcsScore' : 'BCS N/A', // Show single score per request
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGroupBottomSheet(Map<String, dynamic> group, int petCount) {
    final pets = _filteredGroupPets[group['_id']] ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Container(
              padding: EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF6B86C9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.pets,
                      color: Color(0xFF6B86C9),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['group_name'],
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$petCount ${petCount == 1 ? 'pet' : 'pets'}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: pets.isEmpty 
                  ? _buildEmptyGroupState(group)
                  : _buildPetsInGroup(pets, group['group_name']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGroupState(Map<String, dynamic> group) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
              color: Color(0xFF6B86C9).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets,
              size: 64,
              color: Color(0xFF6B86C9),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No pets in this group',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first pet to this group!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/add-record');
            },
            icon: Icon(Icons.add),
            label: Text('Add Pet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6B86C9),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsInGroup(List<Map<String, dynamic>> pets, String groupName) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24),
      itemCount: pets.length,
      itemBuilder: (context, index) {
        final pet = pets[index];
        return _buildModernPetCard(pet, groupName);
      },
    );
  }

  // (removed) _testBCSPrediction - no longer used

  void _showAppGuideDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _AppGuideBottomSheet();
      },
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Color(0xFF6B86C9),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuideStep(String stepNumber, String title, String description, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Step number circle
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Color(0xFF6B86C9),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              stepNumber,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(width: 12),
        // Step content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: Color(0xFF6B86C9)),
                  SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}

// App Guide Bottom Sheet with 2 pages
class _AppGuideBottomSheet extends StatefulWidget {
  @override
  _AppGuideBottomSheetState createState() => _AppGuideBottomSheetState();
}

class _AppGuideBottomSheetState extends State<_AppGuideBottomSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          // Header with close button
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currentPage == 0 ? 'How to Use BCSLens' : 'Body Condition Chart',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Page indicator
          Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPageIndicator(0),
                SizedBox(width: 8),
                _buildPageIndicator(1),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildGuidePage(),
                _buildBCSChartPage(),
              ],
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  TextButton.icon(
                    icon: Icon(Icons.arrow_back),
                    label: Text('Previous'),
                    onPressed: () {
                      _pageController.previousPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  )
                else
                  SizedBox(width: 100),
                
                if (_currentPage < 1)
                  ElevatedButton.icon(
                    icon: Icon(Icons.arrow_forward),
                    label: Text('Next'),
                    onPressed: () {
                      _pageController.nextPage(
                        duration: Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF6B86C9),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Got it!'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      width: _currentPage == index ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: _currentPage == index ? Color(0xFF6B86C9) : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildGuidePage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGuideStepCard('1', 'Add Pet Record', 'Tap the "+" button to add a new pet record', Icons.add_circle_outline, Color(0xFF6B86C9)),
          SizedBox(height: 16),
          _buildGuideStepCard('2', 'Capture Images', 'Take photos from 5 different angles: Front, Back, Left, Right, and Top', Icons.camera_alt, Color(0xFF8B5CF6)),
          SizedBox(height: 16),
          _buildGuideStepCard('3', 'AI Analysis', 'Our AI will analyze the images and calculate the BCS score automatically', Icons.auto_awesome, Color(0xFFF59E0B)),
          SizedBox(height: 16),
          _buildGuideStepCard('4', 'View History', 'Track your pet\'s health progress over time with detailed charts', Icons.show_chart, Color(0xFF10B981)),
          SizedBox(height: 16),
          _buildGuideStepCard('5', 'Get Recommendations', 'Receive personalized care recommendations based on BCS results', Icons.lightbulb_outline, Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _buildGuideStepCard(String number, String title, String description, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 24),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Step $number',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
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

  Widget _buildBCSChartPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Body Condition Scoring System',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Reference guide for assessing your pet\'s body condition',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          SizedBox(height: 24),
          
          // TOO THIN (1-3)
          _buildBCSCategory('TOO THIN', '1-3', Color(0xFF3B82F6)),
          SizedBox(height: 12),
          _buildBCSItem(1, 'Ribs, lumbar vertebrae, pelvic bones and all bony prominences evident from a distance; no discernible body fat; obvious loss of muscle mass.'),
          _buildBCSItem(2, 'Ribs, lumbar vertebrae, pelvic bones easily visible; no palpable fat; some evidence of other bony prominence; minimal loss of muscle mass.'),
          _buildBCSItem(3, 'Ribs easily palpated and may be visible with no palpable fat; tops of lumbar vertebrae visible; pelvic bones becoming prominent; obvious waist and abdominal tuck.'),
          
          SizedBox(height: 24),
          
          // IDEAL (4-5)
          _buildBCSCategory('IDEAL', '4-5', Color(0xFF10B981)),
          SizedBox(height: 12),
          _buildBCSItem(4, 'Ribs easily palpable, with minimal fat covering; waist easily noted when viewed from above; abdominal tuck evident.'),
          _buildBCSItem(5, 'Ribs palpable without excess fat covering; waist observed behind ribs when viewed from above; abdomen tucked up when viewed from the side.'),
          
          SizedBox(height: 24),
          
          // TOO HEAVY (6-9)
          _buildBCSCategory('TOO HEAVY', '6-9', Color(0xFFEF4444)),
          SizedBox(height: 12),
          _buildBCSItem(6, 'Ribs palpable with slight excess fat covering; waist is discernible viewed from above, but is not prominent; abdominal tuck apparent.'),
          _buildBCSItem(7, 'Ribs palpable with difficulty; heavy fat cover; noticeable fat deposits over lumbar area and base of tail; waist absent or barely visible; abdominal tuck may be present.'),
          _buildBCSItem(8, 'Ribs not palpable under very heavy fat cover, or palpable only with significant pressure; heavy fat deposits over lumbar area and base of tail; waist absent; no abdominal tuck; obvious abdominal distention may be present.'),
          _buildBCSItem(9, 'Massive fat deposits over thorax, spine and base of tail; waist and abdominal tuck absent; fat deposits on neck and limbs; obvious abdominal distention.'),
          
          SizedBox(height: 24),
          
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF59E0B).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFF59E0B).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFF59E0B)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Source: Purina Institute - Body Condition System',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBCSCategory(String title, String range, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              range,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBCSItem(int score, String description) {
    Color scoreColor = score <= 3 
        ? Color(0xFF3B82F6) 
        : score <= 5 
            ? Color(0xFF10B981) 
            : Color(0xFFEF4444);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: scoreColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                score.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF475569),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}