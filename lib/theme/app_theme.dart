import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryAccent = Color(0xFFB9FF66);
  static const Color primaryBg = Color(0xFF191A23);

  static const Color darkSurface = Color(0xFF232634);
  static const Color darkSurfaceSoft = Color(0xFF2B2F40);
  static const Color darkCard = Color(0xFF242838);
  static const Color darkBorder = Color(0xFF3A4055);

  static const Color lightBg = Color(0xFFF7F8F3);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceSoft = Color(0xFFF1F4E8);
  static const Color lightBorder = Color(0xFFD9E1C7);

  static const Color secondaryAccent = Color(0xFF7EE0C6);
  static const Color warningColor = Color(0xFFFFC857);
  static const Color errorColor = Color(0xFFFF6B6B);
  static const Color successColor = Color(0xFF56D364);

  static const Color lightText = Color(0xFF171923);
  static const Color lightMuted = Color(0xFF687083);

  static const Color darkText = Colors.white;
  static const Color darkMuted = Color(0xFFB8BECC);

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: lightBg,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: primaryAccent,
      onPrimary: Colors.black,
      secondary: secondaryAccent,
      onSecondary: Colors.black,
      error: errorColor,
      onError: Colors.white,
      surface: lightSurface,
      onSurface: lightText,
      surfaceContainerHighest: lightSurfaceSoft,
      onSurfaceVariant: lightMuted,
      outline: lightBorder,
      shadow: Colors.black12,
      inverseSurface: primaryBg,
      onInverseSurface: Colors.white,
      inversePrimary: primaryAccent,
      surfaceTint: Colors.transparent,
    ),
    textTheme: GoogleFonts.montserratTextTheme().apply(
      bodyColor: lightText,
      displayColor: lightText,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: lightBg,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: lightText),
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: lightText,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0x12000000)),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE7ECDD),
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightSurface,
      hintStyle: GoogleFonts.montserrat(
        color: const Color(0xFF97A0B3),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: GoogleFonts.montserrat(
        color: lightMuted,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: lightBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: lightBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: primaryAccent,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: errorColor,
          width: 1.6,
        ),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryAccent;
        return const Color(0xFFB8C0D2);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryAccent;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: const BorderSide(color: lightBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: lightSurface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: primaryAccent.withOpacity(0.22),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? lightText : const Color(0xFF7D8494),
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? lightText : const Color(0xFF7D8494),
        );
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightSurfaceSoft,
      selectedColor: primaryAccent.withOpacity(0.22),
      disabledColor: const Color(0xFFE8EDD9),
      side: const BorderSide(color: lightBorder),
      labelStyle: GoogleFonts.montserrat(
        fontWeight: FontWeight.w600,
        color: lightText,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: lightText,
      textColor: lightText,
      titleTextStyle: GoogleFonts.montserrat(
        color: lightText,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: GoogleFonts.montserrat(
        color: lightMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF16181F),
      contentTextStyle: GoogleFonts.montserrat(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryAccent,
        foregroundColor: Colors.black,
        disabledBackgroundColor: const Color(0xFFD6E3B7),
        disabledForegroundColor: Colors.black54,
        elevation: 0,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        textStyle: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: lightText,
        side: const BorderSide(color: lightBorder),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        textStyle: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: primaryBg,
    colorScheme: const ColorScheme(
      brightness: Brightness.dark,
      primary: primaryAccent,
      onPrimary: Colors.black,
      secondary: secondaryAccent,
      onSecondary: Colors.black,
      error: errorColor,
      onError: Colors.black,
      surface: darkSurface,
      onSurface: darkText,
      surfaceContainerHighest: darkSurfaceSoft,
      onSurfaceVariant: darkMuted,
      outline: darkBorder,
      shadow: Colors.black,
      inverseSurface: Colors.white,
      onInverseSurface: Colors.black,
      inversePrimary: primaryAccent,
      surfaceTint: Colors.transparent,
    ),
    textTheme: GoogleFonts.montserratTextTheme(
      ThemeData.dark().textTheme,
    ).apply(
      bodyColor: darkText,
      displayColor: darkText,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: false,
      backgroundColor: primaryBg,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      titleTextStyle: GoogleFonts.montserrat(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: darkCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: darkBorder),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: darkBorder,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      hintStyle: GoogleFonts.montserrat(
        color: const Color(0xFF8A90A0),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      labelStyle: GoogleFonts.montserrat(
        color: darkMuted,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: darkBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: darkBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: primaryAccent,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: errorColor,
          width: 1.6,
        ),
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryAccent;
        return const Color(0xFF8088A0);
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryAccent;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.black),
      side: const BorderSide(color: darkBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: primaryAccent.withOpacity(0.18),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? primaryAccent : Colors.white70,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? primaryAccent : Colors.white70,
        );
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkSurfaceSoft,
      selectedColor: primaryAccent.withOpacity(0.18),
      disabledColor: const Color(0xFF303446),
      side: const BorderSide(color: darkBorder),
      labelStyle: GoogleFonts.montserrat(
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: Colors.white,
      textColor: Colors.white,
      titleTextStyle: GoogleFonts.montserrat(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: GoogleFonts.montserrat(
        color: darkMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkSurfaceSoft,
      contentTextStyle: GoogleFonts.montserrat(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryAccent,
        foregroundColor: Colors.black,
        disabledBackgroundColor: const Color(0xFF4A513F),
        disabledForegroundColor: Colors.black54,
        elevation: 0,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        textStyle: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: darkBorder),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        textStyle: GoogleFonts.montserrat(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}