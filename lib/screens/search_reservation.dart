import 'package:bookcomfy/utils/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/reservation/reservation__bloc.dart' show ReservationBloc;
import '../blocs/reservation/reservation__state.dart';
import '../utils/color_utils.dart';
import '../widgets/reservation_card_view.dart';

class SearchReservation extends StatefulWidget {
  const SearchReservation({Key? key}) : super(key: key);

  @override
  State<SearchReservation> createState() => _SearchReservationState();
}

class _SearchReservationState extends State<SearchReservation> {
  String searchStr = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      appBar: AppBar(
        backgroundColor: ColorUtils.blue,
        leadingWidth: 0,
        leading: SizedBox(),
        title: Container(
          height: 45,
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50), color: Colors.white12),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back),
                ),
              ),
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      searchStr = value;
                    });
                  },
                  style: TextStyle(color: ColorUtils.white),
                  cursorColor: ColorUtils.white,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Search by name or phone",
                    hintStyle: TextStyle(color: ColorUtils.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: BlocBuilder<ReservationBloc, ReservationState>(
        builder: (context, state) {
          if (state is ReservationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ReservationError) {
            return Center(child: Text('Error: ${state.message}'));
          } else if (state is ReservationLoaded) {
            final reservationList = state.reservations;

            if (searchStr.isEmpty) {
              // Show full list when search is empty
              if (reservationList.isEmpty) {
                return const Center(child: Text('No Data available'));
              }

              return ListView.builder(
                itemCount: reservationList.length,
                itemBuilder: (context, index) {
                  final reservation = reservationList[index];
                  return ReservationCardView(
                    reservation: reservation,
                    isFromToday: false,
                  );
                },
              );
            }

            // Filtered list as per search string
            final filteredList = reservationList
                .where(
                  (element) =>
                      element.fullname
                          .toLowerCase()
                          .contains(searchStr.toLowerCase()) ||
                      element.phone
                          .toLowerCase()
                          .contains(searchStr.toLowerCase()),
                )
                .toList();

            if (filteredList.isEmpty) {
              return Center(
                child: Text(StringUtils.noReservationsFound2),
              );
            }

            return ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final reservation = filteredList[index];
                return ReservationCardView(
                  reservation: reservation,
                  isFromToday: false,
                );
              },
            );
          } else {
            return const Center(child: Text('No Reservations Found'));
          }
        },
      ),
    );
  }
}
