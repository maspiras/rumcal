import '/utils/string_utils.dart' show StringUtils;
import '/widgets/add_edit_reservation_bottom_sheet.dart';
import '/widgets/add_edit_room_bottom_sheet.dart';
import 'package:flutter/material.dart';

void chooseAddCalendarBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SafeArea( child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              StringUtils.addTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                addEditReservationBottomSheet(context);
              },
              title: Text(StringUtils.reservation),
              leading: const Icon(Icons.add),
            ),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                addEditRoomBottomSheet(context);
              },
              title: Text(StringUtils.room),
              leading: const Icon(Icons.bedroom_parent_outlined),
            ),
          ],
        ),
        ),
      );
    },
  );
}
