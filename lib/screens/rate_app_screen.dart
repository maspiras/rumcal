import 'package:flutter/material.dart';
import 'package:cal_room/utils/color_utils.dart';

class RateAppScreen extends StatelessWidget {
  const RateAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rate the App'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: Text("Rate & Review",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: Icon(Icons.star, color: ColorUtils.purple),
            title: Text('Rate on App Store'),
          ),
          ListTile(
            leading: Icon(Icons.feedback, color: ColorUtils.blue),
            title: Text('Send Feedback'),
          ),
          ListTile(
            leading: Icon(Icons.share, color: ColorUtils.green),
            title: Text('Share App'),
          ),
        ],
      ),
    );
  }
}