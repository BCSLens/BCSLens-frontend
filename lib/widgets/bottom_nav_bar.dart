import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final bool showAddPetForm;
  final VoidCallback onAddRecordsTap;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    required this.onItemTapped,
    this.showAddPetForm = false,
    required this.onAddRecordsTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Records - left item
          Expanded(
            flex: 3,
            child: _bottomNavItem(
              icon: Icons.folder_outlined,
              label: 'Records',
              isSelected: selectedIndex == 0,
              onTap: () => onItemTapped(0),
            ),
          ),
          
          // Add Records - center item with right shift
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0),
              child: _bottomNavItem(
                icon: Icons.add_circle_outline,
                label: 'Add Records',
                isSelected: showAddPetForm,
                onTap: onAddRecordsTap,
              ),
            ),
          ),
          
          // Special Care - right item
          Expanded(
            flex: 3,
            child: _bottomNavItem(
              icon: Icons.star_border,
              label: 'Special Care',
              isSelected: selectedIndex == 2,
              onTap: () => onItemTapped(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF7B8EB5) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isSelected ? const Color(0xFF7B8EB5) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}