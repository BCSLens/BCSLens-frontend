// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  final Map<String, dynamic> pet;
  final String groupName;

  const HistoryScreen({Key? key, required this.pet, required this.groupName})
    : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedIndex = 0; // Records tab
  String _selectedTab = 'Records'; // Default selected tab

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF7B8EB5)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${widget.pet['name'] ?? 'Pet'}\'s Record',
          style: const TextStyle(
            color: Color(0xFF7B8EB5),
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pet avatar - centered
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child:
                    widget.pet['image_url'] != null &&
                            widget.pet['image_url'].toString().isNotEmpty
                        ? CircleAvatar(
                          backgroundImage: NetworkImage(
                            widget.pet['image_url'],
                          ),
                          onBackgroundImageError: (_, __) {
                            // Fallback if image loading fails
                            return;
                          },
                        )
                        : CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: Icon(
                            Icons.pets,
                            size: 60,
                            color: Colors.white,
                          ),
                        ),
              ),
            ),
          ),

          // Pet name and favorite - with correct spacing
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
            child: Row(
              children: [
                Text(
                  widget.pet['name'] ?? 'Pet',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star, color: Colors.amber, size: 24),
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
                      Navigator.pushNamed(context, '/add-record');
                    },
                  ),
                ),
              ],
            ),
          ),

          // Pet details in horizontal row - with correct spacing and styling
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            child: SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  _buildInfoPill('Age', '${widget.pet['age'] ?? 'N/A'} years'),
                  const SizedBox(width: 8),
                  _buildInfoPill('Breed', widget.pet['breed'] ?? 'Unknown'),
                  const SizedBox(width: 8),
                  _buildInfoPill('Gender', widget.pet['gender'] ?? 'Unknown'),
                  const SizedBox(width: 8),
                  _buildInfoPill('Weight', '$latestWeight kg'),
                ],
              ),
            ),
          ),

          // Tab buttons - matching Figma design
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTab = 'Records';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedTab == 'Records'
                              ? const Color(0xFF7B8EB5)
                              : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color:
                              _selectedTab != 'Records'
                                  ? const Color(0xFFE0E0E0)
                                  : const Color(0xFF7B8EB5),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Records',
                      style: TextStyle(
                        color:
                            _selectedTab == 'Records'
                                ? Colors.white
                                : const Color(0xFF7B8EB5),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _selectedTab = 'Graphs';
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedTab == 'Graphs'
                              ? const Color(0xFF7B8EB5)
                              : Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color:
                              _selectedTab != 'Graphs'
                                  ? const Color(0xFFE0E0E0)
                                  : const Color(0xFF7B8EB5),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Graphs',
                      style: TextStyle(
                        color:
                            _selectedTab == 'Graphs'
                                ? Colors.white
                                : const Color(0xFF7B8EB5),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content based on selected tab
          Expanded(
            child:
                _selectedTab == 'Records'
                    ? groupedRecords.isEmpty
                        ? Center(
                          child: Text(
                            'No records found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                        : _buildRecordsTab(groupedRecords)
                    : _buildGraphsTab(),
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

  Widget _buildInfoPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsTab(
    Map<String, List<Map<String, dynamic>>> groupedRecords,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: groupedRecords.length,
      itemBuilder: (context, index) {
        final month = groupedRecords.keys.elementAt(index);
        final records = groupedRecords[month]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 20),
              child: Text(
                month,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            ...records.map((record) => _buildRecordItem(record)).toList(),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildRecordItem(Map<String, dynamic> record) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // Calendar icon
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            child: const Icon(
              Icons.calendar_today,
              color: Color(0xFF7B8EB5),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          // Date
          Expanded(
            child: Text(
              record['date'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
          // BCS score
          const Text('BCS', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(width: 8),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF7BC67E),
            ),
            child: Center(
              child: Text(
                '${record['bcs']}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Weight
          const Text(
            'Weight',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(width: 8),
          Text(
            record['weight'],
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraphsTab() {
    // Placeholder for graphs tab
    return const Center(
      child: Text(
        'Graphs Coming Soon',
        style: TextStyle(fontSize: 18, color: Colors.grey),
      ),
    );
  }
}
