import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoggedIn>(_onLoggedIn);
    on<LoggedOut>(_onLoggedOut);
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString('uid');
    final email = prefs.getString('email');
    final itemSubscribed = prefs.getBool('itemSubscribed') ?? false;
    final locationSubscribed = prefs.getBool('locationSubscribed') ?? false;

    final currentUser = FirebaseAuth.instance.currentUser;

    // ✅ Re-fetch token to force-check validity
    try {
        if (currentUser != null && currentUser.email == email) {
            await currentUser.getIdToken(true); // force refresh
            emit(Authenticated(
              uid ?? currentUser.uid,
              email ?? currentUser.email!,
              itemsubscribed: itemSubscribed,
              locationSubscribed: locationSubscribed,
            ));
        } else {
            await FirebaseAuth.instance.signOut(); // Clear invalid session
            emit(Unauthenticated());
        }
    } catch (e) {
        await FirebaseAuth.instance.signOut();
        emit(Unauthenticated());
    }
}

  // Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final uid = prefs.getString('uid');
  //   final email = prefs.getString('email');
  //   final itemSubscribed = prefs.getBool('itemsubscribed') ?? false;
  //   final locationSubscribed = prefs.getBool('locationSubscribed') ?? false;

  //   if (uid != null && email != null) {
  //     emit(
  //       Authenticated(
  //         uid,
  //         email,
  //         itemsubscribed: itemSubscribed,
  //         locationSubscribed: locationSubscribed,
  //       ),
  //     );
  //   } else {
  //     emit(Unauthenticated());
  //   }
  // }

  Future<void> _onLoggedIn(LoggedIn event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', event.uid);
    await prefs.setString('email', event.email);
    await prefs.setBool('itemSubscribed', event.itemSubscribed);
    await prefs.setBool('locationSubscribed', event.itemSubscribed);

    emit(
      Authenticated(
        event.uid,
        event.email,
        itemsubscribed: event.itemSubscribed,
        locationSubscribed: event.locationSubscribed,
      ),
    );
  }

  Future<void> _onLoggedOut(LoggedOut event, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    emit(Unauthenticated());
  }
}
