import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/beverage.dart';
import '../models/user.dart';
import '../models/promotion.dart';

class AppState extends ChangeNotifier {
  // Singleton pattern
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;

  AppState._internal() {
    // Initialise default users
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

    // Initial local fallback data
    _beverages = List.from(mockBeverages);
    _promotions = List.from(mockPromotions);

    // Bind real-time Firebase Firestore listeners
    _initFirestoreListeners();
  }

  // Firestore Subscriptions
  StreamSubscription<QuerySnapshot>? _beveragesSub;
  StreamSubscription<QuerySnapshot>? _ordersSub;
  StreamSubscription<QuerySnapshot>? _promotionsSub;

  void _initFirestoreListeners() {
    final firestore = FirebaseFirestore.instance;

    // 1. Beverages Collection Listener
    _beveragesSub = firestore.collection('beverages').snapshots().listen(
      (snapshot) {
        if (snapshot.docs.isEmpty) {
          _seedBeveragesToFirestore();
        } else {
          _beverages = snapshot.docs
              .map((doc) => Beverage.fromFirestore(doc))
              .toList();
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint("Firestore Beverages Listener Error: $error");
      },
    );

    // 2. Orders Collection Listener
    _ordersSub = firestore.collection('orders').orderBy('date', descending: true).snapshots().listen(
      (snapshot) {
        _orders = snapshot.docs
            .map((doc) => Order.fromFirestore(doc))
            .toList();
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore Orders Listener Error: $error");
      },
    );

    // 3. Promotions Collection Listener
    _promotionsSub = firestore.collection('promotions').snapshots().listen(
      (snapshot) {
        if (snapshot.docs.isEmpty) {
          _seedPromotionsToFirestore();
        } else {
          _promotions = snapshot.docs
              .map((doc) => Promotion.fromFirestore(doc))
              .toList();
          notifyListeners();
        }
      },
      onError: (error) {
        debugPrint("Firestore Promotions Listener Error: $error");
      },
    );
  }

  /// Seed initial beverages into Firestore if collection is empty
  Future<void> _seedBeveragesToFirestore() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance.collection('beverages');
      for (var bev in mockBeverages) {
        batch.set(collection.doc(bev.id), bev.toMap());
      }
      await batch.commit();
      debugPrint("✅ Initial beverages successfully seeded to Cloud Firestore");
    } catch (e) {
      debugPrint("⚠️ Seed Beverages Error: $e");
    }
  }

  /// Seed initial promotions into Firestore if collection is empty
  Future<void> _seedPromotionsToFirestore() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      final collection = FirebaseFirestore.instance.collection('promotions');
      for (var promo in mockPromotions) {
        batch.set(collection.doc(promo.id), promo.toMap());
      }
      await batch.commit();
      debugPrint("✅ Initial promotions successfully seeded to Cloud Firestore");
    } catch (e) {
      debugPrint("⚠️ Seed Promotions Error: $e");
    }
  }

  @override
  void dispose() {
    _beveragesSub?.cancel();
    _ordersSub?.cancel();
    _promotionsSub?.cancel();
    super.dispose();
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

    if (!_users.containsKey(cleanEmail)) {
      _users[cleanEmail] = UserModel(
        email: cleanEmail,
        password: newPassword,
        name: cleanEmail.split('@')[0],
      );
    } else {
      _users[cleanEmail]!.password = newPassword;
      if (_currentUser?.email.toLowerCase() == cleanEmail) {
        _currentUser!.password = newPassword;
      }
    }

    notifyListeners();

    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(cleanEmail);
      final doc = await userDoc.get();
      if (doc.exists) {
        await userDoc.update({'password': newPassword});
      } else {
        await userDoc.set({
          'email': cleanEmail,
          'password': newPassword,
          'name': cleanEmail.split('@')[0],
          'phone': '',
          'address': '',
          'isAdmin': false,
        });
      }
    } catch (e) {
      debugPrint("Firebase Reset Password Error: $e");
    }

    return true;
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

  Future<bool> checkIfUserExists(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_users.containsKey(cleanEmail)) {
      return true;
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(cleanEmail).get();
      if (doc.exists) {
        final data = doc.data()!;
        _users[cleanEmail] = UserModel(
          email: cleanEmail,
          password: data['password'] ?? '',
          name: data['name'] ?? cleanEmail.split('@')[0],
          phone: data['phone'] ?? '',
          address: data['address'] ?? '',
          isAdmin: data['isAdmin'] ?? false,
        );
        return true;
      }
    } catch (e) {
      debugPrint("Check User Exists Error: $e");
    }

    if (RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(cleanEmail)) {
      _users[cleanEmail] = UserModel(
        email: cleanEmail,
        password: '',
        name: cleanEmail.split('@')[0],
      );
      return true;
    }

    return false;
  }

  Future<UserModel?> findUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_users.containsKey(cleanEmail)) {
      return _users[cleanEmail];
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(cleanEmail).get();
      if (doc.exists) {
        final data = doc.data()!;
        final user = UserModel(
          email: cleanEmail,
          password: data['password'] ?? '',
          name: data['name'] ?? cleanEmail.split('@')[0],
          phone: data['phone'] ?? '',
          address: data['address'] ?? '',
          isAdmin: data['isAdmin'] ?? false,
        );
        _users[cleanEmail] = user;
        return user;
      }
    } catch (e) {
      debugPrint("Find User By Email Error: $e");
    }

    return null;
  }

  Future<bool> updateUserRole(String email, bool isAdmin) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_users.containsKey(cleanEmail)) {
      _users[cleanEmail]!.isAdmin = isAdmin;
      if (_currentUser?.email.toLowerCase() == cleanEmail) {
        _currentUser!.isAdmin = isAdmin;
      }
    }

    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('users').doc(cleanEmail).set({
        'isAdmin': isAdmin,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Update User Role Error: $e");
    }

    return true;
  }

  // -------------------------------------------------------------
  // BEVERAGES / PRODUCTS STATE & FIRESTORE CRUD
  // -------------------------------------------------------------
  List<Beverage> _beverages = [];
  List<Beverage> get beverages => _beverages.where((b) => _currentRole == 'admin' || b.isAvailable).toList();
  List<Beverage> get allBeveragesForAdmin => _beverages;

  Future<void> addBeverage(Beverage beverage) async {
    _beverages.insert(0, beverage);
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('beverages').doc(beverage.id).set(beverage.toMap());
    } catch (e) {
      debugPrint("Firestore Add Beverage Error: $e");
    }
  }

  Future<void> updateBeverage(Beverage updated) async {
    final index = _beverages.indexWhere((b) => b.id == updated.id);
    if (index != -1) {
      _beverages[index] = updated;
      notifyListeners();
    }

    try {
      await FirebaseFirestore.instance.collection('beverages').doc(updated.id).update(updated.toMap());
    } catch (e) {
      debugPrint("Firestore Update Beverage Error: $e");
    }
  }

  Future<void> toggleAvailability(String id) async {
    final index = _beverages.indexWhere((b) => b.id == id);
    if (index != -1) {
      _beverages[index].isAvailable = !_beverages[index].isAvailable;
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('beverages').doc(id).update({
          'isAvailable': _beverages[index].isAvailable,
        });
      } catch (e) {
        debugPrint("Firestore Toggle Availability Error: $e");
      }
    }
  }

  Future<void> deleteBeverage(String id) async {
    _beverages.removeWhere((b) => b.id == id);
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('beverages').doc(id).delete();
    } catch (e) {
      debugPrint("Firestore Delete Beverage Error: $e");
    }
  }

  // -------------------------------------------------------------
  // PROMOTIONS STATE & FIRESTORE CRUD
  // -------------------------------------------------------------
  List<Promotion> _promotions = [];
  List<Promotion> get promotions => _promotions.where((p) => _currentRole == 'admin' || p.isAvailable).toList();
  List<Promotion> get allPromotionsForAdmin => _promotions;

  Promotion? _appliedPromotion;
  Promotion? get appliedPromotion => _appliedPromotion;

  String? applyPromotionCode(String code) {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return 'Vui lòng nhập mã khuyến mãi';

    final index = _promotions.indexWhere((p) => p.code == cleanCode && p.isAvailable);
    if (index == -1) {
      return 'Mã khuyến mãi không hợp lệ hoặc đã hết hạn!';
    }

    final promo = _promotions[index];
    if (cartSubtotal < promo.minOrderPrice) {
      final minStr = promo.minOrderPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
      return 'Mã này chỉ áp dụng cho đơn từ $minStr đ trở lên!';
    }

    _appliedPromotion = promo;
    notifyListeners();
    return null; // Null means success
  }

  void removeAppliedPromotion() {
    _appliedPromotion = null;
    notifyListeners();
  }

  double get discountAmount {
    if (_appliedPromotion == null) return 0.0;
    return _appliedPromotion!.calculateDiscount(cartSubtotal);
  }

  double get cartFinalTotal {
    final total = cartSubtotal - discountAmount;
    return total < 0 ? 0 : total;
  }

  Future<void> addPromotion(Promotion promotion) async {
    _promotions.insert(0, promotion);
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('promotions').doc(promotion.id).set(promotion.toMap());
    } catch (e) {
      debugPrint("Firestore Add Promotion Error: $e");
    }
  }

  Future<void> updatePromotion(Promotion updated) async {
    final index = _promotions.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _promotions[index] = updated;
      notifyListeners();
    }

    try {
      await FirebaseFirestore.instance.collection('promotions').doc(updated.id).update(updated.toMap());
    } catch (e) {
      debugPrint("Firestore Update Promotion Error: $e");
    }
  }

  Future<void> togglePromotionAvailability(String id) async {
    final index = _promotions.indexWhere((p) => p.id == id);
    if (index != -1) {
      _promotions[index].isAvailable = !_promotions[index].isAvailable;
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('promotions').doc(id).update({
          'isAvailable': _promotions[index].isAvailable,
        });
      } catch (e) {
        debugPrint("Firestore Toggle Promotion Error: $e");
      }
    }
  }

  Future<void> deletePromotion(String id) async {
    _promotions.removeWhere((p) => p.id == id);
    if (_appliedPromotion?.id == id) {
      _appliedPromotion = null;
    }
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('promotions').doc(id).delete();
    } catch (e) {
      debugPrint("Firestore Delete Promotion Error: $e");
    }
  }

  // -------------------------------------------------------------
  // CART STATE
  // -------------------------------------------------------------
  final List<CartItem> _cartItems = [];
  List<CartItem> get cartItems => _cartItems;

  void addToCart(Beverage beverage, {int quantity = 1, String size = 'M', double sugar = 1.0, double ice = 1.0}) {
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
    _appliedPromotion = null;
    notifyListeners();
  }

  double get cartSubtotal {
    double total = 0;
    for (var item in _cartItems) {
      total += item.totalPrice;
    }
    return total;
  }

  // -------------------------------------------------------------
  // ORDERS STATE & FIRESTORE CRUD
  // -------------------------------------------------------------
  List<Order> _orders = [];
  List<Order> get orders => _orders;

  Future<void> placeOrder(String name, String phone, String address) async {
    if (_cartItems.isEmpty) return;

    final orderId = 'PL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final appliedPromo = _appliedPromotion;
    final finalDiscount = discountAmount;
    final finalTotal = cartFinalTotal;

    final newOrder = Order(
      id: orderId,
      items: List.from(_cartItems),
      total: finalTotal,
      discountAmount: finalDiscount,
      promoCode: appliedPromo?.code ?? '',
      date: DateTime.now(),
      customerName: name,
      customerPhone: phone,
      customerAddress: address,
      status: 'Chờ xử lý',
    );

    _orders.insert(0, newOrder);
    clearCart();
    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('orders').doc(newOrder.id).set(newOrder.toMap());
    } catch (e) {
      debugPrint("Firestore Place Order Error: $e");
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].status = status;
      notifyListeners();
    }

    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': status,
      });
    } catch (e) {
      debugPrint("Firestore Update Order Status Error: $e");
    }
  }
}
