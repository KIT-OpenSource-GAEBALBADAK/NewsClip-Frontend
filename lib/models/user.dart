// components/AppContext.tsx (User interface) 변환
class User {
  final String id;
  final String name;
  final String email;
  final String? avatar;
  final String provider; // 'kakao', 'google', 'apple', 'naver'

  User({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    required this.provider,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatar: json['avatar'] as String?,
      provider: json['provider'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'provider': provider,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    String? provider,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      provider: provider ?? this.provider,
    );
  }
}
