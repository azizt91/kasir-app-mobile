import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  const AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object> get props => [email, password];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}

class AuthUpdateFcmToken extends AuthEvent {
  final String token;
  const AuthUpdateFcmToken(this.token);
  @override
  List<Object> get props => [token];
}
