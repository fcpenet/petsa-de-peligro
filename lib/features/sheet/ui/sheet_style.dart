import 'package:material_ui/material_ui.dart';

import '../domain/sheet_model.dart';

/// Google-Sheets-like look: white cells, light grid lines, grey headers.
abstract final class SheetStyle {
  static const background = Color(0xFFFFFFFF);
  static const chrome = Color(0xFFF8F9FA);
  static const chromeText = Color(0xFF5F6368);
  static const grid = Color(0xFFE2E3E3);
  static const blockEdge = Color(0xFF3C4043);
  static const selection = Color(0xFF1A73E8);
  static const selectionFill = Color(0x141A73E8);
  static const text = Color(0xFF202124);
  static const muted = Color(0xFF9AA0A6);
  static const negative = Color(0xFFD93025);
  static const action = Color(0xFF1A73E8);

  static const rowNumberWidth = 46.0;
  static const letterRowHeight = 22.0;
  static const rowHeight = 28.0;
  static const fontSize = 13.0;

  static const _accountTints = [
    Color(0xFFE8F0FE), // blue
    Color(0xFFE6F4EA), // green
    Color(0xFFFCE8E6), // red
    Color(0xFFFEF7E0), // yellow
    Color(0xFFF3E8FD), // purple
    Color(0xFFE4F7FB), // cyan
  ];

  static Color headerTint(SheetBlock block, int index) => switch (block.kind) {
    BlockKind.summary => const Color(0xFFF1F3F4),
    BlockKind.income => const Color(0xFFE6F4EA),
    BlockKind.account => _accountTints[index % _accountTints.length],
  };

  /// A, B, … Z, AA, AB, …
  static String columnLetter(int index) {
    var n = index + 1;
    final buffer = StringBuffer();
    while (n > 0) {
      final rem = (n - 1) % 26;
      buffer.write(String.fromCharCode(65 + rem));
      n = (n - 1) ~/ 26;
    }
    return buffer.toString().split('').reversed.join();
  }
}
