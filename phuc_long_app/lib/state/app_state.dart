import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/beverage.dart';
import '../models/user.dart';

class AppState extends ChangeNotifier {
  // Singleton pattern
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;
  AppState._internal() {
    // Initialise lists
    _beverages = List.from(mockBeverages);
    // Initialize default users
    _users['user@gmail.com'] = UserModel(
      email: 'user@gmail.com',
      password: 'user',
      name: 'Khách hàng Thân thiết',
      phone: '0901234567',
      address: '123 Đường Lê Lợi, Quận 1, TP. HCM',
    );
    _users['admin@phuclong.com.vn'] = UserModel(
      email: 'admin@phuclong.com.vn',
      password: 'admin',
      name: 'Quản trị viên',
      isAdmin: true,
    );
  }

  // Registered users map: email -> UserModel
  final Map<String, UserModel> _users = {};
  
  // Current logged in user
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Active Role: 'user' or 'admin'
  String _currentRole = 'user';
  String get currentRole => _currentRole;

  void setRole(String role) {
    _currentRole = role;
    notifyListeners();
  }

  // Authentication Helpers
  Future<bool> login(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      
      final doc = await FirebaseFirestore.instance.collection('users').doc(cleanEmail).get();
      if (doc.exists) {
        final data = doc.data()!;
        final user = UserModel(
          email: cleanEmail,
          password: password,
          name: data['name'] ?? '',
          phone: data['phone'] ?? '',
          address: data['address'] ?? '',
          isAdmin: data['isAdmin'] ?? false,
        );
        _currentUser = user;
        _currentRole = user.isAdmin ? 'admin' : 'user';
        _users[cleanEmail] = user;
        notifyListeners();
        return true;
      } else {
        final user = UserModel(
          email: cleanEmail,
          password: password,
          name: userCredential.user?.displayName ?? cleanEmail.split('@')[0],
          phone: userCredential.user?.phoneNumber ?? '',
          address: '',
          isAdmin: false,
        );
        _currentUser = user;
        _currentRole = 'user';
        _users[cleanEmail] = user;
        notifyListeners();
        return true;
      }
    } on FirebaseAuthException catch (e) {
      final user = _users[cleanEmail];
      if (user != null && user.password == password) {
        _currentUser = user;
        _currentRole = user.isAdmin ? 'admin' : 'user';
        notifyListeners();
        return true;
      }
      debugPrint("Firebase Login Error: ${e.message}");
      return false;
    } catch (e) {
      debugPrint("General Login Error: $e");
      return false;
    }
  }

  Future<bool> register(String email, String password, String name, String phone, String address) async {
    final cleanEmail = email.trim().toLowerCase();
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );
      
      await FirebaseFirestore.instance.collection('users').doc(cleanEmail).set({
        'email': cleanEmail,
        'name': name,
        'phone': phone,
        'address': address,
        'isAdmin': false,
      });

      final newUser = UserModel(
        email: cleanEmail,
        password: password,
        name: name,
        phone: phone,
        address: address,
        isAdmin: false,
      );
      _users[cleanEmail] = newUser;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Firebase Register Error: $e");
      return false;
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    _currentUser = null;
    _currentRole = 'user';
    notifyListeners();
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    if (_currentUser == null) return false;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      }
      
      _currentUser!.password = newPassword;
      _users[_currentUser!.email]!.password = newPassword;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Firebase Change Password Error: $e");
      if (FirebaseAuth.instance.currentUser == null) {
        if (_currentUser!.password != currentPassword) return false;
        _currentUser!.password = newPassword;
        _users[_currentUser!.email]!.password = newPassword;
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  Future<bool> resetPassword(String email, String newPassword) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_users.containsKey(cleanEmail) && FirebaseAuth.instance.currentUser == null) {
      _users[cleanEmail]!.password = newPassword;
      if (_currentUser?.email.toLowerCase() == cleanEmail) {
        _currentUser!.password = newPassword;
      }
      notifyListeners();
      return true;
    }
    
    try {
      debugPrint("Simulating Firebase Password Reset for $cleanEmail");
      if (_users.containsKey(cleanEmail)) {
        _users[cleanEmail]!.password = newPassword;
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Firebase Reset Password Error: $e");
      return false;
    }
  }

  void updateProfile(String name, String phone, String address) async {
    if (_currentUser == null) return;
    
    _currentUser!.name = name;
    _currentUser!.phone = phone;
    _currentUser!.address = address;
    
    _users[_currentUser!.email]!.name = name;
    _users[_currentUser!.email]!.phone = phone;
    _users[_currentUser!.email]!.address = address;
    
    notifyListeners();

    try {
      final cleanEmail = _currentUser!.email.trim().toLowerCase();
      await FirebaseFirestore.instance.collection('users').doc(cleanEmail).update({
        'name': name,
        'phone': phone,
        'address': address,
      });
    } catch (e) {
      debugPrint("Firebase Update Profile Error: $e");
    }
  }

  bool checkIfUserExists(String email) {
    return _users.containsKey(email.trim().toLowerCase());
  }


  // Beverage List
  late List<Beverage> _beverages;
  List<Beverage> get beverages => _beverages.where((b) => _currentRole == 'admin' || b.isAvailable).toList();
  List<Beverage> get allBeveragesForAdmin => _beverages;

  // Add beverage
  void addBeverage(Beverage beverage) {
    _beverages.insert(0, beverage);
    notifyListeners();
  }

  // Update beverage details
  void updateBeverage(Beverage updated) {
    final index = _beverages.indexWhere((b) => b.id == updated.id);
    if (index != -1) {
      _beverages[index] = updated;
      notifyListeners();
    }
  }

  // Toggle availability
  void toggleAvailability(String id) {
    final index = _beverages.indexWhere((b) => b.id == id);
    if (index != -1) {
      _beverages[index].isAvailable = !_beverages[index].isAvailable;
      notifyListeners();
    }
  }

  // Delete beverage
  void deleteBeverage(String id) {
    _beverages.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  // Shopping Cart State
  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => _cartItems;

  void addToCart(Beverage beverage, {int quantity = 1, String size = 'M', double sugar = 1.0, double ice = 1.0}) {
    // Check if duplicate item exists
    final index = _cartItems.indexWhere((item) =>
        item.beverage.id == beverage.id &&
        item.size == size &&
        item.sugar == sugar &&
        item.ice == ice);

    if (index != -1) {
      _cartItems[index].quantity += quantity;
    } else {
      _cartItems.add(CartItem(
        beverage: beverage,
        quantity: quantity,
        size: size,
        sugar: sugar,
        ice: ice,
      ));
    }
    notifyListeners();
  }

  void updateCartQuantity(int index, int delta) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index].quantity += delta;
      if (_cartItems[index].quantity <= 0) {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      notifyListeners();
    }
  }

  void updateCartItem(int index, {required int quantity, required String size, required double sugar, required double ice}) {
    if (index >= 0 && index < _cartItems.length) {
      final item = _cartItems[index];
      item.quantity = quantity;
      item.size = size;
      item.sugar = sugar;
      item.ice = ice;
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  double get cartSubtotal {
    double total = 0;
    for (var item in _cartItems) {
      total += item.totalPrice;
    }
    return total;
  }

  // Orders State
  final List<Order> _orders = [
    Order(
      id: 'PL-8891',
      items: [
        CartItem(beverage: mockBeverages[0], quantity: 2, size: 'M'),
        CartItem(beverage: mockBeverages[1], quantity: 1, size: 'L'),
      ],
      total: 180000,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      customerName: 'Nguyễn Văn A',
      customerPhone: '0901234567',
      customerAddress: '123 Đường Lê Lợi, Quận 1, TP. HCM',
      status: 'Đang xử lý',
    ),
    Order(
      id: 'PL-8892',
      items: [
        CartItem(beverage: mockBeverages[3], quantity: 1, size: 'S'),
      ],
      total: 40000,
      date: DateTime.now().subtract(const Duration(hours: 5)),
      customerName: 'Trần Thị B',
      customerPhone: '0987654321',
      customerAddress: '456 Đường Nguyễn Huệ, Quận 1, TP. HCM',
      status: 'Đã hoàn thành',
    )
  ];
  List<Order> get orders => _orders;

  void placeOrder(String name, String phone, String address) {
    if (_cartItems.isEmpty) return;
    
    final newOrder = Order(
      id: 'PL-${1000 + _orders.length}',
      items: List.from(_cartItems),
      total: cartSubtotal,
      date: DateTime.now(),
      customerName: name,
      customerPhone: phone,
      customerAddress: address,
      status: 'Chờ xử lý',
    );
    
    _orders.insert(0, newOrder);
    clearCart();
    notifyListeners();
  }

  void updateOrderStatus(String orderId, String status) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].status = status;
      notifyListeners();
    }
  }
}
