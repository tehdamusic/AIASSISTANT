class User {
  final int id;
  final String name;
  final String email;
  final DateTime createdAt;
  
  User({
    required this.id,
    required this.name,
    required this.email,
    required this.createdAt,
  });
  
  // Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
