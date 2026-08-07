import 'package:cloud_firestore/cloud_firestore.dart';

enum BeverageCategory { all, tea, milkTea, coffee, special }

class Beverage {
  final String id;
  final String name;
  final BeverageCategory category;
  final String categoryName;
  final double price;
  final String imageUrl;
  final String description;
  bool isAvailable;
  final double rating;
  final bool isPopular;

  Beverage({
    required this.id,
    required this.name,
    required this.category,
    this.categoryName = '',
    required this.price,
    required this.imageUrl,
    required this.description,
    this.isAvailable = true,
    required this.rating,
    this.isPopular = false,
  });

  Beverage copyWith({
    String? id,
    String? name,
    BeverageCategory? category,
    String? categoryName,
    double? price,
    String? imageUrl,
    String? description,
    bool? isAvailable,
    double? rating,
    bool? isPopular,
  }) {
    return Beverage(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      categoryName: categoryName ?? this.categoryName,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      isPopular: isPopular ?? this.isPopular,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'categoryName': categoryName.isNotEmpty ? categoryName : categoryDisplayName,
      'price': price,
      'imageUrl': imageUrl,
      'description': description,
      'isAvailable': isAvailable,
      'rating': rating,
      'isPopular': isPopular,
    };
  }

  factory Beverage.fromMap(Map<String, dynamic> map, String docId) {
    BeverageCategory cat = BeverageCategory.all;
    final catStr = map['category'] ?? '';
    for (var c in BeverageCategory.values) {
      if (c.name == catStr) {
        cat = c;
        break;
      }
    }
    final catNameStr = (map['categoryName'] as String?)?.trim() ?? '';

    return Beverage(
      id: map['id'] ?? docId,
      name: map['name'] ?? '',
      category: cat,
      categoryName: catNameStr,
      price: (map['price'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      description: map['description'] ?? '',
      isAvailable: map['isAvailable'] ?? true,
      rating: (map['rating'] ?? 4.5).toDouble(),
      isPopular: map['isPopular'] ?? false,
    );
  }

  factory Beverage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Beverage.fromMap(data, doc.id);
  }

  String get categoryDisplayName {
    if (categoryName.trim().isNotEmpty) {
      return categoryName.trim();
    }
    switch (category) {
      case BeverageCategory.tea:
        return 'Trà Trái Cây';
      case BeverageCategory.milkTea:
        return 'Trà Sữa';
      case BeverageCategory.coffee:
        return 'Cà Phê';
      case BeverageCategory.special:
        return 'Đá Xay / Đặc Biệt';
      default:
        return 'Tất Cả';
    }
  }
}

// Initial mock data
List<Beverage> mockBeverages = [
  Beverage(
    id: '1',
    name: 'Trà Đào Phúc Long',
    category: BeverageCategory.tea,
    price: 55000,
    imageUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    description: 'Trà đào thơm ngon nức tiếng trứ danh Phúc Long. Sự kết hợp hoàn hảo giữa vị trà đen đậm đà và những miếng đào tươi giòn ngọt lịm.',
    rating: 4.8,
    isPopular: true,
  ),
  Beverage(
    id: '2',
    name: 'Trà Sữa Phúc Long',
    category: BeverageCategory.milkTea,
    price: 60000,
    imageUrl: 'https://images.unsplash.com/photo-1541658016709-82535e94bc69?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    description: 'Vị trà sữa truyền thống trứ danh với vị trà đen Phúc Long đậm đà đặc trưng kết hợp với sữa đặc béo ngậy, mang lại hương vị khó quên.',
    rating: 4.9,
    isPopular: true,
  ),
  Beverage(
    id: '3',
    name: 'Hồng Trà Đười Ươi Hạt Chia',
    category: BeverageCategory.tea,
    price: 65000,
    imageUrl: 'https://images.unsplash.com/photo-1597481499750-3e6b22637e12?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    description: 'Sự thanh mát tuyệt vời từ hạt chia và hạt đười ươi, hòa quyện với vị hồng trà thanh ngọt tự nhiên giúp thanh nhiệt giải độc.',
    rating: 4.5,
  ),
  Beverage(
    id: '4',
    name: 'Cà Phê Sữa Đá Phúc Long',
    category: BeverageCategory.coffee,
    price: 45000,
    imageUrl: 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    description: 'Được pha chế từ những hạt cà phê Robusta và Arabica thượng hạng rang xay nguyên chất, kết hợp với sữa đặc béo ngọt thuần Việt.',
    rating: 4.7,
    isPopular: true,
  ),
  Beverage(
    id: '5',
    name: 'Trà Ô Long Sữa',
    category: BeverageCategory.milkTea,
    price: 58000,
    imageUrl: 'https://images.unsplash.com/photo-1576092768241-dec231879fc3?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    description: 'Trà ô long thượng hạng được chắt lọc kỹ lưỡng kết hợp với sữa béo dịu nhẹ, tạo nên hậu vị chát ngọt sâu lắng ngây ngất.',
    rating: 4.6,
  ),
  Beverage(
    id: '6',
    name: 'Phin Sữa Đá Nóng/Lạnh',
    category: BeverageCategory.coffee,
    price: 39000,
    imageUrl: 'https://images.unsplash.com/photo-1606791405792-1004f1718d0c?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    description: 'Cà phê pha phin truyền thống nhỏ giọt, đậm vị đắng từ hạt cafe nguyên chất hòa quyện cùng sữa đặc.',
    rating: 4.4,
  ),
  Beverage(
    id: '7',
    name: 'Trà Nhãn Sen Phúc Long',
    category: BeverageCategory.special,
    price: 65000,
    imageUrl: 'https://images.unsplash.com/photo-1597481499750-3e6b22637e12?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    description: 'Món nước signature mang hương vị hoàng cung. Vị thanh tao của trà sen kết hợp cùng cùi nhãn ngọt lịm, giòn sần sật bọc hạt sen bùi ngậy.',
    rating: 4.9,
    isPopular: true,
  ),
  Beverage(
    id: '8',
    name: 'Matcha Đá Xay',
    category: BeverageCategory.special,
    price: 65000,
    imageUrl: 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3',
    description: 'Bột matcha Uji Nhật Bản thượng hạng kết hợp kem sữa béo ngậy được xay nhuyễn mịn màng, phủ thêm lớp kem tươi bông mịn trên cùng.',
    rating: 4.7,
  ),
];

class CartItem {
  final Beverage beverage;
  int quantity;
  String size; // S, M, L
  double sugar; // 0%, 30%, 50%, 70%, 100%
  double ice; // 0%, 50%, 100%

