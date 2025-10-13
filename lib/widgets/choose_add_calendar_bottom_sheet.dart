import '/utils/string_utils.dart' show StringUtils;
import '/widgets/add_edit_reservation_bottom_sheet.dart';
import '/widgets/add_edit_room_bottom_sheet.dart';
import 'package:flutter/material.dart';

// void chooseAddCalendarBottomSheet(BuildContext context) {
//   showModalBottomSheet(
//     context: context,
//     isScrollControlled: true,
//     shape: const RoundedRectangleBorder(
//       borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//     ),
//     builder: (context) {
//       return Padding(
//         padding: const EdgeInsets.all(16),
//         child: SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 StringUtils.addTitle,
//                 style:
//                     const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 20),
//               ListTile(
//                 onTap: () {
//                   Navigator.pop(context);
//                   addEditReservationBottomSheet(context);
//                 },
//                 title: Text(StringUtils.reservation),
//                 leading: const Icon(Icons.add),
//               ),
//               ListTile(
//                 onTap: () {
//                   Navigator.pop(context);
//                   addEditRoomBottomSheet(context);
//                 },
//                 title: Text(StringUtils.room),
//                 leading: const Icon(Icons.bedroom_parent_outlined),
//               ),
//             ],
//           ),
//         ),
//       );
//     },
//   );
// }
// CHANGE: let the chooser accept a callback (same as before)
void chooseAddCalendarBottomSheet(
  BuildContext context, {
  VoidCallback? onReservationAdded,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.add),
                title: Text(StringUtils.reservation),
                onTap: () async {
                  // ⬇️ DO NOT close the chooser yet.
                  final result = await addEditReservationBottomSheet(context);

                  // now close the chooser
                  if (context.mounted) Navigator.pop(context);

                  // if reservation was saved, notify calendar AFTER a frame
                  if (result != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      onReservationAdded?.call();
                    });
                  }
                },
              ),
              /* ListTile(
                leading: const Icon(Icons.bedroom_parent_outlined),
                title: Text(StringUtils.room),
                onTap: () {
                  // this one can stay as-is
                  Navigator.pop(context);
                  addEditRoomBottomSheet(context);
                },
              ),*/
              ListTile(
                leading: const Icon(Icons.bedroom_parent_outlined),
                title: Text(StringUtils.room),
                onTap: () async {
                  // chooser ko turant band MAT karo
                  final result = await addEditRoomBottomSheet(context);

                  // ab chooser band karo
                  if (context.mounted) Navigator.pop(context);

                  // agar room add/update hua ho to calendar ko today pe le aao
                  if (result != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      onReservationAdded?.call(); // same callback reuse
                    });
                  }
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}
