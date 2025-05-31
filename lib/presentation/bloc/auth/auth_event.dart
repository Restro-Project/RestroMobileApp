import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SignInRequested extends AuthEvent {
  final String email, password;
  SignInRequested(this.email, this.password);
}

/*  ─────────────────────────────────────────
 *  seluruh data profil dikirim sekali saja
 *  ───────────────────────────────────────── */
class SignUpRequested extends AuthEvent {
  // akun-dasar
  final String email, password, username, fullName, phone;

  // data pasien
  final String gender;
  final DateTime birthDate;
  final String birthPlace, address, companionName;

  // data kesehatan
  final int height, weight;
  final String bloodType, medicalHistory, allergyHistory;

  SignUpRequested({
    required this.email,
    required this.password,
    required this.username,
    required this.fullName,
    required this.phone,
    required this.gender,
    required this.birthDate,
    required this.birthPlace,
    required this.address,
    required this.companionName,
    required this.height,
    required this.weight,
    required this.bloodType,
    required this.medicalHistory,
    required this.allergyHistory,
  });

  @override
  List<Object?> get props => [
    email,
    username,
    birthDate,
    height,
    weight,
  ];
}

class SignOutRequested extends AuthEvent {}