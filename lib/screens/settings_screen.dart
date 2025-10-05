// ignore_for_file: use_key_in_widget_constructors, use_build_context_synchronously

import '/blocs/reservation/reservation__bloc.dart';
import '/blocs/reservation/reservation__event.dart';
import '/blocs/room/room_bloc.dart';
import '/blocs/room/room_event.dart';
import '/blocs/user/user_bloc.dart';
import '/blocs/user/user_event.dart';
import '/screens/sales_report_screen.dart';
import '/screens/transaction_report.dart';
import '/screens/user_screen.dart';
import '/utils/color_utils.dart';
import '/utils/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import '../database/db_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'download_db.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = false;

  bool isLoading = false;

  /// Reset Specific Table or Entire Database
  void resetDatabase(BuildContext context, {String? table}) async {
    if (isLoading) return;
    isLoading = true;

    final db = await DBHelper.database;
    await db.transaction((txn) async {
      try {
        await txn.execute("PRAGMA foreign_keys = OFF;");

        if (table == StringUtils.users) {
          await txn.execute("DELETE FROM Users;");
          context.read<UserBloc>().add(FetchUsers());
        } else if (table == StringUtils.rooms) {
          await txn.execute("DELETE FROM Rooms;");
          context.read<RoomBloc>().add(FetchRooms());
        } else if (table == StringUtils.reservations) {
          await txn.execute("DELETE FROM Reservations;");
          context.read<ReservationBloc>().add(FetchReservationsEvent());
        } else {
          await txn.execute("DELETE FROM Reservations;");
          await txn.execute("DELETE FROM Rooms;");
          await txn.execute("DELETE FROM Users;");
          context.read<UserBloc>().add(FetchUsers());
          context.read<RoomBloc>().add(FetchRooms());
          context.read<ReservationBloc>().add(FetchReservationsEvent());
        }

        await txn.execute("PRAGMA foreign_keys = ON;");
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${StringUtils.dbResetFailed}: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    // ✅ Update badge counts **AFTER** database operations are complete
    Future.delayed(Duration(milliseconds: 500), () {
      // if (Get.isRegistered<BadgeController>()) {
      //   badgeController.updateBadgeCounts();
      // }
    });

    isLoading = false; // ✅ Stop loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text("${table ?? StringUtils.allData} ${StringUtils.resetSuccess}"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(StringUtils.settings)),
      body: ListView(
        children: [
          // Appearance
          ListTile(
            title: Text("Appearance & Preferences",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          SwitchListTile(
            title: Text(StringUtils.darkMode),
            value: isDarkMode,
            onChanged: (value) {
              setState(() {
                isDarkMode = value;
                Get.changeTheme(value ? ThemeData.dark() : ThemeData.light());
              });
            },
          ),

          Divider(),

          // User & Data Management
          ListTile(
            title: Text("User & Data Management",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Icon(Icons.person, color: ColorUtils.green),
            title: Text(StringUtils.users),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => UserScreen())),
          ),
          ListTile(
            leading: Icon(Icons.delete, color: ColorUtils.red),
            title: Text(StringUtils.resetAll),
            onTap: () => showResetOptions(context),
          ),
          ListTile(
            leading: Icon(Icons.people, color: ColorUtils.blue),
            title: Text(StringUtils.resetUsers),
            onTap: () => resetDatabase(context, table: StringUtils.users),
          ),
          ListTile(
            leading: Icon(Icons.meeting_room, color: ColorUtils.green),
            title: Text(StringUtils.resetRooms),
            onTap: () => resetDatabase(context, table: StringUtils.rooms),
          ),
          ListTile(
            leading: Icon(Icons.event, color: ColorUtils.purple),
            title: Text(StringUtils.resetReservations),
            onTap: () =>
                resetDatabase(context, table: StringUtils.reservations),
          ),
          ListTile(
            leading:
                Icon(Icons.insert_drive_file_outlined, color: ColorUtils.blue),
            title: Text(StringUtils.downloadDB),
            onTap: () async => await DownloadDBFile.downloadDBFile(),
          ),

          Divider(),

          // Reports
          ListTile(
            title: Text("Reports & Analytics",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Icon(Icons.history, color: ColorUtils.blue),
            title: Text(StringUtils.salesReport),
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => ReportScreen())),
          ),
          ListTile(
            leading: Icon(Icons.payment, color: ColorUtils.blue),
            title: Text(StringUtils.transactionReport),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => TransactionScreen())),
          ),

          Divider(),

          // System
          ListTile(
            title: Text("System & Access",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: ColorUtils.red),
            title: Text(StringUtils.logout),
            onTap: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),

      // Column(
      //   children: [
      //     SwitchListTile(
      //       title: Text(StringUtils.darkMode),
      //       value: isDarkMode,
      //       onChanged: (value) {
      //         setState(() {
      //           isDarkMode = value;
      //           Get.changeTheme(value ? ThemeData.dark() : ThemeData.light());
      //         });
      //       },
      //     ),
      //     if (isLoading) Center(child: CircularProgressIndicator()),
      //     if (!isLoading)
      //       Column(
      //         children: [
      //           ListTile(
      //             leading: Icon(Icons.person, color: ColorUtils.green),
      //             title: Text(StringUtils.users),
      //             onTap: () async {
      //               Navigator.push(
      //                 context,
      //                 MaterialPageRoute(builder: (context) => UserScreen()),
      //               );
      //             },
      //           ),
      //           ListTile(
      //             leading: Icon(Icons.delete, color: ColorUtils.red),
      //             title: Text(StringUtils.resetAll),
      //             onTap: () => showResetOptions(context),
      //           ),
      //           ListTile(
      //             leading: Icon(Icons.people, color: ColorUtils.blue),
      //             title: Text(StringUtils.resetUsers),
      //             onTap: () => resetDatabase(context, table: StringUtils.users),
      //           ),
      //           ListTile(
      //             leading: Icon(Icons.meeting_room, color: ColorUtils.green),
      //             title: Text(StringUtils.resetRooms),
      //             onTap: () => resetDatabase(context, table: StringUtils.rooms),
      //           ),
      //           ListTile(
      //             leading: Icon(Icons.event, color: ColorUtils.purple),
      //             title: Text(StringUtils.resetReservations),
      //             onTap: () =>
      //                 resetDatabase(context, table: StringUtils.reservations),
      //           ),
      //           ListTile(
      //             leading: Icon(Icons.insert_drive_file_outlined,
      //                 color: ColorUtils.blue),
      //             title: Text(StringUtils.downloadDB),
      //             onTap: () async {
      //               await DownloadDBFile.downloadDBFile();
      //             },
      //           ),
      //           ListTile(
      //             leading: Icon(Icons.history, color: ColorUtils.blue),
      //             title: Text(StringUtils.salesReport),
      //             onTap: () async {
      //               Navigator.push(
      //                 context,
      //                 MaterialPageRoute(builder: (context) => ReportScreen()),
      //               );
      //             },
      //           ),
      //           ListTile(
      //             leading: Icon(Icons.payment, color: ColorUtils.blue),
      //             title: Text(StringUtils.transactionReport),
      //             onTap: () async {
      //               Navigator.push(
      //                 context,
      //                 MaterialPageRoute(
      //                     builder: (context) => TransactionScreen()),
      //               );
      //             },
      //           ),
      //           ListTile(
      //             leading: Icon(Icons.logout, color: ColorUtils.red),
      //             title: Text(StringUtils.logout),
      //             onTap: () async {
      //               SharedPreferences prefs =
      //                   await SharedPreferences.getInstance();
      //               await prefs.clear();
      //               Navigator.pushAndRemoveUntil(
      //                 context,
      //                 MaterialPageRoute(builder: (context) => LoginScreen()),
      //                 (Route<dynamic> route) =>
      //                     false, // This will remove all the previous routes
      //               );
      //             },
      //           ),
      //         ],
      //       ),
      //   ],
      // ),
    );
  }

  /// ✅ Show Confirmation Dialog Before Reset
  void showResetOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(StringUtils.resetDatabase),
          content: const Text(StringUtils.resetConfirmation),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(StringUtils.cancel),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                resetDatabase(context);
              },
              child: Text(StringUtils.confirmReset),
            ),
          ],
        );
      },
    );
  }
}
