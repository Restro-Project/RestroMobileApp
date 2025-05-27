import 'package:bloc/bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth;
  AuthBloc(this._auth) : super(AuthInitial()) {
    on<SignInRequested>((e, emit) async {
      emit(AuthLoading());
      try {
        await _auth.signInWithEmailAndPassword(
            email: e.email, password: e.password);
        emit(AuthSuccess());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });
    on<SignUpRequested>((e, emit) async {
      emit(AuthLoading());
      try {
        await _auth.createUserWithEmailAndPassword(
            email: e.email, password: e.password);
        emit(AuthSuccess());
      } catch (e) {
        emit(AuthFailure(e.toString()));
      }
    });
    on<SignOutRequested>((_, emit) async {
      await _auth.signOut();
      emit(AuthInitial());
    });
  }
}