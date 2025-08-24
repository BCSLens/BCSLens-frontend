// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class HistoryScreen extends StatefulWidget {
  final Map<String, dynamic> pet;
  final String groupName;

  const HistoryScreen({Key? key, required this.pet, required this.groupName})
    : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0; // Records tab
  String _selectedTab = 'Records'; // Default selected tab
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
    );
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.pushReplacementNamed(context, '/add-record');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/special-care');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get records from the pet data
    final List<dynamic> rawRecords = widget.pet['records'] ?? [];

    // Get latest weight from records or default to N/A
    String latestWeight = 'N/A';
    if (rawRecords.isNotEmpty) {
      final latestRecord = rawRecords.last;
      if (latestRecord['weight'] != null) {
        latestWeight = '${latestRecord['weight']}';
      }
    }

    // Format records into the structure we need
    final List<Map<String, dynamic>> records = [];

    for (var record in rawRecords) {
      // Format date string
      DateTime recordDate =
          DateTime.tryParse(record['date'] ?? '') ?? DateTime.now();
      String formattedDate = DateFormat('dd MMMM yyyy').format(recordDate);
      String month = DateFormat('MMMM').format(recordDate);

      // Get weight from record or use N/A
      String weightDisplay =
          record['weight'] != null ? '${record['weight']} kg' : 'N/A kg';

      records.add({
        'date': formattedDate,
        'bcs': record['score'] ?? 0,
        'weight': weightDisplay,
        'month': month,
      });
    }

    // Group records by month
    final Map<String, List<Map<String, dynamic>>> groupedRecords = {};

    for (var record in records) {
      final month = record['month'] as String;

      if (!groupedRecords.containsKey(month)) {
        groupedRecords[month] = [];
      }

      groupedRecords[month]!.add(record);
    }

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildModernHeader(),
            Expanded(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 24), 
                          _buildPetProfileCard(latestWeight),
                          SizedBox(height: 24),
                          _buildModernTabs(),
                          SizedBox(height: 20),
                          Expanded(
                            child: _selectedTab == 'Records'
                                ? groupedRecords.isEmpty
                                    ? _buildEmptyState()
                                    : _buildModernRecordsTab(groupedRecords)
                                : _buildGraphsTab(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
    return Container(
      padding: EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${widget.pet['name'] ?? 'Pet'}\'s Records',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF7B8EB5),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SizedBox(width: 40), // Spacer to balance the back button
          ],
        ),
      ),
    );
  }

  Widget _buildPetProfileCard(String latestWeight) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: Color(0xFF6B86C9).withOpacity(0.04),
            blurRadius: 40,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pet Avatar with modern styling
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF6B86C9), Color(0xFF8B5CF6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF6B86C9).withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: widget.pet['image_url'] != null &&
                    widget.pet['image_url'].toString().isNotEmpty
                ? CircleAvatar(
                    radius: 48,
                    backgroundImage: NetworkImage(widget.pet['image_url']),
                    onBackgroundImageError: (_, __) => null,
                  )
                : Icon(
                    Icons.pets,
                    size: 40,
                    color: Colors.white,
                  ),
          ),
          
          SizedBox(height: 16),
          
          // Pet Name with favorite icon
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.pet['name'] ?? 'Pet',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // Pet Details in modern cards
          _buildModernPetDetails(latestWeight),
        ],
      ),
    );
  }

  Widget _buildModernPetDetails(String latestWeight) {
    return Row(
      children: [
        Expanded(
          child: _buildModernInfoCard(
            'Age',
            '${widget.pet['age_years'] ?? 0}y ${widget.pet['age_months'] ?? 0}m',
            Icons.access_time,
            Color(0xFF6366F1),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildModernInfoCard(
            'Weight',
            '$latestWeight kg',
            Icons.monitor_weight,
            Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildModernInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Records', Icons.history),
          ),
          Expanded(
            child: _buildTabButton('Graphs', Icons.analytics),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon) {
    final isSelected = _selectedTab == title;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTab = title;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Color(0xFF6B86C9) : Color(0xFF94A3B8),
            ),
            SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Inter',
                color: isSelected ? Color(0xFF6B86C9) : Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFF6B86C9).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets,
              size: 32,
              color: Color(0xFF6B86C9),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'No Records Yet',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start tracking your pet\'s health\nby adding their first record',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/add-record');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6B86C9),
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Add First Record',
              style: TextStyle(
                fontFamily: 'Inter',
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernRecordsTab(Map<String, List<Map<String, dynamic>>> groupedRecords) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24),
      itemCount: groupedRecords.length,
      itemBuilder: (context, index) {
        final month = groupedRecords.keys.elementAt(index);
        final records = groupedRecords[month]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 16, top: index == 0 ? 0 : 24),
              child: Text(
                month,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            ...records.map((record) => _buildModernRecordItem(record)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildModernRecordItem(Map<String, dynamic> record) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date section
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF6B86C9).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.calendar_today,
              color: Color(0xFF6B86C9),
              size: 18,
            ),
          ),
          
          SizedBox(width: 16),
          
          // Date text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record['date'],
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Health Check',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          
          // BCS Score
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BCS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${record['bcs']}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(width: 12),
          
          // Weight
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              record['weight'],
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: Color(0xFF8B5CF6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphsTab() {
    final List<dynamic> rawRecords = widget.pet['records'] ?? [];
    
    print('🔍 Debug: Raw records count: ${rawRecords.length}');
    print('🔍 Debug: Raw records: $rawRecords');
    
    if (rawRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFF8B5CF6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.analytics,
                size: 32,
                color: Color(0xFF8B5CF6),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No Data for Graphs',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Add some records to see\nbeautiful health analytics',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 15,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }
    
    // Prepare data for charts
    List<Map<String, dynamic>> chartData = [];
    
    for (int i = 0; i < rawRecords.length; i++) {
      var record = rawRecords[i];
      DateTime recordDate = DateTime.tryParse(record['date'] ?? '') ?? DateTime.now();
      
      // Parse weight more carefully
      double weight = 0.0;
      if (record['weight'] != null) {
        String weightStr = record['weight'].toString();
        // Remove any non-numeric characters except decimal point
        weightStr = weightStr.replaceAll(RegExp(r'[^0-9.]'), '');
        weight = double.tryParse(weightStr) ?? 0.0;
      }
      
      int bcs = 0;
      if (record['score'] != null) {
        bcs = int.tryParse(record['score'].toString()) ?? 0;
      }
      
      print('🔍 Debug record $i: date=$recordDate, weight=$weight, bcs=$bcs');
      
      chartData.add({
        'date': recordDate,
        'weight': weight,
        'bcs': bcs,
        'dateLabel': DateFormat('MMM dd').format(recordDate),
      });
    }
    
    // Sort by date
    chartData.sort((a, b) => a['date'].compareTo(b['date']));
    
    print('🔍 Debug: Chart data prepared: ${chartData.length} items');
    
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 32, 24, 24), // ✅ เพิ่ม top padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeightChart(chartData),
          SizedBox(height: 32),
          _buildBCSChart(chartData),
          SizedBox(height: 32), // ✅ เพิ่ม bottom padding
        ],
      ),
    );
  }

  Widget _buildWeightChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return SizedBox.shrink();
    
    print('🔍 Debug Weight Chart: ${data.length} data points');
    
    // Find min and max weight for scaling
    List<double> weights = data.map((d) => d['weight'] as double).toList();
    weights = weights.where((w) => w > 0).toList(); // Filter out zero weights
    
    if (weights.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.monitor_weight,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Weight Trend',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            Text(
              'No weight data available',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      );
    }
    
    double minWeight = weights.reduce((a, b) => a < b ? a : b);
    double maxWeight = weights.reduce((a, b) => a > b ? a : b);
    
    print('🔍 Weight range: $minWeight - $maxWeight');
    
    // Add some padding to the range
    double weightRange = maxWeight - minWeight;
    if (weightRange == 0) weightRange = 1;
    minWeight = (minWeight - weightRange * 0.1).clamp(0, double.infinity);
    maxWeight = maxWeight + weightRange * 0.1;
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.monitor_weight,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Weight Trend',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 200,
            child: CustomPaint(
              size: Size.infinite,
              painter: WeightChartPainter(data, minWeight, maxWeight),
            ),
          ),
          SizedBox(height: 16),
          _buildChartLegend('Weight (kg)', Color(0xFF10B981)),
        ],
      ),
    );
  }

  Widget _buildBCSChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return SizedBox.shrink();
    
    print('🔍 Debug BCS Chart: ${data.length} data points');
    
    // Check if there's any BCS data
    List<int> bcsScores = data.map((d) => d['bcs'] as int).toList();
    bcsScores = bcsScores.where((bcs) => bcs > 0).toList();
    
    if (bcsScores.isEmpty) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.favorite,
                    color: Color(0xFF6366F1),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Body Condition Score',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            SizedBox(height: 40),
            Text(
              'No BCS data available',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.favorite,
                  color: Color(0xFF6366F1),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Body Condition Score',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            height: 200,
            child: CustomPaint(
              size: Size.infinite,
              painter: BCSChartPainter(data),
            ),
          ),
          SizedBox(height: 16),
          _buildChartLegend('BCS Score (1-9)', Color(0xFF6366F1)),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Custom Painter for Weight Chart
class WeightChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double minWeight;
  final double maxWeight;

  WeightChartPainter(this.data, this.minWeight, this.maxWeight);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Color(0xFF10B981)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = Color(0xFF10B981)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    // Draw grid lines
    for (int i = 0; i <= 4; i++) {
      double y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Calculate points
    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      double x;
      if (data.length == 1) {
        // ✅ ถ้ามีข้อมูลเพียงจุดเดียว ให้วางตรงกลาง
        x = size.width / 2;
      } else {
        x = size.width * i / (data.length - 1);
      }
      
      double weight = data[i]['weight'];
      double y;
      if (maxWeight == minWeight) {
        // ✅ ถ้าน้ำหนักเท่ากัน ให้วางตรงกลาง
        y = size.height / 2;
      } else {
        y = size.height - (size.height * (weight - minWeight) / (maxWeight - minWeight));
      }
      points.add(Offset(x, y));
    }

    // Draw line (only if more than 1 point)
    if (points.length > 1) {
      Path path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw points and labels (always show points)
    for (int i = 0; i < points.length; i++) {
      // Draw larger point for single data point
      double pointRadius = data.length == 1 ? 8 : 6;
      
      // Draw point with glow effect for single point
      if (data.length == 1) {
        canvas.drawCircle(points[i], pointRadius + 4, Paint()
          ..color = Color(0xFF10B981).withOpacity(0.3)
          ..style = PaintingStyle.fill);
      }
      
      canvas.drawCircle(points[i], pointRadius, pointPaint);
      canvas.drawCircle(points[i], pointRadius, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);

      // ✅ แสดง weight value บนจุด
      textPainter.text = TextSpan(
        text: '${data[i]['weight']} kg',
        style: TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      
      double textX = points[i].dx - textPainter.width / 2;
      double textY = points[i].dy - 25;
      
      // Draw background for text
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(textX - 4, textY - 2, textPainter.width + 8, textPainter.height + 4),
          Radius.circular(4),
        ),
        Paint()..color = Colors.white..style = PaintingStyle.fill,
      );
      
      textPainter.paint(canvas, Offset(textX, textY));

      // Draw date labels
      if (data.length == 1 || i % ((data.length / 4).ceil()) == 0 || i == data.length - 1) {
        textPainter.text = TextSpan(
          text: data[i]['dateLabel'],
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );
        textPainter.layout();
        
        double dateTextX = points[i].dx - textPainter.width / 2;
        double dateTextY = size.height + 8;
        
        textPainter.paint(canvas, Offset(dateTextX, dateTextY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Painter for BCS Chart
class BCSChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;

  BCSChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = Color(0xFF6366F1)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = Color(0xFF6366F1)
      ..style = PaintingStyle.fill;

    final gridPaint = Paint()
      ..color = Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    final textPainter = TextPainter(
      textDirection: ui.TextDirection.ltr,
    );

    // Draw grid lines
    for (int i = 0; i <= 4; i++) {
      double y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Calculate points (BCS scale 1-9)
    List<Offset> points = [];
    for (int i = 0; i < data.length; i++) {
      double x;
      if (data.length == 1) {
        // ✅ ถ้ามีข้อมูลเพียงจุดเดียว ให้วางตรงกลาง
        x = size.width / 2;
      } else {
        x = size.width * i / (data.length - 1);
      }
      
      double bcs = data[i]['bcs'].toDouble();
      double y = size.height - (size.height * (bcs - 1) / 8); // Scale 1-9 to full height
      points.add(Offset(x, y));
    }

    // Draw line (only if more than 1 point)
    if (points.length > 1) {
      Path path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw points and labels (always show points)
    for (int i = 0; i < points.length; i++) {
      // Draw larger point for single data point
      double pointRadius = data.length == 1 ? 8 : 6;
      
      // Draw point with glow effect for single point
      if (data.length == 1) {
        canvas.drawCircle(points[i], pointRadius + 4, Paint()
          ..color = Color(0xFF6366F1).withOpacity(0.3)
          ..style = PaintingStyle.fill);
      }
      
      canvas.drawCircle(points[i], pointRadius, pointPaint);
      canvas.drawCircle(points[i], pointRadius, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);

      // ✅ แสดง BCS value บนจุด
      textPainter.text = TextSpan(
        text: 'BCS ${data[i]['bcs']}',
        style: TextStyle(
          color: Color(0xFF1E293B),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
      textPainter.layout();
      
      double textX = points[i].dx - textPainter.width / 2;
      double textY = points[i].dy - 25;
      
      // Draw background for text
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(textX - 4, textY - 2, textPainter.width + 8, textPainter.height + 4),
          Radius.circular(4),
        ),
        Paint()..color = Colors.white..style = PaintingStyle.fill,
      );
      
      textPainter.paint(canvas, Offset(textX, textY));

      // Draw date labels
      if (data.length == 1 || i % ((data.length / 4).ceil()) == 0 || i == data.length - 1) {
        textPainter.text = TextSpan(
          text: data[i]['dateLabel'],
          style: TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );
        textPainter.layout();
        
        double dateTextX = points[i].dx - textPainter.width / 2;
        double dateTextY = size.height + 8;
        
        textPainter.paint(canvas, Offset(dateTextX, dateTextY));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
