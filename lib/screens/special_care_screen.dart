import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'history_screen.dart';

class SpecialCareScreen extends StatefulWidget {
  const SpecialCareScreen({Key? key}) : super(key: key);

  @override
  State<SpecialCareScreen> createState() => _SpecialCareScreenState();
}

class _SpecialCareScreenState extends State<SpecialCareScreen> {
  int _selectedIndex = 2;

  // Sample data for special care pets
  final List<Map<String, dynamic>> _specialCarePets = [
    {
      'name': 'Max',
      'weight': '8 kg',
      'age': '3 years old',
      'bcs': 5,
      'image': 'assets/images/bcs_lens_logo.jpg',
      'isFavorite': true,
    },
    {
      'name': 'Max',
      'weight': '8 kg',
      'age': '3 years old',
      'bcs': 5,
      'image': 'assets/images/bcs_lens_logo.jpg',
      'isFavorite': true,
    },
    {
      'name': 'Max',
      'weight': '8 kg',
      'age': '3 years old',
      'bcs': 5,
      'image': 'assets/images/bcs_lens_logo.jpg',
      'isFavorite': true,
    },
    {
      'name': 'Max',
      'weight': '8 kg',
      'age': '3 years old',
      'bcs': 5,
      'image': 'assets/images/bcs_lens_logo.jpg',
      'isFavorite': true,
    },
    {
      'name': 'Max',
      'weight': '8 kg',
      'age': '3 years old',
      'bcs': 5,
      'image': 'assets/images/bcs_lens_logo.jpg',
      'isFavorite': true,
    },
  ];

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/records');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/add-record');
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
          'Special Care',
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
          
          // Pet list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _specialCarePets.length,
              itemBuilder: (context, index) {
                final pet = _specialCarePets[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPetCard(pet),
                );
              },
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
                          onPressed: () {
                            // Add to special care functionality
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
                            // Navigate to pet details or history
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => HistoryScreen(
                                  pet: pet,
                                  groupName: 'Dogs', // Default group
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