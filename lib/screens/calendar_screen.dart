// ignore_for_file: library_private_types_in_public_api, avoid_function_literals_in_foreach_calls, curly_braces_in_flow_control_structures, deprecated_member_use, unnecessary_to_list_in_spreads
import '/blocs/reservation/reservation__bloc.dart';
import '/blocs/reservation/reservation__event.dart';
import '/blocs/reservation/reservation__state.dart';
import '/blocs/room/room_bloc.dart';
import '/blocs/room/room_event.dart';
import '/blocs/room/room_state.dart';
import '/model/reservation_model.dart';
import '/utils/color_utils.dart';
import '/utils/string_utils.dart';
import '/widgets/add_edit_room_bottom_sheet.dart';
import '/widgets/choose_add_calendar_bottom_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/common_method.dart';
import 'reservation_detail_screen.dart';

class CalendarScreen extends StatefulWidget {
  final bool fromLogin;
  const CalendarScreen({super.key, this.fromLogin = false});

  @override
  CalendarScreenState createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  bool isLoading = true;
  DateTime selectedMonth = DateTime.now();
  DateTime calenderCenterDate = DateTime.now();
  late ScrollController scrollController;
  List<DateTime> calenderDates = [];
  static bool _dataFetched = false;
  static String? _currentUserId;
  bool _shouldShowLoader = false;

  @override
  void initState() {
    super.initState();
    checkUserAndInitialize();
  }

  Future<void> checkUserAndInitialize() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');
    
