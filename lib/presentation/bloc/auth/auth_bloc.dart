import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const _timeout = Duration(seconds: 10);

  AuthBloc(this._auth) : super(AuthInitial()) {
    // ---------- LOGIN ----------
    on<SignInRequested>((e, emit) async {
      emit(AuthLoading());
      try {
        final cred = await _auth
            .signInWithEmailAndPassword(email: e.email, password: e.password)
            .timeout(_timeout);

        /* --- ambil profil --- */
        final snap = await _db.collection('users').doc(cred.user!.uid).get();
        if (snap.exists) {
          final data = snap.data()!;
          // simpan ke profile Auth → cukup sekali agar bisa dipakai offline
          await cred.user!.updateDisplayName(data['username'] as String?);
        }

        emit(AuthSuccess());
      } on TimeoutException {
        emit(AuthFailure('Gagal terhubung ke server'));
      } on FirebaseAuthException catch (e) {
        emit(AuthFailure(_msgLogin(e.code, e.message)));
      }
    });

    // ---------- REGISTER ----------
    on<SignUpRequested>((e, emit) async {
      emit(AuthLoading());
      try {
        final cred = await _auth
            .createUserWithEmailAndPassword(
          email   : e.email,
          password: e.password,
        )
            .timeout(_timeout);

        /* simpan SEMUA field langsung */
        await _db.collection('users').doc(cred.user!.uid).set({
          // akun
          'username'      : e.username,
          'fullName'      : e.fullName,
          'email'         : e.email,
          'phone'         : e.phone,

          // pasien
          'gender'        : e.gender,
          'birthDate'     : e.birthDate,
          'birthPlace'    : e.birthPlace,
          'address'       : e.address,
          'companionName' : e.companionName,

          // kesehatan
          'height'        : e.height,
          'weight'        : e.weight,
          'bloodType'     : e.bloodType,
          'medicalHistory': e.medicalHistory,
          'allergyHistory': e.allergyHistory,

          'createdAt'     : FieldValue.serverTimestamp(),
        });

        /* displayName diset = username supaya Profile cepat ter-muat */
        await cred.user!.updateDisplayName(e.username);

        emit(AuthSuccess());
      } on TimeoutException {
        emit(AuthFailure('Gagal terhubung ke server'));
      } on FirebaseAuthException catch (ex) {
        emit(AuthFailure(_msgRegister(ex.code, ex.message)));
      }
    });

    // ---------- LOG-OUT ----------
    on<SignOutRequested>((_, emit) async {
      await _auth.signOut();
      emit(AuthInitial());
    });
  }

  /* ---------- helper pesan error ---------- */
  String _msgLogin(String code, String? def) => switch (code) {
    'wrong-password' => 'Password salah',
    'user-not-found' => 'Email belum terdaftar',
    _                => def ?? 'Login gagal',
  };

  String _msgRegister(String code, String? def) => switch (code) {
    'email-already-in-use' => 'Email sudah terdaftar',
    'weak-password'        => 'Password minimal 6 karakter',
    _                      => def ?? 'Registrasi gagal',
  };
}