  CartItem({
    required this.beverage,
    this.quantity = 1,
    this.size = 'M',
    this.sugar = 1.0,
    this.ice = 1.0,
  });

  double get totalPrice {
    double basePrice = beverage.price;
    if (size == 'L') basePrice += 10000;
    if (size == 'S') basePrice -= 5000;
    return basePrice * quantity;
  }

  Map<String, dynamic> toMap() {
    return {
      'beverage': beverage.toMap(),
      'quantity': quantity,
      'size': size,
      'sugar': sugar,
      'ice': ice,
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    final bevData = map['beverage'] as Map<String, dynamic>? ?? {};
    return CartItem(
      beverage: Beverage.fromMap(bevData, bevData['id'] ?? ''),
      quantity: map['quantity'] ?? 1,
      size: map['size'] ?? 'M',
      sugar: (map['sugar'] ?? 1.0).toDouble(),
      ice: (map['ice'] ?? 1.0).toDouble(),
    );
  }
}

class Order {
  final String id;
  final String userEmail; // Associated user email/username for data isolation
  final List<CartItem> items;
  final double total;
  final double discountAmount;
  final String promoCode;
  final DateTime date;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  String status; // Pending, Processing, Shipping, Completed, Cancelled
  String cancelReason;

  Order({
    required this.id,
    this.userEmail = '',
    required this.items,
    required this.total,
    this.discountAmount = 0.0,
    this.promoCode = '',
    required this.date,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.status = 'Chờ xử lý',
    this.cancelReason = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userEmail': userEmail,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'discountAmount': discountAmount,
      'promoCode': promoCode,
      'date': Timestamp.fromDate(date),
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'status': status,
      'cancelReason': cancelReason,
    };
  }

  factory Order.fromMap(Map<String, dynamic> map, String docId) {
    DateTime orderDate = DateTime.now();
    if (map['date'] != null) {
      if (map['date'] is Timestamp) {
        orderDate = (map['date'] as Timestamp).toDate();
      } else if (map['date'] is String) {
        orderDate = DateTime.tryParse(map['date']) ?? DateTime.now();
      }
    }

    final rawItems = map['items'] as List<dynamic>? ?? [];
    final itemList = rawItems
        .map((itemMap) => CartItem.fromMap(itemMap as Map<String, dynamic>))
        .toList();

    return Order(
      id: map['id'] ?? docId,
      userEmail: map['userEmail'] ?? '',
      items: itemList,
      total: (map['total'] ?? 0.0).toDouble(),
      discountAmount: (map['discountAmount'] ?? 0.0).toDouble(),
      promoCode: map['promoCode'] ?? '',
      date: orderDate,
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerAddress: map['customerAddress'] ?? '',
      status: map['status'] ?? 'Chờ xử lý',
      cancelReason: map['cancelReason'] ?? '',
    );
  }

  factory Order.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Order.fromMap(data, doc.id);
  }
}
