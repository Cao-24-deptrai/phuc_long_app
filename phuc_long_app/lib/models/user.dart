class UserModel {
  final String email;
  String password;
  String name;
  String phone;
  String address;
  final bool isAdmin;

  UserModel({
    required this.email,
    required this.password,
    required this.name,
    this.phone = '',
    this.address = '',
    this.isAdmin = false,
  });

  UserModel copyWith({
    String? password,
    String? name,
    String? phone,
    String? address,
  }) {
    return UserModel(
      email: email,
      password: password ?? this.password,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      isAdmin: isAdmin,
    );
  }
}
