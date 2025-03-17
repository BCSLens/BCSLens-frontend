import 'package:flutter/material.dart';

class RecordsScreen extends StatefulWidget {
  const RecordsScreen({Key? key}) : super(key: key);

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  bool _showAddPetForm = false;
  int _selectedIndex = 0;
  String _selectedPetType = 'Cats';
  final TextEditingController _petNameController = TextEditingController();

  // Expanded state for groups
  final Map<String, bool> _expandedGroups = {
    'Cats': false,
    'Dogs': false, 
  };

  // Sample data
  final Map<String, List<Map<String, dynamic>>> _pets = {
    'Cats': [
      // Empty for now, will show count (2)
    ],
    'Dogs': [
      {
        'name': 'Max',
        'weight': '8 kg',
        'age': '3 years old',
        'bcs': 5,
        'image': 'assets/images/corgi.jpg',
        'isFavorite': true,
      },
      {
        'name': 'Max',
        'weight': '8 kg',
        'age': '3 years old',
        'bcs': 5,
        'image': 'assets/images/corgi.jpg',
        'isFavorite': true,
      },
      {
        'name': 'Max',
        'weight': '8 kg',
        'age': '3 years old',
        'bcs': 5,
        'image': 'assets/images/corgi.jpg',
        'isFavorite': true,
      },
      {
        'name': 'Max',
        'weight': '8 kg',
        'age': '3 years old',
        'bcs': 5,
        'image': 'assets/images/corgi.jpg',
        'isFavorite': true,
      },
    ],
  };

  @override
  void dispose() {
    _petNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          
          // Divider line under search
          Divider(
            color: Colors.grey.withOpacity(0.2),
            thickness: 1,
            height: 1,
          ),
          
          // Group header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFF5F5F5),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Color(0xFF7B8EB5),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          
          // Pet groups and list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ..._buildAllPetGroups(),
              ],
            ),
          ),
          
          // Bottom nav bar - direct implementation
          if (_showAddPetForm)
            _buildAddPetForm(),
        ],
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.folder_outlined, 'Records', true),
            _buildNavItem(Icons.add_circle_outline, 'Add Records', false, onTap: () {
              setState(() {
                _showAddPetForm = true;
              });
            }),
            _buildNavItem(Icons.star_border, 'Special Care', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon, 
            color: isActive ? const Color(0xFF7B8EB5) : const Color(0xFFACACAC),
            size: 24,
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? const Color(0xFF7B8EB5) : const Color(0xFFACACAC),
              fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAllPetGroups() {
    List<Widget> result = [];
    
    // Add Cats group
    result.add(_buildPetGroupCard('Cats', 2, 'assets/images/cat_icon.png', _expandedGroups['Cats'] ?? false));
    
    // If Cats group is expanded, show its pets (empty in this case but keeps space for UI)
    if (_expandedGroups['Cats'] ?? false) {
      result.add(const SizedBox(height: 8));
    }
    
    result.add(const SizedBox(height: 8));
    
    // Add Dogs group
    result.add(_buildPetGroupCard('Dogs', 4, 'assets/images/dog_icon.png', _expandedGroups['Dogs'] ?? false));
    
    // If Dogs group is expanded, show its pets
    if (_expandedGroups['Dogs'] ?? false) {
      final dogsList = _buildExpandedPets(_pets['Dogs']!);
      result.addAll(dogsList);
    }
    
    return result;
  }

  Widget _buildPetGroupCard(String type, int count, String iconAsset, bool isExpanded) {
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
              isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
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
              icon: const Icon(
                Icons.add,
                color: Color(0xFFACACAC),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _selectedPetType = type;
                  _showAddPetForm = true;
                });
              },
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
                        color: pet['isFavorite'] ? Colors.amber : Colors.grey[300],
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
                          onPressed: () {},
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

  Widget _buildAddPetForm() {
    return Container(
      color: Colors.white.withOpacity(0.95),
      child: Column(
        children: [
          const Spacer(),
          const Center(
            child: Text(
              'Add New Pet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B8EB5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Pet Name input
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.pets, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _petNameController,
                    decoration: const InputDecoration(
                      hintText: 'Pet Name',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Pet Type selection
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedPetType == 'Cats' ? Icons.pets : Icons.pets, 
                  color: Colors.grey
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPetType,
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      items: ['Cats', 'Dogs'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedPetType = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Cancel button
              SizedBox(
                width: 150,
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showAddPetForm = false;
                      _petNameController.clear();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF7B8EB5)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Color(0xFF7B8EB5)),
                  ),
                ),
              ),
              
              // Confirm button
              SizedBox(
                width: 150,
                child: ElevatedButton(
                  onPressed: () {
                    // Add pet logic here
                    setState(() {
                      _showAddPetForm = false;
                      _petNameController.clear();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B8EB5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 100), // Space for the nav bar plus some extra
        ],
      ),
    );
  }
}