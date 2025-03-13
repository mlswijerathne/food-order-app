import 'package:flutter/material.dart';
import 'package:foodapp/models/order_model.dart';
import 'package:foodapp/models/user_model.dart';
import 'package:foodapp/services/admin_orders_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:foodapp/screens/admin/admin_order_details_screen.dart';

class AdminOrderScreen extends StatefulWidget {
  const AdminOrderScreen({super.key});

  @override
  _AdminOrderScreenState createState() => _AdminOrderScreenState();
}

class _AdminOrderScreenState extends State<AdminOrderScreen> with TickerProviderStateMixin {
  final AdminOrderService _adminOrderService = AdminOrderService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  
  List<OrderModel> _orders = [];
  final Map<String, UserModel?> _userCache = {};
  bool _isLoading = true;
  String? _errorMessage;
  
  // Status filter options
  final List<String> _statusFilters = [
    'All',
    'pending',
    'processing',
    'delivered',
    'cancelled'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statusFilters.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
    _setupRealTimeOrders();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _isLoading = true;
      });
      _fetchOrders();
    }
  }

  void _setupRealTimeOrders() {
    // Initial fetch
    _fetchOrders();

    // Setup real-time listener
    _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      _fetchOrders();
    });
  }

  Future<void> _fetchOrders() async {
    try {
      // Get the current selected tab/filter
      String? statusFilter;
      if (_tabController.index > 0) {
        statusFilter = _statusFilters[_tabController.index];
      }

      // Fetch orders with status filter
      List<OrderModel> orders = await _adminOrderService.getAllOrders(
        statusFilter: statusFilter == 'All' ? null : statusFilter,
      );

      // Pre-fetch user details for all orders
      for (var order in orders) {
        if (!_userCache.containsKey(order.userId)) {
          _userCache[order.userId] = await _adminOrderService.getUserById(order.userId);
        }
      }

      setState(() {
        _orders = orders;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load orders: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      bool success = await _adminOrderService.updateOrderStatus(orderId, newStatus);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order status updated to $newStatus')),
        );
        
        // Refresh orders to update the UI
        _fetchOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update order status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
  
  // New method to handle order cancellation with confirmation dialog
  Future<void> _showCancelConfirmationDialog(String orderId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Order'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to cancel this order?'),
                Text('This action cannot be undone.', 
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Yes, Cancel Order', 
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _updateOrderStatus(orderId, 'cancelled');
              },
            ),
          ],
        );
      },
    );
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

  // Handle back navigation
  Future<bool> _onWillPop() async {
    Navigator.of(context).pushReplacementNamed('/admin_home');
    return false; // Prevents default back button behavior
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Order Management'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pushReplacementNamed('/admin_home');
            },
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: _statusFilters.map((status) => Tab(text: status)).toList(),
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!))
                : _orders.isEmpty
                    ? Center(child: Text('No orders found'))
                    : ListView.builder(
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          final user = _userCache[order.userId];
                          
                          return Card(
                            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(order.status),
                                child: Text(
                                  order.status.substring(0, 1).toUpperCase(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Order #${order.id.substring(0, 8)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Customer: ${user?.name ?? 'Unknown'} (${user?.contactNumber ?? 'No phone'})',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    _getOrderSummary(order),
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    'Total: \$${order.totalAmount.toStringAsFixed(2)} • ${DateFormat('MMM dd, yyyy • hh:mm a').format(order.orderDate)}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (order.deliveryAddress != null)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(Icons.location_on, size: 16),
                                              SizedBox(width: 8),
                                              Expanded(
                                                child: Text('${order.deliveryAddress}'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Divider(),
                                      Text(
                                        'Items:',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      ...order.items.map((item) => Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text('${item.quantity}x ${item.food.name}'),
                                                Text('\$${(item.food.price * item.quantity).toStringAsFixed(2)}'),
                                              ],
                                            ),
                                          )),
                                      Divider(),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Total Amount:',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            '\$${order.totalAmount.toStringAsFixed(2)}',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Update Status:',
                                            style: TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          // Add a more visible Cancel button
                                          if (order.status != 'cancelled')
                                            ElevatedButton.icon(
                                              icon: Icon(Icons.cancel),
                                              label: Text('Cancel Order'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                              ),
                                              onPressed: () => _showCancelConfirmationDialog(order.id),
                                            ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Ensures even spacing
                                        children: [
                                          Flexible(child: _buildStatusButton(order.id, 'pending', order.status)),
                                          Flexible(child: _buildStatusButton(order.id, 'process', order.status)),
                                          Flexible(child: _buildStatusButton(order.id, 'delivered', order.status)),
                                        ],
                                      ),
                                      SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        icon: Icon(Icons.info_outline),
                                        label: Text('View Full Details'),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => AdminOrderDetailScreen(orderId: order.id),
                                            ),
                                          ).then((_) => _fetchOrders()); // Refresh after returning
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          foregroundColor: Colors.white,
                                          minimumSize: Size(double.infinity, 36),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
        floatingActionButton: FloatingActionButton(
          onPressed: _fetchOrders,
          tooltip: 'Refresh Orders',
          child: Icon(Icons.refresh),
        ),
      ),
    );
  }

  Widget _buildStatusButton(String orderId, String status, String currentStatus) {
    // Fix for the "process" status to match the expected "processing" status
    String statusValue = status == 'process' ? 'processing' : status;
    bool isCurrentStatus = statusValue == currentStatus;
    
    return ElevatedButton(
      onPressed: isCurrentStatus ? null : () => _updateOrderStatus(orderId, statusValue),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrentStatus ? _getStatusColor(statusValue) : Colors.grey.shade200,
        foregroundColor: isCurrentStatus ? Colors.white : Colors.black,
      ),
      child: Text(StringExtension(status).capitalize()),
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

// Extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return isNotEmpty 
        ? '${this[0].toUpperCase()}${substring(1)}'
        : '';
  }
}