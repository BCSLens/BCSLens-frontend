// Enhanced version of PetDetailsScreen with breed autocomplete, better age handling, and unit displays

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/frosted_glass_header.dart';
import '../models/pet_record_model.dart';
import '../services/group_service.dart';

// Lists of common dog and cat breeds for autocomplete
final List<String> _dogBreeds = [
  'Labrador Retriever',
  'German Shepherd',
  'Golden Retriever',
  'Bulldog',
  'Beagle',
  'Poodle',
  'Rottweiler',
  'Yorkshire Terrier',
  'Boxer',
  'Dachshund',
  'Siberian Husky',
  'Great Dane',
  'Doberman Pinscher',
  'Shih Tzu',
  'Pomeranian',
  'Chihuahua',
  'Border Collie',
  'Pug',
  'Corgi',
  'Dalmatian',
];

final List<String> _catBreeds = [
  'Persian',
  'Maine Coon',
  'Siamese',
  'Ragdoll',
  'Bengal',
  'Abyssinian',
  'Birman',
  'Scottish Fold',
  'Sphynx',
  'British Shorthair',
  'Devon Rex',
  'American Shorthair',
  'Himalayan',
  'Russian Blue',
  'Norwegian Forest Cat',
  'Burmese',
  'Manx',
  'Egyptian Mau',
  'Tonkinese',
];

class PetDetailsScreen extends StatefulWidget {
  final PetRecord petRecord;

  const PetDetailsScreen({Key? key, required this.petRecord}) : super(key: key);

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  int _selectedIndex = 1;

  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _breedController = TextEditingController();

  // Age related variables
  final TextEditingController _ageYearsController = TextEditingController();
  final TextEditingController _ageMonthsController = TextEditingController();

  // Weight related variables
  final TextEditingController _weightController = TextEditingController();

  // Other state variables
  String _selectedGender = 'Male';
  bool _isSterilized = false;
  String _selectedGroup = '';

  // Autocomplete variables
  List<String> _breedSuggestions = [];
  bool _showBreedSuggestions = false;
  FocusNode _breedFocusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _breedFieldKey = GlobalKey();

  // Available groups
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;
  
  // Group creation
  final TextEditingController _newGroupController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Initialize with existing data if available
    if (widget.petRecord.name != null) {
      _nameController.text = widget.petRecord.name!;
    }
    if (widget.petRecord.breed != null) {
      _breedController.text = widget.petRecord.breed!;
    }
    if (widget.petRecord.age != null) {
      // Parse age value which might be in format "X years Y months", "X years", "X months", or just a number
      String age = widget.petRecord.age!;
      
      // Check if it contains both years and months (e.g., "2 years 3 months")
      if (age.contains('year') && age.contains('month')) {
        final parts = age.split(' ');
        // Format: "X years Y months"
        if (parts.length >= 4) {
          _ageYearsController.text = parts[0]; // First number is years
          _ageMonthsController.text = parts[2]; // Third number is months
        } else {
          _ageYearsController.text = '0';
          _ageMonthsController.text = '0';
        }
      } else if (age.contains('year')) {
        // Only years (e.g., "2 years")
        _ageYearsController.text = age.split(' ')[0];
        _ageMonthsController.text = '0';
      } else if (age.contains('month')) {
        // Only months (e.g., "3 months")
        _ageYearsController.text = '0';
        _ageMonthsController.text = age.split(' ')[0];
      } else {
        // Try to parse as a number (years)
        try {
          _ageYearsController.text = age;
          _ageMonthsController.text = '0';
        } catch (e) {
          _ageYearsController.text = '0';
          _ageMonthsController.text = '0';
        }
      }
    }
    if (widget.petRecord.weight != null) {
      // Remove 'kg' suffix if present
      String weight = widget.petRecord.weight!;
      if (weight.toLowerCase().contains('kg')) {
        _weightController.text =
            weight.toLowerCase().replaceAll('kg', '').trim();
      } else {
        _weightController.text = weight;
      }
    }
    if (widget.petRecord.gender != null) {
      _selectedGender = widget.petRecord.gender!;
    }
    if (widget.petRecord.isSterilized != null) {
      _isSterilized = widget.petRecord.isSterilized!;
    }

    // Initialize autocomplete
    _breedController.addListener(_onBreedTextChanged);
    _breedFocusNode.addListener(_onBreedFocusChanged);

