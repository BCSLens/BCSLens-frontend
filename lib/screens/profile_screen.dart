import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../widgets/bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  String _userName = '';
  String _userEmail = '';
  bool _isLoading = true;
  int _selectedIndex = 3;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('user_name') ?? 'User';
        _userEmail = prefs.getString('user_email') ?? 'user@example.com';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _userName = 'User';
        _userEmail = 'user@example.com';
        _isLoading = false;
      });
    }
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/records');
        break;
      case 1:
        // History - for now redirect to special care
        Navigator.pushReplacementNamed(context, '/special-care');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/special-care');
        break;
      case 3:
        // Already on Profile screen
        break;
    }
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _authService.signOut();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/welcome',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFEF4444),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontFamily: 'Inter',
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Soft blue gradient - อ่อนๆสวยๆ
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5B8CC9), // สีฟ้าเข้ม (บน)
              Color(0xFF7CA6DB), // สีฟ้ากลาง
              Color(0xFFA8C5E8), // สีฟ้าอ่อน
              Color(0xFFD0E3F5), // สีฟ้าอ่อนมาก (ล่าง)
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildModernHeader(),
                      SizedBox(height: 52),
                      _buildProfileCard(),
                      SizedBox(height: 24),
                      _buildMenuItems(),
                      SizedBox(height: 32),
                    ],
                  ),
                ),
        ),
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

  Widget _buildModernHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3), // แก้วใสๆ
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 25,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(Icons.settings, color: Color(0xFF6B86C9)),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Settings coming soon!'),
                          backgroundColor: Color(0xFF6B86C9),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6B86C9),
                  Color(0xFF8B9DC3),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Text(
            _userName,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 4),
          Text(
            _userEmail,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems() {
    final menuItems = [
      {
        'icon': Icons.edit_outlined,
        'title': 'Edit Profile',
        'subtitle': 'Update your information',
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Edit Profile coming soon!'),
              backgroundColor: Color(0xFF6B86C9),
            ),
          );
        },
      },
      {
        'icon': Icons.notifications_outlined,
        'title': 'Notifications',
        'subtitle': 'Manage notification settings',
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Notifications coming soon!'),
              backgroundColor: Color(0xFF6B86C9),
            ),
          );
        },
      },
      {
        'icon': Icons.help_outline,
        'title': 'Help & Support',
        'subtitle': 'Get help and contact support',
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Help & Support coming soon!'),
              backgroundColor: Color(0xFF6B86C9),
            ),
          );
        },
      },
      {
        'icon': Icons.info_outline,
        'title': 'About',
        'subtitle': 'App version and information',
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('BCS Lens v1.0.0'),
              backgroundColor: Color(0xFF6B86C9),
            ),
          );
        },
      },
      {
        'icon': Icons.logout,
        'title': 'Logout',
        'subtitle': 'Sign out of your account',
        'onTap': _handleLogout,
        'isDestructive': true,
      },
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: menuItems.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == menuItems.length - 1;
          final isDestructive = item['isDestructive'] as bool? ?? false;

          return InkWell(
            onTap: item['onTap'] as VoidCallback,
            borderRadius: BorderRadius.vertical(
              top: index == 0 ? Radius.circular(20) : Radius.zero,
              bottom: isLast ? Radius.circular(20) : Radius.zero,
            ),
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: !isLast
                    ? Border(
                        bottom: BorderSide(
                          color: Color(0xFFF1F5F9),
                          width: 1,
                        ),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDestructive
                          ? Color(0xFFEF4444).withOpacity(0.1)
                          : Color(0xFF6B86C9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: isDestructive ? Color(0xFFEF4444) : Color(0xFF6B86C9),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDestructive
                                ? Color(0xFFEF4444)
                                : Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          item['subtitle'] as String,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}