abstract class AuthState {}

class AuthInitial extends AuthState {}

class Authenticated extends AuthState {
  final String uid;
  final String email;
  final bool itemsubscribed;
  final bool locationSubscribed;

  Authenticated(this.uid, this.email, {this.itemsubscribed = false,this.locationSubscribed = false});
}


class Unauthenticated extends AuthState {}
