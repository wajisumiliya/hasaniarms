import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData light()=>ThemeData(
    useMaterial3:true,
    colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xff2358d8)),
    scaffoldBackgroundColor:const Color(0xfff5f7fb),
    cardTheme:const CardThemeData(margin:EdgeInsets.zero,elevation:0),
    inputDecorationTheme:InputDecorationTheme(border:OutlineInputBorder(),filled:true,fillColor:Colors.white),
  );
}
