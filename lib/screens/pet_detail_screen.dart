import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../models/pet_record_model.dart';

class PetDetailsScreen extends StatefulWidget {
  final PetRecord petRecord;

  const PetDetailsScreen({
    Key? key,
    required this.petRecord,
  }) : super(key: key);

  @override
  State<PetDetailsScreen> createState() => _PetDetailsScreenState();
}

class _PetDetailsScreenState extends State<PetDetailsScreen> {
  int _selectedIndex = 1;
  String _recordType = 'Add a New Pet';
  
  // Controllers for text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  // Other state variables
  String _selectedGender = 'Male';
  bool _isSterilized = false;
  String _selectedCategory = 'Dogs';
  
  // Available categories (groups)
  final List<String> _categories = ['Dogs', 'Cats'];

  @override
  void initState() {
    super.initState();
    // Initialize with existing data if available
    if (widget.petRecord.name != null) {
      _nameController.text = widget.petRecord.name!;
    }
    if (widget.petRecord.age != null) {
      _ageController.text = widget.petRecord.age!;
    }
    if (widget.petRecord.weight != null) {
      _weightController.text = widget.petRecord.weight!;
    }
    if (widget.petRecord.category != null) {
      _selectedCategory = widget.petRecord.category!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
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

  void _submitRecord() {
    // Validate inputs
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a name for your pet')),
      );
      return;
    }
    
    // Update pet record with form data
    widget.petRecord.name = _nameController.text;
    widget.petRecord.age = _ageController.text;
    widget.petRecord.weight = _weightController.text;
    widget.petRecord.category = _selectedCategory;
    // Add additional fields - you'll need to update your PetRecord model
    // widget.petRecord.gender = _selectedGender;
    // widget.petRecord.isSterilized = _isSterilized;
    
    // Save to database (implementation depends on your backend)
    // For now, we'll just navigate to records page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Record saved successfully!')),
    );
    
    // Navigate to records page
    Navigator.pushReplacementNamed(context, '/records');
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
                      'Step 4 of 4',
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
                      'Provide details about your pet',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF333333),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Record Type Question
                    Text(
                      'How would you like to add this record?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF333333),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Record Type Dropdown
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton<String>(
                            value: _recordType,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF333333),
                              fontSize: 15,
                            ),
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  _recordType = value;
                                });
                              }
                            },
                            items: <String>[
                              'Add a New Pet',
                              'Add to Existing Pet'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Pet Detail Heading
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Age Field
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
                    
                    TextField(
                      controller: _ageController,
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        hintText: 'e.g., 3 years',
                      ),
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
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        hintText: 'e.g., 8.5 kg',
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Gender selection
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
                    
                    // Sterilized checkbox
                    CheckboxListTile(
                      title: const Text(
                        'Sterilized',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Color(0xFF333333),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
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
                    
                    // Category Field
                    Text(
                      'Category',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF333333),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            icon: const Icon(Icons.keyboard_arrow_down),
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF333333),
                              fontSize: 15,
                            ),
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              }
                            },
                            items: _categories.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    Icon(
                                      value == 'Dogs' ? Icons.pets : Icons.emoji_nature,
                                      color: Color(0xFF7B8EB5),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(value),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
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
                            onPressed: _submitRecord,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6B86C9),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'Submit',
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