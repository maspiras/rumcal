import 'package:bookcomfy/blocs/room/room_state.dart';

import '/database/db_helper.dart';
import '/model/room_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'room_event.dart';

class RoomBloc extends Bloc<RoomEvent, RoomState> {
  RoomBloc() : super(RoomInitial()) {
    on<FetchRooms>(_onFetchRooms);
    on<AddRoom>(_onAddRoom);
    on<UpdateRoom>(_onUpdateRoom);
    on<DeleteRoom>(_onDeleteRoom);
  }

  Future<void> _onFetchRooms(FetchRooms event, Emitter<RoomState> emit) async {
    emit(RoomLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = int.tryParse(prefs.getString('userId') ?? '0') ?? 0;
      final rooms = await DBHelper.getRooms(userId > 0 ? userId : null);
      final roomList = rooms.map((e) => RoomModel.fromMap(e)).toList();
      emit(RoomLoaded(roomList));
    } catch (e) {
      emit(RoomError('Failed to load rooms: ${e.toString()}'));
    }
  }

  Future<void> _onAddRoom(AddRoom event, Emitter<RoomState> emit) async {
    emit(RoomLoading());
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = int.tryParse(prefs.getString('userId') ?? '0') ?? 0;

      final roomData = event.room.toMap();
      roomData['user_id'] = userId; // Set current user ID

      await DBHelper.database.then((db) async {
        await db.transaction((txn) async {
          await txn.insert('Rooms', roomData);
        });
      });
      add(FetchRooms());
    } catch (e) {
      emit(RoomError('Failed to add room: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateRoom(UpdateRoom event, Emitter<RoomState> emit) async {
    emit(RoomLoading());
    try {
      await DBHelper.database.then((db) async {
        await db.transaction((txn) async {
          await txn.update('Rooms', event.room.toMap(),
              where: 'id = ?', whereArgs: [event.room.id]);
        });
      });
      add(FetchRooms());
    } catch (e) {
      emit(RoomError('Failed to update room: ${e.toString()}'));
    }
  }

  Future<void> _onDeleteRoom(DeleteRoom event, Emitter<RoomState> emit) async {
    emit(RoomLoading());
    try {
      await DBHelper.database.then((db) async {
        await db.transaction((txn) async {
          await txn.delete('Rooms', where: 'id = ?', whereArgs: [event.id]);
        });
      });
      add(FetchRooms());
    } catch (e) {
      emit(RoomError('Failed to delete room: ${e.toString()}'));
    }
  }
}
