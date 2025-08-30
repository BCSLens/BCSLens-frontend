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

  static const _activeColor = Color(0xFF6B86C9);
  static const _inactiveColor = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6B86C9).withOpacity(0.15),
            spreadRadius: 0,
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(
            icon: Icons.home,
            label: 'Home',
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
            icon: Icons.add,
            label: 'Add',
            isSelected: selectedIndex == 1,
            onTap: onAddRecordsTap,
          ),
          _buildNavItem(
            icon: Icons.star,
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
          _buildNavItem(
            icon: Icons.person,
            label: 'Profile',
            isSelected: selectedIndex == 3,
            onTap: () {
              if (onItemTapped != null) {
                onItemTapped!(3);
              } else {
                Navigator.pushReplacementNamed(context, '/profile');
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
        child: Container(
          height: 55,
          margin: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? _activeColor : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _activeColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : _inactiveColor,
                size: 22,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : _inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}