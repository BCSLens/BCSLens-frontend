import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';

class SpecialCareScreen extends StatefulWidget {
  const SpecialCareScreen({Key? key}) : super(key: key);

  @override
  State<SpecialCareScreen> createState() => _SpecialCareScreenState();
}

class _SpecialCareScreenState extends State<SpecialCareScreen> {
  int _selectedIndex = 2;

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
      // ... other code ...
      bottomNavigationBar: BottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        onAddRecordsTap: () {
          Navigator.pushReplacementNamed(context, '/add-record');
        },
      ),
    );
  }
}