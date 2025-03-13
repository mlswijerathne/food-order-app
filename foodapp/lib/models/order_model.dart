import '../models/cart_item_model.dart';

class OrderModel {
  final String id;
  final String userId;
  final List<CartItemModel> items;
  final double totalAmount;
  final String status; // "pending", "processing", "delivered", "cancelled"
  final DateTime orderDate;
  final String? deliveryAddress;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.orderDate,
    this.deliveryAddress,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'items': items.map((item) => {
        'foodId': item.food.id,
        'name': item.food.name,
        'price': item.food.price,
        'quantity': item.quantity,
      }).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'orderDate': orderDate,
      'deliveryAddress': deliveryAddress,
    };
  }
}
