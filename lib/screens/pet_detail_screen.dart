// Enhanced version of PetDetailsScreen with breed autocomplete, better age handling, and unit displays

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/bottom_nav_bar.dart';
import '../models/pet_record_model.dart';
import '../services/pet_service.dart';
import '../services/group_service.dart';
import 'dart:io';

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
  String _recordType = 'Add a New Pet';

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
  final GlobalKey _breedFieldKey = GlobalKey(); // Add this key for positioning

  // Available groups
  List<Map<String, dynamic>> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;

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
      // Parse age value which might be in format "X years" or "X months"
      String age = widget.petRecord.age!;
      if (age.contains('year')) {
        _ageYearsController.text = age.split(' ')[0];
        _ageMonthsController.text = '0';
      } else if (age.contains('month')) {
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

    print('Breed text changed: "$query"'); // Debug print

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

    print(
      'Using breeds for: ${widget.petRecord.predictedAnimal}',
    ); // Debug print
    print('Available breeds: ${breeds.take(5).toList()}'); // Debug print

    // Filter breeds that match the query (case insensitive)
    List<String> filteredBreeds =
        breeds
            .where((breed) => breed.toLowerCase().contains(query))
            .take(5) // Limit to 5 suggestions
            .toList();

    print('Filtered breeds: $filteredBreeds'); // Debug print

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
      builder:
          (context) => Positioned(
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
                  separatorBuilder:
                      (context, index) =>
                          Divider(height: 1, color: Colors.grey[200]),
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        print(
                          'Selected breed: ${_breedSuggestions[index]}',
                        ); // Debug print
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
      _errorMessage = null;
    });

    try {
      // Load groups
      final groupService = GroupService();
      final groups = await groupService.getGroups();

      setState(() {
        _groups = groups;

        // Set default group if available
        if (groups.isNotEmpty) {
          _selectedGroup = groups[0]['_id'];
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading groups: $e';
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

  void _goBack() {
    Navigator.pop(context);
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
    print('🔍 _submitRecord called');
    print(
      '🔍 isNewRecordForExistingPet: ${widget.petRecord.isNewRecordForExistingPet}',
    );
    print('🔍 existingPetId: ${widget.petRecord.existingPetId}');

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
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final petService = PetService();

      if (widget.petRecord.isNewRecordForExistingPet &&
          widget.petRecord.existingPetId != null) {
        // อัปเดตเฉพาะ weight สำหรับสัตว์เก่า
        widget.petRecord.weight = _formatWeightForSubmission();

        print(
          '🔍 Adding record to existing pet: ${widget.petRecord.existingPetId}',
        );

        final result = await petService.addRecordToExistingPet(
          widget.petRecord.existingPetId!,
          widget.petRecord,
        );

        print('✅ Record added successfully');

        // Navigate กลับไปหน้า Records
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/records',
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('New record added for ${widget.petRecord.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // สร้างสัตว์ใหม่ (original code)
        widget.petRecord.name = _nameController.text;
        widget.petRecord.age = _formatAgeForSubmission();
        widget.petRecord.weight = _formatWeightForSubmission();
        widget.petRecord.breed = _breedController.text;
        widget.petRecord.gender = _selectedGender;
        widget.petRecord.isSterilized = _isSterilized;
        widget.petRecord.groupId = _selectedGroup;
        widget.petRecord.category =
            widget.petRecord.predictedAnimal == 'cat' ? 'Cats' : 'Dogs';

        final result = await petService.createPet(widget.petRecord);

        Navigator.pushReplacementNamed(
          context,
          '/review-details',
          arguments: widget.petRecord,
        );
      }
    } catch (e) {
      print('❌ Error in _submitRecord: $e');
      setState(() {
        _errorMessage = 'Error: $e';
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ✅ อัปเดต method build เพื่อแสดงข้อความที่แตกต่างกัน
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 46),
                  Center(
                    child: Text(
                      widget.petRecord.isNewRecordForExistingPet
                          ? 'Add New Record'
                          : 'Add Records',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF7B8EB5),
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  Container(height: 1, color: Colors.grey[300]),

                  const SizedBox(height: 27),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.petRecord.isNewRecordForExistingPet
                              ? 'Final Step'
                              : 'Step 4 of 4',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF7B8EB5),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          widget.petRecord.isNewRecordForExistingPet
                              ? 'Update weight for ${widget.petRecord.name}'
                              : 'Provide details about your pet',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Color(0xFF333333),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ถ้าเป็นการเพิ่ม record ให้สัตว์เก่า แสดงแค่ weight field
                        if (widget.petRecord.isNewRecordForExistingPet) ...[
                          // แสดงข้อมูลสัตว์ที่มีอยู่แล้ว
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Color(0xFFE2E8F0)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pet Information',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF7B8EB5),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Text(
                                      'Name: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text('${widget.petRecord.name}'),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Breed: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${widget.petRecord.breed ?? 'Unknown'}',
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Age: ',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${widget.petRecord.age ?? 'Unknown'}',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          SizedBox(height: 24),

                          // Weight field only for existing pets
                          Text(
                            'Current Weight',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF333333),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextField(
                            controller: _weightController,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Color(0xFF6B86C9),
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              hintText: '0.0',
                              suffixText: 'kg',
                            ),
                          ),
                        ] else ...[
                          // แสดงฟอร์มเต็มสำหรับสัตว์ใหม่
                          Text(
                            'Pet Detail',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF7B8EB5),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Name Field
                          Text(
                            'Name',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF333333),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Color(0xFF6B86C9),
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Breed Field with Autocomplete
                          Text(
                            'Breed',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF333333),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          CompositedTransformTarget(
                            link: _layerLink,
                            child: Container(
                              key: _breedFieldKey,
                              child: TextField(
                                controller: _breedController,
                                focusNode: _breedFocusNode,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: Color(0xFF6B86C9),
                                    ),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  hintText: 'e.g., Labrador Retriever',
                                  suffixIcon:
                                      _breedController.text.isNotEmpty
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

                          const SizedBox(height: 16),

                          // Age Field with Years and Months
                          Text(
                            'Age',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF333333),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _ageYearsController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Color(0xFF6B86C9),
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    hintText: '0',
                                    suffixText: 'years',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _ageMonthsController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    TextInputFormatter.withFunction((
                                      oldValue,
                                      newValue,
                                    ) {
                                      final int? value = int.tryParse(
                                        newValue.text,
                                      );
                                      if (value == null) return newValue;
                                      if (value > 11) return oldValue;
                                      return newValue;
                                    }),
                                  ],
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey[300]!,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Color(0xFF6B86C9),
                                      ),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    hintText: '0',
                                    suffixText: 'months',
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Weight Field
                          Text(
                            'Weight',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF333333),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _weightController,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Colors.grey[300]!,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(
                                  color: Color(0xFF6B86C9),
                                ),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              hintText: '0.0',
                              suffixText: 'kg',
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Gender selection (only for new pets)
                          Text(
                            'Gender',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF333333),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Male'),
                                  value: 'Male',
                                  groupValue: _selectedGender,
                                  activeColor: Color(0xFF6B86C9),
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGender = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Female'),
                                  value: 'Female',
                                  groupValue: _selectedGender,
                                  activeColor: Color(0xFF6B86C9),
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGender = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Sterilized checkbox (only for new pets)
                          CheckboxListTile(
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedGender == 'Male'
                                      ? 'Neutered'
                                      : 'Spayed',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF333333),
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  _selectedGender == 'Male'
                                      ? '(Has been castrated)'
                                      : '(Has had ovaries removed)',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            value: _isSterilized,
                            activeColor: Color(0xFF6B86C9),
                            contentPadding: EdgeInsets.zero,
                            controlAffinity: ListTileControlAffinity.leading,
                            onChanged: (bool? value) {
                              setState(() {
                                _isSterilized = value!;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // Group Selection (only for new pets)
                          Text(
                            'Group',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF333333),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child:
                                    _groups.isEmpty
                                        ? Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Center(
                                            child: Text(
                                              'No groups available. Please create a group first.',
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        )
                                        : DropdownButtonHideUnderline(
                                          child: ButtonTheme(
                                            alignedDropdown: true,
                                            child: DropdownButton<String>(
                                              value:
                                                  _selectedGroup.isEmpty
                                                      ? _groups[0]['_id']
                                                      : _selectedGroup,
                                              icon: const Icon(
                                                Icons.keyboard_arrow_down,
                                              ),
                                              isExpanded: true,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                color: Color(0xFF333333),
                                                fontSize: 15,
                                              ),
                                              onChanged: (String? value) {
                                                if (value != null) {
                                                  setState(() {
                                                    _selectedGroup = value;
                                                  });
                                                }
                                              },
                                              items:
                                                  _groups.map<
                                                    DropdownMenuItem<String>
                                                  >((group) {
                                                    return DropdownMenuItem<
                                                      String
                                                    >(
                                                      value: group['_id'],
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.pets,
                                                            color: Color(
                                                              0xFF7B8EB5,
                                                            ),
                                                            size: 20,
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Text(
                                                            group['group_name'],
                                                          ),
                                                        ],
                                                      ),
                                                    );
                                                  }).toList(),
                                            ),
                                          ),
                                        ),
                              ),
                        ],

                        const SizedBox(height: 32),

                        // Navigation Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _goBack,
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF6B86C9),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child: const Text(
                                  'Back',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    color: Color(0xFF6B86C9),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _submitRecord,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6B86C9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                ),
                                child:
                                    _isLoading
                                        ? CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                        : Text(
                                          widget
                                                  .petRecord
                                                  .isNewRecordForExistingPet
                                              ? 'Add Record'
                                              : 'Submit',
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
        onItemTapped: _onItemTapped,
        onAddRecordsTap: () {},
      ),
    );
  }
}
