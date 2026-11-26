/// Formatting helpers — Persian/Latin digits and unit strings.
library;

const List<String> faDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];

/// Converts western digits to Persian digits.
String faNum(int n) => n.toString().replaceAllMapped(
      RegExp(r'\d'),
      (m) => faDigits[int.parse(m.group(0)!)],
    );

/// Locale-aware number formatting: fa → Persian digits, en → Latin.
String numStr(bool isFa, int n) => isFa ? faNum(n) : n.toString();

/// Zero-padded, locale-aware two-digit number (clock displays).
String num2(bool isFa, int n) {
  final s = n.toString().padLeft(2, '0');
  return isFa ? s.replaceAllMapped(RegExp(r'\d'), (m) => faDigits[int.parse(m.group(0)!)]) : s;
}

/// Locale-aware number helper shared across screens.
String faNumInt(bool fa, int n) => fa ? faNum(n) : n.toString();
