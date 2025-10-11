/*
// ignore_for_file: library_private_types_in_public_api, avoid_function_literals_in_foreach_calls, curly_braces_in_flow_control_structures, deprecated_member_use, unnecessary_to_list_in_spreads, unused_local_variable
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
                                      return SizedBox(
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
                                      if (state is RoomLoading &&
                                          _shouldShowLoader) {
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
                                                  //color: ColorUtils.green,
                                                  //color: Theme.of(context).colorScheme.secondary(),
                                                  color: Color(0xFF967969),
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

                                              return SizedBox(
                                                width: 50,
                                                child: Column(
                                                  children: [
                                                    // Date Header
                                                    SizedBox(
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
                                                              print(
                                                                  'Device Height: ${MediaQuery.of(context).size.height}');

                                                              return Padding(
                                                                padding: EdgeInsets.only(
                                                                    top: MediaQuery.of(context).size.height > 900
                                                                        ? 3.0
                                                                        : MediaQuery.of(context).size.height > 800
                                                                            ? 8.0
                                                                            : MediaQuery.of(context).size.height < 700
                                                                                ? 0.0
                                                                                : MediaQuery.of(context).size.height < 600
                                                                                    ? 0.0
                                                                                    : 0),
                                                                child:
                                                                    Container(
                                                                  height: 50,
                                                                  width: 50,
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: ColorUtils
                                                                          .grey
                                                                          .withOpacity(
                                                                              0.3),
                                                                      width:
                                                                          0.4,
                                                                    ),
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

                                            // 🔹 Adaptive top logic - match room height
                                            double baseTop =
                                                50.0; // Match room container height
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

                                            // Calculate dynamic heights to match room positioning
                                            final isSmallOrLargeFont =
                                                MediaQuery.of(context)
                                                            .size
                                                            .height <
                                                        700 ||
                                                    MediaQuery.of(context)
                                                            .textScaleFactor >
                                                        1.1;
                                            final headerHeight =
                                                isSmallOrLargeFont
                                                    ? 60.0
                                                    : 70.0;
                                            final roomSpacing =
                                                52.0; // Room height + margin

                                            // Calculate positioning based on device conditions
                                            final reservationHeaderHeight =
                                                isSmallDevice || isLargeFont
                                                    ? 60.0
                                                    : 70.0;

                                            return Positioned(
                                              top: reservationHeaderHeight +
                                                  (roomIdIndex *
                                                      50.0), // Dynamic positioning
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
                                                  height: 48,
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
                              } else if (state is RoomLoading &&
                                  _shouldShowLoader) {
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


*/

