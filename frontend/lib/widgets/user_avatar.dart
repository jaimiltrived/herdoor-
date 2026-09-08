import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/auth_api_service.dart';

class UserAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final double size;
  final double? fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final double borderWidth;

  const UserAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = 40,
    this.fontSize,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.borderWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final user = AuthApiService.instance.currentUser;
    final effectiveName = name ?? user?['name']?.toString() ?? 'Citizen';
    final effectiveImg = imageUrl ?? user?['profile_image']?.toString() ?? user?['profileImage']?.toString();

    final hasImage = effectiveImg != null &&
        effectiveImg.isNotEmpty &&
        (effectiveImg.startsWith('http://') || effectiveImg.startsWith('https://'));

    final initial = effectiveName.trim().isNotEmpty
        ? effectiveName.trim()[0].toUpperCase()
        : 'C';

    final calculatedFontSize = fontSize ?? (size * 0.42);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppTheme.surfaceWarm,
        border: Border.all(
          color: borderColor ?? AppTheme.borderLight,
          width: borderWidth,
        ),
      ),
      child: ClipOval(
        child: hasImage
            ? Image.network(
                effectiveImg,
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildFallback(initial, calculatedFontSize),
              )
            : _buildFallback(initial, calculatedFontSize),
      ),
    );
  }

  Widget _buildFallback(String initial, double calculatedFontSize) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.plusJakartaSans(
          fontSize: calculatedFontSize,
          fontWeight: FontWeight.bold,
          color: textColor ?? AppTheme.primaryTerracotta,
        ),
      ),
    );
  }
}
