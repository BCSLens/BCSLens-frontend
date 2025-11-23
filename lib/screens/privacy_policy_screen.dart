// lib/screens/privacy_policy_screen.dart
import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B86C9)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: Color(0xFF333333),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE5E5E5),
            height: 1,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B86C9).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.privacy_tip_outlined,
                          color: Color(0xFF6B86C9),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'BCS LENS',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B86C9),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Privacy Notification',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B86C9).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B86C9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    context,
                    Icons.collections_bookmark_outlined,
                    '1. Information We Collect',
                    'ข้อมูลที่เรารวบรวม',
                    [
                      'BCS Lens collects the following information from users:',
                      '',
                      '1.1 Personal Information:',
                      '   • Name (First Name and Last Name)',
                      '   • Email Address',
                      '   • Username',
                      '   • Phone Number (Optional)',
                      '   • User Role (User or Expert)',
                      '',
                      '1.2 Authentication Data:',
                      '   • Password - Stored in encrypted format',
                      '',
                      '1.3 Pet Information:',
                      '   • Pet name, breed, age, gender, species',
                      '',
                      '1.4 Pet Health Records:',
                      '   • Body Condition Score (BCS Score)',
                      '   • Weight, record date',
                      '   • Pet images (front, back, left, right, top views)',
                      '',
                      '1.5 Usage Data:',
                      '   • Login information and application usage data',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context,
                    Icons.track_changes_outlined,
                    '2. Purpose of Data Collection',
                    'วัตถุประสงค์ในการเก็บข้อมูล',
                    [
                      'We collect data for the following purposes:',
                      '',
                      '2.1 User Authentication and Login',
                      '2.2 Core Services:',
                      '   • Evaluate Body Condition Score (BCS) of pets',
                      '   • Analyze pet images using AI',
                      '   • Record and track pet health history',
                      '   • Provide health recommendations based on BCS score',
                      '2.3 Service Improvement',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context,
                    Icons.storage_outlined,
                    '3. How We Store Data',
                    'วิธีการเก็บข้อมูล',
                    [
                      '3.1 Data is stored in:',
                      '   • MongoDB database with security systems',
                      '   • Images stored on secure servers',
                      '',
                      '3.2 Security Measures:',
                      '   • Passwords encrypted with bcrypt',
                      '   • Data access uses JWT Token authentication',
                      '   • Data transmitted via HTTPS',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context,
                    Icons.schedule_outlined,
                    '4. Data Retention Period',
                    'ระยะเวลาการเก็บข้อมูล',
                    [
                      'We will retain your data until you:',
                      '   • Delete your user account',
                      '   • Request data deletion by contacting us',
                      '',
                      'When you delete your account, all your data will be removed from the system within 30 days',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context,
                    Icons.share_outlined,
                    '5. Data Sharing',
                    'การแชร์ข้อมูล',
                    [
                      'We do not share your personal data with third parties except:',
                      '   • When required by law',
                      '   • When we have your explicit consent',
                      '',
                      'Data used for AI analysis is processed only within our system',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context,
                    Icons.account_balance_outlined,
                    '6. User Rights',
                    'สิทธิ์ของผู้ใช้',
                    [
                      'You have the right to:',
                      '   • Access your personal data',
                      '   • Edit your personal data',
                      '   • Delete your personal data',
                      '   • Withdraw consent for data collection (requires account deletion)',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context,
                    Icons.update_outlined,
                    '7. Policy Changes',
                    'การเปลี่ยนแปลงนโยบาย',
                    [
                      'We may update this privacy policy from time to time',
                      'If there are significant changes, we will notify you through the application or email',
                    ],
                  ),
                  const SizedBox(height: 20),
                  _buildSection(
                    context,
                    Icons.contact_support_outlined,
                    '8. Contact Us',
                    'การติดต่อ',
                    [
                      'If you have questions about this privacy policy',
                      'Please contact us at:',
                      '',
                      'Email: bcslens@gmail.com',
                    ],
                  ),
                  const SizedBox(height: 30),
                  // Footer
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF6B86C9).withOpacity(0.1),
                          const Color(0xFF6B86C9).withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Color(0xFF6B86C9),
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Thank you for using BCS Lens',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B86C9),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ขอบคุณที่ใช้บริการ BCS Lens',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    IconData icon,
    String titleThai,
    String titleEnglish,
    List<String> content,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B86C9).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF6B86C9),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleThai,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        titleEnglish,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Divider
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey[300]!,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Content
            ...content.map((line) {
              if (line.isEmpty) {
                return const SizedBox(height: 8);
              }
              final isSubSection = line.startsWith('   •') ||
                  line.startsWith('1.') ||
                  line.startsWith('2.') ||
                  line.startsWith('3.');
              final isBold = line.contains(':') && !line.startsWith('   •');
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  line,
                  style: TextStyle(
                    fontSize: isSubSection ? 14 : 15,
                    color: isSubSection 
                        ? Colors.grey[700] 
                        : const Color(0xFF333333),
                    height: 1.6,
                    fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

