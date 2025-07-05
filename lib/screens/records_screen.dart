import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'history_screen.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({Key? key}) : super(key: key);

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  int _selectedIndex = 0;
  bool _showAddGroupForm = false;
  bool _showAddPetForm = false;
  String _selectedPetType = 'Cats';
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();

  // Expanded state for groups
  final Map<String, bool> _expandedGroups = {'Cats': false, 'Dogs': false};

  // Sample data
  final Map<String, List<Map<String, dynamic>>> _pets = {
    'Cats': [],
    'Dogs': [
      {
        'name': 'Max',
        'weight': '8 kg',
        'age': '3 years old',
        'bcs': 5,
        'image': 'assets/images/bcs_lens_logo.jpg',
        'isFavorite': true,
      },
      {
        'name': 'SAN',
        'weight': '8 kg',
        'age': '3 years old',
        'bcs': 5,
        'image': 'assets/images/bcs_lens_logo.jpg',
        'isFavorite': true,
      },
    ],
  };

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
    _petNameController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  void _showAddGroupDialog() {
    setState(() {
      _showAddGroupForm = true;
    });
  }

  void _addNewGroup() {
    if (_groupNameController.text.isNotEmpty) {
      setState(() {
        // Check if group doesn't already exist
        String newGroupName = _groupNameController.text;
        if (!_pets.containsKey(newGroupName)) {
          // Add new group to pets map
          _pets[newGroupName] = [];
          // Set initial expansion state for new group
          _expandedGroups[newGroupName] = false;
          // Clear the group name controller
          _groupNameController.clear();
          // Hide the group creation form
          _showAddGroupForm = false;
        } else {
          // Optional: Show a snackbar if group already exists
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Group already exists')));
        }
      });
    }
  }

  void _showAddPetDialog(String groupName) {
    setState(() {
      _selectedPetType = groupName;
      _showAddPetForm = true;
    });
  }

  void _addNewPet() {
    if (_petNameController.text.isNotEmpty) {
      setState(() {
        // Add new pet to the selected group
        _pets[_selectedPetType]?.add({
          'name': _petNameController.text,
          'weight': 'N/A',
          'age': 'N/A',
          'bcs': 0,
          'image': 'assets/images/default_pet.png', // Add a placeholder image
          'isFavorite': false,
        });

        // Reset form
        _petNameController.clear();
        _showAddPetForm = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Records',
          style: TextStyle(
            color: Color(0xFF7B8EB5),
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.upload_outlined,
              color: Color(0xFF7B8EB5),
              size: 24,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
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
                      const Text(
                        'Search',
                        style: TextStyle(
                          color: Color(0xFFACACAC),
                          fontSize: 17,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.tune,
                        color: Color(0xFFACACAC),
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),

              // Group header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [..._buildAllPetGroups()],
                ),
              ),
            ],
          ),

          // Group creation overlay
          if (_showAddGroupForm)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _groupNameController,
                            decoration: const InputDecoration(
                              hintText: 'Group Name',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _showAddGroupForm = false;
                                    _groupNameController.clear();
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF7B8EB5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Color(0xFF7B8EB5),
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
                                  backgroundColor: const Color(0xFF7B8EB5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: const EdgeInsets.symmetric(
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

          // Add Pet overlay
          if (_showAddPetForm)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Add New Pet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF7B8EB5),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Pet Name Field
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: TextField(
                            controller: _petNameController,
                            decoration: const InputDecoration(
                              hintText: 'Pet Name',
                              prefixIcon: Icon(
                                Icons.pets,
                                color: Color(0xFF7B8EB5),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Group Selection
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedPetType,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                Icons.pets,
                                color: Color(0xFF7B8EB5),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down),
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                            onChanged: (String? value) {
                              if (value != null) {
                                setState(() {
                                  _selectedPetType = value;
                                });
                              }
                            },
                            items:
                                _pets.keys.map<DropdownMenuItem<String>>((
                                  String value,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _showAddPetForm = false;
                                    _petNameController.clear();
                                  });
                                },
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFF7B8EB5),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: Color(0xFF7B8EB5),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _addNewPet,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF7B8EB5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  padding: const EdgeInsets.symmetric(
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

  List<Widget> _buildAllPetGroups() {
    List<Widget> result = [];

    // Dynamically build groups
    _pets.forEach((groupName, groupPets) {
      result.add(
        _buildPetGroupCard(
          groupName,
          groupPets.length,
          'assets/images/bcs_lens_logo.png',
          _expandedGroups[groupName] ?? false,
        ),
      );

      // If group is expanded, show its pets
      if (_expandedGroups[groupName] ?? false) {
        final petsList = _buildExpandedPets(groupPets);
        result.addAll(petsList);
      }

      result.add(const SizedBox(height: 8));
    });

    return result;
  }

  Widget _buildPetGroupCard(
    String type,
    int count,
    String iconAsset,
    bool isExpanded,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedGroups[type] = !(_expandedGroups[type] ?? false);
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
            Icon(
              type == 'Cats' ? Icons.pets : Icons.pets,
              color: const Color(0xFF7B8EB5),
              size: 24,
            ),
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
              onPressed: () => _showAddPetDialog(type),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExpandedPets(List<Map<String, dynamic>> pets) {
    List<Widget> petWidgets = [];

    for (var pet in pets) {
      petWidgets.add(const SizedBox(height: 8));
      petWidgets.add(_buildPetCard(pet));
    }

    return petWidgets;
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
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
            // Pet image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                pet['image'],
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 70,
                    height: 70,
                    color: Colors.grey[300],
                    child: const Icon(Icons.pets, color: Colors.white),
                  );
                },
              ),
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
                        pet['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.star,
                        color:
                            pet['isFavorite'] ? Colors.amber : Colors.grey[300],
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Weight ${pet['weight']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Age ${pet['age']}',
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
                            '${pet['bcs']}',
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
                          onPressed: () {},
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
                                builder:
                                    (context) => HistoryScreen(
                                      pet: pet,
                                      groupName: _selectedPetType,
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
}
