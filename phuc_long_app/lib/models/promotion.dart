import 'package:cloud_firestore/cloud_firestore.dart';

class Promotion {
  final String id;
  final String code;
  final String title;
  final String description;
  final String discountType; // 'percent' or 'amount'
  final double discountValue; // e.g. 10.0 for 10% or 20000.0 for 20k
  final double minOrderPrice;
  bool isAvailable;
  final DateTime? expiryDate;

  Promotion({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderPrice = 0.0,
    this.isAvailable = true,
    this.expiryDate,
  });

  /// Calculates discount amount for a given subtotal
  double calculateDiscount(double subtotal) {
    if (!isAvailable || subtotal < minOrderPrice) return 0.0;
    if (expiryDate != null && DateTime.now().isAfter(expiryDate!)) return 0.0;

    if (discountType == 'percent') {
      final discount = subtotal * (discountValue / 100.0);
      return discount > subtotal ? subtotal : discount;
    } else {
      return discountValue > subtotal ? subtotal : discountValue;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code.toUpperCase().trim(),
      'title': title,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderPrice': minOrderPrice,
      'isAvailable': isAvailable,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
    };
  }

  factory Promotion.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parsedExpiry;
    if (map['expiryDate'] != null) {
      if (map['expiryDate'] is Timestamp) {
        parsedExpiry = (map['expiryDate'] as Timestamp).toDate();
      } else if (map['expiryDate'] is String) {
        parsedExpiry = DateTime.tryParse(map['expiryDate']);
      }
    }

    return Promotion(
      id: map['id'] ?? docId,
      code: (map['code'] ?? docId).toString().toUpperCase().trim(),
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      discountType: map['discountType'] ?? 'percent',
      discountValue: (map['discountValue'] ?? 0.0).toDouble(),
      minOrderPrice: (map['minOrderPrice'] ?? 0.0).toDouble(),
      isAvailable: map['isAvailable'] ?? true,
      expiryDate: parsedExpiry,
    );
  }

  factory Promotion.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Promotion.fromMap(data, doc.id);
  }

  Promotion copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    String? discountType,
    double? discountValue,
    double? minOrderPrice,
    bool? isAvailable,
    DateTime? expiryDate,
  }) {
    return Promotion(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minOrderPrice: minOrderPrice ?? this.minOrderPrice,
      isAvailable: isAvailable ?? this.isAvailable,
      expiryDate: expiryDate ?? this.expiryDate,
    );
  }
}

// Default initial mock promotions for Firestore seeding
List<Promotion> mockPromotions = [
  Promotion(
    id: 'PROMO-10',
    code: 'PHUCLONG10',
    title: 'Giảm 10% Tổng Đơn Hàng',
    description: 'Áp dụng cho mọi đơn hàng từ 50.000đ khi đặt mua trà & cà phê Phúc Long.',
    discountType: 'percent',
    discountValue: 10.0,
    minOrderPrice: 50000.0,
    isAvailable: true,
  ),
  Promotion(
    id: 'PROMO-20K',
    code: 'WELCOME20K',
    title: 'Giảm 20.000đ Cho Đơn Từ 80k',
    description: 'Khuyến mãi tri ân khách hàng thân thiết áp dụng cho hóa đơn từ 80.000đ trở lên.',
    discountType: 'amount',
    discountValue: 20000.0,
    minOrderPrice: 80000.0,
    isAvailable: true,
  ),
  Promotion(
    id: 'PROMO-FREESHIP',
    code: 'FREESHIP15K',
    title: 'Giảm 15.000đ Phí Vận Chuyển',
    description: 'Ưu đãi giảm 15k trên tổng hóa đơn áp dụng cho đơn từ 100.000đ.',
    discountType: 'amount',
    discountValue: 15000.0,
    minOrderPrice: 100000.0,
    isAvailable: true,
  ),
];
