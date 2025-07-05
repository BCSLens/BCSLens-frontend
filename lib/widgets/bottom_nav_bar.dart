import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int)? onItemTapped;
  final VoidCallback onAddRecordsTap;

  const BottomNavBar({
    Key? key,
    required this.selectedIndex,
    this.onItemTapped,
    required this.onAddRecordsTap,
  }) : super(key: key);

  static const _activeColor = Color(0xFF7B8EB5);
  static const _inactiveColor = Colors.grey;

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
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            icon: Icons.folder_outlined,
            label: 'Records',
            isSelected: selectedIndex == 0,
            onTap: () {
              if (onItemTapped != null) {
                onItemTapped!(0);
              } else {
                Navigator.pushReplacementNamed(context, '/records');
              }
            },
          ),
          _buildNavItem(
            icon: Icons.add_circle_outline,
            label: 'Add Records',
            isSelected: selectedIndex == 1,
            onTap: onAddRecordsTap,
          ),
          _buildNavItem(
            icon: Icons.star_border,
            label: 'Special Care',
            isSelected: selectedIndex == 2,
            onTap: () {
              if (onItemTapped != null) {
                onItemTapped!(2);
              } else {
                Navigator.pushReplacementNamed(context, '/special-care');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? _activeColor : _inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? _activeColor : _inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}