import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../models/pet_record_model.dart';

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
    if (widget.petRecord.gender != null) {
      _selectedGender = widget.petRecord.gender!;
    }
    if (widget.petRecord.isSterilized != null) {
      _isSterilized = widget.petRecord.isSterilized!;
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
      Navigator.pushNamedAndRemoveUntil(context, '/records', (route) => false);
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
    widget.petRecord.gender = _selectedGender;
    widget.petRecord.isSterilized = _isSterilized;

    // Debug print all the input information
    _printInputInformation();

    // Navigate to review details page
    Navigator.pushNamed(
      context,
      '/review-details',
      arguments: widget.petRecord,
    );
  }

  void _printInputInformation() {
    // Print all the input information to the console for debugging
    print('===== Pet Information =====');
    print('Record Type: $_recordType');
    print('Name: ${_nameController.text}');
    print('Age: ${_ageController.text}');
    print('Weight: ${_weightController.text}');
    print('Gender: $_selectedGender');
    print('Sterilized: $_isSterilized');
    print('Category: $_selectedCategory');

    // Also print to the PetRecord object for verification
    print('===== PetRecord Object =====');
    print('Name: ${widget.petRecord.name}');
    print('Age: ${widget.petRecord.age}');
    print('Weight: ${widget.petRecord.weight}');
    print('Gender: ${widget.petRecord.gender}');
    print('Sterilized: ${widget.petRecord.isSterilized}');
    print('Category: ${widget.petRecord.category}');
    print('BCS ${widget.petRecord.bcs}');
    print('suggestion ${widget.petRecord.additionalNotes}');

    // You can also show a toast or snackbar with this information
    final message = '''
    Name: ${_nameController.text}
    Age: ${_ageController.text}
    Weight: ${_weightController.text}
    Gender: $_selectedGender
    Sterilized: ${_isSterilized ? 'Yes' : 'No'}
    Category: $_selectedCategory
    ''';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pet information submitted:\n$message'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'How would you like to add this record?',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7B8EB5)),
          onPressed: _goBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    style: const TextStyle(
                      color: Color(0xFF333333),
                      fontSize: 16,
                    ),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _recordType = value;
                        });
                      }
                    },
                    items:
                        <String>[
                          'Add a New Pet',
                          'Add to Existing Pet',
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
            const Text(
              'Pet Detail',
              style: TextStyle(
                color: Color(0xFF7B8EB5),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // Name Field
            const Text(
              'Name',
              style: TextStyle(
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
                  borderSide: const BorderSide(color: Color(0xFF6B86C9)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Age Field
            const Text(
              'Age',
              style: TextStyle(
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
                  borderSide: const BorderSide(color: Color(0xFF6B86C9)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintText: 'e.g., 3 years',
              ),
            ),

            const SizedBox(height: 16),

            // Weight Field
            const Text(
              'Weight',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
                  borderSide: const BorderSide(color: Color(0xFF6B86C9)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                hintText: 'e.g., 8.5 kg',
              ),
            ),

            const SizedBox(height: 24),

            // Gender selection
            const Text(
              'Gender',
              style: TextStyle(
                color: Color(0xFF333333),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Radio<String>(
                  value: 'Male',
                  groupValue: _selectedGender,
                  activeColor: const Color(0xFF6B86C9),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                ),
                const Text('Male'),
                const SizedBox(width: 24),
                Radio<String>(
                  value: 'Female',
                  groupValue: _selectedGender,
                  activeColor: const Color(0xFF6B86C9),
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value!;
                    });
                  },
                ),
                const Text('Female'),
              ],
            ),

            const SizedBox(height: 16),

            // Sterilized checkbox
            Row(
              children: [
                Checkbox(
                  value: _isSterilized,
                  activeColor: const Color(0xFF6B86C9),
                  onChanged: (bool? value) {
                    setState(() {
                      _isSterilized = value!;
                    });
                  },
                ),
                const Text(
                  'Sterilized',
                  style: TextStyle(
                    color: Color(0xFF333333),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Category Field
            const Text(
              'Category',
              style: TextStyle(
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
                    style: const TextStyle(
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
                    items:
                        _categories.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Row(
                              children: [
                                Icon(
                                  value == 'Dogs'
                                      ? Icons.pets
                                      : Icons.emoji_nature,
                                  color: const Color(0xFF7B8EB5),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Back',
                      style: TextStyle(color: Color(0xFF6B86C9), fontSize: 16),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