///Scroll working
/*import '/blocs/reservation/reservation__bloc.dart';
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
  // ─── Data / state ────────────────────────────────────────────────────────────
  bool isLoading = true;
  DateTime selectedMonth = DateTime.now();
  DateTime calenderCenterDate = DateTime.now();
  List<DateTime> calenderDates = [];
  static bool _dataFetched = false;
  static String? _currentUserId;
  bool _shouldShowLoader = false;

  // ─── Layout constants (single source of truth) ───────────────────────────────
  static const double kRoomListWidth = 130.0;
  static const double kCellWidth = 60.0;
  static const double kRowHeight = 56.0; // room row (left + grid)
  static const double kDateHeaderHeight = 70.0;

  // ─── Scroll controllers (linked without packages) ────────────────────────────
  late final ScrollController _hHeader; // horizontal header (dates row)
  late final ScrollController _hBody; // horizontal grid (cells + bookings)
  late final ScrollController _vLeft; // vertical rooms (left)
  late final ScrollController _vRight; // vertical grid (right)

  bool _syncingH = false;
  bool _syncingV = false;

  @override
  void initState() {
    super.initState();
    _hHeader = ScrollController();
    _hBody = ScrollController();
    _vLeft = ScrollController();
    _vRight = ScrollController();

    // link horizontal
    _hHeader.addListener(_onHHeaderScroll);
    _hBody.addListener(_onHBodyScroll);

    // link vertical
    _vLeft.addListener(_onVLeftScroll);
    _vRight.addListener(_onVRightScroll);

    checkUserAndInitialize();
  }

  @override
  void dispose() {
    _hHeader.removeListener(_onHHeaderScroll);
    _hBody.removeListener(_onHBodyScroll);
    _vLeft.removeListener(_onVLeftScroll);
    _vRight.removeListener(_onVRightScroll);

    _hHeader.dispose();
    _hBody.dispose();
    _vLeft.dispose();
    _vRight.dispose();
    super.dispose();
  }

  // ─── Scroll sync handlers ────────────────────────────────────────────────────
  void _onHHeaderScroll() {
    if (_syncingH) return;
    _syncingH = true;
    if (_hBody.hasClients) {
      _hBody.jumpTo(_hHeader.offset);
    }
    _updateSelectedMonthFromOffset(_hHeader.offset);
    _syncingH = false;
  }

  void _onHBodyScroll() {
    if (_syncingH) return;
    _syncingH = true;
    if (_hHeader.hasClients) {
      _hHeader.jumpTo(_hBody.offset);
    }
    _updateSelectedMonthFromOffset(_hBody.offset);
    _syncingH = false;
  }

  void _onVLeftScroll() {
    if (_syncingV) return;
    _syncingV = true;
    if (_vRight.hasClients) {
      _vRight.jumpTo(_vLeft.offset);
    }
    _syncingV = false;
  }

  void _onVRightScroll() {
    if (_syncingV) return;
    _syncingV = true;
    if (_vLeft.hasClients) {
      _vLeft.jumpTo(_vRight.offset);
    }
    _syncingV = false;
  }

  void _updateSelectedMonthFromOffset(double offset) {
    if (calenderDates.isEmpty) return;
    final idx =
        (offset / kCellWidth).round().clamp(0, calenderDates.length - 1);
    final d = calenderDates[idx];
    if (DateFormat("MM-yyyy").format(selectedMonth) !=
        DateFormat("MM-yyyy").format(d)) {
      setState(() => selectedMonth = d);
    }
  }

  // ─── Init & data fetch ───────────────────────────────────────────────────────
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
      _buildDateRange();
    }
  }

  Future<void> initializeScreen() async {
    if (_shouldShowLoader) setState(() => isLoading = true);
    context.read<ReservationBloc>().add(FetchReservationsEvent());
    context.read<RoomBloc>().add(FetchRooms());
    _dataFetched = true;
    await Future.delayed(const Duration(milliseconds: 200));
    _buildDateRange();
    if (mounted) setState(() => isLoading = false);
  }

  void _buildDateRange() {
    final now = calenderCenterDate;
    calenderDates.clear();
    final before = List.generate(120, (i) => now.subtract(Duration(days: i)));
    calenderDates.addAll(before.reversed);
    final after = List.generate(120, (i) => now.add(Duration(days: i + 1)));
    calenderDates.addAll(after);
    // center both horizontal controllers
    final initial = ((calenderDates.length ~/ 2) * kCellWidth) - kCellWidth;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hHeader.hasClients) _hHeader.jumpTo(initial);
      if (_hBody.hasClients) _hBody.jumpTo(initial);
      _updateSelectedMonthFromOffset(initial);
    });
  }

  // ─── UI ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calendar")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => chooseAddCalendarBottomSheet(context),
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCalendar(),
    );
  }

  Widget _buildCalendar() {
    return BlocBuilder<ReservationBloc, ReservationState>(
      builder: (context, rState) {
        if (rState is ReservationError) {
          return Center(child: Text('Error: ${rState.message}'));
        }
        if (rState is! ReservationLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        // flatten reservations per room
        final List<ReservationModel> reservations = [];
        for (final e1 in rState.reservations) {
          final map = e1.toMap();
          for (final e2 in e1.rooms) {
            map['roomId'] = e2.id;
            map['roomName'] = e2.roomName;
            reservations.add(ReservationModel.fromMap(map));
          }
        }

        return BlocBuilder<RoomBloc, RoomState>(
          builder: (context, roomState) {
            if (roomState is RoomError) {
              return Center(child: Text(roomState.message));
            }
            if (roomState is! RoomLoaded) {
              return const Center(child: CircularProgressIndicator());
            }
            final rooms = roomState.rooms;

            final totalWidth = calenderDates.length * kCellWidth;
            final totalHeight = rooms.length * kRowHeight;

            // today index for blue vertical line
            final todayIndex = calenderDates.indexWhere((d) =>
                DateFormat("yyyy-MM-dd").format(d) ==
                DateFormat("yyyy-MM-dd").format(DateTime.now()));

            return Column(
              children: [
                // ─────────── INLINE MONTH + DATE HEADER (H-scrolling) ───────────
                SizedBox(
                  height: kDateHeaderHeight,
                  child: Row(
                    children: [
                      Container(
                        width: kRoomListWidth,
                        alignment: Alignment.center,
                        color: Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("${selectedMonth.year}",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                            Text(DateFormat('MMM').format(selectedMonth),
                                style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _hHeader,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: totalWidth,
                            height: kDateHeaderHeight,
                            child: Row(
                              children:
                                  List.generate(calenderDates.length, (i) {
                                final date = calenderDates[i];
                                return Container(
                                  width: kCellWidth,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.grey.withOpacity(0.3),
                                        width: 0.6,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text("${date.day}",
                                          style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                        DateFormat("EEE")
                                            .format(date)
                                            .substring(0, 2),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─────────── BODY: V + H synced scrolls ───────────
                Expanded(
                  child: Row(
                    children: [
                      // Left rooms (vertical scroll)
                      SizedBox(
                        width: kRoomListWidth,
                        child: SingleChildScrollView(
                          controller: _vLeft,
                          child: Column(
                            children: List.generate(rooms.length, (i) {
                              final room = rooms[i];
                              return Container(
                                height: kRowHeight,
                                margin: const EdgeInsets.symmetric(vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF967969),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  room.roomName,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),

                      // Right grid (both directions)
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _vRight,
                          child: SingleChildScrollView(
                            controller: _hBody,
                            scrollDirection: Axis.horizontal,
                            child: Stack(
                              children: [
                                // grid background (cells)
                                SizedBox(
                                  width: totalWidth,
                                  height: totalHeight,
                                  child: Row(
                                    children: List.generate(
                                        calenderDates.length, (x) {
                                      return Column(
                                        children:
                                            List.generate(rooms.length, (y) {
                                          return Container(
                                            width: kCellWidth,
                                            height: kRowHeight,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey
                                                    .withOpacity(0.3),
                                                width: 0.4,
                                              ),
                                            ),
                                          );
                                        }),
                                      );
                                    }),
                                  ),
                                ),

                                // today guideline (blue dot + vertical line)
                                if (todayIndex != -1)
                                  Positioned(
                                    left: todayIndex * kCellWidth +
                                        kCellWidth / 2 -
                                        1,
                                    top: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 2,
                                      color: ColorUtils.blue.withOpacity(0.8),
                                    ),
                                  ),

                                // bookings bars
                                ...reservations.where((r) => r.roomId != 0).map(
                                  (r) {
                                    final startIndex = calenderDates.indexWhere(
                                        (d) =>
                                            DateFormat("yyyy-MM-dd")
                                                .format(d) ==
                                            r.checkin);
                                    if (startIndex == -1) {
                                      return const SizedBox.shrink();
                                    }
                                    final inDays = DateTime.parse(r.checkout)
                                        .difference(DateTime.parse(r.checkin))
                                        .inDays;
                                    final roomIndex = rooms
                                        .indexWhere((rm) => rm.id == r.roomId);
                                    if (roomIndex == -1) {
                                      return const SizedBox.shrink();
                                    }

                                    return Positioned(
                                      left: startIndex * kCellWidth,
                                      top: (roomIndex * kRowHeight) + 4,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  ReservationDetailScreen(
                                                      reservation: r),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          height: kRowHeight - 8,
                                          width: (inDays + 1) * kCellWidth,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: CommonMethod()
                                                .reservationColor(r),
                                            borderRadius:
                                                BorderRadius.circular(40),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.15),
                                                blurRadius: 2,
                                                offset: const Offset(1, 1),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              r.fullname,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: r.balance == 0
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
                                  },
                                ).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}*/

