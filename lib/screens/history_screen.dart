// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:intl/intl.dart';
import '../services/pet_service.dart';

class HistoryScreen extends StatefulWidget {
  final Map<String, dynamic> pet;
  final String groupName;

  const HistoryScreen({Key? key, required this.pet, required this.groupName})
    : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _bubbleController;
  late AnimationController _numberController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _bubbleAnimation;
  late Animation<double> _numberAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 200),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _bubbleController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _numberController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );

    _bubbleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _bubbleController, curve: Curves.elasticOut));

    _numberAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _numberController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
    
    // Start bubble animation after a delay
    Future.delayed(Duration(milliseconds: 150), () {
      _bubbleController.forward();
    });
    
    // Start number animation after bubble animation
    Future.delayed(Duration(milliseconds: 250), () {
      _numberController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _bubbleController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
        child: Column(
          children: [
            _buildModernHeader(),
              _buildPetImageSection(),
              _buildBubbleSection(),
              _buildPetInfoSection(),
              _buildRecordsSection(),
              _buildGraphsSection(),
              SizedBox(height: 100), // Space for bottom nav
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 0,
        onItemTapped: (index) {
          if (index == 1) {
          Navigator.pushReplacementNamed(context, '/add-record');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/special-care');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
        },
        onAddRecordsTap: () {},
      ),
    );
  }

  Widget _buildModernHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6B86C9),
            Color(0xFF8BA3E7),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6B86C9).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 20, 24, 30),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  children: [
                    Text(
                      widget.groupName,
                  style: TextStyle(
                    fontFamily: 'Inter',
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pet Health History',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 44), // Balance the back button
          ],
        ),
      ),
    );
  }

  Widget _buildPetImageSection() {
    String imageUrl = '';

    if (widget.pet['records'] != null && (widget.pet['records'] as List).isNotEmpty) {
      final latestRecord = (widget.pet['records'] as List).last;
      final frontImageUrl = latestRecord['front_image_url'];

      if (frontImageUrl != null && frontImageUrl.toString().isNotEmpty) {
        String originalUrl = frontImageUrl.toString();
        
        if (originalUrl.startsWith('http')) {
          if (originalUrl.contains('172.20.10.3') || originalUrl.contains('localhost') || originalUrl.contains('127.0.0.1')) {
            String filename = originalUrl.split('/').last;
            imageUrl = '${PetService.uploadBaseUrl}/uploads/$filename';
        } else {
            imageUrl = originalUrl;
        }
      } else {
          imageUrl = '${PetService.uploadBaseUrl}/uploads/$originalUrl';
        }
      }
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: EdgeInsets.all(24),
          height: 400,
          child: Stack(
        children: [
              // Pet Image - ครึ่งหน้าจอ
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5 - 48, // ครึ่งหน้าจอลบ margin
                  height: 350,
            decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: Offset(0, 20),
                ),
              ],
            ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: imageUrl.isNotEmpty
                      ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                          return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF6B86C9), Color(0xFF8BA3E7)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                            Icons.pets,
                            color: Colors.white,
                                    size: 120,
                                  ),
                                ),
                          );
                        },
                      )
                        : Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF6B86C9), Color(0xFF8BA3E7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.pets,
                                color: Colors.white,
                                size: 120,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              // BCS Score with connecting line - ขนาดใหญ่ขึ้น
              Positioned(
                right: 100,
                top: 50,
                child: _buildConnectedBubble(
                  'BCS',
                  _getBcsScore(),
                  Color(0xFF6B86C9), // ใช้สีน้ำเงินสวยงาม
                  Icons.monitor_weight,
                  Offset(-200, 50), // เส้นยาวขึ้นสำหรับ BCS
                  Offset(0, 50), // End point (at bubble)
                  isLarge: true, // เพิ่มพารามิเตอร์สำหรับขนาดใหญ่
                ),
              ),
              // Weight with connecting line
              Positioned(
                right: 191, // เลื่อนชิดซ้ายมากขึ้น (จาก 20 เป็น 40)
                top: 200, // กลับไปที่ตำแหน่งเดิม
                child: _buildConnectedBubble(
                  'Weight',
                  _getWeight(),
                  Color(0xFF10B981), // ใช้สีเขียวสวยงาม
                  Icons.scale,
                  Offset(-130, 50), // เพิ่มความยาวเส้นล่าง
                  Offset(0, 50), // End point (at bubble)
                ),
              ),
      ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedBubble(String label, int value, Color color, IconData icon, Offset lineStart, Offset lineEnd, {bool isLarge = false}) {
    return AnimatedBuilder(
      animation: _bubbleAnimation,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Connecting line - ปรับความยาวตาม isLarge
            Positioned(
              left: lineStart.dx,
              top: lineStart.dy,
              child: Container(
                width: isLarge ? 200 : 132, // เพิ่มความยาวเส้นล่างอีกนิดนึง
                height: 1, // ลดความหนาให้บางลง
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
            // Bubble with enhanced design - ปรับขนาดตาม isLarge
            Transform.scale(
              scale: _bubbleAnimation.value,
              child: Container(
                width: isLarge ? 100 : 80, // ขนาดใหญ่ถ้า isLarge = true
                height: isLarge ? 100 : 80, // ขนาดใหญ่ถ้า isLarge = true
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.9),
                      color.withOpacity(0.7),
                      color.withOpacity(0.5),
                    ],
                    stops: [0.0, 0.3, 0.7, 1.0], // เพิ่ม stops สำหรับไล่เฉดที่สวยงาม
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.6),
                      blurRadius: 30,
                      offset: Offset(0, 20),
                    ),
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 60,
                      offset: Offset(0, 30),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.3),
                      blurRadius: 10,
                      offset: Offset(-5, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLarge ? 8 : 6, 
                        vertical: isLarge ? 3 : 2
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(isLarge ? 10 : 8),
                      ),
                      child: Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: Colors.white,
                          fontSize: isLarge ? 12 : 10, // ขนาดใหญ่ขึ้นถ้า isLarge
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    SizedBox(height: isLarge ? 6 : 4),
                    AnimatedBuilder(
                      animation: _numberAnimation,
                      builder: (context, child) {
                        int animatedValue = (value * _numberAnimation.value).round();
                        return Container(
                          padding: EdgeInsets.all(isLarge ? 6 : 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            animatedValue.toString(),
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Colors.white,
                              fontSize: isLarge ? 22 : 18, // ขนาดใหญ่ขึ้นถ้า isLarge
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  int _getBcsScore() {
    final List<dynamic> rawRecords = widget.pet['records'] ?? [];
    if (rawRecords.isNotEmpty) {
      final latestRecord = rawRecords.last;
      return int.tryParse(latestRecord['score']?.toString() ?? '5') ?? 5;
    }
    return 5;
  }

  int _getWeight() {
    final List<dynamic> rawRecords = widget.pet['records'] ?? [];
    if (rawRecords.isNotEmpty) {
      final latestRecord = rawRecords.last;
      return (double.tryParse(latestRecord['weight']?.toString() ?? '0') ?? 0.0).toInt();
    }
    return 0;
  }

  Widget _buildBubbleSection() {
    // This section is now integrated into the pet image section
    return SizedBox.shrink();
  }

  Widget _buildBubble(String label, int value, Color color, IconData icon) {
    return AnimatedBuilder(
      animation: _numberAnimation,
      builder: (context, child) {
        int animatedValue = (value * _numberAnimation.value).round();
        
        return Container(
          width: 80,
          height: 80,
        decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
                    BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
                color: Colors.white,
                size: 20,
            ),
              SizedBox(height: 4),
            Text(
                animatedValue.toString(),
              style: TextStyle(
                fontFamily: 'Inter',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
          Text(
                label,
            style: TextStyle(
              fontFamily: 'Inter',
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActualGraph(String title, Color color) {
    // ใช้ข้อมูลจริงจาก records
    final List<dynamic> rawRecords = widget.pet['records'] ?? [];
    List<Map<String, dynamic>> chartData = [];
    
    if (rawRecords.isNotEmpty) {
      // แปลงข้อมูล records เป็นข้อมูลสำหรับกราฟ
      chartData = rawRecords.map((record) {
        final date = DateTime.parse(record['date'] ?? DateTime.now().toIso8601String());
        return {
          'date': date,
          'bcs': record['score'] ?? 5,
          'weight': record['weight'] ?? 0,
          'formattedDate': '${date.day}/${date.month}',
        };
      }).toList();
      
      // เรียงลำดับตามวันที่
      chartData.sort((a, b) => a['date'].compareTo(b['date']));
    }
    
    // ถ้าไม่มีข้อมูลเลย ให้แสดงข้อความว่าไม่มีข้อมูล
    if (chartData.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              color: color.withOpacity(0.5),
              size: 32,
            ),
            SizedBox(height: 8),
            Text(
              'No data available',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // แสดงข้อมูลล่าสุด
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest: ${title == 'BCS Trend' ? chartData.last['bcs'] : chartData.last['weight']}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '${chartData.length} record${chartData.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // แสดงกราฟแบบ Line Chart
          Container(
            height: 80,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: CustomPaint(
              painter: LineChartPainter(
                data: chartData,
                title: title,
                color: color,
              ),
              size: Size.infinite,
            ),
          ),
          SizedBox(height: 6),
          // แสดงวันที่
          Container(
            height: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: chartData.map((data) {
                return Text(
                  data['formattedDate'],
                  style: TextStyle(
                    fontSize: 9, 
                    color: Color(0xFF64748B), 
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBcsColor(int score) {
    if (score <= 3) return Color(0xFF3B82F6); // Blue for underweight
    if (score >= 4 && score <= 6) return Color(0xFF10B981); // Green for ideal
    return Color(0xFFEF4444); // Red for overweight
  }

  Widget _buildPetInfoSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.all(24),
        child: Column(
          children: [
            // Pet Information
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
                borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 25,
                    offset: Offset(0, 15),
          ),
        ],
      ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                  Row(
                    children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF6B86C9).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
                          Icons.pets,
              color: Color(0xFF6B86C9),
                          size: 24,
            ),
          ),
          SizedBox(width: 16),
                Text(
                        'Pet Information',
                  style: TextStyle(
                    fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
                    ],
                  ),
                  SizedBox(height: 24),
                  _buildInfoRow(Icons.badge, 'Name', widget.pet['name'] ?? 'Unknown'),
                  _buildInfoRow(Icons.pets, 'Gender', widget.pet['gender'] ?? 'Unknown'),
                  _buildInfoRow(Icons.category, 'Breed', widget.pet['breed'] ?? 'Unknown'),
                  _buildInfoRow(Icons.medical_services, 'Spay/Neuter', 
                      (widget.pet['is_sterilized'] == true) ? 'Yes' : 'No'),
              ],
            ),
          ),
            SizedBox(height: 20),
            // Recommendation
          Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 25,
                    offset: Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.lightbulb_outline,
                          color: Color(0xFFF59E0B),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                Text(
                        'Recommendation',
                  style: TextStyle(
                    fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Based on BCS Score',
                      style: TextStyle(
                        fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildRecommendationContent(),
                ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildRecommendationContent() {
    int bcsScore = _getBcsScore();
    String recommendation = '';
    Color recommendationColor = Color(0xFF6B86C9);

    if (bcsScore <= 3) {
      recommendation = 'Your pet is underweight. Consider increasing food portions and consult a veterinarian.';
      recommendationColor = Color(0xFF3B82F6);
    } else if (bcsScore >= 4 && bcsScore <= 6) {
      recommendation = 'Great! Your pet has an ideal body condition. Maintain current feeding routine.';
      recommendationColor = Color(0xFF10B981);
    } else {
      recommendation = 'Your pet is overweight. Consider reducing food portions and increasing exercise.';
      recommendationColor = Color(0xFFEF4444);
    }

    return Container(
      padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
        color: recommendationColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: recommendationColor.withOpacity(0.3),
          width: 1,
        ),
            ),
            child: Text(
        recommendation,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
          color: Color(0xFF1E293B),
          height: 1.4,
              ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
          children: [
            Container(
            padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
              color: Color(0xFF6B86C9).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Color(0xFF6B86C9),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
            Text(
                  label,
              style: TextStyle(
                fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
            Text(
                  value,
              style: TextStyle(
                fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
              ),
            ),
          ],
        ),
      );
    }

  Widget _buildRecordsSection() {
    final List<dynamic> rawRecords = widget.pet['records'] ?? [];
    
    if (rawRecords.isEmpty) {
      return _buildEmptyRecords();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              'Health Records',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 16),
            ...rawRecords.reversed.take(5).map((record) => _buildRecordCard(record)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyRecords() {
      return Container(
      margin: EdgeInsets.all(24),
      padding: EdgeInsets.all(40),
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
          Icon(
            Icons.medical_information,
            color: Color(0xFF6B86C9),
            size: 48,
          ),
          SizedBox(height: 16),
                Text(
            'No Records Yet',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
              fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
          SizedBox(height: 8),
            Text(
            'Start tracking your pet\'s health by adding their first record.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    DateTime recordDate = DateTime.tryParse(record['date'] ?? '') ?? DateTime.now();
    String formattedDate = DateFormat('dd MMMM yyyy').format(recordDate);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
            children: [
              Container(
            width: 40,
            height: 40,
                decoration: BoxDecoration(
              color: Color(0xFF6B86C9).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
              Icons.medical_information,
              color: Color(0xFF6B86C9),
                  size: 20,
                ),
              ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Text(
                  formattedDate,
                style: TextStyle(
                  fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
                SizedBox(height: 4),
                Text(
                  'BCS: ${record['score'] ?? 'N/A'} • Weight: ${record['weight'] ?? 'N/A'} kg',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphsSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Text(
              'Health Trends',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
            SizedBox(height: 16),
            _buildTrendGraph('BCS Trend', Color(0xFF6B86C9)),
            SizedBox(height: 16),
            _buildTrendGraph('Weight Trend', Color(0xFF10B981)),
          ],
        ),
        ),
      );
    }

  Widget _buildTrendGraph(String title, Color color) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _buildActualGraph(title, color),
          ),
        ],
      ),
    );
  }
}

class LineChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final String title;
  final Color color;

  LineChartPainter({
    required this.data,
    required this.title,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // เพิ่ม padding เพื่อป้องกัน overflow
    final padding = 12.0;
    final chartWidth = size.width - (padding * 2);
    final chartHeight = size.height - (padding * 2);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // คำนวณจุดข้อมูล
    final points = <Offset>[];
    final double maxValue = title == 'BCS Trend' ? 9.0 : 30.0;
    final double minValue = title == 'BCS Trend' ? 1.0 : 0.0;
    
    // หาค่าต่ำสุดและสูงสุดจากข้อมูลจริง
    double actualMin = double.infinity;
    double actualMax = double.negativeInfinity;
    
    for (int i = 0; i < data.length; i++) {
      final value = title == 'BCS Trend' 
          ? data[i]['bcs'].toDouble() 
          : data[i]['weight'].toDouble();
      if (value < actualMin) actualMin = value;
      if (value > actualMax) actualMax = value;
    }
    
    // ใช้ค่าจริงหรือค่าเริ่มต้น
    final double rangeMin = actualMin == double.infinity ? minValue : actualMin - 1;
    final double rangeMax = actualMax == double.negativeInfinity ? maxValue : actualMax + 1;
    
    for (int i = 0; i < data.length; i++) {
      final value = title == 'BCS Trend' 
          ? data[i]['bcs'].toDouble() 
          : data[i]['weight'].toDouble();
      
      final x = padding + (i / (data.length - 1)) * chartWidth;
      final y = padding + chartHeight - ((value - rangeMin) / (rangeMax - rangeMin)) * chartHeight;
      
      points.add(Offset(x, y));
    }

    // วาดพื้นที่ใต้เส้นกราฟ (Gradient effect)
    if (points.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, padding + chartHeight);
      fillPath.lineTo(points.first.dx, points.first.dy);
      
      for (int i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      
      fillPath.lineTo(points.last.dx, padding + chartHeight);
      fillPath.close();
      
      canvas.drawPath(fillPath, fillPaint);
    }

    // วาดเส้นกราฟ
    if (points.length == 1) {
      // ถ้ามี 1 จุด ให้วาดจุดเดียว
      final point = points.first;
      canvas.drawCircle(point, 6, pointPaint);
      canvas.drawCircle(point, 3, Paint()..color = Colors.white);
    } else if (points.length == 2) {
      // ถ้ามี 2 จุด ให้วาดเส้นตรง
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      path.lineTo(points.last.dx, points.last.dy);
      canvas.drawPath(path, paint);
    } else {
      // ถ้ามีมากกว่า 2 จุด ให้วาด smooth curve
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      
      for (int i = 1; i < points.length - 1; i++) {
        final current = points[i];
        final next = points[i + 1];
        
        final controlPoint1 = Offset(
          current.dx + (next.dx - current.dx) * 0.3,
          current.dy,
        );
        final controlPoint2 = Offset(
          current.dx + (next.dx - current.dx) * 0.7,
          next.dy,
        );
        
        path.cubicTo(
          controlPoint1.dx, controlPoint1.dy,
          controlPoint2.dx, controlPoint2.dy,
          next.dx, next.dy,
        );
      }
      
      canvas.drawPath(path, paint);
    }

    // วาดจุดข้อมูลพร้อม shadow
    for (final point in points) {
      // Shadow
      canvas.drawCircle(Offset(point.dx + 1, point.dy + 1), 5, shadowPaint);
      // Main point
      canvas.drawCircle(point, 4, pointPaint);
      // Inner highlight
      canvas.drawCircle(point, 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF6B86C9)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(
      size.width / 2, 
      size.height / 2 - 10,
      size.width, 
      size.height / 2
    );

      canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
