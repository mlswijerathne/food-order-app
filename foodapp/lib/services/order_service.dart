import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../models/food_model.dart';
import '../services/cart_service.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CartService _cartService = CartService();
  final AuthService _authService = AuthService();

  // Get current user
  Future<UserModel?> getUser() async {
    try {
      return await _authService.getCurrentUser();
    } catch (e) {
      debugPrint("Error getting current user in OrderService: ${e.toString()}");
      return null;
    }
  }

  // Place a new order with improved security
  Future<String?> placeOrder(String userId, List<CartItemModel> cartItems, 
      double totalAmount, String? deliveryAddress) async {
    try {
      // Get the authenticated user from AuthService
      UserModel? currentUser = await _authService.getCurrentUser();
      
      // Verify user is authenticated
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }
      
      // Verify the provided userId matches the authenticated user's ID
      if (currentUser.uid != userId) {
        throw Exception("User authentication mismatch");
      }
      
      // Create a new order with the verified user ID
      DocumentReference orderRef = await _firestore.collection('orders').add({
        'userId': currentUser.uid,
        'items': cartItems.map((item) => {
          'foodId': item.food.id,
          'name': item.food.name,
          'price': item.food.price,
          'quantity': item.quantity,
        }).toList(),
        'totalAmount': totalAmount,
        'status': 'pending',
        'orderDate': FieldValue.serverTimestamp(),
        'deliveryAddress': deliveryAddress,
      });
      
      // Update with the generated ID
      await orderRef.update({'id': orderRef.id});
      
      // Clear the cart after successful order
      await _cartService.clearCart(userId);
      
      return orderRef.id;
    } catch (e) {
      debugPrint("Error placing order: ${e.toString()}");
      return null;
    }
  }

  // Get user orders
  Future<List<OrderModel>> getUserOrders(String userId) async {
    try {
      // Verify the user is authenticated and matches the requested userId
      UserModel? currentUser = await _authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }
      
      if (currentUser.uid != userId && !currentUser.isAdmin) {
        throw Exception("Unauthorized access to orders");
      }
      
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .orderBy('orderDate', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        List<CartItemModel> items = [];
        if (data['items'] != null) {
          for (var item in data['items']) {
            FoodModel food = FoodModel(
              id: item['foodId'],
              name: item['name'],
              description: '', // These fields won't be available in the order
              price: item['price'],
              foodPicture: '', // We don't store the image in the order
            );
            
            items.add(CartItemModel(
              id: item['foodId'],
              food: food,
              quantity: item['quantity'],
            ));
          }
        }
        
        return OrderModel(
          id: data['id'],
          userId: data['userId'],
          items: items,
          totalAmount: data['totalAmount'],
          status: data['status'],
          orderDate: (data['orderDate'] as Timestamp).toDate(),
          deliveryAddress: data['deliveryAddress'],
        );
      }).toList();
    } catch (e) {
      debugPrint("Error getting user orders: ${e.toString()}");
      return [];
    }
  }
  
  // Admin function to get all orders
  Future<List<OrderModel>> getAllOrders() async {
    try {
      // Verify the current user is an admin
      UserModel? currentUser = await _authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }
      
      if (!currentUser.isAdmin) {
        throw Exception("Unauthorized access: Admin privileges required");
      }
      
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .orderBy('orderDate', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        List<CartItemModel> items = [];
        if (data['items'] != null) {
          for (var item in data['items']) {
            FoodModel food = FoodModel(
              id: item['foodId'],
              name: item['name'],
              description: '',
              price: item['price'],
              foodPicture: '',
            );
            
            items.add(CartItemModel(
              id: item['foodId'],
              food: food,
              quantity: item['quantity'],
            ));
          }
        }
        
        return OrderModel(
          id: data['id'],
          userId: data['userId'],
          items: items,
          totalAmount: data['totalAmount'],
          status: data['status'],
          orderDate: (data['orderDate'] as Timestamp).toDate(),
          deliveryAddress: data['deliveryAddress'],
        );
      }).toList();
    } catch (e) {
      debugPrint("Error getting all orders: ${e.toString()}");
      return [];
    }
  }
  
  // Update order status (admin only)
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      // Verify the current user is an admin
      UserModel? currentUser = await _authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }
      
      if (!currentUser.isAdmin) {
        throw Exception("Unauthorized access: Admin privileges required");
      }
      
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus
      });
      
      return true;
    } catch (e) {
      debugPrint("Error updating order status: ${e.toString()}");
      return false;
    }
  }
  
  // Cancel an order (user can cancel their own orders)
  Future<bool> cancelOrder(String orderId) async {
    try {
      // Get the current user
      UserModel? currentUser = await _authService.getCurrentUser();
      
      if (currentUser == null) {
        throw Exception("User not authenticated");
      }
      
      // Get the order
      DocumentSnapshot orderDoc = await _firestore.collection('orders').doc(orderId).get();
      
      if (!orderDoc.exists) {
        throw Exception("Order not found");
      }
      
      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
      
      // Verify the order belongs to the current user or user is admin
      if (orderData['userId'] != currentUser.uid && !currentUser.isAdmin) {
        throw Exception("Unauthorized access to order");
      }
      
      // Only allow cancellation if order is still pending or processing
      if (orderData['status'] != 'pending' && orderData['status'] != 'processing') {
        throw Exception("Cannot cancel order at current status: ${orderData['status']}");
      }
      
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'cancelled'
      });
      
      return true;
    } catch (e) {
      debugPrint("Error cancelling order: ${e.toString()}");
      return false;
    }
  }
}