// lib/screens/records_screen.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'history_screen.dart';
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
  RangeValues _bcsScoreRange = RangeValues(1, 9);

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
    if (_searchQuery.isEmpty && _bcsScoreRange == const RangeValues(1, 9)) {
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

            bool scoreInRange = true;
            if (pet['records'] != null && (pet['records'] as List).isNotEmpty) {
              final latestRecord = (pet['records'] as List).last;
              if (latestRecord['score'] != null) {
            final int score = int.tryParse(latestRecord['score'].toString()) ?? 5;
            scoreInRange = score >= _bcsScoreRange.start && score <= _bcsScoreRange.end;
          }
        }

            return (_searchQuery.isEmpty || nameMatches) && scoreInRange;
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
  newRecord.age = pet['age'];
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
            final score = int.tryParse(latestRecord['score']?.toString() ?? '5') ?? 5;
            if (score >= 4 && score <= 6) {
              healthyPets++;
            } else {
              concernPets++;
            }
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
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
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
                          ? _buildEmptyState()
                          : _buildPetsList(),
            ),
                                    ],
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
        child: Container(
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                          'Welcome Back! 👋',
                                            style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 4),
                                          Text(
                          'Pet Health Records',
                                            style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                                              fontWeight: FontWeight.bold,
                            color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.notifications_outlined, color: Colors.white),
                                            onPressed: () {
                              // Add notification functionality
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.play_arrow, color: Colors.white),
                                            onPressed: () {
                              _showWelcomeDialog();
                            },
                            tooltip: 'Welcome to Pet Health',
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.logout, color: Colors.white),
                            onPressed: _signOut,
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
    );
  }

  Widget _buildDashboardStats() {
    final stats = _getDashboardStats();
    
    return Container(
      margin: EdgeInsets.all(24),
                                child: Row(
                                  children: [
          Expanded(
            child: _buildStatCard(
              'Total Pets',
              stats['totalPets'].toString(),
              Icons.pets,
              Color(0xFF6B86C9),
              Color(0xFF6B86C9).withOpacity(0.1),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Healthy',
              stats['healthyPets'].toString(),
              Icons.favorite,
              Color(0xFF10B981),
              Color(0xFF10B981).withOpacity(0.1),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Need Care',
              stats['concernPets'].toString(),
              Icons.warning,
              Color(0xFFF59E0B),
              Color(0xFFF59E0B).withOpacity(0.1),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Records',
              stats['totalRecords'].toString(),
              Icons.description,
              Color(0xFF8B5CF6),
              Color(0xFF8B5CF6).withOpacity(0.1),
                                      ),
                                    ),
                                  ],
                                ),
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
                    'BCS Score Range',
                                                      style: TextStyle(
                      fontFamily: 'Inter',
                                                        fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 16),
                  RangeSlider(
                    values: _bcsScoreRange,
                    min: 1,
                    max: 9,
                    divisions: 8,
                    labels: RangeLabels(
                      _bcsScoreRange.start.round().toString(),
                      _bcsScoreRange.end.round().toString(),
                    ),
                    activeColor: Color(0xFF6B86C9),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _bcsScoreRange = values;
                        _applyFilters();
                      });
                    },
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
              color: Colors.white,
        borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
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
        if (frontImageUrl.toString().startsWith('http')) {
          imageUrl = frontImageUrl.toString();
        } else {
          imageUrl = '${PetService.uploadBaseUrl}/uploads/$frontImageUrl';
        }
      }
    }

    // Get latest record data
    String weightDisplay = 'N/A';
    String bcsScore = 'N/A';
    Color bcsColor = Color(0xFF64748B);

    if (pet['records'] != null && (pet['records'] as List).isNotEmpty) {
      final latestRecord = (pet['records'] as List).last;
      
      if (latestRecord['weight'] != null) {
        weightDisplay = '${latestRecord['weight']}';
      }
      
      if (latestRecord['score'] != null) {
        final score = int.tryParse(latestRecord['score'].toString()) ?? 5;
        bcsScore = score.toString();
        
        // Color coding for BCS score
        if (score <= 3) {
          bcsColor = Color(0xFF3B82F6); // Blue for underweight
        } else if (score >= 4 && score <= 6) {
          bcsColor = Color(0xFF10B981); // Green for ideal
        } else {
          bcsColor = Color(0xFFEF4444); // Red for overweight
        }
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/pet-details',
            arguments: PetRecord()
              ..name = pet['name']
              ..breed = pet['breed']
              ..age = pet['age']
              ..weight = weightDisplay
              ..gender = pet['gender']
              ..isSterilized = pet['is_sterilized']
              ..category = pet['category'],
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              // Main row with pet info and BCS badge
              Row(
                children: [
                  // Pet Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
          ),
        ],
      ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                        return Container(
                                  color: Color(0xFF6B86C9).withOpacity(0.1),
                                  child: Icon(
                                    Icons.pets,
                                    color: Color(0xFF6B86C9),
                                    size: 30,
                          ),
                        );
                      },
                            )
                          : Container(
                              color: Color(0xFF6B86C9).withOpacity(0.1),
                              child: Icon(
                                Icons.pets,
                                color: Color(0xFF6B86C9),
                                size: 30,
                              ),
                            ),
                    ),
                  ),
                  
                  SizedBox(width: 16),
                  
                  // Pet Basic Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                      Text(
                          pet['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        
                        SizedBox(height: 4),
                        
                  Text(
                          '${pet['breed'] ?? 'Unknown breed'} • ${pet['gender'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        
                        SizedBox(height: 8),
                        
                  Row(
                    children: [
                            Icon(Icons.monitor_weight, size: 14, color: Color(0xFF64748B)),
                            SizedBox(width: 4),
                      Text(
                              '${weightDisplay} kg',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                      ),
                    ],
                  ),
                  ),
                  
                  // Right side with BCS Badge and Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // BCS Badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: bcsColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: bcsColor.withOpacity(0.3)),
                        ),
                          child: Text(
                          'BCS $bcsScore',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: bcsColor,
                            ),
                          ),
                        ),
                      
                      SizedBox(width: 8),
                      
                      // View Graph Button
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.analytics, color: Color(0xFF8B5CF6), size: 16),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/history',
                              arguments: {
                                'pet': pet,
                                'groupName': groupName,
                              },
                            );
                          },
                          tooltip: 'View analytics',
                          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.all(4),
                        ),
                      ),
                      
                      SizedBox(width: 4),
                      
                      // Add Record Button
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF6B86C9).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.add, color: Color(0xFF6B86C9), size: 16),
                          onPressed: () => _addNewRecordForPet(pet),
                          tooltip: 'Add new record',
                          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.all(4),
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

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFF6B86C9).withOpacity(0.1),
                shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.pets,
                size: 48,
                color: Color(0xFF6B86C9),
              ),
            ),
            SizedBox(height: 20),
            
            // Title
            Text(
              'Welcome to Pet Health Records! 🐾',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            
            // Description
            Text(
              'Manage your pet\'s health with our comprehensive tracking system. Track BCS scores, weight, and health records for all your beloved pets.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            
            // Features
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF6B86C9).withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF6B86C9).withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  _buildFeatureItem(Icons.pets, 'Organize pets by groups'),
                  SizedBox(height: 8),
                  _buildFeatureItem(Icons.monitor_weight, 'Track weight and BCS scores'),
                  SizedBox(height: 8),
                  _buildFeatureItem(Icons.analytics, 'View health analytics'),
                  SizedBox(height: 8),
                  _buildFeatureItem(Icons.photo_camera, 'Capture pet photos'),
                ],
              ),
            ),
            SizedBox(height: 24),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6B86C9),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Get Started',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

}