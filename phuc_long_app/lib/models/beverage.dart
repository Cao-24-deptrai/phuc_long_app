import 'package:flutter/material.dart';

enum BeverageCategory { all, tea, milkTea, coffee, special }

class Beverage {
  final String id;
  final String name;
  final BeverageCategory category;
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
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating ?? this.rating,
      isPopular: isPopular ?? this.isPopular,
    );
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
}

class Order {
  final String id;
  final List<CartItem> items;
  final double total;
  final DateTime date;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  String status; // Pending, Processing, Shipping, Completed, Cancelled

  Order({
    required this.id,
    required this.items,
    required this.total,
    required this.date,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    this.status = 'Chờ xử lý',
  });
}
