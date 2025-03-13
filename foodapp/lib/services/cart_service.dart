import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/cart_item_model.dart';
import '../models/food_model.dart';
import 'food_service.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FoodService _foodService = FoodService();

  // Add item to cart
  Future<bool> addToCart(String userId, FoodModel food, {int quantity = 1}) async {
    try {
      // Check if the item already exists in the cart
      QuerySnapshot existingItems = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .where('foodId', isEqualTo: food.id)
          .get();

      if (existingItems.docs.isNotEmpty) {
        // Update existing item quantity
        String cartItemId = existingItems.docs.first.id;
        int currentQuantity = existingItems.docs.first['quantity'];
        
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('cart')
            .doc(cartItemId)
            .update({'quantity': currentQuantity + quantity});
      } else {
        // Add new item to cart
        await _firestore.collection('users').doc(userId).collection('cart').add({
          'foodId': food.id,
          'quantity': quantity,
          'addedAt': FieldValue.serverTimestamp(),
        });
      }
      
      return true;
    } catch (e) {
      debugPrint("Error adding to cart: ${e.toString()}");
      return false;
    }
  }

  // Get cart items
  Future<List<CartItemModel>> getCartItems(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();

      List<CartItemModel> cartItems = [];
      
      for (var doc in snapshot.docs) {
        String foodId = doc['foodId'];
        FoodModel? food = await _foodService.getFoodById(foodId);
        
        if (food != null) {
          cartItems.add(CartItemModel(
            id: doc.id,
            food: food,
            quantity: doc['quantity'],
          ));
        }
      }
      
      return cartItems;
    } catch (e) {
      debugPrint("Error getting cart items: ${e.toString()}");
      return [];
    }
  }

  // Update cart item quantity
  Future<bool> updateCartItemQuantity(String userId, String cartItemId, int quantity) async {
    try {
      if (quantity <= 0) {
        // Remove item if quantity is 0 or less
        return removeCartItem(userId, cartItemId);
      }
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(cartItemId)
          .update({'quantity': quantity});
      
      return true;
    } catch (e) {
      debugPrint("Error updating cart item: ${e.toString()}");
      return false;
    }
  }

  // Remove item from cart
  Future<bool> removeCartItem(String userId, String cartItemId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .doc(cartItemId)
          .delete();
      
      return true;
    } catch (e) {
      debugPrint("Error removing cart item: ${e.toString()}");
      return false;
    }
  }

  // Clear cart
  Future<bool> clearCart(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('cart')
          .get();
      
      WriteBatch batch = _firestore.batch();
      
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      return true;
    } catch (e) {
      debugPrint("Error clearing cart: ${e.toString()}");
      return false;
    }
  }

  // Get cart total
  Future<double> getCartTotal(String userId) async {
    try {
      List<CartItemModel> cartItems = await getCartItems(userId);
      double total = 0;
      
      for (var item in cartItems) {
        total += item.food.price * item.quantity;
      }
      
      return total;
    } catch (e) {
      debugPrint("Error calculating cart total: ${e.toString()}");
      return 0;
    }
  }
}