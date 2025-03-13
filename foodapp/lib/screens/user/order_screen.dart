import 'package:flutter/material.dart';
import 'package:foodapp/models/order_model.dart';
import 'package:foodapp/models/user_model.dart';
import 'package:foodapp/services/order_service.dart';
import 'package:foodapp/services/auth_service.dart';
import 'package:foodapp/screens/user/order_detail_screen.dart';
import 'package:intl/intl.dart';

class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key});

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final AuthService _authService = AuthService();
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = true;
  String? _errorMessage;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _fetchUserAndOrders();
  }

  Future<void> _fetchUserAndOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserModel? user = await _authService.getCurrentUser();
      if (user == null) {
        setState(() {
          _errorMessage = 'Please sign in to view your orders';
          _isLoading = false;
        });
        return;
      }

      _currentUser = user;
      List<OrderModel> orders = await _orderService.getUserOrders(user.uid);

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load orders: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  String _getOrderSummary(OrderModel order) {
    if (order.items.isEmpty) {
      return "No items";
    }
    
    // Get the first item details
    final firstItem = order.items[0];
    final itemCount = order.items.length;
    
    if (itemCount == 1) {
      return "${firstItem.quantity}x ${firstItem.food.name}";
    } else {
      return "${firstItem.quantity}x ${firstItem.food.name} + ${itemCount - 1} more";
    }
  }

  // Handle back button press
  Future<bool> _onWillPop() async {
    // Navigate to home route
    Navigator.of(context).pushReplacementNamed('/');
    // Return false to prevent default back behavior
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Orders'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/');
            },
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _fetchUserAndOrders,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : _orders.isEmpty
                      ? const Center(child: Text('No orders found'))
                      : ListView.builder(
                          itemCount: _orders.length,
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => OrderDetailScreen(order: order),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Order #${order.id.substring(0, 8)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(order.status),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              order.status,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _getOrderSummary(order),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total: \$${order.totalAmount.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('MMM dd, yyyy').format(order.orderDate),
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}