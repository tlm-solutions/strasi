import 'package:flutter/material.dart';

final ThemeData appTheme = _appTheme();

ThemeData _appTheme() {
  final ThemeData base = ThemeData.dark();

  return base.copyWith(
    elevatedButtonTheme: _elevatedButtonTheme(base.elevatedButtonTheme),
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.yellow),
    textTheme: _textTheme(base.textTheme),
    inputDecorationTheme: _inputDecorationTheme(base.inputDecorationTheme),
  );
}

ElevatedButtonThemeData _elevatedButtonTheme(ElevatedButtonThemeData base) =>
    ElevatedButtonThemeData(
      style: ButtonStyle(
        shape: MaterialStateProperty.all(RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
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
