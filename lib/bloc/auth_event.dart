abstract class AuthEvent {}

class AppStarted extends AuthEvent {}

class LoggedIn extends AuthEvent {
  final String uid;
  final String email;
  final bool itemSubscribed; 
  final bool locationSubscribed;

  LoggedIn(this.uid, this.email, {this.itemSubscribed = false, this.locationSubscribed = false});
}

class LoggedOut extends AuthEvent {}
