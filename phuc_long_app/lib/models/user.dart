class UserModel {
  final String username; // Unique username (e.g. 'khachhang', 'hainguyen99')
  final String email;
  String password;
  String name; // Display name / Họ và tên
  String phone;
  String address;
  String avatarUrl;
  bool isAdmin;

  UserModel({
    required this.username,
    required this.email,
    required this.password,
    required this.name,
    this.phone = '',
    this.address = '',
    this.avatarUrl = '',
    this.isAdmin = false,
  });

  UserModel copyWith({
    String? username,
    String? password,
    String? name,
    String? phone,
    String? address,
    String? avatarUrl,
    bool? isAdmin,
  }) {
    return UserModel(
      username: username ?? this.username,
      email: email,
      password: password ?? this.password,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'email': email,
      'password': password,
      'name': name,
      'phone': phone,
      'address': address,
      'avatarUrl': avatarUrl,
      'isAdmin': isAdmin,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String fallbackEmail) {
    final email = map['email'] ?? fallbackEmail;
    final fallbackUsername = email.contains('@') ? email.split('@')[0] : email;

    return UserModel(
      username: map['username'] ?? fallbackUsername,
      email: email,
      password: map['password'] ?? '',
      name: map['name'] ?? fallbackUsername,
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      avatarUrl: map['avatarUrl'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}
