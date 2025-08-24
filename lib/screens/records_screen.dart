// lib/screens/records_screen.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'history_screen.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../services/pet_service.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({Key? key}) : super(key: key);

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  int _selectedIndex = 0;
  bool _showAddGroupForm = false;
  bool _showAddPetForm = false;
  bool _showFilterOptions = false;
  String _selectedGroupId = '';
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

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
    _loadData();

    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _applyFilters();
    });
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty && _bcsScoreRange == const RangeValues(1, 9)) {
      // No filters applied
      _filteredGroups = List.from(_groups);
      _filteredGroupPets = Map.from(_groupPets);
      return;
    }

    // Filter pets based on search query and BCS score
    final Map<String, List<Map<String, dynamic>>> newFilteredGroupPets = {};
    final List<Map<String, dynamic>> newFilteredGroups = [];

    for (final group in _groups) {
      final String groupId = group['_id'];
      final String groupName = group['group_name'].toLowerCase();
      final List<Map<String, dynamic>> pets = _groupPets[groupId] ?? [];

      // Filter pets in this group
      final List<Map<String, dynamic>> filteredPets =
          pets.where((pet) {
            // Check pet name against search query
            final bool nameMatches =
                pet['name'] != null &&
                pet['name'].toString().toLowerCase().contains(_searchQuery);

            // Check BCS score against range
            bool scoreInRange = true;
            if (pet['records'] != null && (pet['records'] as List).isNotEmpty) {
              final latestRecord = (pet['records'] as List).last;
              if (latestRecord['score'] != null) {
                final int score =
                    int.tryParse(latestRecord['score'].toString()) ?? 5;
                scoreInRange =
                    score >= _bcsScoreRange.start &&
                    score <= _bcsScoreRange.end;
              }
            }

            // Pet matches if both conditions are satisfied
            return (_searchQuery.isEmpty || nameMatches) && scoreInRange;
          }).toList();

      // Only include group if it has matching pets or group name contains search query
      if (filteredPets.isNotEmpty || groupName.contains(_searchQuery)) {
        newFilteredGroupPets[groupId] = filteredPets;

        // Add group to filtered groups
        final Map<String, dynamic> filteredGroup = Map.from(group);
        newFilteredGroups.add(filteredGroup);
      }
    }

    setState(() {
      _filteredGroups = newFilteredGroups;
      _filteredGroupPets = newFilteredGroupPets;
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if user is authenticated
      if (!AuthService().isAuthenticated) {
        print('User not authenticated in _loadData');
        setState(() {
          _errorMessage = 'You need to log in to view your records';
          _isLoading = false;
        });

        // Redirect to login after a short delay
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/login');
        });

        return;
      }

      // Load groups with pets included
      final groupService = GroupService();
      // Remove the context parameter since it doesn't exist in your current implementation
      final groups = await groupService.getGroups();

      // Initialize expanded state for each group
      for (var group in groups) {
        _expandedGroups[group['_id']] = false;
      }

      // Group pets are already included in the groups response
      final Map<String, List<Map<String, dynamic>>> groupPets = {};

      // Extract pets from groups
      for (var group in groups) {
        final String groupId = group['_id'];
        final List<dynamic> pets = group['pets'] as List;
        groupPets[groupId] =
            pets.map((pet) => pet as Map<String, dynamic>).toList();
      }

      setState(() {
        _groups = groups;
        _groupPets = groupPets;
        _filteredGroups = List.from(groups);
        _filteredGroupPets = Map.from(groupPets);
        _isLoading = false;
      });
    } catch (e) {
      print('Error in _loadData: $e');

      // Check if it's an authentication error
      if (e.toString().contains('auth') ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        setState(() {
          _errorMessage = 'Authentication error. Please log in again.';
          _isLoading = false;
        });

        // Redirect to login after a short delay
        Future.delayed(Duration(seconds: 2), () {
          Navigator.pushReplacementNamed(context, '/login');
        });
      } else {
        // For other errors, display a user-friendly message with a retry button
        setState(() {
          _errorMessage = 'Could not load data. Please check your connection.';
          _isLoading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.pushReplacementNamed(context, '/add-record');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/special-care');
    }
  }

  void _handleAddRecordsTap() {
    Navigator.pushNamed(context, '/add-record');
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _petNameController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  void _showAddGroupDialog() {
    setState(() {
      _showAddGroupForm = true;
    });
  }

  Future<void> _addNewGroup() async {
    if (_groupNameController.text.isEmpty) {
      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty')),
      );
      return;
    }

    // Hide the form while processing
    setState(() {
      _showAddGroupForm = false;
    });

    try {
      // Create new group
      final groupService = GroupService();
      await groupService.createGroup(_groupNameController.text);

      // Clear the group name controller
      _groupNameController.clear();

      // Refresh data
      _loadData();
    } catch (e) {
      // Show error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating group: $e')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(
        0xFFF8FAFC,
      ), // ✅ เปลี่ยนเป็น background เดียวกับหน้าอื่น
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Modern Header แบบเดียวกับหน้าอื่น
            _buildModernHeader(),

            // ✅ Content ทั้งหมด
            Expanded(
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                      ? Center(child: Text(_errorMessage!))
                      : Stack(
                        children: [
                          Column(
                            children: [
                              // Search bar
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                child: Container(
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F7F9),
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 16),
                                      const Icon(
                                        Icons.search,
                                        color: Color(0xFFACACAC),
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          decoration: InputDecoration(
                                            hintText: 'Search',
                                            hintStyle: TextStyle(
                                              color: Color(0xFFACACAC),
                                              fontSize: 17,
                                            ),
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          style: TextStyle(
                                            fontSize: 17,
                                            color: Color(0xFF333333),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          Icons.tune,
                                          color:
                                              _showFilterOptions
                                                  ? Color(0xFF7B8EB5)
                                                  : Color(0xFFACACAC),
                                          size: 24,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _showFilterOptions =
                                                !_showFilterOptions;
                                          });
                                        },
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ),
                                ),
                              ),

                              // Filter options - shown when filter icon is tapped
                              if (_showFilterOptions)
                                Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        spreadRadius: 1,
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                    border: Border.all(
                                      color: Color(0xFFEEEEEE),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Filter by BCS Score',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF333333),
                                        ),
                                      ),
                                      SizedBox(height: 16),
                                      Row(
                                        children: [
                                          Text(
                                            '${_bcsScoreRange.start.round()}',
                                            style: TextStyle(
                                              color: Color(0xFF7B8EB5),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Expanded(
                                            child: RangeSlider(
                                              values: _bcsScoreRange,
                                              min: 1,
                                              max: 9,
                                              divisions: 8,
                                              activeColor: Color(0xFF7BC67E),
                                              inactiveColor: Color(0xFFE6F0EB),
                                              labels: RangeLabels(
                                                _bcsScoreRange.start
                                                    .round()
                                                    .toString(),
                                                _bcsScoreRange.end
                                                    .round()
                                                    .toString(),
                                              ),
                                              onChanged: (RangeValues values) {
                                                setState(() {
                                                  _bcsScoreRange = values;
                                                  _applyFilters();
                                                });
                                              },
                                            ),
                                          ),
                                          Text(
                                            '${_bcsScoreRange.end.round()}',
                                            style: TextStyle(
                                              color: Color(0xFF7B8EB5),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _bcsScoreRange = RangeValues(
                                                  1,
                                                  9,
                                                );
                                                _searchController.clear();
                                                _applyFilters();
                                              });
                                            },
                                            child: Text(
                                              'Reset',
                                              style: TextStyle(
                                                color: Color(0xFF7B8EB5),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _showFilterOptions = false;
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color(
                                                0xFF7B8EB5,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                            ),
                                            child: Text(
                                              'Apply',
                                              style: TextStyle(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                              // Group header
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Group',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF333333),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: _showAddGroupDialog,
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFFF5F5F5),
                                          border: Border.all(
                                            color: const Color(0xFF7B8EB5),
                                            width: 1,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          color: Color(0xFF7B8EB5),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Pet groups and list
                              Expanded(
                                child:
                                    _filteredGroups.isEmpty
                                        ? _buildEmptyState()
                                        : ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          itemCount: _filteredGroups.length,
                                          itemBuilder: (context, index) {
                                            final group =
                                                _filteredGroups[index];
                                            final groupId = group['_id'];
                                            final groupName =
                                                group['group_name'];
                                            final isExpanded =
                                                _expandedGroups[groupId] ??
                                                false;
                                            final pets =
                                                _filteredGroupPets[groupId] ??
                                                [];

                                            return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Group card
                                                _buildPetGroupCard(
                                                  groupId,
                                                  groupName,
                                                  pets.length,
                                                  isExpanded,
                                                ),

                                                // Show pets if group is expanded
                                                if (isExpanded)
                                                  ...pets
                                                      .map(
                                                        (pet) => Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 8.0,
                                                              ),
                                                          child: _buildPetCard(
                                                            pet,
                                                            groupName,
                                                          ),
                                                        ),
                                                      )
                                                      .toList(),

                                                const SizedBox(height: 8),
                                              ],
                                            );
                                          },
                                        ),
                              ),
                            ],
                          ),

                          // Group creation overlay
                          if (_showAddGroupForm)
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showAddGroupForm = false;
                                    _groupNameController.clear();
                                  });
                                },
                                child: Container(
                                  color: Colors.black.withOpacity(0.5),
                                  child: Center(
                                    child: GestureDetector(
                                      onTap:
                                          () {}, // Prevent taps from closing the form
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                            0.85,
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'Add New Group',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF7B8EB5),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Container(
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF5F5F5),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: TextField(
                                                controller:
                                                    _groupNameController,
                                                decoration:
                                                    const InputDecoration(
                                                      hintText: 'Group Name',
                                                      border: InputBorder.none,
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 16,
                                                            vertical: 14,
                                                          ),
                                                    ),
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 24),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: OutlinedButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        _showAddGroupForm =
                                                            false;
                                                        _groupNameController
                                                            .clear();
                                                      });
                                                    },
                                                    style: OutlinedButton.styleFrom(
                                                      side: const BorderSide(
                                                        color: Color(
                                                          0xFF7B8EB5,
                                                        ),
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              25,
                                                            ),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'Cancel',
                                                      style: TextStyle(
                                                        color: Color(
                                                          0xFF7B8EB5,
                                                        ),
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: ElevatedButton(
                                                    onPressed: _addNewGroup,
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor:
                                                          const Color(
                                                            0xFF7B8EB5,
                                                          ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              25,
                                                            ),
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 12,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'Confirm',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 16,
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
                              ),
                            ),
                        ],
                      ),
            ),
          ],
        ),
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

  // ✅ เพิ่ม Modern Header แบบเดียวกับหน้าอื่น
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
            // ✅ ไม่มี back button เพราะเป็นหน้าหลัก
            Expanded(
              child: Center(
                child: Text(
                  'Records',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF7B8EB5),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            // ✅ Profile button แบบเดียวกับเดิม แต่ดี design ขึ้น
            GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/profile');
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      AuthService().isExpert
                          ? Color(0xFFFFF4E0)
                          : Color(0xFFE6F0EB),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        AuthService().isExpert
                            ? Colors.amber
                            : Color(0xFF7BC67E),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  size: 20,
                  color:
                      AuthService().isExpert ? Colors.amber : Color(0xFF7BC67E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Pet illustration
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7F9),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/empty_pets.png', // Add this image to your assets
                width: 150,
                height: 150,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.pets,
                    size: 100,
                    color: Color(0xFF7B8EB5).withOpacity(0.7),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Title text
          const Text(
            'No Pet Groups Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          // Description text
          Text(
            'Start monitoring your pets\' health by creating your first group. You can organize pets by type, location, or any category you prefer.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Add group button
          ElevatedButton(
            onPressed: _showAddGroupDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7B8EB5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              elevation: 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text(
                  'Create New Group',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Tutorial card
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: const Color(0xFFE6F0EB), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F0EB),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFF7BC67E),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Tip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create different groups for different types of pets to better organize their health records.',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetGroupCard(
    String groupId,
    String type,
    int count,
    bool isExpanded,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedGroups[groupId] = !isExpanded;
        });
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_right,
              color: const Color(0xFFACACAC),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.pets, color: Color(0xFF7B8EB5), size: 24),
            const SizedBox(width: 12),
            Text(
              '$type ($count)',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.add, color: Color(0xFFACACAC), size: 20),
              onPressed: () => Navigator.pushNamed(context, '/add-record'),
            ),
          ],
        ),
      ),
    );
  }

 Widget _buildPetCard(Map<String, dynamic> pet, String groupName) {
    // ✅ เพิ่ม debug logs
    print('🔍 Building pet card for: ${pet['name']}');
    print('🔍 Pet data: $pet');
    
    String imageUrl = '';

    if (pet['records'] != null && (pet['records'] as List).isNotEmpty) {
      final latestRecord = (pet['records'] as List).last;
      final frontImageUrl = latestRecord['front_image_url'];
      
      print('🔍 Latest record: $latestRecord');
      print('🔍 Front image URL from record: $frontImageUrl');

      if (frontImageUrl != null && frontImageUrl.toString().isNotEmpty) {
        if (frontImageUrl.toString().startsWith('http')) {
          imageUrl = frontImageUrl.toString();
          print('✅ Using full URL: $imageUrl');
        } else {
          imageUrl = '${PetService.uploadBaseUrl}/uploads/$frontImageUrl';
          print('✅ Constructed URL: $imageUrl');
          print('🔍 Upload base URL: ${PetService.uploadBaseUrl}');
        }
      } else {
        print('❌ No front_image_url in latest record');
      }
    } else {
      print('❌ No records found for pet');
    }

    // Get weight from the latest record if available
    String weightDisplay = 'N/A kg';
    if (pet['records'] != null && (pet['records'] as List).isNotEmpty) {
      final latestRecord = (pet['records'] as List).last;
      if (latestRecord['weight'] != null) {
        weightDisplay = '${latestRecord['weight']} kg';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Pet image with enhanced debugging
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) {
                          print('✅ Image loaded successfully: $imageUrl');
                          return child;
                        }
                        print('⏳ Loading image: $imageUrl');
                        return Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey[200],
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF6B86C9),
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        print('❌ Image load error for URL: $imageUrl');
                        print('❌ Error: $error');
                        
                        // ✅ แสดง error info ใน debug mode
                        if (imageUrl.isNotEmpty) {
                          print('💡 Try opening this URL in browser: $imageUrl');
                        }
                        
                        return _buildPlaceholderImage();
                      },
                    )
                  : _buildPlaceholderImage(),
            ),
            const SizedBox(width: 16),

            // Pet details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pet['name'] ?? 'Unnamed Pet',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.star,
                        color: pet['favorite'] == true
                            ? Colors.amber
                            : Colors.grey[300],
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Weight $weightDisplay',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Age ${pet['age_years'] ?? 0}y ${pet['age_months'] ?? 0}m',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'BCS',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: Color(0xFF7BC67E),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${pet['records'] != null && (pet['records'] as List).isNotEmpty ? (pet['records'] as List).last['score'] ?? '?' : '?'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F0EB),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.add,
                            color: Color(0xFF7BC67E),
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.pushNamed(context, '/add-record');
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B8EB5),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward,
                            color: Colors.white,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HistoryScreen(
                                  pet: pet,
                                  groupName: groupName,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ เพิ่ม placeholder image ที่สวยขึ้น
  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6B86C9), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6B86C9).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        Icons.pets,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}
