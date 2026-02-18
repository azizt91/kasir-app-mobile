import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? accessToken;
  final List<String> permissions;
  final Map<String, dynamic> settings;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.accessToken,
    this.permissions = const [],
    this.settings = const {},
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userData = json['user'] ?? json; 
    
    return UserModel(
      id: userData['id'],
      name: userData['name'],
      email: userData['email'],
      role: userData['role'],
      accessToken: json['access_token'],
      permissions: userData['permissions'] != null 
          ? (userData['permissions'] is Map 
              ? (userData['permissions'] as Map).keys.map((e) => e.toString()).toList() 
              : List<String>.from(userData['permissions']))
          : [],
      settings: json['settings'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'permissions': permissions,
      },
      'access_token': accessToken,
      'settings': settings,
    };
  }

  @override
  List<Object?> get props => [id, name, email, role, accessToken, permissions, settings];
}
