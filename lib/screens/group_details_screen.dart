// lib/screens/group_details_screen.dart
import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/pet_service.dart';
import '../models/pet_record_model.dart';

class GroupDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> group;
  final List<Map<String, dynamic>> pets;

  const GroupDetailsScreen({
    Key? key,
    required this.group,
    required this.pets,
  }) : super(key: key);

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _headerAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    
    _cardAnimationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeOut),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: Offset(0, -0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerAnimationController, curve: Curves.elasticOut));

    // Start animations
    _headerAnimationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFD0E3F5), // สีฟ้าอ่อนมาก (ล่างสุด) เพื่อให้ตรงกับ gradient
      body: Container(
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
        child: Column(
          children: [
            _buildModernHeader(),
            SizedBox(height: 20),
            _buildGroupStats(),
            SizedBox(height: 20),
            Expanded(
              child: widget.pets.isEmpty 
                  ? _buildEmptyState() 
                  : _buildPetsList(),
            ),
          ],
        ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 0,
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pop(context);
              break;
            case 1:
              Navigator.pushNamed(context, '/add-record');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/special-care');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profile');
              break;
          }
        },
        onAddRecordsTap: () {
          Navigator.pushNamed(context, '/add-record');
        },
      ),
    );
  }

  Widget _buildModernHeader() {
    return SlideTransition(
      position: _headerSlideAnimation,
      child: FadeTransition(
        opacity: _headerFadeAnimation,
        child: Container(
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
                          widget.group['group_name'],
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${widget.pets.length} ${widget.pets.length == 1 ? 'pet' : 'pets'}',
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
        ),
      ),
    );
  }

  Widget _buildGroupStats() {
    int healthyPets = 0;
    int concernPets = 0;
    int totalRecords = 0;

    for (final pet in widget.pets) {
      if (pet['records'] != null) {
        final records = pet['records'] as List;
        totalRecords += records.length;
        
        if (records.isNotEmpty) {
          final latestRecord = records.last;
          final score = int.tryParse(latestRecord['score']?.toString() ?? '5') ?? 5;
          if (score >= 4 && score <= 6) {
            healthyPets++;
          } else {
            concernPets++;
          }
        }
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Pets',
              widget.pets.length.toString(),
              Icons.pets,
              Color(0xFF6B86C9),
              Color(0xFF6B86C9).withOpacity(0.1),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Healthy',
              healthyPets.toString(),
              Icons.favorite,
              Color(0xFF10B981),
              Color(0xFF10B981).withOpacity(0.1),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Need Care',
              concernPets.toString(),
              Icons.warning,
              Color(0xFFF59E0B),
              Color(0xFFF59E0B).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconColor, Color bgColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Color(0xFF6B86C9).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.pets,
              size: 64,
              color: Color(0xFF6B86C9),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No pets in this group',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Add your first pet to this group!',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/add-record');
            },
            icon: Icon(Icons.add),
            label: Text('Add Pet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6B86C9),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetsList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24),
      itemCount: widget.pets.length,
      itemBuilder: (context, index) {
        final pet = widget.pets[index];
        return _buildModernPetCard(pet, widget.group['group_name']);
      },
    );
  }

  Widget _buildModernPetCard(Map<String, dynamic> pet, String groupName) {
    String imageUrl = '';

    if (pet['records'] != null && (pet['records'] as List).isNotEmpty) {
      final latestRecord = (pet['records'] as List).last;
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
            imageUrl = '${PetService.uploadBaseUrl}/upload/$filename';
          } else {
            imageUrl = originalUrl;
          }
        } 
        // ถ้าเป็น relative path ที่ขึ้นต้นด้วย /upload/ หรือ /uploads/
        else if (originalUrl.startsWith('/upload/') || originalUrl.startsWith('/uploads/')) {
          // แปลง /uploads/ เป็น /upload/ ถ้าจำเป็น
          String correctedPath = originalUrl.startsWith('/uploads/') 
              ? originalUrl.replaceFirst('/uploads/', '/upload/')
              : originalUrl;
          imageUrl = '${PetService.uploadBaseUrl}$correctedPath';
        } 
        // ถ้าเป็นแค่ filename → สร้าง URL เต็ม
        else {
          // เช็คว่าเป็น filename จริงๆ (มี extension)
          if (originalUrl.contains('.')) {
            imageUrl = '${PetService.uploadBaseUrl}/upload/$originalUrl';
        } else {
            // ถ้าไม่ใช่ filename อาจเป็น path อื่น
            imageUrl = originalUrl;
          }
        }
      }
    }

    // Get latest record data
    String weightDisplay = 'N/A';
    String bcsScore = 'N/A';
    Color bcsColor = Color(0xFF64748B);

    if (pet['records'] != null && (pet['records'] as List).isNotEmpty) {
      final latestRecord = (pet['records'] as List).last;
      
      if (latestRecord['weight'] != null) {
        weightDisplay = '${latestRecord['weight']}';
      }
      
      if (latestRecord['score'] != null) {
        final score = int.tryParse(latestRecord['score'].toString()) ?? 5;
        bcsScore = score.toString();
        
        // Color coding for BCS score
        if (score <= 3) {
          bcsColor = Color(0xFF3B82F6); // Blue for underweight
        } else if (score >= 4 && score <= 6) {
          bcsColor = Color(0xFF10B981); // Green for ideal
        } else {
          bcsColor = Color(0xFFEF4444); // Red for overweight
        }
      }
    }

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/pet-details',
            arguments: PetRecord()
              ..name = pet['name']
              ..breed = pet['breed']
              ..age = pet['age']
              ..weight = weightDisplay
              ..gender = pet['gender']
              ..isSterilized = pet['is_sterilized']
              ..category = pet['category'],
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Main row with pet info and BCS badge
              Row(
                children: [
                  // Pet Avatar
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Color(0xFF6B86C9).withOpacity(0.1),
                                  child: Icon(
                                    Icons.pets,
                                    color: Color(0xFF6B86C9),
                                    size: 30,
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Color(0xFF6B86C9).withOpacity(0.1),
                              child: Icon(
                                Icons.pets,
                                color: Color(0xFF6B86C9),
                                size: 30,
                              ),
                            ),
                    ),
                  ),
                  
                  SizedBox(width: 16),
                  
                  // Pet Basic Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet['name'] ?? 'Unknown',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        
                        SizedBox(height: 4),
                        
                        Text(
                          '${pet['breed'] ?? 'Unknown breed'} • ${pet['gender'] ?? 'Unknown'}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        
                        SizedBox(height: 8),
                        
                        Row(
                          children: [
                            Icon(Icons.monitor_weight, size: 14, color: Color(0xFF64748B)),
                            SizedBox(width: 4),
                            Text(
                              '${weightDisplay} kg',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Right side with BCS Badge and Action Buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // BCS Badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: bcsColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: bcsColor.withOpacity(0.3)),
                        ),
                        child: Text(
                          'BCS $bcsScore',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: bcsColor,
                          ),
                        ),
                      ),
                      
                      SizedBox(width: 8),
                      
                      // View Graph Button
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.analytics, color: Color(0xFF8B5CF6), size: 16),
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/history',
                              arguments: {
                                'pet': pet,
                                'groupName': groupName,
                              },
                            );
                          },
                          tooltip: 'View analytics',
                          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.all(4),
                        ),
                      ),
                      
                      SizedBox(width: 4),
                      
                      // Add Record Button
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF6B86C9).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: IconButton(
                          icon: Icon(Icons.add, color: Color(0xFF6B86C9), size: 16),
                          onPressed: () => _addNewRecordForPet(pet),
                          tooltip: 'Add new record',
                          constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                          padding: EdgeInsets.all(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addNewRecordForPet(Map<String, dynamic> pet) {
    final PetRecord newRecord = PetRecord();
    
    newRecord.existingPetId = pet['_id'];
    newRecord.name = pet['name'];
    newRecord.breed = pet['breed'];
    newRecord.age = pet['age'];
    newRecord.gender = pet['gender'];
    newRecord.isSterilized = pet['is_sterilized'];
    newRecord.category = pet['category'];
    newRecord.groupId = pet['group_id'];
    newRecord.isNewRecordForExistingPet = true;

    Navigator.pushNamed(context, '/add-record', arguments: newRecord);
  }
}
