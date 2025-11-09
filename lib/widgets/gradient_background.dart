import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: child,
    );
  }
}