///
/*import '/blocs/reservation/reservation__bloc.dart';
import '/blocs/reservation/reservation__event.dart';
import '/blocs/reservation/reservation__state.dart';
import '/blocs/room/room_bloc.dart';
import '/blocs/room/room_event.dart';
import '/blocs/room/room_state.dart';
import '/model/reservation_model.dart';
import '/utils/color_utils.dart';
import '/widgets/choose_add_calendar_bottom_sheet.dart';
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
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  // ── Layout constants ────────────────────────────────────────────────────────
  static const double kRoomListWidth = 130.0;
  static const double kCellWidth = 60.0;

  // Visible content height of a row (where booking sits)
  static const double kRowHeight = 48.0;

  // Space between rows
  static const double kRowGap = 8.0;

  // Total step per row = content + gap
  static const double kRowPitch = kRowHeight + kRowGap;

  static const double kDateHeaderH = 70.0;

  // Scrollers (linked)
  late final ScrollController _hHeader; // dates row
  late final ScrollController _hBody; // grid + bookings
  late final ScrollController _vLeft; // room names
  late final ScrollController _vRight; // grid + bookings

  bool _syncH = false, _syncV = false;

  // Data state
  bool isLoading = true;
  DateTime selectedMonth = DateTime.now();
  DateTime calenderCenterDate = DateTime.now();
  List<DateTime> calenderDates = [];

  static bool _dataFetched = false;
  static String? _currentUserId;
  bool _shouldShowLoader = false;

  @override
  void initState() {
    super.initState();
    _hHeader = ScrollController()..addListener(_onHHeader);
    _hBody = ScrollController()..addListener(_onHBody);
    _vLeft = ScrollController()..addListener(_onVLeft);
    _vRight = ScrollController()..addListener(_onVRight);
    _checkUserAndInit();
  }

  @override
  void dispose() {
    _hHeader.removeListener(_onHHeader);
    _hBody.removeListener(_onHBody);
    _vLeft.removeListener(_onVLeft);
    _vRight.removeListener(_onVRight);
    _hHeader.dispose();
    _hBody.dispose();
    _vLeft.dispose();
    _vRight.dispose();
    super.dispose();
  }

  // ── Scroll sync handlers ────────────────────────────────────────────────────
  void _onHHeader() {
    if (_syncH) return;
    _syncH = true;
    if (_hBody.hasClients) _hBody.jumpTo(_hHeader.offset);
    _updateSelectedMonth(_hHeader.offset);
    _syncH = false;
  }

  void _onHBody() {
    if (_syncH) return;
    _syncH = true;
    if (_hHeader.hasClients) _hHeader.jumpTo(_hBody.offset);
    _updateSelectedMonth(_hBody.offset);
    _syncH = false;
  }

  void _onVLeft() {
    if (_syncV) return;
    _syncV = true;
    if (_vRight.hasClients) _vRight.jumpTo(_vLeft.offset);
    _syncV = false;
  }

  void _onVRight() {
    if (_syncV) return;
    _syncV = true;
    if (_vLeft.hasClients) _vLeft.jumpTo(_vRight.offset);
    _syncV = false;
  }

  void _updateSelectedMonth(double offset) {
    if (calenderDates.isEmpty) return;
    final idx =
        (offset / kCellWidth).round().clamp(0, calenderDates.length - 1);
    final d = calenderDates[idx];
    if (DateFormat("MM-yyyy").format(selectedMonth) !=
        DateFormat("MM-yyyy").format(d)) {
      setState(() => selectedMonth = d);
    }
  }

  // ── Init & data ─────────────────────────────────────────────────────────────
  Future<void> _checkUserAndInit() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');

    if (_currentUserId != currentUserId || !_dataFetched) {
      _currentUserId = currentUserId;
      _dataFetched = false;
      _shouldShowLoader = widget.fromLogin;
      await _initialize();
    } else {
      _shouldShowLoader = false;
      setState(() => isLoading = false);
      _buildDates();
    }
  }

  Future<void> _initialize() async {
    if (_shouldShowLoader) setState(() => isLoading = true);
    context.read<ReservationBloc>().add(FetchReservationsEvent());
    context.read<RoomBloc>().add(FetchRooms());
    _dataFetched = true;
    await Future.delayed(const Duration(milliseconds: 200));
    _buildDates();
    if (mounted) setState(() => isLoading = false);
  }

  void _buildDates() {
    final now = calenderCenterDate;
    calenderDates
      ..clear()
      ..addAll(
          List.generate(120, (i) => now.subtract(Duration(days: i))).reversed)
      ..addAll(List.generate(120, (i) => now.add(Duration(days: i + 1))));
    // Center horizontal
    final initial = ((calenderDates.length ~/ 2) * kCellWidth) - kCellWidth;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hHeader.hasClients) _hHeader.jumpTo(initial);
      if (_hBody.hasClients) _hBody.jumpTo(initial);
      _updateSelectedMonth(initial);
    });
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final extraBottomPadding =
        bottomSafe + 76; // keep last row above bottom bar/FAB

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => chooseAddCalendarBottomSheet(context),
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : BlocBuilder<ReservationBloc, ReservationState>(
              builder: (context, rState) {
                if (rState is ReservationError) {
                  return Center(child: Text('Error: ${rState.message}'));
                }
                if (rState is! ReservationLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Flatten reservations by room
                final reservations = <ReservationModel>[];
                for (final e in rState.reservations) {
                  final map = e.toMap();
                  for (final rm in e.rooms) {
                    map['roomId'] = rm.id;
                    map['roomName'] = rm.roomName;
                    reservations.add(ReservationModel.fromMap(map));
                  }
                }

                return BlocBuilder<RoomBloc, RoomState>(
                  builder: (context, roomState) {
                    if (roomState is RoomError) {
                      return Center(child: Text(roomState.message));
                    }
                    if (roomState is! RoomLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rooms = roomState.rooms;
                    final totalCols = calenderDates.length;
                    final totalRows = rooms.length;
                    final gridWidth = totalCols * kCellWidth;
                    final gridHeight = totalRows * kRowPitch;

                    final todayIndex = calenderDates.indexWhere((d) =>
                        DateFormat("yyyy-MM-dd").format(d) ==
                        DateFormat("yyyy-MM-dd").format(DateTime.now()));

                    return Column(
                      children: [
                        // ── Inline Month + Dates header (H-synced)
                        SizedBox(
                          height: kDateHeaderH,
                          child: Row(
                            children: [
                              Container(
                                width: kRoomListWidth,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${selectedMonth.year}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                        DateFormat('MMM').format(selectedMonth),
                                        style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: _hHeader,
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: gridWidth,
                                    height: kDateHeaderH,
                                    child: Row(
                                      children: List.generate(totalCols, (i) {
                                        final date = calenderDates[i];
                                        return Container(
                                          width: kCellWidth,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                color:
                                                    Colors.grey.withOpacity(.3),
                                                width: .6,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text('${date.day}',
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(
                                                DateFormat('EEE')
                                                    .format(date)
                                                    .substring(0, 2),
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Body (V+H synced)
                        Expanded(
                          child: Row(
                            children: [
                              // Left rooms WITH spacing exactly matching grid band
                              SizedBox(
                                width: kRoomListWidth,
                                child: ListView.builder(
                                  controller: _vLeft,
                                  itemExtent: kRowPitch, // content + gap
                                  padding: EdgeInsets.only(
                                      bottom: extraBottomPadding),
                                  itemCount: rooms.length,
                                  itemBuilder: (_, i) {
                                    final room = rooms[i];
                                    // IMPORTANT: symmetric vertical padding = kRowGap/2
                                    // so the tile's top aligns with grid 'bandTop'
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: kRowGap / 2),
                                      child: Container(
                                        height:
                                            kRowHeight, // exact content height
                                        color: const Color(
                                            0xFF967969), // square (no radius)
                                        alignment: Alignment.center,
                                        child: Text(
                                          room.roomName,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 16),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // Right grid + bookings
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: _vRight,
                                  child: SingleChildScrollView(
                                    controller: _hBody,
                                    scrollDirection: Axis.horizontal,
                                    child: Stack(
                                      children: [
                                        // Grid via painter (respects gaps)
                                        SizedBox(
                                          width: gridWidth,
                                          height:
                                              gridHeight + extraBottomPadding,
                                          child: CustomPaint(
                                            painter: _SpacedGridPainter(
                                              rows: totalRows,
                                              cols: totalCols,
                                              rowHeight: kRowHeight,
                                              rowGap: kRowGap,
                                              colWidth: kCellWidth,
                                              lineColor:
                                                  Colors.grey.withOpacity(.3),
                                              lineWidth: .6,
                                            ),
                                          ),
                                        ),

                                        // Today vertical guideline
                                        if (todayIndex != -1)
                                          Positioned(
                                            left: todayIndex * kCellWidth +
                                                (kCellWidth / 2) -
                                                1,
                                            top: 0,
                                            bottom: extraBottomPadding,
                                            child: Container(
                                              width: 2,
                                              color: ColorUtils.blue,
                                            ),
                                          ),

                                        // Bookings centered within content band (square corners)
                                        ...reservations
                                            .where((r) => r.roomId != 0)
                                            .map((r) {
                                          final start =
                                              calenderDates.indexWhere(
                                            (d) =>
                                                DateFormat('yyyy-MM-dd')
                                                    .format(d) ==
                                                r.checkin,
                                          );
                                          if (start == -1)
                                            return const SizedBox.shrink();

                                          final span =
                                              DateTime.parse(r.checkout)
                                                  .difference(
                                                      DateTime.parse(r.checkin))
                                                  .inDays;

                                          final rowIndex = rooms.indexWhere(
                                              (rm) => rm.id == r.roomId);
                                          if (rowIndex == -1)
                                            return const SizedBox.shrink();

                                          final double top =
                                              rowIndex * kRowPitch +
                                                  (kRowGap / 2);

                                          return Positioned(
                                            left: start * kCellWidth + 2,
                                            top: top,
                                            child: GestureDetector(
                                              onTap: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        ReservationDetailScreen(
                                                            reservation: r),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                height: kRowHeight,
                                                width:
                                                    (span + 1) * kCellWidth - 4,
                                                alignment: Alignment.center,
                                                color: CommonMethod()
                                                    .reservationColor(
                                                        r), // square
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6),
                                                child: FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    r.fullname,
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: r.balance == 0
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
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

/// Paints a grid with vertical gaps between rows:
/// Each row has a visible band of `rowHeight` and a gap of `rowGap`.
class _SpacedGridPainter extends CustomPainter {
  final int rows, cols;
  final double rowHeight, rowGap, colWidth;
  final double lineWidth;
  final Color lineColor;

  _SpacedGridPainter({
    required this.rows,
    required this.cols,
    required this.rowHeight,
    required this.rowGap,
    required this.colWidth,
    required this.lineColor,
    this.lineWidth = .6,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth;

    // For each row, draw a "band" from bandTop to bandBottom; leave gap empty.
    for (int r = 0; r < rows; r++) {
      final double bandTop = r * (rowHeight + rowGap) + (rowGap / 2);
      final double bandBottom = bandTop + rowHeight;

      // horizontal lines for this band
      canvas.drawLine(Offset(0, bandTop), Offset(cols * colWidth, bandTop), p);
      canvas.drawLine(
          Offset(0, bandBottom), Offset(cols * colWidth, bandBottom), p);

      // vertical separators inside the band
      for (int c = 0; c <= cols; c++) {
        final double x = c * colWidth;
        canvas.drawLine(Offset(x, bandTop), Offset(x, bandBottom), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SpacedGridPainter old) =>
      old.rows != rows ||
      old.cols != cols ||
      old.rowHeight != rowHeight ||
      old.rowGap != rowGap ||
      old.colWidth != colWidth ||
      old.lineColor != lineColor ||
      old.lineWidth != lineWidth;
}*/
import '/blocs/reservation/reservation__bloc.dart';
import '/blocs/reservation/reservation__event.dart';
import '/blocs/reservation/reservation__state.dart';
import '/blocs/room/room_bloc.dart';
import '/blocs/room/room_event.dart';
import '/blocs/room/room_state.dart';
import '/model/reservation_model.dart';
import '/utils/color_utils.dart';
import '/widgets/choose_add_calendar_bottom_sheet.dart';
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
  State<CalendarScreen> createState() => CalendarScreenState();
}

