import 'package:flutter/material.dart';

import '../../core/theme/a2c_dimens.dart';
import '../../core/theme/a2c_typography.dart';

/// Campo de texto con etiqueta visible arriba (no solo placeholder).
class A2CTextField extends StatelessWidget {
  const A2CTextField({
    super.key,
    required this.label,
    this.controller,
    this.hint,
    this.keyboardType,
    this.obscureText = false,
    this.maxLength,
    this.validator,
    this.textInputAction,
    this.autofillHints,
    this.prefixIcon,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLength;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: A2CText.label),
        const SizedBox(height: A2CSpace.sm),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          validator: validator,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          style: A2CText.body,
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixIcon: prefixIcon == null ? null : Icon(prefixIcon, size: 20),
          ),
        ),
      ],
    );
  }
}