    if (_currentUserId != currentUserId || !_dataFetched) {
      _currentUserId = currentUserId;
      _dataFetched = false;
      _shouldShowLoader = widget.fromLogin;
      initializeScreen();
    } else {
      _shouldShowLoader = false;
      setState(() => isLoading = false);
      setCalenderDates(isFromInit: true);
    }
  }

  Future<void> initializeScreen() async {
    if (_shouldShowLoader) {
      setState(() => isLoading = true);
    }
    
    context.read<ReservationBloc>().add(FetchReservationsEvent());
    context.read<RoomBloc>().add(FetchRooms());
    _dataFetched = true;
    
    await Future.delayed(Duration(milliseconds: 300), () {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            SizedBox(height: 10),
            Expanded(
              child: BlocBuilder<ReservationBloc, ReservationState>(
                builder: (context, state) {
                  if (state is ReservationLoading && _shouldShowLoader) {
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
                              children: [
                                GestureDetector(
                                  onTap: onDateTap,
                                  child: Builder(
                                    builder: (context) {
                                      final media = MediaQuery.of(context);
                                      final deviceHeight = media.size.height;
                                      final textScale = media.textScaleFactor;

                                      // 🔹 Conditions
                                      bool isSmallDevice =
                                          deviceHeight < 700; // compact devices
                                      bool isLargeFont = textScale > 1.1;

                                      // 🔹 Adaptive font size logic
                                      double fontSize;
                                      if (isLargeFont && !isSmallDevice) {
                                        fontSize =
                                            18; // large font on normal device
                                      } else if (isLargeFont && isSmallDevice) {
                                        fontSize =
                                            11.5; // large font on small device
                                      } else {
                                        fontSize = 18; // normal/small font
                                      }
                                      return Container(
                                        height: isSmallDevice || isLargeFont
                                            ? 60
                                            : 70,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "${selectedMonth.year}",
                                                style: TextStyle(fontSize: 18),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                DateFormat('MMM')
                                                    .format(selectedMonth),
                                                style: TextStyle(fontSize: 16),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: BlocBuilder<RoomBloc, RoomState>(
                                    builder: (context, state) {
                                      if (state is RoomLoading && _shouldShowLoader) {
                                        return Center(
                                            child: CircularProgressIndicator());
                                      } else if (state is RoomLoaded) {
                                        return ListView(
                                          children: state.rooms.map((e) {
                                            return GestureDetector(
                                              onTap: () {
                                                showModalBottomSheet(
                                                  context: context,
                                                  builder: (context) =>
                                                      SafeArea(
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.all(16),
                                                      decoration: BoxDecoration(
                                                        color: ColorUtils.white,
                                                        borderRadius:
                                                            BorderRadius
                                                                .vertical(
                                                          top: Radius.circular(
                                                              16),
                                                        ),
                                                      ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(StringUtils
                                                              .rooms),
                                                          ListTile(
                                                            title: Text(
                                                              e.roomName,
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                            subtitle: Text(
                                                                e.roomDesc),
                                                            trailing: Row(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                IconButton(
                                                                  icon: Icon(
                                                                      Icons
                                                                          .edit,
                                                                      color: ColorUtils
                                                                          .blue),
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.pop(
                                                                        context);
                                                                    addEditRoomBottomSheet(
                                                                        context,
                                                                        room:
                                                                            e);
                                                                  },
                                                                ),
                                                                IconButton(
                                                                  icon: Icon(
                                                                      Icons
                                                                          .delete,
                                                                      color: ColorUtils
                                                                          .red),
                                                                  onPressed:
                                                                      () {
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
                                                margin: EdgeInsets.fromLTRB(
                                                    2, 0, 2, 2),
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
                                                        color:
                                                            ColorUtils.white),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      } else if (state is RoomError) {
                                        return Center(
                                            child: Text(state.message));
                                      } else {
                                        return Center(
                                            child: Text('No Rooms Available'));
                                      }
                                    },
                                  ),
                                )
                              ],
                            ),
                          ),

                          // Calendar Grid
                          BlocBuilder<RoomBloc, RoomState>(
                            builder: (context, state) {
                              if (state is RoomLoaded) {
                                final media = MediaQuery.of(context);
                                final deviceHeight = media.size.height;
                                final textScale = media.textScaleFactor;

                                // 🔹 Conditions
                                bool isSmallDevice =
                                    deviceHeight < 700; // compact devices
                                bool isLargeFont = textScale > 1.1;

                                // 🔹 Adaptive font size logic
                                double fontSize;
                                if (isLargeFont && !isSmallDevice) {
                                  fontSize = 18; // large font on normal device
                                } else if (isLargeFont && isSmallDevice) {
                                  fontSize = 11.5; // large font on small device
                                } else {
                                  fontSize = 18; // normal/small font
                                }
                                final roomList = state.rooms;

                                return Expanded(
                                  child: SizedBox(
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
                                              final textScale =
                                                  MediaQuery.of(context)
                                                      .textScaleFactor;
                                              final date = calenderDates[index];
                                              final isCurrentDate = DateFormat(
                                                          "dd-MM-yyyy")
                                                      .format(date) ==
                                                  DateFormat("dd-MM-yyyy")
                                                      .format(DateTime.now());

                                              return Container(
                                                width: 50,
                                                child: Column(
                                                  children: [
                                                    // Date Header
                                                    Container(
                                                      height: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .height <
                                                                  700 ||
                                                              MediaQuery.of(
                                                                          context)
                                                                      .textScaleFactor >
                                                                  1.1
                                                          ? 60
                                                          : 60,
                                                      child: FittedBox(
                                                        fit: BoxFit.scaleDown,
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text("${date.day}",
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16)),
                                                            Text(
                                                              DateFormat("EEE")
                                                                  .format(date)
                                                                  .substring(
                                                                      0, 2),
                                                              style: TextStyle(
                                                                  fontSize: 14),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),

                                                    // Room grid cells
                                                    Flexible(
                                                      child: Stack(
                                                        children: [
                                                          Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: roomList
                                                                .map((room) {
                                                              return Container(
                                                                height: 50,
                                                                width: 50,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  border: Border
                                                                      .all(
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
                                                                    child:
                                                                        Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          top:
                                                                              5),
                                                                      child:
                                                                          CircleAvatar(
                                                                        radius:
                                                                            5,
                                                                        backgroundColor:
                                                                            ColorUtils.blue,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        VerticalDivider(
                                                                      color: ColorUtils
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
                                            final media =
                                                MediaQuery.of(context);
                                            final deviceHeight =
                                                media.size.height;
                                            final textScale =
                                                media.textScaleFactor;

                                            // 🔹 Conditions
                                            bool isSmallDevice = deviceHeight <
                                                700; // e.g. compact screens
                                            bool isLargeFont = textScale >
                                                1.1; // accessibility text scaling

                                            // 🔹 Adaptive top logic
                                            double baseTop =
                                                isSmallDevice && isLargeFont
                                                    ? 65.5
                                                    : 48.5;
                                            final inDays = DateTime.parse(
                                                    reservation.checkout)
                                                .difference(DateTime.parse(
                                                    reservation.checkin))
                                                .inDays;

                                            final containIndex = calenderDates
                                                .indexWhere((date) =>
                                                    DateFormat("yyyy-MM-dd")
                                                        .format(date) ==
                                                    reservation.checkin);

                                            if (containIndex == -1)
                                              return const SizedBox();

                                            final roomIdIndex =
                                                roomList.indexWhere((room) =>
                                                    room.id ==
                                                    reservation.roomId);
                                            if (roomIdIndex == -1)
                                              return const SizedBox();

                                            return Positioned(
                                              top: ((roomIdIndex + 1) *
                                                      baseTop) +
                                                  (MediaQuery.of(context)
                                                                  .size
                                                                  .height <
                                                              700 ||
                                                          MediaQuery.of(context)
                                                                  .textScaleFactor >
                                                              1.1
                                                      ? 12
                                                      : 12),
                                              left: (containIndex * 50),
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ReservationDetailScreen(
                                                        reservation:
                                                            reservation,
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
                                                        BorderRadius.circular(
                                                            50),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.15),
                                                        blurRadius: 2,
                                                        offset:
                                                            const Offset(1, 1),
                                                      ),
                                                    ],
                                                  ),
                                                  alignment: Alignment.center,
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 6),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      reservation.fullname,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: reservation
                                                                    .balance ==
                                                                0
                                                            ? ColorUtils.black
                                                            : ColorUtils.white,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                              } else if (state is RoomLoading && _shouldShowLoader) {
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
            )
          ],
        );
      },
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