class CalendarScreenState extends State<CalendarScreen> {
  // ── Layout constants ────────────────────────────────────────────────────────
  static const double kRoomListWidth = 130.0;
  static const double kCellWidth = 60.0;

  // Visible content height of a row (where booking sits)
  static const double kRowHeight = 48.0;

  // ↓↓↓ smaller gap between rooms (tweak here if needed)
  static const double kRowGap = 2.0;

  // Total vertical step per row = content + gap
  static const double kRowPitch = kRowHeight + kRowGap;

  static const double kDateHeaderH = 70.0;

  // Grid stroke width (used by painters AND bookings to overlap perfectly)
  static const double kGridStroke = 1.0;

  // Scrollers (linked)
  late final ScrollController _hHeader; // dates row
  late final ScrollController _hBody; // grid + bookings
  late final ScrollController _vLeft; // room names
  late final ScrollController _vRight; // grid + bookings

  bool _syncH = false, _syncV = false;

  // Data state
  bool isLoading = true;
  DateTime selectedMonth = DateTime.now();
  DateTime calenderCenterDate = DateTime.now();
  List<DateTime> calenderDates = [];

  static bool _dataFetched = false;
  static String? _currentUserId;
  bool _shouldShowLoader = false;

  @override
  void initState() {
    super.initState();
    _hHeader = ScrollController()..addListener(_onHHeader);
    _hBody = ScrollController()..addListener(_onHBody);
    _vLeft = ScrollController()..addListener(_onVLeft);
    _vRight = ScrollController()..addListener(_onVRight);
    _checkUserAndInit();
  }

