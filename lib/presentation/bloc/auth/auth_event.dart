import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

final class SignInRequested extends AuthEvent {
  final String identifier, password;
  SignInRequested(this.identifier, this.password);
}

final class SignUpRequested extends AuthEvent {
  final String username, fullName, email, password, phone;
  SignUpRequested({
    required this.username,
    required this.fullName,
    required this.email,
    required this.password,
    required this.phone,
  });
}

final class SignOutRequested extends AuthEvent {}

final class UpdateProfileRequested extends AuthEvent {
  final Map<String, dynamic> data;
  UpdateProfileRequested(this.data);
}