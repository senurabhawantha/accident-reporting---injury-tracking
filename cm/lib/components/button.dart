import 'package:flutter/material.dart';
import 'package:cm/theme/app_theme.dart';

enum ButtonType { primary, secondary, error }

class MYButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String text;
  final ButtonType type;
  final bool isLoading;
  final double? width;
  final IconData? icon;

  const MYButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.width,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (type) {
      case ButtonType.primary:
        backgroundColor = AppTheme.primaryColor;
        textColor = Colors.white;
        break;
      case ButtonType.secondary:
        backgroundColor = Colors.white;
        textColor = AppTheme.primaryColor;
        break;
      case ButtonType.error:
        backgroundColor = AppTheme.errorColor;
        textColor = Colors.white;
        break;
    }

    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: type == ButtonType.secondary
                ? BorderSide(color: AppTheme.primaryColor)
                : BorderSide.none,
          ),
          backgroundColor: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: type == ButtonType.secondary ? 0 : 2,
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