  @override
  void dispose() {
    _hHeader.removeListener(_onHHeader);
    _hBody.removeListener(_onHBody);
    _vLeft.removeListener(_onVLeft);
    _vRight.removeListener(_onVRight);
    _hHeader.dispose();
    _hBody.dispose();
    _vLeft.dispose();
    _vRight.dispose();
    super.dispose();
  }

  // ── Scroll sync handlers ────────────────────────────────────────────────────
  void _onHHeader() {
    if (_syncH) return;
    _syncH = true;
    if (_hBody.hasClients) _hBody.jumpTo(_hHeader.offset);
    _updateSelectedMonth(_hHeader.offset);
    _syncH = false;
  }

  void _onHBody() {
    if (_syncH) return;
    _syncH = true;
    if (_hHeader.hasClients) _hHeader.jumpTo(_hBody.offset);
    _updateSelectedMonth(_hBody.offset);
    _syncH = false;
  }

  void _onVLeft() {
    if (_syncV) return;
    _syncV = true;
    if (_vRight.hasClients) _vRight.jumpTo(_vLeft.offset);
    _syncV = false;
  }

  void _onVRight() {
    if (_syncV) return;
    _syncV = true;
    if (_vLeft.hasClients) _vLeft.jumpTo(_vRight.offset);
    _syncV = false;
  }

