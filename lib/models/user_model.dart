class UserModel {
  final String id;
  final String email;
  final String publicKey;
  final String createdAt;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.email,
    required this.publicKey,
    required this.createdAt,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      publicKey: json['publicKey'],
      createdAt: json['createdAt'],
      roles: List<String>.from(json['roles']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'publicKey': publicKey,
      'createdAt': createdAt,
      'roles': roles,
    };
  }
}