    // Load groups
    _loadGroups();
  }

  void _onBreedFocusChanged() {
    if (_breedFocusNode.hasFocus) {
      // When focus is gained, show suggestions if there's text
      if (_breedController.text.isNotEmpty) {
        _onBreedTextChanged();
      }
    } else {
      // When focus is lost, hide suggestions with a small delay
      Future.delayed(Duration(milliseconds: 150), () {
        if (mounted) {
          _hideBreedOverlay();
          setState(() {
            _showBreedSuggestions = false;
          });
        }
      });
    }
  }

  void _onBreedTextChanged() {
    final String query = _breedController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _breedSuggestions = [];
        _showBreedSuggestions = false;
      });
      _hideBreedOverlay();
      return;
    }

    // Choose breed list based on predicted animal
    List<String> breeds =
        widget.petRecord.predictedAnimal == 'cat' ? _catBreeds : _dogBreeds;

    // Filter breeds that match the query (case insensitive)
    List<String> filteredBreeds =
        breeds
            .where((breed) => breed.toLowerCase().contains(query))
            .take(5) // Limit to 5 suggestions
            .toList();

    setState(() {
      _breedSuggestions = filteredBreeds;
      _showBreedSuggestions =
          filteredBreeds.isNotEmpty && _breedFocusNode.hasFocus;
    });

    if (_showBreedSuggestions) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showBreedOverlay();
      });
    } else {
      _hideBreedOverlay();
    }
  }

  void _showBreedOverlay() {
    _hideBreedOverlay(); // Remove any existing overlay

    if (_breedSuggestions.isEmpty || !_breedFocusNode.hasFocus) {
      return;
    }

    final RenderBox? renderBox =
        _breedFieldKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero, ancestor: overlay),
        renderBox.localToGlobal(
          renderBox.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
            left: position.left + 24, // Account for screen padding
            top: position.bottom + 4,
            width: renderBox.size.width,
            child: Material(
              elevation: 8.0,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                constraints: BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: _breedSuggestions.length,
              separatorBuilder: (context, index) =>
                          Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        _breedController.text = _breedSuggestions[index];
                        _hideBreedOverlay();
                        _breedFocusNode.unfocus();
                        setState(() {
                          _showBreedSuggestions = false;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.pets, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _breedSuggestions[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideBreedOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load groups
      final groupService = GroupService();
      final groups = await groupService.getGroups();

      setState(() {
        _groups = groups;

        // Restore previously selected group if exists, otherwise use first group
        if (widget.petRecord.groupId != null && widget.petRecord.groupId!.isNotEmpty) {
          // Check if the saved group still exists in the list
          bool groupExists = groups.any((g) => g['_id'] == widget.petRecord.groupId);
          if (groupExists) {
            _selectedGroup = widget.petRecord.groupId!;
          } else if (groups.isNotEmpty) {
            _selectedGroup = groups[0]['_id'];
          }
        } else if (groups.isNotEmpty) {
          // No previously selected group, use first one
          _selectedGroup = groups[0]['_id'];
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _ageYearsController.dispose();
    _ageMonthsController.dispose();
    _weightController.dispose();
    _breedFocusNode.dispose();
    _newGroupController.dispose();
    _hideBreedOverlay();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/records');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/special-care');
    }
  }


  void _showCreateGroupDialog() {
    showDialog(
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
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF10B981).withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.create_new_folder,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Title
                  Text(
                    'Create New Group',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  
                  // TextField
                  TextField(
                    controller: _newGroupController,
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
                        borderSide: BorderSide(color: Color(0xFF10B981), width: 2),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.8),
                    ),
                    autofocus: true,
                  ),
                  SizedBox(height: 24),
                  
                  // Buttons
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _newGroupController.clear();
                          },
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
                      
                      // Create Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF10B981).withOpacity(0.3),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              _createNewGroup();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'Create',
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
    );
  }

  Future<void> _createNewGroup() async {
    if (_newGroupController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final groupService = GroupService();
      await groupService.createGroup(_newGroupController.text);
      _newGroupController.clear();
      _loadGroups(); // Reload groups
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating group: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatAgeForSubmission() {
    final int years = int.tryParse(_ageYearsController.text) ?? 0;
    final int months = int.tryParse(_ageMonthsController.text) ?? 0;

    if (years > 0 && months > 0) {
      return '$years years $months months';
    } else if (years > 0) {
      return years == 1 ? '1 year' : '$years years';
    } else if (months > 0) {
      return months == 1 ? '1 month' : '$months months';
    } else {
      return '0';
    }
  }

  String _formatWeightForSubmission() {
    final weight =
        double.tryParse(_weightController.text.replaceAll(',', '.')) ?? 0;
    return '${weight.toStringAsFixed(1)} kg';
  }

  Future<void> _submitRecord() async {
    // Validate weight for existing pets
    if (widget.petRecord.isNewRecordForExistingPet) {
      if (_weightController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter current weight')),
        );
        return;
      }
    } else {
      // Validate for new pets
      if (_nameController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a name for your pet')),
        );
        return;
      }
      
      // Validate group selection
      if (_selectedGroup.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select a group or create a new one'),
            action: SnackBarAction(
              label: 'Create Group',
              onPressed: _showCreateGroupDialog,
            ),
          ),
        );
        return;
      }
    }

    // Update pet record with form data
    if (widget.petRecord.isNewRecordForExistingPet) {
      // For existing pets, only update weight
      widget.petRecord.weight = _formatWeightForSubmission();
    } else {
      // For new pets, update all data
      widget.petRecord.name = _nameController.text;
      widget.petRecord.age = _formatAgeForSubmission();
      widget.petRecord.weight = _formatWeightForSubmission();
      widget.petRecord.breed = _breedController.text;
      widget.petRecord.gender = _selectedGender;
      widget.petRecord.isSterilized = _isSterilized;
      widget.petRecord.groupId = _selectedGroup;
      widget.petRecord.category =
          widget.petRecord.predictedAnimal == 'cat' ? 'Cats' : 'Dogs';
    }

    // Navigate to review screen
    Navigator.pushReplacementNamed(
      context,
      '/review-details',
      arguments: widget.petRecord,
    );
  }

  // Helper method to build modern input fields
  Widget _buildInputSection(String label, String hint, IconData icon, TextEditingController controller, {TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters, String? suffixText}) {
    return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Color(0xFF6B86C9).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: Color(0xFF6B86C9),
              ),
            ),
            SizedBox(width: 8),
            Text(
              label,
                      style: TextStyle(
                        fontFamily: 'Inter',
                fontSize: 14,
                        fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF6B86C9), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              hintText: hint,
              hintStyle: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF94A3B8),
              ),
              suffixText: suffixText,
              suffixStyle: TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF6B86C9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build info rows for existing pets
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Color(0xFF6B86C9).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: Color(0xFF6B86C9),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                  fontSize: 14,
                            fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                value,
                          style: TextStyle(
                            fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Modern header with back button
  Widget _buildModernHeader() {
    return FrostedGlassHeader(
      title: widget.petRecord.isNewRecordForExistingPet
          ? 'Add New Record'
          : 'Pet Details',
      leadingWidget: HeaderBackButton(
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  // Progress indicator
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
                  'Step 4 of 4',
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
                    widthFactor: 1.0, // 4/4 progress - complete
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
            'Pet Details',
                                  style: TextStyle(
                            fontFamily: 'Inter',
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
                                    Text(
            'Complete your pet\'s information to finish the record',
                                      style: TextStyle(
                            fontFamily: 'Inter',
              color: Color(0xFF64748B),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
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
    
    return await _showModernConfirmDialog(
      context: context,
      title: 'Leave without saving?',
      message: 'You have unsaved changes. Are you sure you want to leave?',
      confirmText: 'Leave',
    ) ?? false;
  }
  
  // Helper function for modern confirmation dialog
  Future<bool?> _showModernConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
    IconData? icon,
  }) async {
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
                  // Icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: icon != null && icon == Icons.create_new_folder
                            ? [Color(0xFF10B981), Color(0xFF059669)]
                            : [
                                Color(0xFFFFB84D),
                                Color(0xFFFF9500),
                              ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (icon != null && icon == Icons.create_new_folder
                                  ? Color(0xFF10B981)
                                  : Color(0xFFFF9500))
                              .withOpacity(0.3),
                          blurRadius: 15,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon ?? Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Title
                  Text(
                    title,
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
                    message,
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
                            cancelText,
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
                      
                      // Confirm Button
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: confirmColor != null
                                  ? [confirmColor, confirmColor.withOpacity(0.8)]
                                  : icon != null && icon == Icons.create_new_folder
                                      ? [Color(0xFF10B981), Color(0xFF059669)]
                                      : [
                                          Color(0xFFEF4444),
                                          Color(0xFFDC2626),
                                        ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: (confirmColor ??
                                        (icon != null && icon == Icons.create_new_folder
                                            ? Color(0xFF10B981)
                                            : Color(0xFFEF4444)))
                                    .withOpacity(0.3),
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
                              confirmText,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _showExitConfirmation();
          if (shouldPop) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Color(0xFFD0E3F5), // สีฟ้าอ่อนมาก (ล่างสุด) เพื่อให้ตรงกับ gradient
        body: SafeArea(
          child: Stack(
            children: [
              // Background with blue gradient
              Container(
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
              ),
            SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                  const SizedBox(height: 20),
                  
                  // Modern Header with back button
                  _buildModernHeader(),

                  const SizedBox(height: 44),
                  
                  // Progress Indicator
                  _buildProgressIndicator(),

                  const SizedBox(height: 32),
                  
                  // Main Content Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Check if this is for existing pet or new pet
                            if (widget.petRecord.isNewRecordForExistingPet) ...[
                              // Header for existing pet
                                Row(
                                  children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF6B86C9).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.pets,
                                      color: Color(0xFF6B86C9),
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Update Record for ${widget.petRecord.name}',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                    ),
                                  ],
                                ),
                              
                              SizedBox(height: 24),
                              
                              // Pet Info Card
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFF8FAFC),
                                      Color(0xFFF1F5F9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Color(0xFFE2E8F0), width: 1),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Row(
                                  children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Color(0xFF6B86C9),
                                          size: 18,
                                        ),
                                        SizedBox(width: 8),
                                    Text(
                                          'Pet Information',
                                      style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF6B86C9),
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    
                                    // Info Row Items
                                    _buildInfoRow(Icons.badge, 'Name', widget.petRecord.name ?? 'Unknown'),
                                    SizedBox(height: 12),
                                    _buildInfoRow(Icons.category, 'Breed', widget.petRecord.breed ?? 'Unknown'),
                                    SizedBox(height: 12),
                                    _buildInfoRow(Icons.cake, 'Age', '${widget.petRecord.age ?? 'Unknown'}'),
                                    SizedBox(height: 12),
                                    _buildInfoRow(Icons.pets, 'Type', widget.petRecord.category ?? 'Unknown'),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                              // Weight Section
                              Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Color(0xFF10B981).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.monitor_weight,
                                            color: Color(0xFF10B981),
                                            size: 20,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                          Text(
                                          'Update Weight',
                            style: TextStyle(
                              fontFamily: 'Inter',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                          ),
                          SizedBox(height: 8),
                                    Text(
                                      'Enter the current weight of ${widget.petRecord.name}',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                    SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: TextField(
                                        controller: _weightController,
                                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                        ],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Color(0xFF6B86C9), width: 2),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          hintText: 'Enter weight...',
                                          hintStyle: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Color(0xFF94A3B8),
                                          ),
                                          suffixIcon: Container(
                                            margin: EdgeInsets.all(8),
                                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: Color(0xFF6B86C9).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'kg',
                            style: TextStyle(
                              fontFamily: 'Inter',
                                                color: Color(0xFF6B86C9),
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              // Header for new pet
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF6B86C9).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.pets,
                                  color: Color(0xFF6B86C9),
                                      size: 20,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Pet Details',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Complete your pet\'s information',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Name Field
                              _buildInputSection(
                                'Pet Name',
                                'Enter your pet\'s name',
                                Icons.badge,
                                _nameController,
                              ),
                              const SizedBox(height: 20),

                              // Breed Field - Special handling for autocomplete
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF6B86C9).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.category,
                                          size: 16,
                                          color: Color(0xFF6B86C9),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                          Text(
                            'Breed',
                            style: TextStyle(
                              fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                          CompositedTransformTarget(
                            link: _layerLink,
                            child: Container(
                              key: _breedFieldKey,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                              child: TextField(
                                controller: _breedController,
                                focusNode: _breedFocusNode,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Color(0xFF6B86C9), width: 2),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                          hintText: 'Enter your pet\'s breed',
                                          hintStyle: TextStyle(
                                            fontFamily: 'Inter',
                                            color: Color(0xFF94A3B8),
                                          ),
                                          suffixIcon: _breedController.text.isNotEmpty
                                          ? IconButton(
                                            icon: Icon(Icons.clear),
                                            onPressed: () {
                                              _breedController.clear();
                                              _hideBreedOverlay();
                                              setState(() {
                                                _showBreedSuggestions = false;
                                              });
                                            },
                                          )
                                          : Icon(
                                            Icons.pets,
                                            color: Colors.grey[400],
                                          ),
                                ),
                              ),
                            ),
                          ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Age Fields
                          Row(
                            children: [
                              Expanded(
                                    child: _buildInputSection(
                                      'Years',
                                      '0',
                                      Icons.cake,
                                      _ageYearsController,
                                  keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                    ),
                                  ),
                                  SizedBox(width: 16),
                              Expanded(
                                    child: _buildInputSection(
                                      'Months',
                                      '0',
                                      Icons.schedule,
                                      _ageMonthsController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                        TextInputFormatter.withFunction((oldValue, newValue) {
                                          final int? value = int.tryParse(newValue.text);
                                      if (value == null) return newValue;
                                      if (value > 11) return oldValue;
                                      return newValue;
                                    }),
                                  ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Weight Field
                              _buildInputSection(
                                'Weight',
                                'Enter weight',
                                Icons.monitor_weight,
                                _weightController,
                                keyboardType: TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                suffixText: 'kg',
                              ),
                              const SizedBox(height: 20),

                              // Gender Selection
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF6B86C9).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.pets,
                                          size: 16,
                                        color: Color(0xFF6B86C9),
                                      ),
                                    ),
                                      SizedBox(width: 8),
                          Text(
                                        'Gender',
                            style: TextStyle(
                              fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 8,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedGender,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(color: Color(0xFF6B86C9), width: 2),
                                        ),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                      ),
                                      items: ['Male', 'Female'].map((String gender) {
                                        return DropdownMenuItem<String>(
                                          value: gender,
                                          child: Text(gender),
                                        );
                                      }).toList(),
                                      onChanged: (String? newValue) {
                                    setState(() {
                                          _selectedGender = newValue!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                              const SizedBox(height: 20),

                              // Sterilization Status
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                              children: [
                                    Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Color(0xFF6B86C9).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.medical_services,
                                        size: 16,
                                        color: Color(0xFF6B86C9),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Spayed/Neutered',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                  ),
                                ),
                            ),
                                    Switch(
                            value: _isSterilized,
                                      onChanged: (bool value) {
                              setState(() {
                                          _isSterilized = value;
                              });
                            },
                                      activeColor: Color(0xFF6B86C9),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                          // Group Selection (only for new pets)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Color(0xFF6B86C9).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          Icons.group,
                                          size: 16,
                                          color: Color(0xFF6B86C9),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Group',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      Spacer(),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Color(0xFF10B981).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.add, color: Color(0xFF10B981), size: 20),
                                          onPressed: _showCreateGroupDialog,
                                          tooltip: 'Create New Group',
                                          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                                          padding: EdgeInsets.all(8),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  if (_groups.isNotEmpty) ...[
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 8,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: DropdownButtonFormField<String>(
                                        value: _selectedGroup.isEmpty ? _groups[0]['_id'] : _selectedGroup,
                                        decoration: InputDecoration(
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Color(0xFF6B86C9), width: 2),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                        ),
                                        items: _groups.map<DropdownMenuItem<String>>((group) {
                                          return DropdownMenuItem<String>(
                                            value: group['_id'],
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.pets,
                                                  color: Color(0xFF7B8EB5),
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(group['group_name']),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            _selectedGroup = newValue!;
                                          });
                                        },
                                      ),
                                    ),
                                  ] else ...[
                                    Center(
                                      child: Container(
                                        padding: EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFF8FAFC),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Color(0xFFE2E8F0)),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.group_add,
                                              color: Color(0xFF6B86C9),
                                              size: 32,
                                            ),
                                            SizedBox(height: 12),
                                            Text(
                                              'No groups available',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1E293B),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Create your first group to organize your pets',
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 14,
                                                color: Color(0xFF64748B),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            SizedBox(height: 16),
                                            ElevatedButton.icon(
                                              onPressed: _showCreateGroupDialog,
                                              icon: Icon(Icons.add),
                                              label: Text('Create Group'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(0xFF10B981),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                        ],

                        const SizedBox(height: 32),

                            // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                    onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: Color(0xFF6B86C9)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                ),
                                    child: Text(
                                  'Back',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                        color: Color(0xFF6B86C9),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF6B86C9), Color(0xFF8BA3E7)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(25),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0xFF6B86C9).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitRecord,
                                style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                        padding: EdgeInsets.symmetric(vertical: 16),
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                          color: Colors.white,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  widget.petRecord.isNewRecordForExistingPet
                                                      ? Icons.add_circle_outline
                                                      : Icons.check_circle_outline,
                                                  color: Colors.white,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  widget.petRecord.isNewRecordForExistingPet
                                              ? 'Add Record'
                                                      : 'Complete Setup',
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
                            ),
                          ],
                        ),
                      ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),

            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
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
        onAddRecordsTap: () {},
      ),
      ),
    );
  }
}