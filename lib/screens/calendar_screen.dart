// ignore_for_file: library_private_types_in_public_api, avoid_function_literals_in_foreach_calls
import '/blocs/reservation/reservation__bloc.dart';
import '/blocs/reservation/reservation__event.dart';
import '/blocs/reservation/reservation__state.dart';
import '/blocs/room/room_bloc.dart';
import '/blocs/room/room_event.dart';
import '/blocs/room/room_state.dart';
import '/model/reservation_model.dart';
import '/utils/color_utils.dart';
import '/utils/string_utils.dart';
import '/widgets/add_edit_reservation_bottom_sheet.dart';
import '/widgets/add_edit_room_bottom_sheet.dart';
import '/widgets/choose_add_calendar_bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';
import '../widgets/common_method.dart';
import 'reservation_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  // final ReservationController reservationController = Get.find();
  // late Worker _reservationListener;
  bool isLoading = true;
  DateTime selectedMonth = DateTime.now();
  DateTime calenderCenterDate = DateTime.now();
  late ScrollController scrollController;
  List<DateTime> calenderDates = [];

  @override
  void initState() {
    super.initState();
    initializeScreen();
  }

  Future<void> initializeScreen() async {
    setState(() => isLoading = true);

    // Await room and reservation data before building UI
    context.read<ReservationBloc>().add(FetchReservationsEvent());
    context.read<RoomBloc>().add(FetchRooms());
    // _loadEvents();
    //r
    // _reservationListener = ever(reservationController.reservationList, (_) {
    //   if (mounted) _loadEvents();
    // });
    await Future.delayed(Duration(milliseconds: 500), () {
      setCalenderDates(isFromInit: true);
    });
    if (mounted) setState(() => isLoading = false);
  }

  @override
  void dispose() {
    // _reservationListener.dispose();
    super.dispose();
  }

  void setCalenderDates({bool isFromInit = false}) {
    final now = calenderCenterDate;
    final oldDates =
        List.generate(120, (index) => now.subtract(Duration(days: index)));
    calenderDates.addAll(oldDates.reversed);

    final newDates =
        List.generate(120, (index) => now.add(Duration(days: index + 1)));
    calenderDates.addAll(newDates);

    scrollController = ScrollController(
      initialScrollOffset: ((calenderDates.length ~/ 2) * 50) - 60,
    );
    if (isFromInit) {
      listenScrollController();
    }
    setState(() {});
  }

  bool isDataLoad = false;

  void listenScrollController() {
    scrollController.addListener(() {
      if (scrollController.offset <= 0 && !isDataLoad) {
        isDataLoad = true;
        setBeforeDates(isFromListen: true);
      } else if (scrollController.offset >=
              scrollController.position.maxScrollExtent &&
          !isDataLoad) {
        isDataLoad = true;
        setAfterDates(isFromListen: true);
      }

      // 🔹 Update month dynamically while scrolling
      double offset = scrollController.offset;
      int currentIndex =
          (offset / 50).round().clamp(0, calenderDates.length - 1);
      final currentDate = calenderDates[currentIndex];

      if (DateFormat("MM-yyyy").format(selectedMonth) !=
          DateFormat("MM-yyyy").format(currentDate)) {
        setState(() => selectedMonth = currentDate);
      }
    });
  }

  void setBeforeDates({bool isFromListen = false}) {
    final startDate = calenderDates.first.subtract(Duration(days: 1));
    final oldDates = List.generate(isFromListen ? 90 : 10,
        (index) => startDate.subtract(Duration(days: index)));

    calenderDates.insertAll(0, oldDates.reversed);

    setState(() {});
    if (isFromListen) {
      scrollController.jumpTo((90 * 50) - 60);
      Future.delayed((Duration(seconds: 2)), () {
        isDataLoad = false;
      });
    } else {
      scrollController.jumpTo(scrollController.offset + ((10 * 50)));
    }
  }

  void setAfterDates({bool isFromListen = false}) {
    final startDate = calenderDates.last.add(Duration(days: 1));
    final oldDates = List.generate(isFromListen ? 90 : 10,
        (index) => startDate.add(Duration(days: index)));

    calenderDates.addAll(oldDates);
    setState(() {});
    if (isFromListen) {
      Future.delayed((Duration(seconds: 2)), () {
        isDataLoad = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Calendar"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => chooseAddCalendarBottomSheet(context),
        child: Icon(Icons.add),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : buildCalendarBody(),
    );
  }

  void scrollToToday() {
    final todayIndex = calenderDates.indexWhere((date) =>
        DateFormat("dd-MM-yyyy").format(date) ==
        DateFormat("dd-MM-yyyy").format(DateTime.now()));

    if (todayIndex != -1) {
      final scrollOffset = todayIndex * 50.0; // width of each day column
      scrollController.animateTo(
        scrollOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      calenderDates.clear();
      calenderCenterDate = DateTime.now();
      setCalenderDates();
    }
  }

  Widget buildCalendarBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 10),
          BlocBuilder<ReservationBloc, ReservationState>(
            builder: (context, state) {
              if (state is ReservationLoading) {
                return Center(child: CircularProgressIndicator());
              } else if (state is ReservationError) {
                return Center(child: Text('Error: ${state.message}'));
              } else if (state is ReservationLoaded) {
                List<ReservationModel> reservationList = [];
                state.reservations.forEach(
                  (e1) {
                    Map<String, dynamic> map = e1.toMap();
                    e1.rooms.forEach(
                      (e2) {
                        map['roomId'] = e2.id;
                        map['roomName'] = e2.roomName;
                        reservationList.add(ReservationModel.fromMap(map));
                      },
                    );
                  },
                );

                return SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sidebar with Month + Room Names
                      SizedBox(
                        width: 130,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: onDateTap,
                              child: SizedBox(
                                height: 62,
                                child: Column(
                                  children: [
                                    Text("${selectedMonth.year}",
                                        style: TextStyle(fontSize: 18)),
                                    Text(
                                        DateFormat('MMM').format(selectedMonth),
                                        style: TextStyle(fontSize: 18)),
                                  ],
                                ),
                              ),
                            ),
                            BlocBuilder<RoomBloc, RoomState>(
                              builder: (context, state) {
                                if (state is RoomLoading) {
                                  return Center(
                                      child: CircularProgressIndicator());
                                } else if (state is RoomLoaded) {
                                  return Column(
                                    children: state.rooms.map((e) {
                                      return GestureDetector(
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            builder: (context) => SafeArea(
                                              child: Container(
                                                padding: EdgeInsets.all(16),
                                                decoration: BoxDecoration(
                                                  color: ColorUtils.white,
                                                  borderRadius:
                                                      BorderRadius.vertical(
                                                    top: Radius.circular(16),
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(StringUtils.rooms),
                                                    ListTile(
                                                      title: Text(
                                                        e.roomName,
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      ),
                                                      subtitle:
                                                          Text(e.roomDesc),
                                                      trailing: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          IconButton(
                                                            icon: Icon(
                                                                Icons.edit,
                                                                color:
                                                                    ColorUtils
                                                                        .blue),
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                              addEditRoomBottomSheet(
                                                                  context,
                                                                  room: e);
                                                            },
                                                          ),
                                                          IconButton(
                                                            icon: Icon(
                                                                Icons.delete,
                                                                color:
                                                                    ColorUtils
                                                                        .red),
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                              context
                                                                  .read<
                                                                      RoomBloc>()
                                                                  .add(DeleteRoom(
                                                                      e.id!));
                                                            },
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          height: 50,
                                          margin:
                                              EdgeInsets.fromLTRB(2, 0, 2, 2),
                                          decoration: BoxDecoration(
                                            color: ColorUtils.green,
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: Center(
                                            child: Text(
                                              e.roomName,
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  color: ColorUtils.white),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                } else if (state is RoomError) {
                                  return Center(child: Text(state.message));
                                } else {
                                  return Center(
                                      child: Text('No Rooms Available'));
                                }
                              },
                            )
                          ],
                        ),
                      ),

                      // Calendar Grid
                      BlocBuilder<RoomBloc, RoomState>(
                        builder: (context, state) {
                          if (state is RoomLoaded) {
                            final roomList = state.rooms;

                            return Expanded(
                              child: SizedBox(
                                height: (roomList.length + 1) * 52,
                                width: MediaQuery.of(context).size.width,
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  controller: scrollController,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      // ───────── GRID ─────────
                                      Row(
                                        children: List.generate(
                                            calenderDates.length, (index) {
                                          final date = calenderDates[index];
                                          final isCurrentDate =
                                              DateFormat("dd-MM-yyyy")
                                                      .format(date) ==
                                                  DateFormat("dd-MM-yyyy")
                                                      .format(DateTime.now());

                                          return SizedBox(
                                            width: 50,
                                            child: Column(
                                              children: [
                                                // Date Header
                                                SizedBox(
                                                  height: 48.5,
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text("${date.day}",
                                                          style:
                                                              const TextStyle(
                                                                  fontSize:
                                                                      13)),
                                                      Text(
                                                        DateFormat("EEE")
                                                            .format(date)
                                                            .substring(0, 2),
                                                        style: const TextStyle(
                                                            fontSize: 11),
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                // Room grid cells
                                                Expanded(
                                                  child: Stack(
                                                    children: [
                                                      Column(
                                                        children: roomList
                                                            .map((room) {
                                                          return Container(
                                                            height: 51.5,
                                                            width: 50,
                                                            decoration:
                                                                BoxDecoration(
                                                              border:
                                                                  Border.all(
                                                                color: ColorUtils
                                                                    .grey
                                                                    .withOpacity(
                                                                        0.3),
                                                                width: 0.4,
                                                              ),
                                                            ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                      if (isCurrentDate)
                                                        Positioned.fill(
                                                          child: Column(
                                                            children: [
                                                              Align(
                                                                alignment:
                                                                    Alignment
                                                                        .topCenter,
                                                                child: Padding(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              5),
                                                                  child:
                                                                      CircleAvatar(
                                                                    radius: 5,
                                                                    backgroundColor:
                                                                        ColorUtils
                                                                            .blue,
                                                                  ),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child:
                                                                    VerticalDivider(
                                                                  color:
                                                                      ColorUtils
                                                                          .blue,
                                                                  width: 2,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ),

                                      // ───────── RESERVATION BARS ─────────
                                      ...reservationList
                                          .where((r) => r.roomId != 0)
                                          .map((reservation) {
                                        final inDays =
                                            DateTime.parse(reservation.checkout)
                                                .difference(DateTime.parse(
                                                    reservation.checkin))
                                                .inDays;

                                        final containIndex =
                                            calenderDates.indexWhere((date) =>
                                                DateFormat("yyyy-MM-dd")
                                                    .format(date) ==
                                                reservation.checkin);

                                        if (containIndex == -1)
                                          return const SizedBox();

                                        final roomIdIndex = roomList.indexWhere(
                                            (room) =>
                                                room.id == reservation.roomId);
                                        if (roomIdIndex == -1)
                                          return const SizedBox();

                                        return Positioned(
                                          top: ((roomIdIndex + 1) * 51.5) + 3,
                                          left: (containIndex * 50),
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ReservationDetailScreen(
                                                    reservation: reservation,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: Container(
                                              height: 45,
                                              width: ((inDays + 1) * 50),
                                              decoration: BoxDecoration(
                                                color: CommonMethod()
                                                    .reservationColor(
                                                        reservation),
                                                borderRadius:
                                                    BorderRadius.circular(50),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withOpacity(0.15),
                                                    blurRadius: 2,
                                                    offset: const Offset(1, 1),
                                                  ),
                                                ],
                                              ),
                                              alignment: Alignment.center,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6),
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  reservation.fullname,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    color:
                                                        reservation.balance == 0
                                                            ? ColorUtils.black
                                                            : ColorUtils.white,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else if (state is RoomLoading) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (state is RoomError) {
                            return Center(child: Text(state.message));
                          } else {
                            return const SizedBox();
                          }
                        },
                      )
                    ],
                  ),
                );
              } else {
                return Center(child: Text('No Reservations Found'));
              }
            },
          ),
        ],
      ),
    );
  }

  DateTime chosenDateTime = DateTime.now();

  void onDateTap() {
    iosDatePicker(context);

    // if (Platform.isIOS) {
    //   iosDatePicker(context);
    // } else {
    //   androidDatePicker(context);
    // }
  }

  androidDatePicker(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) {
      chosenDateTime = date;
    }
  }

  iosDatePicker(BuildContext context) {
    showCupertinoModalPopup(
        context: context,
        builder: (BuildContext builder) {
          return Container(
            height: MediaQuery.of(context).copyWith().size.height * 0.35,
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.monthYear,
                    onDateTimeChanged: (value) {
                      chosenDateTime = value;
                    },
                    initialDateTime: DateTime.now(),
                    minimumYear: DateTime.now().year - 50,
                    maximumYear: DateTime.now().year + 50,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text("CANCEL")),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            selectedMonth = chosenDateTime;
                            calenderCenterDate = chosenDateTime;
                            calenderDates.clear();
                            setCalenderDates();
                          },
                          child: Text("OK")),
                    ],
                  ),
                ),
                SizedBox(
                  height: 30,
                )
              ],
            ),
          );
        });
  }
}