  void _updateSelectedMonth(double offset) {
    if (calenderDates.isEmpty) return;
    final idx =
        (offset / kCellWidth).round().clamp(0, calenderDates.length - 1);
    final d = calenderDates[idx];
    if (DateFormat("MM-yyyy").format(selectedMonth) !=
        DateFormat("MM-yyyy").format(d)) {
      setState(() => selectedMonth = d);
    }
  }

  // ── Init & data ─────────────────────────────────────────────────────────────
  Future<void> _checkUserAndInit() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('userId');

    if (_currentUserId != currentUserId || !_dataFetched) {
      _currentUserId = currentUserId;
      _dataFetched = false;
      _shouldShowLoader = widget.fromLogin;
      await _initialize();
    } else {
      _shouldShowLoader = false;
      setState(() => isLoading = false);
      _buildDates();
    }
  }

  Future<void> _initialize() async {
    if (_shouldShowLoader) setState(() => isLoading = true);
    context.read<ReservationBloc>().add(FetchReservationsEvent());
    context.read<RoomBloc>().add(FetchRooms());
    _dataFetched = true;
    await Future.delayed(const Duration(milliseconds: 200));
    _buildDates();
    if (mounted) setState(() => isLoading = false);
  }

  void _buildDates() {
    final now = calenderCenterDate;
    calenderDates
      ..clear()
      ..addAll(
          List.generate(120, (i) => now.subtract(Duration(days: i))).reversed)
      ..addAll(List.generate(120, (i) => now.add(Duration(days: i + 1))));
    // Center horizontal
    final initial = ((calenderDates.length ~/ 2) * kCellWidth) - kCellWidth;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hHeader.hasClients) _hHeader.jumpTo(initial);
      if (_hBody.hasClients) _hBody.jumpTo(initial);
      _updateSelectedMonth(initial);
    });
  }

  // ── UI ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    final extraBottomPadding =
        bottomSafe + 76; // keep last row above bottom bar/FAB

    // same half-gap on top so the first room gets spacing like others
    const double _topLead = kRowGap / 2;

    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => chooseAddCalendarBottomSheet(context),
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : BlocBuilder<ReservationBloc, ReservationState>(
              builder: (context, rState) {
                if (rState is ReservationError) {
                  return Center(child: Text('Error: ${rState.message}'));
                }
                if (rState is! ReservationLoaded) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Flatten reservations by room
                final reservations = <ReservationModel>[];
                for (final e in rState.reservations) {
                  final map = e.toMap();
                  for (final rm in e.rooms) {
                    map['roomId'] = rm.id;
                    map['roomName'] = rm.roomName;
                    reservations.add(ReservationModel.fromMap(map));
                  }
                }

                return BlocBuilder<RoomBloc, RoomState>(
                  builder: (context, roomState) {
                    if (roomState is RoomError) {
                      return Center(child: Text(roomState.message));
                    }
                    if (roomState is! RoomLoaded) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final rooms = roomState.rooms;
                    final totalCols = calenderDates.length;
                    final totalRows = rooms.length;
                    final gridWidth = totalCols * kCellWidth;
                    final gridHeight = totalRows * kRowPitch;

                    final todayIndex = calenderDates.indexWhere((d) =>
                        DateFormat("yyyy-MM-dd").format(d) ==
                        DateFormat("yyyy-MM-dd").format(DateTime.now()));

                    return Column(
                      children: [
                        // ── Inline Month + Dates header (H-synced)
                        SizedBox(
                          height: kDateHeaderH,
                          child: Row(
                            children: [
                              Container(
                                width: kRoomListWidth,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('${selectedMonth.year}',
                                        style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600)),
                                    Text(
                                        DateFormat('MMM').format(selectedMonth),
                                        style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: _hHeader,
                                  scrollDirection: Axis.horizontal,
                                  child: SizedBox(
                                    width: gridWidth,
                                    height: kDateHeaderH,
                                    child: Row(
                                      children: List.generate(totalCols, (i) {
                                        final date = calenderDates[i];
                                        return Container(
                                          width: kCellWidth,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                color:
                                                    Colors.grey.withOpacity(.3),
                                                width: .6,
                                              ),
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text('${date.day}',
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                              Text(
                                                DateFormat('EEE')
                                                    .format(date)
                                                    .substring(0, 2),
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── Body (V+H synced)
                        Expanded(
                          child: Row(
                            children: [
                              // LEFT: Rooms with right vertical grid line & band lines
                              SizedBox(
                                width: kRoomListWidth,
                                child: SingleChildScrollView(
                                  controller: _vLeft,
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.only(top: _topLead),
                                    child: Stack(
                                      children: [
                                        SizedBox(
                                          width: kRoomListWidth,
                                          height: gridHeight +
                                              extraBottomPadding +
                                              _topLead, // extend painter
                                          child: CustomPaint(
                                            painter: _LeftPanelPainter(
                                              rows: totalRows,
                                              rowHeight: kRowHeight,
                                              rowGap: kRowGap,
                                              lineColor:
                                                  Colors.grey.withOpacity(.3),
                                              lineWidth: kGridStroke,
                                            ),
                                          ),
                                        ),
                                        Column(
                                          children:
                                              List.generate(rooms.length, (i) {
                                            final room = rooms[i];
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: kRowGap / 2),
                                              child: Container(
                                                height: kRowHeight,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFF967969),
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                child: Text(
                                                  room.roomName,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16),
                                                ),
                                              ),
                                            );
                                          }),
                                        ),
                                        SizedBox(height: extraBottomPadding),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // RIGHT: Grid + bookings
                              Expanded(
                                child: SingleChildScrollView(
                                  controller: _vRight,
                                  child: SingleChildScrollView(
                                    controller: _hBody,
                                    scrollDirection: Axis.horizontal,
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(top: _topLead),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Grid via painter:
                                          SizedBox(
                                            width: gridWidth,
                                            height: gridHeight +
                                                extraBottomPadding +
                                                _topLead,
                                            child: CustomPaint(
                                              painter: _JointGridPainter(
                                                rows: totalRows,
                                                cols: totalCols,
                                                rowHeight: kRowHeight,
                                                rowGap: kRowGap,
                                                colWidth: kCellWidth,
                                                lineColor:
                                                    Colors.grey.withOpacity(.3),
                                                lineWidth: kGridStroke,
                                              ),
                                            ),
                                          ),

                                          // Bookings (rounded + slight overlap to kiss lines)
                                          ...reservations
                                              .where((r) => r.roomId != 0)
                                              .map((r) {
                                            final start =
                                                calenderDates.indexWhere(
                                              (d) =>
                                                  DateFormat('yyyy-MM-dd')
                                                      .format(d) ==
                                                  r.checkin,
                                            );
                                            if (start == -1)
                                              return const SizedBox.shrink();

                                            final span = DateTime.parse(
                                                    r.checkout)
                                                .difference(
                                                    DateTime.parse(r.checkin))
                                                .inDays;

                                            final rowIndex = rooms.indexWhere(
                                                (rm) => rm.id == r.roomId);
                                            if (rowIndex == -1)
                                              return const SizedBox.shrink();

                                            final double bandTop =
                                                rowIndex * kRowPitch +
                                                    (kRowGap / 2);
                                            final bool isFirstRow =
                                                rowIndex == 0;

                                            final double top = isFirstRow
                                                ? (bandTop - kGridStroke / 2)
                                                : (bandTop - kGridStroke / 2) -
                                                    kRowGap;

                                            final double height = isFirstRow
                                                ? (kRowHeight + kGridStroke)
                                                : (kRowHeight + kGridStroke) +
                                                    kRowGap;

                                            return Positioned(
                                              left: start * kCellWidth,
                                              top: top,
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          ReservationDetailScreen(
                                                              reservation: r),
                                                    ),
                                                  );
                                                },
                                                child: Container(
                                                  height: height,
                                                  width:
                                                      (span + 1) * kCellWidth,
                                                  alignment: Alignment.center,
                                                  padding: const EdgeInsets
                                                      .symmetric(horizontal: 6),
                                                  decoration: BoxDecoration(
                                                    color: CommonMethod()
                                                        .reservationColor(r),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            50),
                                                  ),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      r.fullname,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: r.balance == 0
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

                                          // Today vertical guideline (full height)
                                          if (todayIndex != -1)
                                            Positioned(
                                              left: todayIndex * kCellWidth +
                                                  (kCellWidth / 2) -
                                                  1,
                                              top: 0,
                                              bottom: extraBottomPadding,
                                              child: Container(
                                                width: 2,
                                                color: ColorUtils.blue,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}

/// LEFT panel painter: draws horizontal band lines and a right vertical line
class _LeftPanelPainter extends CustomPainter {
  final int rows;
  final double rowHeight, rowGap;
  final double lineWidth;
  final Color lineColor;

  _LeftPanelPainter({
    required this.rows,
    required this.rowHeight,
    required this.rowGap,
    required this.lineColor,
    this.lineWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth;

    final totalHeight = rows * (rowHeight + rowGap);

    // Right vertical line to match first grid column divider
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, totalHeight),
      p,
    );

    // Top line once, then each band's bottom line
    final double firstTop = rowGap / 2;
    canvas.drawLine(Offset(0, firstTop), Offset(size.width, firstTop), p);

    for (int r = 0; r < rows; r++) {
      final double bandBottom =
          r * (rowHeight + rowGap) + (rowGap / 2) + rowHeight;
      canvas.drawLine(
        Offset(0, bandBottom),
        Offset(size.width, bandBottom),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LeftPanelPainter old) =>
      old.rows != rows ||
      old.rowHeight != rowHeight ||
      old.rowGap != rowGap ||
      old.lineWidth != lineWidth ||
      old.lineColor != lineColor;
}

/// Joint grid painter (continuous verticals + single horizontal divider)
class _JointGridPainter extends CustomPainter {
  final int rows, cols;
  final double rowHeight, rowGap, colWidth;
  final double lineWidth;
  final Color lineColor;

  _JointGridPainter({
    required this.rows,
    required this.cols,
    required this.rowHeight,
    required this.rowGap,
    required this.colWidth,
    required this.lineColor,
    this.lineWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth;

    final totalHeight = rows * (rowHeight + rowGap);

    // Continuous vertical lines
    for (int c = 0; c <= cols; c++) {
      final double x = c * colWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, totalHeight), p);
    }

    // Single horizontal line between rows
    final double firstTop = rowGap / 2;
    canvas.drawLine(Offset(0, firstTop), Offset(cols * colWidth, firstTop), p);
    for (int r = 0; r < rows; r++) {
      final double bandBottom =
          r * (rowHeight + rowGap) + (rowGap / 2) + rowHeight;
      canvas.drawLine(
          Offset(0, bandBottom), Offset(cols * colWidth, bandBottom), p);
    }
  }

  @override
  bool shouldRepaint(covariant _JointGridPainter old) =>
      old.rows != rows ||
      old.cols != cols ||
      old.rowHeight != rowHeight ||
      old.rowGap != rowGap ||
      old.colWidth != colWidth ||
      old.lineColor != lineColor ||
      old.lineWidth != lineWidth;
}
