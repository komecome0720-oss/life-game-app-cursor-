import 'package:cloud_firestore/cloud_firestore.dart';

class WishItem {
  const WishItem({
    required this.id,
    required this.name,
    required this.price,
    this.shopUrl = '',
    this.imageUrl = '',
    this.isPurchased = false,
    required this.createdAt,
  });

  final String id;
  final String name;
  final int price;
  final String shopUrl;
  final String imageUrl;
  final bool isPurchased;
  final DateTime createdAt;

  factory WishItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WishItem(
      id: doc.id,
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      shopUrl: data['shopUrl'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      isPurchased: data['isPurchased'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'price': price,
      'shopUrl': shopUrl,
      'imageUrl': imageUrl,
      'isPurchased': isPurchased,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  WishItem copyWith({bool? isPurchased}) {
    return WishItem(
      id: id,
      name: name,
      price: price,
      shopUrl: shopUrl,
      imageUrl: imageUrl,
      isPurchased: isPurchased ?? this.isPurchased,
      createdAt: createdAt,
    );
  }
}
