import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable { @override List<Object?> get props => []; }
class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthSuccess extends AuthState {}
class AuthFailure extends AuthState { final String msg; AuthFailure(this.msg); @override List<Object?> get props => [msg]; }