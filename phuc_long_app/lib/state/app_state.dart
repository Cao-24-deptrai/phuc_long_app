import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/beverage.dart';
import '../models/user.dart';
import '../models/promotion.dart';
import '../models/review.dart';

class AppState extends ChangeNotifier {
  // Singleton pattern
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;

  AppState._internal() {
    // Initialize default users with unique username & display name
    final defaultUser = UserModel(
      username: 'khachhang',
      email: 'user@gmail.com',
      password: 'user',
      name: 'Khách hàng Thân thiết',
      phone: '0901234567',
      address: '123 Đường Lê Lợi, Quận 1, TP. HCM',
    );
    final defaultAdmin = UserModel(
      username: 'admin',
      email: 'admin@phuclong.com.vn',
      password: 'admin',
      name: 'Quản trị viên',
      isAdmin: true,
    );
    _users[defaultUser.email] = defaultUser;
    _users[defaultAdmin.email] = defaultAdmin;

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
  StreamSubscription<QuerySnapshot>? _reviewsSub;

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

    // 4. Reviews Collection Listener
    _reviewsSub = firestore.collection('reviews').orderBy('date', descending: true).snapshots().listen(
      (snapshot) {
        _reviews = snapshot.docs
            .map((doc) => Review.fromFirestore(doc))
            .toList();
        notifyListeners();
      },
      onError: (error) {
        debugPrint("Firestore Reviews Listener Error: $error");
      },
    );
  }

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
  Map<String, UserModel> get users => _users;

  // Active Role: 'user' or 'admin'
  String _currentRole = 'user';
  String get currentRole => _currentRole;

  void setRole(String role) {
    _currentRole = role;
    notifyListeners();
  }

