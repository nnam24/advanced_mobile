class User {
  final String id;
  final String name;
  final String email;
  final String photoUrl;
  final String plan; // 'free', 'premium', 'enterprise'
  final int tokenBalance;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.plan,
    required this.tokenBalance,
    required this.createdAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? plan,
    int? tokenBalance,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      plan: plan ?? this.plan,
      tokenBalance: tokenBalance ?? this.tokenBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      plan: json['plan'] ?? 'free',
      tokenBalance: json['tokenBalance'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'plan': plan,
      'tokenBalance': tokenBalance,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

