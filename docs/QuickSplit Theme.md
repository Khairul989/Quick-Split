
# QuickSplit Flutter Theme Specification

This file contains the complete color system, design tokens, and Flutter `ThemeData` implementations for **QuickSplit**, including **Light Mode** and **Dark Mode**.

---

# 🎨 Color Palette

## 🌈 Primary Colors (QuickSplit Blue)
| Token | Hex | Usage |
|-------|------|-------|
| `primary-500` | **#248CFF** | Main brand color |
| `primary-600` | **#007BFF** | Buttons, prominent actions |
| `primary-700` | **#0063D6** | Pressed/active states |
| `primary-light` | **#A7D4FF** | Light tint, backgrounds |
| `primary-dark` | **#004A99** | Dark mode primary |

## 🟩 Secondary / Accent (Mint)
| Token | Hex |
|-------|------|
| `secondary-500` | **#10B981** |
| `secondary-600` | **#059669** |
| `secondary-light` | **#6EE7B7** |

## 🟥 Semantic Colors
| Token | Hex | Meaning |
|--------|------|---------|
| `success` | **#16A34A** | Positive actions |
| `warning` | **#F59E0B** | Alerts |
| `error` | **#DC2626** | Errors |
| `info` | **#0EA5E9** | Informational |

## ⚪ Neutral Colors
| Token | Hex |
|--------|------|
| `bg` | **#F7F9FC** |
| `surface` | **#FFFFFF** |
| `surface-variant` | **#F0F3F8** |
| `text-primary` | **#1F2937** |
| `text-secondary` | **#6B7280** |
| `divider` | **#E5E7EB** |

## 🌙 Dark Mode Palette
| Token | Hex |
|--------|------|
| `dark-bg` | **#0F172A** |
| `dark-surface` | **#1E293B** |
| `dark-text-primary` | **#F8FAFC** |
| `dark-text-secondary` | **#CBD5E1** |
| `dark-divider` | **#334155** |
| `dark-primary` | **#3EA8FF** |

---

# 🧩 Flutter ThemeData (Light + Dark)

## **Light Theme**

```dart
import 'package:flutter/material.dart';

class QuickSplitTheme {
  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF248CFF),
    scaffoldBackgroundColor: const Color(0xFFF7F9FC),
    fontFamily: 'Inter',

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF248CFF),
      primaryContainer: Color(0xFFA7D4FF),
      secondary: Color(0xFF10B981),
      background: Color(0xFFF7F9FC),
      surface: Color(0xFFFFFFFF),
      onPrimary: Colors.white,
      onSurface: Color(0xFF1F2937),
      error: Color(0xFFDC2626),
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      foregroundColor: Color(0xFF1F2937),
    ),

    dividerColor: const Color(0xFFE5E7EB),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF1F2937)),
      bodyMedium: TextStyle(color: Color(0xFF1F2937)),
      labelLarge: TextStyle(color: Color(0xFF1F2937)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF248CFF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
```

---

## **Dark Theme**

```dart
  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF3EA8FF),
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    fontFamily: 'Inter',

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF3EA8FF),
      primaryContainer: Color(0xFF1E293B),
      secondary: Color(0xFF10B981),
      background: Color(0xFF0F172A),
      surface: Color(0xFF1E293B),
      onPrimary: Colors.white,
      onSurface: Color(0xFFF8FAFC),
      error: Color(0xFFDC2626),
    ),

    dividerColor: const Color(0xFF334155),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFFF8FAFC)),
      bodyMedium: TextStyle(color: Color(0xFFF8FAFC)),
      labelLarge: TextStyle(color: Color(0xFFF8FAFC)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3EA8FF),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}
```

---

# ✔ How to Use

Inside `main.dart`:

```dart
return MaterialApp(
  theme: QuickSplitTheme.light,
  darkTheme: QuickSplitTheme.dark,
  themeMode: ThemeMode.system,
  home: const HomeScreen(),
);
```

---

# 🧱 Notes for Claude
- Convert all tokens into reusable constants if needed.
- Implement typography scaling if design expands.
- Extend button, chip, card, and form themes using the same tokens.
- Keep animations subtle and minimal.

---

This theme is production‑ready and can be applied immediately.
