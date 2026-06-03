import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// A pixel-art styled button with a hard rectangular shape.
class PixelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isLoading;

  const PixelButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.primary;
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        side: const BorderSide(color: AppColors.primaryLight, width: 1),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
    );
  }
}
