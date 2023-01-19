import 'package:flutter/material.dart';

final ThemeData appTheme = _appTheme();

const MaterialColor dvbYellow = MaterialColor(
    0xFFFEC401,
    <int, Color>{
      50: Color(0xFFFFF8E1),
      100: Color(0xFFFFEDB3),
      200: Color(0xFFFFE280),
      300: Color(0xFFFED64D),
      400: Color(0xFFFECD27),
      500: Color(0xFFFEC401),
      600: Color(0xFFFEBE01),
      700: Color(0xFFFEB601),
      800: Color(0xFFFEAF01),
      900: Color(0xFFFDA200),
    },
);

ThemeData _appTheme() {
  final ThemeData base = ThemeData.dark();

  return base.copyWith(
    elevatedButtonTheme: _elevatedButtonTheme(base.elevatedButtonTheme),
    colorScheme: ColorScheme.fromSwatch(primarySwatch: dvbYellow),
    textTheme: _textTheme(base.textTheme),
    inputDecorationTheme: _inputDecorationTheme(base.inputDecorationTheme),
    dividerTheme: _dividerTheme(base.dividerTheme),
    snackBarTheme: _snackBarTheme(base.snackBarTheme),
  );
}

ElevatedButtonThemeData _elevatedButtonTheme(ElevatedButtonThemeData base) =>
    ElevatedButtonThemeData(
      style: ButtonStyle(
        shape: MaterialStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
          side: const BorderSide(),
        ))
      )
    );

TextTheme _textTheme(TextTheme base) =>
    base.copyWith(button: const TextStyle(fontSize: 14.0));

InputDecorationTheme _inputDecorationTheme(InputDecorationTheme base) =>
    base.copyWith(
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10.0)
      ),
      filled: true
    );

DividerThemeData _dividerTheme(DividerThemeData base) =>
    base.copyWith(
      space: 8,
      indent: 0,
      endIndent: 0,
      thickness: 1,
    );

SnackBarThemeData _snackBarTheme(SnackBarThemeData base) =>
    base.copyWith(
      backgroundColor: dvbYellow.shade900,
    );
