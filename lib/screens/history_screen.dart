// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../widgets/frosted_glass_header.dart';
import '../widgets/gradient_background.dart';
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
      backgroundColor: Color(0xFFD0E3F5), // สีฟ้าอ่อนมาก (ล่างสุด) เพื่อให้ตรงกับ gradient
      body: GradientBackground(
        child: SafeArea(
        child: SingleChildScrollView(
        child: Column(
          children: [
                FrostedGlassHeader(
                  title: widget.groupName,
                  subtitle: 'Pet Health History',
                  leadingWidget: HeaderBackButton(),
        ),
                // Box ใหญ่ครอบทั้งหมด (รวม Health Trends)
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85), // สีขาวมากขึ้น
                    borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
                        color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
                child: Column(
                  children: [
                      _buildPetImageSection(),
                      SizedBox(height: 16),
                      _buildPetInfoSection(),
                      SizedBox(height: 16),
                      _buildRecommendationSection(),
                      SizedBox(height: 24),
                      _buildRecordsSection(), // ย้ายมาก่อน Health Trends
                      SizedBox(height: 24),
                      _buildGraphsSection(),
                    ],
                  ),
                ),
                SizedBox(height: 24), // ลด space เพราะไม่มี navbar
                  ],
                ),
              ),
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
        String originalUrl = frontImageUrl.toString().trim();
        
        // ถ้าเป็น URL เต็มรูปแบบ และไม่ใช่ localhost/old IP → ใช้ตามเดิม
        if (originalUrl.startsWith('http') && 
            !originalUrl.contains('172.20.10.3') && 
            !originalUrl.contains('localhost') && 
            !originalUrl.contains('127.0.0.1')) {
          imageUrl = originalUrl;
        } 
        // ถ้าเป็น URL แบบเก่าหรือ localhost → แปลงเป็น URL ใหม่
        else if (originalUrl.startsWith('http')) {
            String filename = originalUrl.split('/').last;
          // เช็คว่า filename ไม่ว่างและมี extension
          if (filename.isNotEmpty && filename.contains('.')) {
            imageUrl = '${PetService.uploadBaseUrl}/uploads/$filename';
        } else {
            imageUrl = originalUrl;
        }
        } 
        // ถ้าเป็นแค่ filename → สร้าง URL เต็ม
        else {
          // เช็คว่าเป็น filename จริงๆ (มี extension)
          if (originalUrl.contains('.')) {
          imageUrl = '${PetService.uploadBaseUrl}/uploads/$originalUrl';
          } else {
            // ถ้าไม่ใช่ filename อาจเป็น path อื่น
            imageUrl = originalUrl;
          }
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
              // Pet Image - สี่เหลี่ยมมุมมนแบบเดิม
              Positioned(
                left: 0,
                top: 0,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.5 - 48,
                  height: 350,
            decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30), // กลับเป็นสี่เหลี่ยมมุมมน
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
              // BCS Score with connecting line
              Positioned(
                right: 18,
                top: 50,
                child: _buildConnectedBubble(
                  'BCS',
                  _getBcsScore() ?? 'N/A', // Use score directly
                  Color(0xFF6B86C9),
                  Icons.monitor_weight,
                  Offset(-200, 50),
                  Offset(0, 50),
                  isLarge: true,
                ),
              ),
              // Weight with connecting line
              Positioned(
                right: 109,
                top: 200,
                child: _buildConnectedBubble(
                  'Weight',
                  _getWeight(),
                  Color(0xFF10B981),
                  Icons.scale,
                  Offset(-130, 50),
                  Offset(0, 50),
                ),
              ),
      ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedBubble(String label, dynamic value, Color color, IconData icon, Offset lineStart, Offset lineEnd, {bool isLarge = false}) {
    return AnimatedBuilder(
      animation: _bubbleAnimation,
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Simple straight line - เส้นตรงธรรมดาแบบในรูป
            Positioned(
              left: lineStart.dx,
              top: lineStart.dy,
              child: Container(
                width: isLarge ? 200 : 132,
                height: 2,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.6), // เส้นสีเดียวกับ bubble แต่อ่อนลง
                  borderRadius: BorderRadius.circular(1),
                    ),
                ),
              ),
            // Simple rounded box - เหมือนรูปแรก
            Transform.scale(
              scale: _bubbleAnimation.value,
              child: Container(
                width: isLarge ? 110 : 90,
                height: isLarge ? 110 : 90,
                decoration: BoxDecoration(
                  color: Color(0xFFF5F1E8), // สีครีม/เบจ
                  borderRadius: BorderRadius.circular(20), // มุมมนน้อยลง
                  border: Border.all(
                    color: Color(0xFF4A5568), // สีเทาเข้ม
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Label ด้านบน (BCS หรือ Weight)
                    Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'Inter',
                        color: Color(0xFF4A5568),
                        fontSize: isLarge ? 18 : 14,
                          fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: isLarge ? 6 : 4),
                    // ค่าด้านล่าง (range หรือ weight)
                    value is String
                        ? Text(
                            value.toString(), // Display range directly (e.g., "4-6")
                            style: TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF4A5568),
                              fontSize: isLarge ? 28 : 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          )
                        : AnimatedBuilder(
                      animation: _numberAnimation,
                      builder: (context, child) {
                              int animatedValue = ((value as int) * _numberAnimation.value).round();
                              return Text(
                            animatedValue.toString(),
                            style: TextStyle(
                              fontFamily: 'Inter',
                                  color: Color(0xFF4A5568),
                                  fontSize: isLarge ? 32 : 26,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
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

  // Get BCS score (prefer backend score, fallback from range)
  int? _getBcsScore() {
    final List<dynamic> rawRecords = widget.pet['records'] ?? [];
    if (rawRecords.isNotEmpty) {
      final latestRecord = rawRecords.last;
      // Prefer bcs_score
      if (latestRecord['bcs_score'] != null) {
        final dynamic raw = latestRecord['bcs_score'];
        if (raw is num) return raw.toInt();
        if (raw is String) return int.tryParse(raw);
      }
      // Fallback from range
      final String? range = latestRecord['bcs_range']?.toString();
      if (range == '1-3') return 2;
      if (range == '4-5') return 5;
      if (range == '6-9') return 8;
      // Backward compatibility with old ranges
      if (range == '4-6') return 5;
      if (range == '7-9') return 8;
    }
    return null; // Return null if no records
  }

  

  // Calculate current age based on records or initial age
  String _calculateAge() {
    int ageYears = widget.pet['age_years'] ?? 0;
    int ageMonths = widget.pet['age_months'] ?? 0;
    
    // ถ้ามี records ให้คำนวณอายุจากวันที่สร้าง record แรก
    final List<dynamic> rawRecords = widget.pet['records'] ?? [];
    if (rawRecords.isNotEmpty) {
      // หาวันที่ของ record แรก
      final firstRecord = rawRecords.first;
      final firstRecordDate = DateTime.tryParse(firstRecord['date'] ?? '');
      
      if (firstRecordDate != null) {
        final now = DateTime.now();
        final monthsDiff = (now.year - firstRecordDate.year) * 12 + 
                          (now.month - firstRecordDate.month);
        
        // เพิ่มเดือนที่ผ่านไปเข้ากับอายุเดิม
        int totalMonths = (ageYears * 12) + ageMonths + monthsDiff;
        ageYears = totalMonths ~/ 12;
        ageMonths = totalMonths % 12;
      }
    }
    
    if (ageYears > 0 && ageMonths > 0) {
      return '$ageYears years $ageMonths months';
    } else if (ageYears > 0) {
      return '$ageYears year${ageYears > 1 ? 's' : ''}';
    } else if (ageMonths > 0) {
      return '$ageMonths month${ageMonths > 1 ? 's' : ''}';
    } else {
      return 'Unknown';
    }
  }

  int _getWeight() {
    final List<dynamic> rawRecords = widget.pet['records'] ?? [];
    if (rawRecords.isNotEmpty) {
      final latestRecord = rawRecords.last;
      return (double.tryParse(latestRecord['weight']?.toString() ?? '0') ?? 0.0).toInt();
    }
    return 0;
  }

  Widget _buildActualGraph(String title, Color color) {
    // ใช้ข้อมูลจริงจาก records
    final List<dynamic> rawRecords = widget.pet['records'] ?? [];
    List<Map<String, dynamic>> chartData = [];
    
    if (rawRecords.isNotEmpty) {
      // แปลงข้อมูล records เป็นข้อมูลสำหรับกราฟ (ใช้ bcs_score โดยตรง)
      chartData = rawRecords.map((record) {
        final date = DateTime.parse(record['date'] ?? DateTime.now().toIso8601String());
        int? bcsScore;
        if (record['bcs_score'] != null) {
          final dynamic raw = record['bcs_score'];
          if (raw is num) bcsScore = raw.toInt();
          else if (raw is String) bcsScore = int.tryParse(raw);
        } else if (record['bcs_range'] != null) {
          final String range = record['bcs_range'].toString();
          if (range == '1-3') bcsScore = 2;
          else if (range == '4-5') bcsScore = 5;
          else if (range == '6-9') bcsScore = 8;
          // Backward compatibility with old ranges
          else if (range == '4-6') bcsScore = 5;
          else if (range == '7-9') bcsScore = 8;
        }
        final int bcsValue = bcsScore ?? 5; // default if missing
        return {
          'date': date,
          'bcs': bcsValue,
          'bcs_label': bcsValue.toString(), // label uses score
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
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // แสดงข้อมูลล่าสุด
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Latest: ${title == 'BCS Trend' ? chartData.last['bcs'].toString() : chartData.last['weight'].toString() + ' kg'}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                '${chartData.length} record${chartData.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          // แสดงกราฟแบบ Line Chart
          Container(
            height: 108, // Make BCS same as Weight trend height
            padding: EdgeInsets.all(0),
            child: CustomPaint(
              painter: LineChartPainter(
                data: chartData,
                title: title,
                color: color,
              ),
              size: Size.infinite,
            ),
          ),
          SizedBox(height: 10),
          // แสดงวันที่ - วางตรงกับจุด plot
          Container(
            height: 16,
            padding: EdgeInsets.symmetric(
              horizontal: 15.0, // Align with weight trend
            ),
            child: chartData.length == 1
                ? Center(
                    child: Text(
                      chartData[0]['formattedDate'],
                      style: TextStyle(
                        fontSize: 10, 
                        color: Color(0xFF64748B), 
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: chartData.map((data) {
                return Text(
                  data['formattedDate'],
                  style: TextStyle(
                          fontSize: 10, 
                    color: Color(0xFF64748B), 
                          fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetInfoSection() {
    return Container(
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
          _buildInfoRow(Icons.cake, 'Age', _calculateAge()),
                  _buildInfoRow(Icons.pets, 'Gender', widget.pet['gender'] ?? 'Unknown'),
                  _buildInfoRow(Icons.category, 'Breed', widget.pet['breed'] ?? 'Unknown'),
                  _buildInfoRow(Icons.medical_services, 'Spay/Neuter', 
                      (widget.pet['is_sterilized'] == true) ? 'Yes' : 'No'),
              ],
            ),
    );
  }

  Widget _buildRecommendationSection() {
    return Container(
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
              Expanded(
                child: Text(
                        'Recommendation',
                  style: TextStyle(
                    fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                  ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
          _buildRecommendationContent(),
        ],
      ),
    );
  }

  Widget _buildRecommendationContent() {
    int? bcsScore = _getBcsScore();
    String species = widget.pet['species']?.toString().toLowerCase() ?? 'dog';
    
    // If no BCS score, show message
    if (bcsScore == null) {
      return Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF64748B).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Color(0xFF64748B).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Text(
          'No BCS data available. Please add a record to get recommendations.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            color: Color(0xFF1E293B),
            height: 1.5,
          ),
        ),
      );
    }
    
    // Determine BCS category and color
    String bcsCategory = '';
    Color categoryColor = Color(0xFF6B86C9);
    
    if (bcsScore <= 3) {
      bcsCategory = 'Underweight';
      categoryColor = Color(0xFF3B82F6);
    } else if (bcsScore >= 4 && bcsScore <= 5) {
      bcsCategory = 'Ideal';
      categoryColor = Color(0xFF10B981);
    } else {
      bcsCategory = 'Overweight';
      categoryColor = Color(0xFFEF4444);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header showing BCS range, category, and species
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: categoryColor.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Icon(
                species == 'cat' ? Icons.pets : Icons.pets,
                color: categoryColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                      'BCS Score: $bcsScore $bcsCategory',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                    ),
                  ),
                    SizedBox(height: 4),
                    Text(
                      '${species == 'cat' ? 'Cat' : 'Dog'}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: categoryColor,
                      ),
                    ),
                ],
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 16),
        // Weekly Recommendations based on BCS and species
        Text(
          'Recommendation for 1 month',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 12),
        _buildWeeklyRecommendations(bcsScore, species),
      ],
    );
  }

  Widget _buildWeeklyRecommendations(int bcsScore, String species) {
    List<Map<String, String>> weeklyRecs = _getWeeklyRecommendations(bcsScore, species);
    // ใช้สีเดียวกันทั้งหมดสำหรับ week cards
    Color weekCardColor = Color(0xFF6B86C9);
    
    return Column(
      children: [
        _buildWeekCard(1, weeklyRecs[0]['dog'] ?? '', weeklyRecs[0]['cat'] ?? '', species, weekCardColor),
        SizedBox(height: 12),
        _buildWeekCard(2, weeklyRecs[1]['dog'] ?? '', weeklyRecs[1]['cat'] ?? '', species, weekCardColor),
        SizedBox(height: 12),
        _buildWeekCard(3, weeklyRecs[2]['dog'] ?? '', weeklyRecs[2]['cat'] ?? '', species, weekCardColor),
        SizedBox(height: 12),
        _buildWeekCard(4, weeklyRecs[3]['dog'] ?? '', weeklyRecs[3]['cat'] ?? '', species, weekCardColor),
      ],
    );
  }

  Widget _buildWeekCard(int weekNumber, String dogRec, String catRec, String species, Color weekCardColor) {
    String recommendation = species == 'cat' ? catRec : dogRec;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: weekCardColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: weekCardColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: weekCardColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                'Week $weekNumber',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: weekCardColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      species == 'cat' ? Icons.pets : Icons.pets,
                      size: 16,
                      color: weekCardColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      species == 'cat' ? 'Cat' : 'Dog',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: weekCardColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  recommendation,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Map<String, String>> _getWeeklyRecommendations(int bcsScore, String species) {
    // BCS 1-3: Underweight
    if (bcsScore <= 3) {
      return [
        {
          'dog': 'Perform a basic health check. Adjust food formula to be higher in energy. Divide meals into 3-4 servings per day.',
          'cat': 'Perform a health check and screen for chronic diseases. Adjust food formula to be higher in energy.',
        },
        {
          'dog': 'Observe weight and appetite. Start light exercise such as short walks for 5-10 minutes.',
          'cat': 'Evaluate eating and defecation habits. If weight still does not increase, adjust the food formula to be even higher in energy.',
        },
        {
          'dog': 'Monitor weight, measure BCS again. Supplement with recommended supplements from the veterinarian.',
          'cat': 'Encourage light play, such as with a fishing rod toy, without overdoing it.',
        },
        {
          'dog': 'Evaluate the results of weight gain. Schedule a follow-up appointment with the veterinarian.',
          'cat': 'Weigh, monitor BCS. Schedule a veterinarian visit to check the response to the care plan.',
        },
      ];
    }
    // BCS 4-5: Ideal
    else if (bcsScore >= 4 && bcsScore <= 5) {
      return [
        {
          'dog': 'Provide age-appropriate balanced food. Check vaccinations/deworming.',
          'cat': 'Provide food according to body weight. Care for oral health. Check vaccinations/deworming.',
        },
        {
          'dog': 'Schedule exercise activities 30-60 minutes/day.',
          'cat': 'Stimulate play 10-15 minutes/day. Arrange climbing environment.',
        },
        {
          'dog': 'Recheck weight and BCS. Enhance social activities.',
          'cat': 'Check litter box hygiene and observe defecation behavior.',
        },
        {
          'dog': 'General health check with veterinarian. Behavioral assessment and nutritional assessment.',
          'cat': 'General health check with veterinarian. Behavioral assessment and nutritional assessment.',
        },
      ];
    }
    // BCS 6-9: Overweight
    else {
      return [
        {
          'dog': 'Health check to assess complications. Adjust to weight-loss diet.',
          'cat': 'Health check. Screen for metabolic disease. Start weight-control diet.',
        },
        {
          'dog': 'Start light exercise program, e.g., slow walking 10-15 minutes/day.',
          'cat': 'Stimulate movement, e.g., laser play/interactive toys.',
        },
        {
          'dog': 'Weigh to monitor progress. Reduce treats and off-meal feeding.',
          'cat': 'Assess eating-defecation. Adjust amount if weight loss is too rapid.',
        },
        {
          'dog': 'Follow-up with veterinarian for progress check. Continuous planning.',
          'cat': 'Weigh and monitor BCS. Schedule recheck with veterinarian.',
        },
      ];
    }
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

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medical_information,
                color: Color(0xFF8B5CF6),
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Text(
              'Health Records',
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
        ...rawRecords.reversed.take(5).map((record) => _buildRecordCard(record)),
      ],
    );
  }

  Widget _buildEmptyRecords() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.medical_information,
                color: Color(0xFF8B5CF6),
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Text(
              'Health Records',
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
        Container(
      padding: EdgeInsets.all(40),
        decoration: BoxDecoration(
            color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(0xFFE2E8F0),
              width: 1,
            ),
        ),
        child: Column(
          children: [
          Icon(
                Icons.folder_open,
                color: Color(0xFF8B5CF6).withOpacity(0.5),
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
        ),
      ],
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
                  'BCS: ${record['bcs_range'] ?? 'N/A'} • Weight: ${record['weight'] ?? 'N/A'} kg',
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
    return Column(
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
                Icons.trending_up,
                color: Color(0xFF6B86C9),
                size: 24,
              ),
            ),
            SizedBox(width: 16),
                Text(
              'Health Trends',
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
        _buildTrendGraph('BCS Trend', Color(0xFFEF4444)),
            SizedBox(height: 16),
            _buildTrendGraph('Weight Trend', Color(0xFF10B981)),
          ],
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
            height: 220, // Make BCS same as Weight trend
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: _buildActualGraph(title, color),
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Speech Bubble Tail - หางของกล่องข้อความ
class SpeechBubbleTailPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  SpeechBubbleTailPainter({
    required this.fillColor,
    required this.borderColor,
    this.borderWidth = 3.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // วาดหางแบบสามเหลี่ยมโค้งมน
    final path = Path();
    path.moveTo(size.width * 0.3, 0); // จุดเริ่มต้นบนซ้าย
    path.quadraticBezierTo(
      size.width * 0.5, size.height * 0.3, // control point
      size.width * 0.7, size.height, // end point ล่างขวา
    );
    path.lineTo(size.width * 0.1, size.height * 0.2); // กลับไปซ้าย
    path.close();

    // วาดเส้นขอบ
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, borderPaint);

    // วาดเติมสี
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

    // Unified padding for both BCS and Weight trends
    final topPadding = 15.0;
    final bottomPadding = 15.0;
    final leftPadding = 15.0;
    final rightPadding = 15.0;
    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 4.0 // ใช้ความหนาเดียวกันทั้งหมด
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
      
      final x = data.length > 1 
          ? leftPadding + (i / (data.length - 1)) * chartWidth
          : leftPadding + chartWidth / 2;
      
      final y = topPadding + chartHeight - ((value - rangeMin) / (rangeMax - rangeMin)) * chartHeight;
      
      points.add(Offset(x, y));
    }

    // Remove background zones for BCS to match Weight trend

    // วาดพื้นที่ใต้เส้นกราฟ
    if (points.length > 1) {
      final fillPath = Path();
      fillPath.moveTo(points.first.dx, topPadding + chartHeight);
      fillPath.lineTo(points.first.dx, points.first.dy);
      
      for (int i = 1; i < points.length; i++) {
        fillPath.lineTo(points[i].dx, points[i].dy);
      }
      
      fillPath.lineTo(points.last.dx, topPadding + chartHeight);
      fillPath.close();
      
      canvas.drawPath(fillPath, fillPaint);
    }

    // วาดเส้นกราฟ
    if (points.length == 1) {
      final point = points.first;
      final pointSize = 8.0; // ใช้ขนาดเดียวกันทั้งหมด
      canvas.drawCircle(point, pointSize, pointPaint);
      canvas.drawCircle(point, pointSize * 0.5, Paint()..color = Colors.white);
    } else if (points.length == 2) {
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      path.lineTo(points.last.dx, points.last.dy);
      canvas.drawPath(path, paint);
    } else {
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

    // วาดจุดข้อมูลพร้อม labels
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      
      final pointSize = 6.0; // ใช้ขนาดเดียวกันทั้ง BCS และ Weight
      final innerSize = 3.0; // ใช้ขนาดเดียวกันทั้ง BCS และ Weight
      
      // Shadow
      canvas.drawCircle(Offset(point.dx + 1, point.dy + 1), pointSize + 1, shadowPaint);
      // Main point
      canvas.drawCircle(point, pointSize, pointPaint);
      // Inner highlight
      canvas.drawCircle(point, innerSize, Paint()..color = Colors.white);
      
      // แสดง label
      final labelPainter = TextPainter(
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      if (title == 'BCS Trend') {
        final labelText = data[i]['bcs_label']?.toString() ?? 'N/A';
        labelPainter.text = TextSpan(
          text: labelText,
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            backgroundColor: Colors.white.withOpacity(0.95),
          ),
        );
        labelPainter.layout();
        labelPainter.paint(
          canvas,
          Offset(point.dx - labelPainter.width / 2, point.dy - 24),
        );
      } else {
        final weight = data[i]['weight'];
        final weightText = weight is double ? weight.toStringAsFixed(1) : weight.toString();
        labelPainter.text = TextSpan(
          text: '$weightText kg',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            backgroundColor: Colors.white.withOpacity(0.95),
          ),
        );
        labelPainter.layout();
        // วาง label ด้านบนจุดข้อมูล
        labelPainter.paint(
          canvas,
          Offset(point.dx - labelPainter.width / 2, point.dy - 24),
        );
      }
    }
    
    // Remove custom Y-axis labels for BCS to match Weight trend
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
