import 'package:flutter/services.dart';

/// Formatting TextInputFormatter for Currency inputs (e.g. 50000 -> 50.000)
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Extract only digits
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digitsOnly.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final number = int.parse(digitsOnly);
    final formatted = number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  /// Helper static method to format raw double value to 50.000
  static String format(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  /// Helper static method to parse formatted text "50.000" -> 50000.0
  static double parse(String formattedText, {double defaultValue = 0.0}) {
    final cleanDigits = formattedText.replaceAll(RegExp(r'[^\d]'), '');
    return double.tryParse(cleanDigits) ?? defaultValue;
  }
}
