import 'package:flutter/material.dart';
import 'dart:io'; // Add this import

class PhotoCaptureSection extends StatelessWidget {
  final String label;
  final String? imagePath;
  final VoidCallback onTakePhoto;
  final bool isLoading;

  const PhotoCaptureSection({
    Key? key,
    required this.label,
    required this.imagePath,
    required this.onTakePhoto,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Inter',
                color: Color(0xFF333333),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton(
              onPressed: onTakePhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE0F2F1),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    color: Color(0xFF4CAF50),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Take Photo',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF4CAF50),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 202,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : (imagePath == null
                  ? Center(
                      child: Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.grey[400],
                        size: 64,
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: _buildImageWidget(imagePath!),
                    )),
        ),
      ],
    );
  }

  Widget _buildImageWidget(String path) {
    // Check if the path is an asset or a file path
    if (path.startsWith('assets/')) {
      // It's an asset path
      return Image.asset(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      // It's a file path
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(height: 8),
                Text(
                  'Error loading image',
                  style: TextStyle(color: Colors.red[700]),
                ),
                const SizedBox(height: 4),
                Text(
                  path,
                  style: TextStyle(color: Colors.grey[600], fontSize: 10),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      );
    }
  }
}