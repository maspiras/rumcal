import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logout_event.dart';

abstract class LogoutState {}

class LogoutInitial extends LogoutState {}
class LogoutLoading extends LogoutState {}
class LogoutSuccess extends LogoutState {}

class LogoutBloc extends Bloc<LogoutEvent, LogoutState> {
  LogoutBloc() : super(LogoutInitial()) {
    on<LogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLogoutRequested(
      LogoutRequested event, Emitter<LogoutState> emit) async {
    emit(LogoutLoading());
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all user session data
      emit(LogoutSuccess());
    } catch (e) {
      emit(LogoutInitial()); // Reset to initial state on error
    }
  }
}