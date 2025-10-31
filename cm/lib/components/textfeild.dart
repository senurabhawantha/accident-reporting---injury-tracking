import 'package:flutter/material.dart';
import 'package:cm/theme/app_theme.dart';

class MYTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final String? labelText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconPressed;
  final bool isEnabled;
  final int maxLines;
  final void Function(String)? onChanged;

  const MYTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.labelText,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconPressed,
    this.isEnabled = true,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  State<MYTextField> createState() => _MYTextFieldState();
}

class _MYTextFieldState extends State<MYTextField> {
  late bool _obscureText;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      child: TextFormField(
        controller: widget.controller,
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        enabled: widget.isEnabled,
        maxLines: widget.obscureText ? 1 : widget.maxLines,
        validator: widget.validator,
        onChanged: widget.onChanged,
        style: const TextStyle(
          fontSize: 16,
          color: AppTheme.textColor,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: widget.isEnabled ? Colors.white : Colors.grey[100],
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide:
                const BorderSide(color: AppTheme.primaryColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          errorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppTheme.errorColor),
            borderRadius: BorderRadius.circular(8),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: AppTheme.errorColor, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          hintText: widget.hintText,
          labelText: widget.labelText,
          hintStyle: const TextStyle(color: Colors.grey),
          labelStyle: TextStyle(
            color: _isFocused ? AppTheme.primaryColor : Colors.grey,
          ),
          prefixIcon: widget.prefixIcon != null
              ? Icon(
                  widget.prefixIcon,
                  color: _isFocused ? AppTheme.primaryColor : Colors.grey,
                )
              : null,
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility : Icons.visibility_off,
                    color: _isFocused ? AppTheme.primaryColor : Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                )
              : widget.suffixIcon != null
                  ? IconButton(
                      icon: Icon(
                        widget.suffixIcon,
                        color: _isFocused ? AppTheme.primaryColor : Colors.grey,
                      ),
                      onPressed: widget.onSuffixIconPressed,
                    )
                  : null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
