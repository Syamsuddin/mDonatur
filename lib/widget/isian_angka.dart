// Isian angka (docs/26_UI_CONVENTIONS.md §Inventaris): TextField berlabel, keypad angka, hanya digit.
// Rentang nilai diperiksa server; [maksDigit] hanya membatasi panjang ketikan.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IsianAngka extends StatelessWidget {
  const IsianAngka({
    super.key,
    required this.label,
    required this.controller,
    this.focusNode,
    this.errorText,
    this.maksDigit,
    this.enabled = true,
    this.padat = false,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? errorText;
  final int? maksDigit;
  final bool enabled;

  /// Tinggi rapat (isDense) untuk layar Input Sumbangan; target sentuh tetap ≥ 48 dp.
  final bool padat;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        if (maksDigit case final maks?) LengthLimitingTextInputFormatter(maks),
      ],
      autocorrect: false,
      enableSuggestions: false,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        errorMaxLines: 3,
        isDense: padat,
      ),
    );
  }
}
