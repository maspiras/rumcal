// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

/*import '/screens/account_screen.dart';
import '/screens/app_settings_screen.dart';
import '/screens/rate_app_screen.dart';*/
import 'package:bookcomfy/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/screens/reservation_screen.dart';
import '/screens/search_reservation.dart';
import '/screens/settings_screen.dart';
import '/screens/today_screen.dart';
import '/utils/color_utils.dart';
import '/utils/string_utils.dart';
import 'package:flutter/material.dart';

import 'calendar_screen.dart';

class MainScreen extends StatefulWidget {
  final bool fromLogin;
  const MainScreen({super.key, this.fromLogin = false});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  final GlobalKey<CalendarScreenState> calendarKey =
      GlobalKey<CalendarScreenState>();

  late final List<Widget> screens;

  @override
  void initState() {
    super.initState();
    screens = [
      CalendarScreen(key: calendarKey, fromLogin: widget.fromLogin),
      TodayScreen(),
      ReservationScreen(),
      SettingsScreen(),
    ];
  }

  // In your logout function (in the appropriate screen or function)
  Future<void> logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Set isLoggedIn to false when logging out
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('username');
    await prefs.remove('userId');

    // Navigate to login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

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
        title: Text(StringUtils.appTitle),
        actions: [
          if (currentIndex == 0)
            IconButton(
              onPressed: () {
                // calendarKey.currentState?.scrollToToday();
              },
              icon: Icon(Icons.calendar_today),
            ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SearchReservation(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            SizedBox(
              height: 120.0, // Set your desired height here
              child: DrawerHeader(
                decoration: BoxDecoration(color: Color(0xFF967969)),
                child: Text(
                  StringUtils.appTitle,
                  style: TextStyle(
                    color: ColorUtils.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            /*ListTile(
              leading: Icon(Icons.person, color: ColorUtils.green),
              title: Text('My Account'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AccountScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.settings, color: ColorUtils.blue),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AppSettingsScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.star, color: ColorUtils.purple),
              title: Text('Rate the App'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => RateAppScreen()));
              },
            ),
            Divider(),*/
            ListTile(
                leading: Icon(Icons.logout, color: ColorUtils.red),
                title: Text('Logout'),
                onTap: () {
                  logout();
                }),
          ],
        ),
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
          // _buildNavItem(
          //   Icons.person, StringUtils.users,
          //   // badgeController.usersBadge.value,
          // ),
          _buildNavItem(
            Icons.more_horiz, StringUtils.more,
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
    // Widget iconWidget;

    // if (icon is IconData) {
    //   iconWidget = Icon(icon, size: 28);
    // } else if (icon is String) {
    //   iconWidget = Image.asset(
    //     icon,
    //     width: 28,
    //     height: 28,
    //   );
    // } else {
    //   throw ArgumentError("icon must be IconData or String path");
    // }

    return NavigationDestination(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          // iconWidget
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
