// ignore_for_file: library_private_types_in_public_api

import 'package:cal_room/screens/reservation_screen.dart';
import 'package:cal_room/screens/search_reservation.dart';
import 'package:cal_room/screens/settings_screen.dart';
import 'package:cal_room/screens/today_screen.dart';
import 'package:cal_room/screens/user_screen.dart';
import 'package:cal_room/utils/color_utils.dart';
import 'package:cal_room/utils/string_utils.dart';
import 'package:flutter/material.dart';

import 'calendar_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  final screens = [
    CalendarScreen(),
    TodayScreen(),
    // RoomScreen(),
    ReservationScreen(),
    UserScreen(),
    SettingsScreen(),
  ];

  // final BadgeController badgeController = Get.find<BadgeController>();

  /// Clear badge count for the selected screen when tapped
  // void clearBadge(int index) {
  //   switch (index) {
  //     case 0:
  //       badgeController.calendarBadge.value = 0;
  //       break;
  //     case 1:
  //       badgeController.roomsBadge.value = 0;
  //       break;
  //     case 2:
  //       badgeController.reservationsBadge.value = 0;
  //       break;
  //     case 3:
  //       badgeController.usersBadge.value = 0;
  //       break;
  //     case 4:
  //       badgeController.settingsBadge.value = 0;
  //       break;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false, // Removes floating bottom bar
      appBar: AppBar(
        leading: Icon(
          Icons.calendar_month,
          size: 30,
        ),
        // ✅ Replace with your logo

        title: Text(StringUtils.appTitle),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: ColorUtils.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchReservation(),
                ),
              );
              //  showSearch(context: context, delegate: DataSearch());
            },
          ),
        ],
      ),
      body: screens[currentIndex],

      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
            // clearBadge(index); // Clear badge on tap
          });
        },
        destinations: [
          _buildNavItem(
            Icons.calendar_today, StringUtils.calendar,
            // badgeController.calendarBadge.value,
          ),
          // _buildNavItem(Icons.meeting_room, "Rooms", badgeController.roomsBadge.value),
          _buildNavItem(
            Icons.meeting_room, StringUtils.today,
            // badgeController.roomsBadge.value,
          ),
          _buildNavItem(
            Icons.event, StringUtils.reservations,
            // badgeController.reservationsBadge.value,
          ),
          _buildNavItem(
            Icons.person, StringUtils.users,
            // badgeController.usersBadge.value,
          ),
          _buildNavItem(
            Icons.settings, StringUtils.settings,
            // badgeController.settingsBadge.value,
          ),
        ],
      ),
    );
  }

  /// 🔹 Modern **Navigation Bar Item with Notification Badges**
  NavigationDestination _buildNavItem(
    IconData icon,
    String label,
    /* int badgeCount*/
  ) {
    return NavigationDestination(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, size: 28),
          // if (badgeCount > 0)
          //   Positioned(
          //     right: -2,
          //     top: -2,
          //     child: Container(
          //       padding: EdgeInsets.all(4),
          //       decoration: BoxDecoration(color: ColorUtils.red, shape: BoxShape.circle),
          //       constraints: BoxConstraints(minWidth: 18, minHeight: 18),
          //       child: Text(
          //         badgeCount > 99 ? "99+" : badgeCount.toString(),
          //         style: TextStyle(color: ColorUtils.white, fontSize: 12, fontWeight: FontWeight.bold),
          //         textAlign: TextAlign.center,
          //       ),
          //     ),
          //   ),
        ],
      ),
      label: label,
    );
  }
}

// 🔹 Search Feature with Improved UI
class DataSearch extends SearchDelegate<String> {
  final List<String> searchItems = [
    "User 1",
    "User 2",
    "Room 101",
    "Room 102",
    "Reservation A",
    "Reservation B",
  ];

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
          icon: Icon(Icons.clear, color: ColorUtils.black),
          onPressed: () => query = ""),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        icon: Icon(Icons.arrow_back, color: ColorUtils.black),
        onPressed: () => close(context, ""));
  }

  @override
  Widget buildResults(BuildContext context) {
    return Center(
        child: Text("${StringUtils.searchResult}: $query",
            style: TextStyle(color: ColorUtils.black, fontSize: 18)));
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = searchItems
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) => ListTile(
        leading: Icon(Icons.search, color: ColorUtils.blue),
        title:
            Text(suggestions[index], style: TextStyle(color: ColorUtils.black)),
        onTap: () => query = suggestions[index],
      ),
    );
  }
}
