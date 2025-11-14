import 'package:flutter/material.dart';

class EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final bool obscure;
  final String? Function(String?)? validator;
  final int? maxLines;
  final int? minLines;
  final String? hintText;
  final TextCapitalization textCapitalization;

  const EditField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.validator,
    this.maxLines,
    this.minLines,
    this.hintText,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        maxLines: maxLines ?? 1,
        minLines: maxLines != null ? (minLines ?? 1) : null,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
        ),
        validator: validator,
      ),
    );
  }
}