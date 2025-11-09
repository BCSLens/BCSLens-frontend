import 'package:flutter/material.dart';
import 'dart:ui';

class FrostedGlassHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leadingWidget;
  final List<Widget>? trailingWidgets;
  final bool centerTitle;

  const FrostedGlassHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.leadingWidget,
    this.trailingWidgets,
    this.centerTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Leading widget (เช่น back button)
                    if (leadingWidget != null)
                      leadingWidget!
                    else
                      SizedBox(width: 44),
                    
                    // Title
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            title,
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
                            textAlign: centerTitle ? TextAlign.center : TextAlign.left,
                          ),
                          if (subtitle != null) ...[
                            SizedBox(height: 6),
                            Text(
                              subtitle!,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF475569),
                                letterSpacing: 0.5,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withOpacity(0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              textAlign: centerTitle ? TextAlign.center : TextAlign.left,
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Trailing widgets (เช่น action buttons)
                    if (trailingWidgets != null && trailingWidgets!.isNotEmpty)
                      Row(
                        children: trailingWidgets!,
                      )
                    else
                      SizedBox(width: 44),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Helper widget สำหรับปุ่มใน header
class HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? iconColor;

  const HeaderButton({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
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
        icon: Icon(icon, color: iconColor ?? Color(0xFF6B86C9)),
        onPressed: onPressed,
      ),
    );
  }
}

// Back button component
class HeaderBackButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const HeaderBackButton({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF6B8FD1).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1E293B)),
        onPressed: onPressed ?? () => Navigator.pop(context),
      ),
    );
  }
}

