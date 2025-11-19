class Usuario {
  final int id;
  final String username;
  final String email;
  final String? firstName;
  final String? lastName;
  final String rol;
  final String? firmaDigital;

  Usuario({
    required this.id,
    required this.username,
    required this.email,
    this.firstName,
    this.lastName,
    required this.rol,
    this.firmaDigital,
  });

  String get nombreCompleto {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return username;
  }

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      rol: json['rol'] as String? ?? 'Funcionario',
      firmaDigital: json['firma_digital'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'rol': rol,
      'firma_digital': firmaDigital,
    };
  }
}