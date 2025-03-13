import 'package:foodapp/models/food_model.dart';

class CartItemModel {
  final String id;
  final FoodModel food;
  int quantity;

  CartItemModel({
    required this.id,
    required this.food,
    this.quantity = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodId': food.id,
      'quantity': quantity,
    };
  }

  double get totalPrice => food.price * quantity;
}