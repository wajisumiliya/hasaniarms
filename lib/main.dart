import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/home/home_screen.dart';

void main()=>runApp(const HasaniCustomerApp());

class HasaniCustomerApp extends StatelessWidget {
  const HasaniCustomerApp({super.key});
  @override Widget build(BuildContext context)=>MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'Hasani Customer',
    theme:AppTheme.light(),
    home:const HomeScreen(),
  );
}
