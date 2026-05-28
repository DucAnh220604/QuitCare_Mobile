import 'package:flutter/material.dart';
import 'home_screen.dart';

// This widget is deprecated - use MainApp instead which handles navigation
// Keeping for backwards compatibility
class HomeScreenNav extends StatelessWidget {
  const HomeScreenNav({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomeScreen();
  }
}