  /// Check if username is already taken (Unique validation)
  Future<bool> checkIfUsernameExists(String username) async {
    final cleanUsername = username.trim().toLowerCase();
    if (cleanUsername.isEmpty) return false;

    // Local in-memory check
    for (var u in _users.values) {
      if (u.username.toLowerCase() == cleanUsername) {
        return true;
      }
    }

    // Firestore query check
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: cleanUsername)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        return true;
      }
    } catch (e) {
      debugPrint("Check Username Exists Error: $e");
    }

    return false;
  }

  /// Login with either Username OR Email
  Future<bool> login(String input, String password) async {
    final cleanInput = input.trim().toLowerCase();
    if (cleanInput.isEmpty || password.isEmpty) return false;

    // 1. Resolve user profile from memory or Firestore by username or email
    UserModel? user = await findUserByEmail(cleanInput);

    if (user != null) {
      // Direct local password match check
      if (user.password == password) {
        _currentUser = user;
        _currentRole = user.isAdmin ? 'admin' : 'user';
        notifyListeners();
        return true;
      }

      // Try Firebase Auth using resolved valid email
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: user.email,
          password: password,
        );
        _currentUser = user;
        _currentRole = user.isAdmin ? 'admin' : 'user';
        notifyListeners();
        return true;
      } on FirebaseAuthException catch (e) {
        debugPrint("Firebase Auth error for ${user.email}: ${e.message}");
        if (user.password == password) {
          _currentUser = user;
          _currentRole = user.isAdmin ? 'admin' : 'user';
          notifyListeners();
          return true;
        }
        return false;
      } catch (e) {
        debugPrint("Login error: $e");
        if (user.password == password) {
          _currentUser = user;
          _currentRole = user.isAdmin ? 'admin' : 'user';
          notifyListeners();
          return true;
        }
        return false;
      }
    }

    // 2. Direct Firebase Auth login attempt if input is email format
    if (cleanInput.contains('@')) {
      try {
        final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: cleanInput,
          password: password,
        );
        final newUser = UserModel(
          username: cleanInput.split('@')[0],
          email: cleanInput,
          password: password,
          name: userCredential.user?.displayName ?? cleanInput.split('@')[0],
          isAdmin: false,
        );
        _currentUser = newUser;
        _currentRole = 'user';
        _users[cleanInput] = newUser;
        notifyListeners();
        return true;
      } catch (e) {
        debugPrint("Direct Firebase login error: $e");
      }
    }

    return false;
  }

  /// Register user with unique username, email, password, display name, phone, address
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String name,
    required String phone,
    required String address,
  }) async {
    final cleanUsername = username.trim().toLowerCase();
    final cleanEmail = email.trim().toLowerCase();

    // Check unique username
    final usernameExists = await checkIfUsernameExists(cleanUsername);
    if (usernameExists) {
      debugPrint("Register Error: Username '$cleanUsername' is already taken.");
      return false;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: cleanEmail,
        password: password,
      );

      final newUser = UserModel(
        username: cleanUsername,
        email: cleanEmail,
        password: password,
        name: name,
        phone: phone,
        address: address,
        isAdmin: false,
      );

      await FirebaseFirestore.instance.collection('users').doc(cleanEmail).set(newUser.toMap());

      _users[cleanEmail] = newUser;
      _currentUser = newUser;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Firebase Register Error: $e");
      // Fallback local memory registration
      final newUser = UserModel(
        username: cleanUsername,
        email: cleanEmail,
        password: password,
        name: name,
        phone: phone,
        address: address,
        isAdmin: false,
      );
      _users[cleanEmail] = newUser;
      _currentUser = newUser;
      notifyListeners();
      return true;
    }
  }

  void logout() async {
    await FirebaseAuth.instance.signOut();
    _currentUser = null;
    _currentRole = 'user';
    clearCart();
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
      final fallbackUsername = cleanEmail.split('@')[0];
      _users[cleanEmail] = UserModel(
        username: fallbackUsername,
        email: cleanEmail,
        password: newPassword,
        name: fallbackUsername,
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
          'username': cleanEmail.split('@')[0],
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

  Future<bool> checkIfUserExists(String input) async {
    final cleanInput = input.trim().toLowerCase();

    // Check username or email
    for (var u in _users.values) {
      if (u.email.toLowerCase() == cleanInput || u.username.toLowerCase() == cleanInput) {
        return true;
      }
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(cleanInput).get();
      if (doc.exists) {
        final data = doc.data()!;
        _users[cleanInput] = UserModel.fromMap(data, cleanInput);
        return true;
      }

      final q = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: cleanInput)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        final data = q.docs.first.data();
        final user = UserModel.fromMap(data, data['email'] ?? cleanInput);
        _users[user.email] = user;
        return true;
      }
    } catch (e) {
      debugPrint("Check User Exists Error: $e");
    }

    if (RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(cleanInput)) {
      final fallbackUsername = cleanInput.split('@')[0];
      _users[cleanInput] = UserModel(
        username: fallbackUsername,
        email: cleanInput,
        password: '',
        name: fallbackUsername,
      );
      return true;
    }

    return false;
  }

  Future<UserModel?> findUserByEmail(String input) async {
    final cleanInput = input.trim().toLowerCase();
    if (cleanInput.isEmpty) return null;

    // 1. Check Firestore doc by ID (if ID is email)
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(cleanInput).get();
      if (doc.exists && doc.data() != null) {
        final user = UserModel.fromMap(doc.data()!, cleanInput);
        _users[user.email] = user;
        return user;
      }
    } catch (e) {
      debugPrint("Doc lookup error: $e");
    }

    // 2. Query Firestore by username field
    try {
      final q = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: cleanInput)
          .get();
      if (q.docs.isNotEmpty) {
        final data = q.docs.first.data();
        final user = UserModel.fromMap(data, data['email'] ?? q.docs.first.id);
        _users[user.email] = user;
        return user;
      }
    } catch (e) {
      debugPrint("Where username error: $e");
    }

    // 3. Fallback: Scan all users in Firestore collection to guarantee match even if query indexing or casing varies
    try {
      final allDocs = await FirebaseFirestore.instance.collection('users').get();
      for (var d in allDocs.docs) {
        final data = d.data();
        final uName = (data['username'] ?? '').toString().trim().toLowerCase();
        final uEmail = (data['email'] ?? d.id).toString().trim().toLowerCase();
        if (uName == cleanInput || uEmail == cleanInput) {
          final user = UserModel.fromMap(data, uEmail);
          _users[user.email] = user;
          return user;
        }
      }
    } catch (e) {
      debugPrint("Scan users collection error: $e");
    }

    // 4. Fallback: Check in-memory users map (for offline/default seed users)
    for (var u in _users.values) {
      if (u.email.toLowerCase() == cleanInput || u.username.toLowerCase() == cleanInput) {
        return u;
      }
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
    return null;
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
  // ORDERS STATE & FIRESTORE CRUD (DATA ISOLATION PER USER)
  // -------------------------------------------------------------
  List<Order> _orders = [];

  List<Order> get orders {
    if (_currentRole == 'admin') {
      return _orders;
    }

    final email = _currentUser?.email.trim().toLowerCase() ?? '';
    final uname = _currentUser?.username.trim().toLowerCase() ?? '';
    final name = _currentUser?.name.trim().toLowerCase() ?? '';

    return _orders.where((o) {
      final oEmail = o.userEmail.trim().toLowerCase();
      final oName = o.customerName.trim().toLowerCase();
      if (oEmail.isNotEmpty && (oEmail == email || oEmail == uname)) {
        return true;
      }
      if (name.isNotEmpty && oName == name) {
        return true;
      }
      return false;
    }).toList();
  }

  List<Order> get allOrdersForAdmin => _orders;

  Future<void> placeOrder(String name, String phone, String address) async {
    if (_cartItems.isEmpty) return;

    final orderId = 'PL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final appliedPromo = _appliedPromotion;
    final finalDiscount = discountAmount;
    final finalTotal = cartFinalTotal;
    final userEmail = _currentUser?.email ?? '';

    final newOrder = Order(
      id: orderId,
      userEmail: userEmail,
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

  // -------------------------------------------------------------
  // USER AVATAR UPDATE
  // -------------------------------------------------------------
  Future<void> updateAvatarUrl(String url) async {
    final cleanUrl = url.trim();
    if (_currentUser != null) {
      _currentUser!.avatarUrl = cleanUrl;
      _users[_currentUser!.email.toLowerCase()]?.avatarUrl = cleanUrl;
      notifyListeners();

      try {
        await FirebaseFirestore.instance.collection('users').doc(_currentUser!.email.toLowerCase()).update({
          'avatarUrl': cleanUrl,
        });
      } catch (e) {
        debugPrint("Update Avatar Error: $e");
      }
    }
  }

  // -------------------------------------------------------------
  // REVIEWS & RATINGS STATE & FIRESTORE CRUD
  // -------------------------------------------------------------
  List<Review> _reviews = [];
  List<Review> get reviews => _reviews;

  List<Review> getReviewsForProduct(String productId) {
    return _reviews.where((r) => r.productId == productId).toList();
  }

  bool canUserReviewProduct(String productId) {
    if (_currentUser == null) return false;
    final email = _currentUser!.email.trim().toLowerCase();
    final uname = _currentUser!.username.trim().toLowerCase();
    final name = _currentUser!.name.trim().toLowerCase();

    // Check if user has an order with status 'Đã hoàn thành' containing this productId
    for (var order in _orders) {
      final oEmail = order.userEmail.trim().toLowerCase();
      final oName = order.customerName.trim().toLowerCase();
      final isOwner = (oEmail.isNotEmpty && (oEmail == email || oEmail == uname)) || (name.isNotEmpty && oName == name);

      if (isOwner && order.status == 'Đã hoàn thành') {
        for (var item in order.items) {
          if (item.beverage.id == productId) {
            return true;
          }
        }
      }
    }
    return false;
  }

  Future<void> addReview({
    required String productId,
    required double rating,
    required String comment,
  }) async {
    if (_currentUser == null) return;

    final reviewId = 'REV-${DateTime.now().millisecondsSinceEpoch}';
    final newReview = Review(
      id: reviewId,
      productId: productId,
      userEmail: _currentUser!.email,
      userName: _currentUser!.name.isNotEmpty ? _currentUser!.name : _currentUser!.username,
      userAvatar: _currentUser!.avatarUrl,
      rating: rating,
      comment: comment,
      date: DateTime.now(),
    );

    _reviews.insert(0, newReview);

    // Calculate new average rating for the product
    final productRevs = _reviews.where((r) => r.productId == productId).toList();
    double avgRating = productRevs.fold(0.0, (sum, r) => sum + r.rating) / productRevs.length;
    avgRating = double.parse(avgRating.toStringAsFixed(1));

    // Update beverage rating in memory
    final bevIndex = _beverages.indexWhere((b) => b.id == productId);
    if (bevIndex != -1) {
      _beverages[bevIndex] = _beverages[bevIndex].copyWith(rating: avgRating);
    }

    notifyListeners();

    try {
      await FirebaseFirestore.instance.collection('reviews').doc(newReview.id).set(newReview.toMap());
      await FirebaseFirestore.instance.collection('beverages').doc(productId).update({
        'rating': avgRating,
      });
    } catch (e) {
      debugPrint("Firestore Add Review Error: $e");
    }
  }
}
