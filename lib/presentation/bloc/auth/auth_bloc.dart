import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/api_service.dart';
import 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    _bootstrap();                       // baca token lokal

    on<SignInRequested>(_onLogin);
    on<SignUpRequested>(_onRegister);
    on<SignOutRequested>(_onLogout);
    on<UpdateProfileRequested>(_onUpdateProfile);
  }

  /* -------- in-memory token ---------- */
  String? _token;
  bool get isLoggedIn => _token != null;

  /* -------- cek token di SharedPreferences ---------- */
  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) add(SignInRequested('', '')); // trigger AuthSuccess
  }

  /* -------- LOGIN ---------- */
  Future<void> _onLogin(
      SignInRequested e, Emitter<AuthState> emit) async {
    if (e.identifier.isEmpty && _token != null) {      // bootstrap mode
      emit(AuthSuccess());
      return;
    }
    emit(AuthLoading());
    try {
      final res = await ApiService.dio.post('/auth/pasien/login', data: {
        'identifier': e.identifier,
        'password'  : e.password,
      });

      _token = res.data['access_token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);

      emit(AuthSuccess());
    } catch (err) {
      emit(AuthFailure(_msg(err)));
    }
  }

  /* -------- REGISTER ---------- */
  Future<void> _onRegister(
      SignUpRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await ApiService.dio.post('/auth/pasien/register', data: {
        'username'     : e.username,
        'nama_lengkap' : e.fullName,
        'email'        : e.email,
        'password'     : e.password,
        'nomor_telepon': e.phone,
      });
      add(SignInRequested(e.email, e.password));   // auto login
    } catch (err) {
      emit(AuthFailure(_msg(err)));
    }
  }

  /* -------- LOGOUT ---------- */
  Future<void> _onLogout(
      SignOutRequested e, Emitter<AuthState> emit) async {
    try {
      await ApiService.dio.post('/auth/logout');
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    _token = null;
    emit(AuthInitial());
  }

  /* -------- UPDATE PROFILE ---------- */
  Future<void> _onUpdateProfile(
      UpdateProfileRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      await ApiService.dio.put('/api/patient/profile', data: e.data);
      emit(AuthSuccess());
    } catch (err) {
      emit(AuthFailure(_msg(err)));
    }
  }

  /* -------- helper pesan error ---------- */
  String _msg(Object err) {
    if (err is DioException) {
      final data = err.response?.data;
      if (data is Map<String, dynamic> && data['msg'] != null) {
        return data['msg'].toString();
      }
      return err.response?.statusMessage ??
          err.message ??
          'Terjadi kesalahan tak terduga';
    }
    return err.toString();
  }
}
