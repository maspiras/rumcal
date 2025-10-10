import 'package:flutter/material.dart';
import 'main_screen.dart';
import 'calendar_screen.dart';

class MainScreenWrapper extends StatefulWidget {
  final bool fromLogin;
  const MainScreenWrapper({super.key, this.fromLogin = false});

  @override
  State<MainScreenWrapper> createState() => _MainScreenWrapperState();
}

class _MainScreenWrapperState extends State<MainScreenWrapper> {
  int currentIndex = 0;
  final GlobalKey<CalendarScreenState> calendarKey = GlobalKey<CalendarScreenState>();

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      CalendarScreen(key: calendarKey, fromLogin: widget.fromLogin),
      // Other screens remain same as they don't need fromLogin
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Return MainScreen but with modified CalendarScreen
    return MainScreen();
  }
}