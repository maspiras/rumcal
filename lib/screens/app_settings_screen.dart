import 'package:flutter/material.dart';
import 'package:cal_room/utils/color_utils.dart';

class AppSettingsScreen extends StatelessWidget {
  const AppSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text("Application Settings",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Icon(Icons.notifications, color: ColorUtils.blue),
            title: Text('Notifications'),
          ),
          ListTile(
            leading: Icon(Icons.language, color: ColorUtils.green),
            title: Text('Language'),
          ),
          ListTile(
            leading: Icon(Icons.palette, color: ColorUtils.purple),
            title: Text('Theme'),
          ),
        ],
      ),
    );
  }
}