import 'package:flutter/material.dart';
import '/utils/color_utils.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Account'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text("Account Information",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Icon(Icons.person, color: ColorUtils.green),
            title: Text('Profile'),
          ),
          ListTile(
            leading: Icon(Icons.email, color: ColorUtils.blue),
            title: Text('Email Settings'),
          ),
          ListTile(
            leading: Icon(Icons.security, color: ColorUtils.purple),
            title: Text('Security'),
          ),
        ],
      ),
    );
  }
}