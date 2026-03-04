import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/constants/app_colors.dart';

enum InputType { name, email, password, phoneNumber, digits, multiline }

class TextInputField extends StatefulWidget {
  const TextInputField({
    super.key,
    required this.type,
    required this.controller,
    this.hintLabel,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.readOnly = false,
    this.validator,
    this.maxLines,
    this.onChanged,
  });

  final InputType type;
  final TextEditingController controller;
  final String? hintLabel;
  final String? labelText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool readOnly;
  final String? Function(String?)? validator;
  final int? maxLines;
  final ValueChanged<String>? onChanged;

  @override
  State<TextInputField> createState() => _TextInputFieldState();
}

class _TextInputFieldState extends State<TextInputField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.type == InputType.password;
    return TextFormField(
      controller: widget.controller,
      readOnly: widget.readOnly,
      obscureText: isPassword && _obscure,
      onChanged: widget.onChanged,
      keyboardType: switch (widget.type) {
        InputType.email => TextInputType.emailAddress,
        InputType.phoneNumber => TextInputType.phone,
        InputType.digits => TextInputType.number,
        InputType.multiline => TextInputType.multiline,
        _ => TextInputType.text,
      },
      maxLines: isPassword ? 1 : (widget.maxLines ?? 1),
      inputFormatters: [
        if (widget.type == InputType.digits) FilteringTextInputFormatter.digitsOnly,
        if (widget.type == InputType.phoneNumber) LengthLimitingTextInputFormatter(15),
      ],
      validator: widget.validator,
      decoration: InputDecoration(
        hintText: widget.hintLabel,
        labelText: widget.labelText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.grey,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : widget.suffixIcon,
      ),
    );
  }
}
