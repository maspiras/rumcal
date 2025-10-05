// user_event.dart
import '/model/user_model.dart';

abstract class UserEvent {}

class FetchUsers extends UserEvent {}

class AddUser extends UserEvent {
  final UserModel user;
  AddUser(this.user);
}

class UpdateUser extends UserEvent {
  final UserModel user;
  UpdateUser(this.user);
}

class DeleteUser extends UserEvent {
  final int id;
  DeleteUser(this.id);
}
