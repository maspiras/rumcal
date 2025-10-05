// import 'package:cal_room/screens/login_screen.dart';
import '/blocs/reservation/reservation__bloc.dart';
import '/blocs/room/room_bloc.dart';
import '/blocs/user/user_bloc.dart';
import '/blocs/user/user_event.dart';
import '/screens/splash_screen.dart';
import '/utils/color_utils.dart';
import '/utils/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
// import 'package:sqflite/sqflite.dart';
// import 'screens/user_screen.dart';
// import 'screens/room_screen.dart';
// import 'screens/reservation_screen.dart';
// import 'screens/calendar_screen.dart';
// import 'screens/settings_screen.dart';
// import 'database/db_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize the database before controllers
  // Database db = await DBHelper.database;

  // ✅ Use Get.putAsync() to ensure database is ready before controllers
  // await Get.putAsync(() async => UserController());
  // await Get.putAsync(() async => RoomController());
  // await Get.putAsync(() async => ReservationController());
  // await Get.putAsync(() async => BadgeController());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider<UserBloc>(create: (_) => UserBloc()..add(FetchUsers())),
          BlocProvider<ReservationBloc>(create: (_) => ReservationBloc()),
          BlocProvider(create: (context) => RoomBloc())
        ],
        child: GetMaterialApp(
          title: StringUtils.appTitle,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            //colorSchemeSeed: ColorUtils.blue,
            //ColorScheme myColorScheme = ColorScheme.fromSeed(seedColor: Colors.blue),
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),

            scaffoldBackgroundColor: ColorUtils.grey[100],
            appBarTheme: AppBarTheme(
              /*backgroundColor: ColorUtils.blue,
              foregroundColor: ColorUtils.white,
              elevation: 4,*/
              // backgroundColor: Colors.brown,
              backgroundColor: Color(0xFF967969),
              foregroundColor: ColorUtils.white,
              elevation: 4,

            ),
            iconTheme: IconThemeData(color: ColorUtils.white),
          ),
          home: SplashScreen(),
        ));
  }
}
