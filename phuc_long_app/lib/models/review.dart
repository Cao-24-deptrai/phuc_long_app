import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id;
  final String productId;
  final String userEmail;
  final String userName;
  final String userAvatar;
  final double rating; // 1.0 to 5.0
  final String comment;
  final DateTime date;

  Review({
    required this.id,
    required this.productId,
    required this.userEmail,
    required this.userName,
    this.userAvatar = '',
    required this.rating,
    required this.comment,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'userEmail': userEmail,
      'userName': userName,
      'userAvatar': userAvatar,
      'rating': rating,
      'comment': comment,
      'date': Timestamp.fromDate(date),
    };
  }

  factory Review.fromMap(Map<String, dynamic> map, String docId) {
    DateTime reviewDate = DateTime.now();
    if (map['date'] != null) {
      if (map['date'] is Timestamp) {
        reviewDate = (map['date'] as Timestamp).toDate();
      } else if (map['date'] is String) {
        reviewDate = DateTime.tryParse(map['date']) ?? DateTime.now();
      }
    }

    return Review(
      id: map['id'] ?? docId,
      productId: map['productId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userName: map['userName'] ?? 'Người dùng',
      userAvatar: map['userAvatar'] ?? '',
      rating: (map['rating'] ?? 5.0).toDouble(),
      comment: map['comment'] ?? '',
      date: reviewDate,
    );
  }

  factory Review.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Review.fromMap(data, doc.id);
  }
}
