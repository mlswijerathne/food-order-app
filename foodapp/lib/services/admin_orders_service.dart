import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/cart_item_model.dart';
import '../models/food_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AdminOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  // Get all orders
  Future<List<OrderModel>> getAllOrders({String? statusFilter}) async {
    try {
      QuerySnapshot snapshot;
      
      if (statusFilter != null && statusFilter.isNotEmpty) {
        snapshot = await _firestore
            .collection('orders')
            .where('status', isEqualTo: statusFilter)
            .orderBy('orderDate', descending: true)
            .get();
      } else {
        snapshot = await _firestore
            .collection('orders')
            .orderBy('orderDate', descending: true)
            .get();
      }
      
      List<OrderModel> orders = [];
      
      for (var doc in snapshot.docs) {
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
        
        orders.add(OrderModel(
          id: doc.id, // Use document ID directly to ensure consistency
          userId: data['userId'],
          items: items,
          totalAmount: data['totalAmount'],
          status: data['status'],
          orderDate: (data['orderDate'] as Timestamp).toDate(),
          deliveryAddress: data['deliveryAddress'],
        ));
      }
      
      return orders;
    } catch (e) {
      debugPrint("Error getting all orders: ${e.toString()}");
      return [];
    }
  }

  // Get user details by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        
        return UserModel(
          uid: userId,
          email: data['email'] ?? '',
          name: data['name'] ?? '',
          contactNumber: data['phoneNumber'] ?? '',  // Map phoneNumber to contactNumber
          profilePicture: data['profilePicture'] ?? '',
          isAdmin: data['isAdmin'] ?? false,
        );
      }
      
      return null;
    } catch (e) {
      debugPrint("Error getting user by ID: ${e.toString()}");
      return null;
    }
  }

  // Update order status
  Future<bool> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'lastUpdated': FieldValue.serverTimestamp(), // Add timestamp for when status was last updated
      });
      
      return true;
    } catch (e) {
      debugPrint("Error updating order status: ${e.toString()}");
      return false;
    }
  }

  // Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('orders').doc(orderId).get();
      
      if (doc.exists) {
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
          id: doc.id, // Use document ID directly
          userId: data['userId'],
          items: items,
          totalAmount: data['totalAmount'],
          status: data['status'],
          orderDate: (data['orderDate'] as Timestamp).toDate(),
          deliveryAddress: data['deliveryAddress'],
        );
      }
      
      return null;
    } catch (e) {
      debugPrint("Error getting order by ID: ${e.toString()}");
      return null;
    }
  }

  // Get order statistics - UPDATED to match the statuses used in the app
  Future<Map<String, dynamic>> getOrderStatistics() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('orders')
          .get();
      
      int totalOrders = snapshot.docs.length;
      double totalRevenue = 0;
      Map<String, int> statusCounts = {
        'pending': 0,
        'processing': 0,
        'delivered': 0,
        'cancelled': 0,
      };
      
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        totalRevenue += data['totalAmount'] ?? 0;
        
        String status = data['status'] ?? '';
        if (statusCounts.containsKey(status)) {
          statusCounts[status] = statusCounts[status]! + 1;
        }
      }
      
      return {
        'totalOrders': totalOrders,
        'totalRevenue': totalRevenue,
        'statusCounts': statusCounts,
      };
    } catch (e) {
      debugPrint("Error getting order statistics: ${e.toString()}");
      return {
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'statusCounts': {
          'pending': 0,
          'processing': 0,
          'delivered': 0,
          'cancelled': 0,
        },
      };
    }
  }
  
  // Cancel an order
  Future<bool> cancelOrder(String orderId) async {
    return await updateOrderStatus(orderId, 'cancelled');
  }
}